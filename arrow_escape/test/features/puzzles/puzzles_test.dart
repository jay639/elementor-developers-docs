import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/game/application/game_controller.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:arrow_escape/features/puzzles/puzzle_progress.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/domain/economy.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  final leaf = ShapePuzzles.byId('leaf');
  final flower = ShapePuzzles.byId('flower');

  group('unlock rules', () {
    test('points count campaign, daily and puzzle stars', () {
      const p = Progress(
        stars: {1: 3, 2: 2},
        dailyStars: {'2026-10-29': 3},
        puzzleStars: {'leaf/1': 1},
      );
      expect(p.points, 9);
    });

    test('pictures open at their star count; layers in order', () {
      const none = Progress();
      expect(none.puzzleUnlocked(leaf), isFalse);
      final p = Progress(
        stars: {for (var i = 1; i <= 5; i++) i: 3},
        puzzleStars: const {'leaf/1': 2},
      );
      expect(p.puzzleUnlocked(leaf), isTrue);
      expect(p.puzzleUnlocked(flower), isFalse);
      expect(p.layerOpen(leaf, 1), isTrue);
      expect(p.layerOpen(leaf, 2), isTrue);
      expect(p.layerOpen(leaf, 3), isFalse);
      expect(p.layersDone(leaf), 1);
      expect(nextLockedPuzzle(p), flower);
    });

    test('thresholds rise and crossing one is reported', () {
      final goals = [for (final s in ShapePuzzles.all) s.starsToUnlock];
      expect(goals, [...goals]..sort());
      expect(goals.toSet().length, goals.length);
      expect(puzzlesOpenedBetween(14, 15), [leaf]);
      expect(puzzlesOpenedBetween(15, 39), isEmpty);
    });
  });

  test('a puzzle win pays more for deeper layers and keeps best stars', () {
    final now = DateTime(2026, 10, 29);
    var r = Economy.winPuzzle(const SaveData(), 'leaf/2', 2, 2, now);
    expect(r.coins, 20 + 40 + 20);
    expect(r.save.progress.puzzleStarsFor('leaf/2'), 2);
    r = Economy.winPuzzle(r.save, 'leaf/2', 2, 1, now);
    expect(r.coins, 3);
    expect(r.save.progress.puzzleStarsFor('leaf/2'), 2);
  });

  test(
    'winning a layer stores stars and announces unlocked pictures',
    () async {
      // Two cars that both leave at once.
      final level = parseAsciiLevel('^^');
      final container = ProviderContainer(
        overrides: testOverrides(
          levels: [level],
          // 14 points: the next star opens the Leaf.
          save: SaveData(
            progress: Progress(stars: {for (var i = 1; i <= 7; i++) i: 2}),
          ),
        ),
      );
      addTearDown(container.dispose);
      const ref = LevelRef.puzzle('flower', 1);
      await container.read(levelProvider(ref).future);
      container.listen(gameControllerProvider(ref), (_, _) {});
      container.read(gameControllerProvider(ref).notifier)
        ..tap(0)
        ..tap(1);
      final state = container.read(gameControllerProvider(ref));
      expect(state.status, SessionStatus.won);
      expect(
        container.read(saveProvider).progress.puzzleStarsFor('flower/1'),
        3,
      );
      expect(state.unlockedPuzzles, ['leaf']);
    },
  );

  testWidgets('collection opens a picture and starts a layer', (tester) async {
    await pumpApp(
      tester,
      levels: [parseAsciiLevel('^^')],
      save: SaveData(
        progress: Progress(stars: {for (var i = 1; i <= 10; i++) i: 3}),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(routerProvider).go(Routes.collection);
    await tester.pumpAndSettle();
    expect(find.text('30 stars'), findsOneWidget);
    await tester.tap(find.byKey(const Key('picture-leaf')));
    await tester.pumpAndSettle();
    // Layer 2 is still closed.
    await tester.tap(find.byKey(const Key('layer-leaf-2')));
    await tester.pumpAndSettle();
    expect(find.text('Leaf · Layer 2'), findsNothing);
    await tester.tap(find.byKey(const Key('layer-leaf-1')));
    await tester.pumpAndSettle();
    expect(find.text('Leaf · Layer 1'), findsOneWidget);
  });

  testWidgets('locked pictures do nothing when tapped', (tester) async {
    await pumpApp(tester, levels: [parseAsciiLevel('^^')]);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(routerProvider).go(Routes.collection);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('picture-leaf')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('layer-leaf-1')), findsNothing);
  });
}
