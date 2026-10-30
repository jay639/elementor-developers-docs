import 'dart:async';

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

  int winLevel(int level, int stars) {
    var coins = 0;
    apply((s) {
      final r = Economy.winLevel(s, level, stars, _now);
      coins = r.coins;
      return r.save;
    });
    return coins;
  }

  int winDaily(String dateKey, int stars) {
    var coins = 0;
    apply((s) {
      final r = Economy.winDaily(s, dateKey, stars, _now);
      coins = r.coins;
      return r.save;
    });
    return coins;
  }

  int claimDailyReward({int multiplier = 1}) {
    var coins = 0;
    apply((s) {
      final r = Economy.claimDailyReward(s, _now, multiplier: multiplier);
      coins = r.coins;
      return r.save;
    });
    return coins;
  }

  bool buySkin(String skin, int price) {
    final next = Economy.buySkin(state, skin, price);
    if (next == null) return false;
    apply((_) => next);
    return true;
  }

  void grantSkin(String skin) => apply((s) => Economy.grantSkin(s, skin));
  void selectSkin(String skin) => apply((s) => Economy.selectSkin(s, skin));
  void claimBundle(String bundle, {required int coins, String? skin}) =>
      apply((s) => Economy.claimBundle(s, bundle, coins: coins, skin: skin));
  void addCoins(int amount) => apply((s) => Economy.addCoins(s, amount));
  void updateSettings(AppSettings settings) =>
      apply((s) => s.copyWith(settings: settings));
}
