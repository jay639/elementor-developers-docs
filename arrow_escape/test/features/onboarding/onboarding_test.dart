import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/game/application/game_controller.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:arrow_escape/features/onboarding/tutorial_overlay.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/data/save_repository.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

const one = LevelRef.campaign(1);

Future<void> pumpFrames(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('tutorial controller', () {
    late ProviderContainer c;
    late RecordingAnalytics analytics;

    Future<GameController> start({SaveData save = const SaveData()}) async {
      analytics = RecordingAnalytics();
      c = ProviderContainer(
        overrides: [
          ...testOverrides(levels: [tutorialLevel], analytics: analytics),
          initialSaveProvider.overrideWithValue(LoadedSave(save)),
        ],
      );
      addTearDown(c.dispose);
      await c.read(levelProvider(one).future);
      c.listen(gameControllerProvider(one), (_, _) {});
      return c.read(gameControllerProvider(one).notifier);
    }

    TutorialStep step() => c.read(gameControllerProvider(one)).tutorial;
    int hearts() => c.read(gameControllerProvider(one)).session.hearts;

    test('starts on level 1 and only accepts the highlighted arrow', () async {
      final g = await start();
      expect(step(), TutorialStep.tapBlocker);
      expect(analytics.events.map((e) => e.name), contains('tutorial_begin'));
      // Tapping the blocked arrow is ignored, no heart lost.
      expect(g.tap(TutorialPieces.blocked), isNull);
      expect(hearts(), 3);
      expect(g.tap(TutorialPieces.blocker), isA<ExitMove>());
      expect(step(), TutorialStep.tapFreed);
      expect(g.tap(TutorialPieces.blocked), isA<ExitMove>());
      expect(step(), TutorialStep.finish);
    });

    test('winning completes it and it never shows again', () async {
      final g = await start();
      for (final p in [0, 1, 2, 3]) {
        g.tap(p);
      }
      expect(step(), TutorialStep.none);
      expect(c.read(saveProvider).hasSeen(Tips.tutorial), isTrue);
      expect(analytics.events.last.name, isNot('tutorial_begin'));
      expect(
        analytics.events.map((e) => e.name),
        contains('tutorial_complete'),
      );
      g.restart();
      expect(step(), TutorialStep.none);
    });

    test('restart mid-tutorial starts it over; skip ends it', () async {
      final g = await start();
      g.tap(TutorialPieces.blocker);
      g.restart();
      expect(step(), TutorialStep.tapBlocker);
      g.skipTutorial();
      expect(step(), TutorialStep.none);
      expect(c.read(saveProvider).hasSeen(Tips.tutorial), isTrue);
      expect(analytics.events.last.name, 'tutorial_skip');
    });

    test('not shown once seen', () async {
      await start(save: const SaveData(seenTips: [Tips.tutorial]));
      expect(step(), TutorialStep.none);
    });
  });

  group('onboarding UI', () {
    Future<ProviderContainer> open(
      WidgetTester tester,
      List<Level> levels, {
      SaveData? save,
    }) async {
      await pumpApp(tester, levels: levels, save: save);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(Navigator).first),
      );
      c.read(routerProvider).go(Routes.game(1));
      await pumpFrames(tester);
      return c;
    }

    testWidgets('tutorial shows instructions, the hand, and can be skipped', (
      tester,
    ) async {
      await open(tester, [tutorialLevel]);
      expect(find.text(TutorialStep.tapBlocker.copy), findsOneWidget);
      expect(find.byType(TapHand), findsOneWidget);
      await tapPiece(tester, tutorialLevel, TutorialPieces.blocker);
      await pumpFrames(tester);
      expect(find.text(TutorialStep.tapFreed.copy), findsOneWidget);
      await tester.tap(find.byKey(const Key('skip-tutorial')));
      await pumpFrames(tester);
      expect(find.byType(TapHand), findsNothing);
      expect(find.byKey(const Key('skip-tutorial')), findsNothing);
    });

    testWidgets('pinch hint on the first dense board, once', (tester) async {
      final dense = parseAsciiLevel(List.filled(14, '>${'.' * 13}').join('\n'));
      final c = await open(tester, [dense, dense]);
      expect(find.byKey(const Key('pinch-hint')), findsOneWidget);
      await tester.tap(find.byKey(const Key('pinch-hint')));
      await pumpFrames(tester);
      expect(find.byKey(const Key('pinch-hint')), findsNothing);
      expect(c.read(saveProvider).hasSeen(Tips.pinch), isTrue);
      c.read(routerProvider).go(Routes.game(2));
      await pumpFrames(tester);
      expect(find.byKey(const Key('pinch-hint')), findsNothing);
    });

    testWidgets('a new mechanic is explained once before play', (tester) async {
      final lights = parseAsciiLevel('>.r\n..^');
      final c = await open(tester, [lights, lights]);
      expect(find.text('New: Traffic lights'), findsOneWidget);
      await tester.tap(find.byKey(const Key('mechanic-intro-ok')));
      await pumpFrames(tester);
      expect(find.byKey(const Key('mechanic-intro')), findsNothing);
      expect(c.read(saveProvider).hasSeen('mechanic_lights'), isTrue);
      c.read(routerProvider).go(Routes.game(2));
      await pumpFrames(tester);
      expect(find.byKey(const Key('mechanic-intro')), findsNothing);
    });
  });
}
