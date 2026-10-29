import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/game/presentation/board_view.dart';
import 'package:arrow_escape/features/game/presentation/widgets/hearts_bar.dart';
import 'package:arrow_escape/features/progress/application/progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  // Piece 0 (">") is blocked by piece 1 ("^") until it leaves.
  final level = parseAsciiLevel('>.^');
  final second = parseAsciiLevel('^');

  Future<ProviderContainer> openGame(WidgetTester tester) async {
    await pumpApp(tester, levels: [level, second]);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(routerProvider).go(Routes.game(1));
    await tester.pumpAndSettle();
    return container;
  }

  HeartsBar hearts(WidgetTester tester) =>
      tester.widget<HeartsBar>(find.byType(HeartsBar));

  testWidgets('blocked tap bumps and costs a heart', (tester) async {
    await openGame(tester);
    expect(hearts(tester).hearts, 3);
    await tapPiece(tester, level, 0);
    expect(hearts(tester).hearts, 2);
    await settle(tester);
  });

  testWidgets('double tap on a bumping car only costs one heart', (
    tester,
  ) async {
    await openGame(tester);
    await tapPiece(tester, level, 0);
    await tester.pump(const Duration(milliseconds: 40));
    await tapPiece(tester, level, 0);
    expect(hearts(tester).hearts, 2);
    await settle(tester);
  });

  testWidgets('clearing the board shows the win card with stars', (
    tester,
  ) async {
    final container = await openGame(tester);
    await tapPiece(tester, level, 1);
    await settle(tester);
    await tapPiece(tester, level, 0);
    await settle(tester);
    expect(find.text('Level 1 cleared!'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(container.read(progressProvider).unlocked, 2);

    await tester.tap(find.byKey(const Key('result-primary')));
    await tester.pumpAndSettle();
    expect(find.text('Level 2'), findsOneWidget);
  });

  testWidgets('three bumps show the lose card; retry resets', (tester) async {
    await openGame(tester);
    for (var i = 0; i < 3; i++) {
      await tapPiece(tester, level, 0);
      await settle(tester);
    }
    expect(find.text('Out of hearts'), findsOneWidget);
    await tester.tap(find.byKey(const Key('result-primary')));
    await tester.pumpAndSettle();
    expect(find.text('Out of hearts'), findsNothing);
    expect(hearts(tester).hearts, 3);
  });

  testWidgets('undo is enabled after an exit and only once', (tester) async {
    await openGame(tester);
    IconButton undoButton() => tester.widget<IconButton>(
      find.descendant(
        of: find.byKey(const Key('undo')),
        matching: find.byType(IconButton),
      ),
    );
    expect(undoButton().onPressed, isNull);
    await tapPiece(tester, level, 1);
    await settle(tester);
    expect(undoButton().onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('undo')));
    await settle(tester);
    expect(undoButton().onPressed, isNull);
    expect(
      find.descendant(
        of: find.byKey(const Key('undo')),
        matching: find.byType(Badge),
      ),
      findsNothing,
    );
  });

  testWidgets('show paths toggles', (tester) async {
    await openGame(tester);
    expect(find.text('Show paths'), findsOneWidget);
    await tester.tap(find.byKey(const Key('paths')));
    await tester.pump();
    expect(find.text('Hide paths'), findsOneWidget);
  });

  testWidgets('mechanic banner explains special levels', (tester) async {
    final lights = sampleLevels.firstWhere((l) => l.lights.isNotEmpty);
    await pumpApp(tester, levels: [lights]);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(routerProvider).go(Routes.game(1));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lights switch'), findsOneWidget);
  });

  testWidgets('second tap on a car that just left does not hit a neighbour', (
    tester,
  ) async {
    // Car 0 exits up; car 1 sits right next to it and is blocked by car 2.
    final tight = parseAsciiLevel('^>^');
    await pumpApp(tester, levels: [tight]);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(routerProvider).go(Routes.game(1));
    await tester.pumpAndSettle();

    final box = tester.renderObject<RenderBox>(find.byType(BoardView));
    final layout = BoardLayout(tight, box.size);
    // Tap near the right edge of car 0's cell, close to car 1.
    final spot = box.localToGlobal(
      layout.centerOf(0) + Offset(layout.cell * 0.45, 0),
    );
    await tester.tapAt(spot);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(spot);
    await tester.pump();
    expect(hearts(tester).hearts, 3);
    await settle(tester);
  });
}
