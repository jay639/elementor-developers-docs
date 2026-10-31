import 'dart:async';

import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/core/utils/clock.dart';
import 'package:arrow_escape/features/save/data/save_repository.dart';
import 'package:arrow_escape/features/save/domain/economy.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:arrow_escape/features/settings/domain/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final saveProvider = NotifierProvider<SaveController, SaveData>(
  SaveController.new,
);

/// Owns the save document: applies economy rules, stamps revisions and
/// persists every change (writes are serialised, newest wins).
class SaveController extends Notifier<SaveData> {
  Future<void> _writes = Future.value();

  /// Listeners for cloud sync (phase 6).
  final _changes = StreamController<SaveData>.broadcast();
  Stream<SaveData> get changes => _changes.stream;

  @override
  SaveData build() {
    ref.onDispose(_changes.close);
    return ref.watch(initialSaveProvider).save;
  }

  /// Current save, for collaborators outside the provider graph.
  SaveData get current => state;

  DateTime get _now => ref.read(clockProvider)();

  /// Applies [change]; no-op when nothing changed.
  void apply(SaveData Function(SaveData) change) {
    final next = change(state);
    if (next == state) return;
    _commit(
      next.copyWith(
        revision: state.revision + 1,
        updatedAt: _now.millisecondsSinceEpoch,
      ),
    );
  }

  /// Adopts a save from elsewhere (cloud merge) as-is.
  void replace(SaveData next) {
    if (next == state) return;
    _commit(next);
  }

  void _commit(SaveData next) {
    state = next;
    if (!_changes.isClosed) _changes.add(next);
    final repo = ref.read(saveRepositoryProvider);
    _writes = _writes.then((_) => repo.save(next)).catchError((Object e) {
      debugPrint('Save failed: $e');
    });
  }

  /// Completes pending writes (tests, app pause).
  Future<void> flush() => _writes;

  AnalyticsService get _analytics => ref.read(analyticsProvider);

  void _earned(int coins, String reason) {
    if (coins > 0) _analytics.earnCoins(coins, reason);
  }

  void _logStreak(int before) {
    if (state.streak != before) {
      _analytics.log('streak_update', {'streak_days': state.streak});
    }
  }

  int winLevel(int level, int stars, {int rewardMultiplier = 1}) {
    var coins = 0;
    final firstClear = state.progress.starsFor(level) == 0;
    final streak = state.streak;
    apply((s) {
      final r = Economy.winLevel(
        s,
        level,
        stars,
        _now,
        rewardMultiplier: rewardMultiplier,
      );
      coins = r.coins;
      return r.save;
    });
    _earned(coins, 'level_win');
    _logStreak(streak);
    // Every 10 levels completes a city block.
    if (firstClear && level % 10 == 0) {
      _analytics.log('city_block_built', {'block': level ~/ 10});
    }
    return coins;
  }

  int winDaily(String dateKey, int stars) {
    var coins = 0;
    final streak = state.streak;
    apply((s) {
      final r = Economy.winDaily(s, dateKey, stars, _now);
      coins = r.coins;
      return r.save;
    });
    _earned(coins, 'daily_win');
    _logStreak(streak);
    return coins;
  }

  int winPuzzle(String shape, int layer, int stars) {
    var coins = 0;
    final streak = state.streak;
    apply((s) {
      final r = Economy.winPuzzle(s, '$shape/$layer', layer, stars, _now);
      coins = r.coins;
      return r.save;
    });
    _earned(coins, 'puzzle_win');
    _logStreak(streak);
    return coins;
  }

  /// Pays to skip campaign [level]; false when coins are short.
  bool skipLevel(int level) {
    final next = Economy.skipLevel(state, level);
    if (next == null) return false;
    apply((_) => next);
    _analytics
      ..spendCoins(Economy.skipCost, 'skip_level')
      ..log('level_skip', {'level': '$level'});
    return true;
  }

  int claimDailyReward({int multiplier = 1}) {
    var coins = 0;
    apply((s) {
      final r = Economy.claimDailyReward(s, _now, multiplier: multiplier);
      coins = r.coins;
      return r.save;
    });
    if (coins > 0) {
      _earned(coins, 'daily_reward');
      _analytics.log('daily_reward_claim', {
        'day': state.rewardStreak,
        'coins': coins,
        'doubled': multiplier > 1 ? 1 : 0,
      });
    }
    return coins;
  }

  bool buySkin(String skin, int price) {
    final next = Economy.buySkin(state, skin, price);
    if (next == null) return false;
    apply((_) => next);
    _analytics
      ..spendCoins(price, 'skin_$skin')
      ..log('skin_unlock', {'skin': skin, 'source': 'coins'});
    return true;
  }

  /// Unlocks [skin] for free; [source] is how (video, bundle).
  void grantSkin(String skin, {String source = 'video'}) {
    if (state.owns(skin)) return;
    apply((s) => Economy.grantSkin(s, skin));
    _analytics.log('skin_unlock', {'skin': skin, 'source': source});
  }

  void selectSkin(String skin) => apply((s) => Economy.selectSkin(s, skin));

  void claimBundle(String bundle, {required int coins, String? skin}) {
    if (state.claimedBundles.contains(bundle)) return;
    final hadSkin = skin == null || state.owns(skin);
    apply((s) => Economy.claimBundle(s, bundle, coins: coins, skin: skin));
    _earned(coins, 'bundle');
    if (!hadSkin) {
      _analytics.log('skin_unlock', {'skin': skin, 'source': 'bundle'});
    }
  }

  /// Records that [level] has been played [attempt] times without a win.
  void setAttempts(String level, int attempt) => apply(
    (s) => s.copyWith(levelAttempts: {...s.levelAttempts, level: attempt}),
  );

  void clearAttempts(String level) {
    if (!state.levelAttempts.containsKey(level)) return;
    apply(
      (s) => s.copyWith(levelAttempts: {...s.levelAttempts}..remove(level)),
    );
  }

  /// Records that a one-time tip was shown.
  void markSeen(String tip) => apply(
    (s) => s.hasSeen(tip) ? s : s.copyWith(seenTips: [...s.seenTips, tip]),
  );

  /// [reason] names the source for analytics (double_coins, iap…).
  void addCoins(int amount, {required String reason}) {
    apply((s) => Economy.addCoins(s, amount));
    _earned(amount, reason);
  }

  void updateSettings(AppSettings settings) =>
      apply((s) => s.copyWith(settings: settings));
}
