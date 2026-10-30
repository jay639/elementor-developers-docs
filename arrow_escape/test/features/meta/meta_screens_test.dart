import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/ads/data/ad_service.dart';
import 'package:arrow_escape/features/game/presentation/game_screen.dart';
import 'package:arrow_escape/features/level_map/level_map_screen.dart';
import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:arrow_escape/features/purchases/application/entitlements.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  final levels = [for (var i = 0; i < 25; i++) parseAsciiLevel('>.^')];

  Future<ProviderContainer> open(
    WidgetTester tester,
    String route, {
    SaveData? save,
    FakeAdService? ads,
    FakePurchaseService? purchases,
  }) async {
    await pumpApp(
      tester,
      levels: levels,
      save: save,
      ads: ads,
      purchases: purchases,
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    c.read(routerProvider).go(route);
    await tester.pumpAndSettle();
    return c;
  }

  group('City map', () {
    testWidgets('shows blocks, stars and locks; opens unlocked levels', (
      tester,
    ) async {
      await open(
        tester,
        Routes.map,
        save: const SaveData(
          progress: Progress(unlocked: 4, stars: {1: 3, 2: 2, 3: 1}),
        ),
      );
      expect(find.text(LevelMapScreen.blockName(0)), findsOneWidget);
      expect(find.text('0 of 3 blocks built · 6 stars'), findsOneWidget);
      expect(find.bySemanticsLabel('Level 1, 3 stars'), findsOneWidget);
      expect(find.bySemanticsLabel('Level 9, locked'), findsOneWidget);
      // Locked level does nothing.
      await tester.tap(find.byKey(const Key('level-9')));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsNothing);
      await tester.tap(find.byKey(const Key('level-4')));
      await tester.pumpAndSettle();
      expect(find.text('Level 4'), findsOneWidget);
    });

    testWidgets('banner shows until ads are removed', (tester) async {
      final store = FakePurchaseService();
      final c = await open(tester, Routes.map, purchases: store);
      c.read(entitlementsProvider);
      expect(find.byKey(const Key('banner')), findsOneWidget);
      store.grant('no_ads');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('banner')), findsNothing);
    });

    testWidgets('a finished block is marked built', (tester) async {
      await open(
        tester,
        Routes.map,
        save: SaveData(
          progress: Progress(
            unlocked: 11,
            stars: {for (var n = 1; n <= 10; n++) n: 3},
          ),
        ),
      );
      expect(find.text('1 of 3 blocks built · 30 stars'), findsOneWidget);
      // The map opens on the block being built; scroll back to block 1.
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });
  });

  group('Skins', () {
    testWidgets('buy with coins, then select another', (tester) async {
      final c = await open(
        tester,
        Routes.skins,
        save: const SaveData(coins: 600),
      );
      await tester.tap(find.byKey(const Key('skin-candy-buy')));
      await tester.pumpAndSettle();
      expect(c.read(saveProvider).selectedSkin, 'candy');
      expect(c.read(saveProvider).coins, 300);
      await tester.tap(find.byKey(const Key('skin-classic-select')));
      await tester.pumpAndSettle();
      expect(c.read(saveProvider).selectedSkin, 'classic');
    });

    testWidgets('unaffordable skins cannot be bought', (tester) async {
      await open(tester, Routes.skins);
      final buy = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('skin-candy-buy')),
      );
      expect(buy.onPressed, isNull);
    });

    testWidgets('rewarded video unlocks an ad skin', (tester) async {
      final ads = FakeAdService();
      final c = await open(tester, Routes.skins, ads: ads);
      await tester.tap(find.byKey(const Key('skin-candy-ad')));
      await tester.pumpAndSettle();
      expect(ads.rewarded, [RewardKind.unlockSkin]);
      expect(c.read(saveProvider).owns('candy'), isTrue);
    });

    testWidgets('no video: nothing granted, friendly message', (tester) async {
      final ads = FakeAdService()..earn = false;
      final c = await open(tester, Routes.skins, ads: ads);
      await tester.tap(find.byKey(const Key('skin-candy-ad')));
      await tester.pump();
      expect(c.read(saveProvider).owns('candy'), isFalse);
      expect(find.textContaining('No video available'), findsOneWidget);
    });
  });

  group('Shop', () {
    testWidgets('buying a coin pack adds coins; restore reports', (
      tester,
    ) async {
      final store = FakePurchaseService();
      final c = await open(tester, Routes.shop, purchases: store);
      expect(find.text('€1.00'), findsWidgets);
      await tester.scrollUntilVisible(
        find.byKey(const Key('buy-coins_500')),
        150,
      );
      await tester.tap(find.byKey(const Key('buy-coins_500')));
      await tester.pumpAndSettle();
      expect(c.read(saveProvider).coins, 500);
      // The thank-you snackbar floats over the bottom of the list.
      ScaffoldMessenger.of(
        tester.element(find.byKey(const Key('restore'))),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('restore')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore')));
      await tester.pumpAndSettle();
      expect(find.text('Purchases restored.'), findsOneWidget);
    });

    testWidgets('remove ads shows as owned after purchase', (tester) async {
      final store = FakePurchaseService();
      await open(tester, Routes.shop, purchases: store);
      await tester.tap(find.byKey(const Key('buy-remove_ads')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('buy-remove_ads')), findsNothing);
      expect(find.text('Owned'), findsOneWidget);
    });

    testWidgets('without a store, buying explains it is unavailable', (
      tester,
    ) async {
      await open(tester, Routes.shop);
      await tester.scrollUntilVisible(
        find.byKey(const Key('buy-coins_500')),
        150,
      );
      await tester.tap(find.byKey(const Key('buy-coins_500')));
      await tester.pumpAndSettle();
      expect(find.textContaining('not available'), findsOneWidget);
    });
  });

  group('Home', () {
    testWidgets('daily reward: claim once, then the card goes away', (
      tester,
    ) async {
      final c = await open(tester, Routes.home);
      await tester.tap(find.byKey(const Key('claim-reward')));
      await tester.pumpAndSettle();
      expect(c.read(saveProvider).coins, 20);
      expect(find.byKey(const Key('claim-reward')), findsNothing);
    });

    testWidgets('daily reward x2 with a video', (tester) async {
      final ads = FakeAdService();
      final c = await open(tester, Routes.home, ads: ads);
      await tester.tap(find.byKey(const Key('claim-reward-x2')));
      await tester.pumpAndSettle();
      expect(c.read(saveProvider).coins, 40);
    });

    testWidgets('streak chip shows the live streak', (tester) async {
      await open(
        tester,
        Routes.home,
        save: const SaveData(streak: 4, lastWinDay: '2026-10-28'),
      );
      expect(find.bySemanticsLabel('4 day streak'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('streak')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tiles open map, skins and shop', (tester) async {
      await open(tester, Routes.home);
      for (final (key, title) in [
        ('map', 'City map'),
        ('skins', 'Vehicle skins'),
        ('shop', 'Shop'),
      ]) {
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        expect(find.text(title), findsWidgets, reason: key);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });
  });

  group('Game rewards', () {
    Future<(ProviderContainer, FakeAdService)> game(
      WidgetTester tester,
      int n,
    ) async {
      final ads = FakeAdService();
      final c = await open(tester, Routes.game(n), ads: ads);
      return (c, ads);
    }

    testWidgets('win shows coins and doubles them with a video', (
      tester,
    ) async {
      final (c, ads) = await game(tester, 1);
      await tapPiece(tester, levels.first, 1);
      await settle(tester);
      await tapPiece(tester, levels.first, 0);
      await settle(tester);
      expect(find.text('+25'), findsOneWidget);
      await tester.tap(find.byKey(const Key('result-rewarded')));
      await tester.pumpAndSettle();
      expect(find.text('+50'), findsOneWidget);
      expect(c.read(saveProvider).coins, 50);
      expect(find.byKey(const Key('result-rewarded')), findsNothing);
      expect(ads.completedLevels, [1], reason: 'interstitial policy consulted');
    });

    testWidgets('lose offers +1 heart with a video', (tester) async {
      await game(tester, 1);
      for (var i = 0; i < 3; i++) {
        await tapPiece(tester, levels.first, 0);
        await settle(tester);
      }
      expect(find.text('Out of hearts'), findsOneWidget);
      await tester.tap(find.byKey(const Key('result-rewarded')));
      await tester.pumpAndSettle();
      expect(find.text('Out of hearts'), findsNothing);
    });

    testWidgets('hint button highlights a move after a video', (tester) async {
      final (_, ads) = await game(tester, 1);
      await tester.tap(find.byKey(const Key('hint')));
      await tester.pumpAndSettle();
      expect(ads.rewarded, [RewardKind.hint]);
    });

    testWidgets('daily wins never trigger the interstitial policy', (
      tester,
    ) async {
      final ads = FakeAdService();
      await pumpApp(tester, daily: levels.first, ads: ads);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(Navigator).first),
      );
      c.read(routerProvider).go(Routes.dailyGame('2026-10-29'));
      await tester.pumpAndSettle();
      await tapPiece(tester, levels.first, 1);
      await settle(tester);
      await tapPiece(tester, levels.first, 0);
      await settle(tester);
      expect(find.text('Daily challenge done!'), findsOneWidget);
      expect(ads.completedLevels, isEmpty);
    });
  });

  testWidgets('settings offers privacy options when consent requires it', (
    tester,
  ) async {
    await open(tester, Routes.settings);
    await tester.scrollUntilVisible(
      find.byKey(const Key('privacy-options')),
      200,
    );
    expect(find.byKey(const Key('privacy-options')), findsOneWidget);
  });
}
