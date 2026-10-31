import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/backend/application/analytics_sync.dart';
import 'package:arrow_escape/features/game/application/game_controller.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:arrow_escape/features/purchases/data/purchase_service.dart';
import 'package:arrow_escape/features/purchases/domain/products.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:arrow_escape/features/settings/domain/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

const one = LevelRef.campaign(1);

void main() {
  late ProviderContainer container;
  late RecordingAnalytics analytics;
  // Three cars; piece 1 waits for piece 2.
  final level = parseAsciiLevel('^>.^');

  Future<void> start({SaveData? save}) async {
    analytics = RecordingAnalytics();
    container = ProviderContainer(
      overrides: testOverrides(
        levels: [for (var i = 0; i < 10; i++) level],
        analytics: analytics,
        save: save,
      ),
    );
    addTearDown(container.dispose);
    await container.read(levelProvider(one).future);
  }

  GameController game() => container.read(gameControllerProvider(one).notifier);

  ProviderSubscription<Object?> keepAlive() =>
      container.listen(gameControllerProvider(one), (_, _) {});

  group('level events', () {
    test('start and complete carry attempt, help and result', () async {
      await start();
      keepAlive();
      game()
        ..tap(1) // bump
        ..tap(0)
        ..tap(2)
        ..showHint()
        ..tap(1);
      final s = analytics.last('level_start');
      expect(s['level'], '1');
      expect(s['mode'], 'campaign');
      expect(s['tier'], 'normal');
      expect(s['attempt'], 1);
      expect(s['arrows'], 3);
      final c = analytics.last('level_complete');
      expect(c['stars'], 2);
      expect(c['mistakes'], 1);
      expect(c['hints'], 1);
      expect(c['first_try'], 0);
      expect(analytics.names, isNot(contains('level_quit')));
    });

    test('a fail reports progress; restart counts a new attempt', () async {
      await start();
      keepAlive();
      game().tap(0); // 1 of 3 out
      for (var i = 0; i < 3; i++) {
        game().tap(1);
      }
      expect(analytics.last('level_fail')['progress_pct'], 33);
      await Future<void>.delayed(Duration.zero);
      game().restart();
      expect(analytics.last('level_start')['attempt'], 2);
      // A finished (lost) attempt is not also a quit.
      expect(analytics.names, isNot(contains('level_quit')));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(saveProvider).levelAttempts['1'], 2);
    });

    test('leaving mid-level logs a quit with progress', () async {
      await start();
      final sub = keepAlive();
      game().tap(0);
      sub.close();
      await container.pump();
      final q = analytics.last('level_quit');
      expect(q['progress_pct'], 33);
      expect(q['attempt'], 1);
    });

    test('a continue after a loss reopens the attempt', () async {
      await start();
      keepAlive();
      for (var i = 0; i < 3; i++) {
        game().tap(1);
      }
      game().addHeart();
      expect(analytics.last('level_continue')['source'], 'video');
      game()
        ..tap(0)
        ..tap(2)
        ..tap(1);
      expect(analytics.names, contains('level_complete'));
    });

    test('a win clears the attempt counter', () async {
      await start(save: const SaveData(levelAttempts: {'1': 4}));
      keepAlive();
      expect(analytics.last('level_start')['attempt'], 5);
      game()
        ..tap(0)
        ..tap(2)
        ..tap(1);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(saveProvider).levelAttempts, isEmpty);
    });
  });

  group('economy events', () {
    test(
      'wins, rewards, skins and bundles log currency with reasons',
      () async {
        await start(save: const SaveData(coins: 500));
        final save = container.read(saveProvider.notifier)
          ..winLevel(10, 3)
          ..claimDailyReward()
          ..buySkin('candy', 100)
          ..claimBundle('starter', coins: 200, skin: 'ocean')
          ..addCoins(15, reason: 'double_coins');
        expect(save.current.coins, greaterThan(0));
        final earned = [
          for (final e in analytics.events)
            if (e.name == 'earn_virtual_currency') e.params['reason'],
        ];
        expect(earned, ['level_win', 'daily_reward', 'bundle', 'double_coins']);
        expect(analytics.last('spend_virtual_currency'), {
          'virtual_currency_name': 'coins',
          'value': 100,
          'item_name': 'skin_candy',
        });
        expect(analytics.last('city_block_built')['block'], 1);
        expect(analytics.last('streak_update')['streak_days'], 1);
        expect(analytics.last('daily_reward_claim')['day'], 1);
        expect(
          [
            for (final e in analytics.events)
              if (e.name == 'skin_unlock') e.params['source'],
          ],
          ['coins', 'bundle'],
        );
      },
    );

    test('settings changes are logged by key', () async {
      await start();
      container.read(settingsProvider.notifier).setThickArrows(true);
      expect(analytics.last('settings_change'), {
        'setting': 'thickArrows',
        'value': 'true',
      });
    });
  });

  group('user properties', () {
    test('values are coarse buckets', () {
      final p = userPropertiesFor(
        const SaveData(
          progress: Progress(unlocked: 61, stars: {1: 3, 2: 3}),
          streak: 8,
          selectedSkin: 'candy',
          settings: AppSettings(thickArrows: true, colorblind: true),
        ),
        const Entitlements(active: {Products.noAdsEntitlement}),
      );
      expect(p, {
        'max_level': '50-99',
        'total_stars': '0-29',
        'is_payer': 'true',
        'no_ads': 'true',
        'streak_days': '7-13',
        'skin': 'candy',
        'a11y_mode': 'thick+colorblind',
      });
      expect(
        userPropertiesFor(const SaveData(), const Entitlements())['max_level'],
        '0-9',
      );
    });

    test('sync sends changes only and follows the opt-out', () async {
      await start();
      AnalyticsSync(container).start();
      expect(analytics.collection, [true]);
      expect(analytics.properties['skin'], 'classic');
      analytics.properties.clear();
      container.read(saveProvider.notifier).addCoins(5, reason: 'test');
      expect(analytics.properties, isEmpty);
      container.read(settingsProvider.notifier).setShareAnalytics(false);
      expect(analytics.collection, [true, false]);
    });
  });
}
