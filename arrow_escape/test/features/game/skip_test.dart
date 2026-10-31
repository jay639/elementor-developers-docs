import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/domain/economy.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  test('skipping costs coins, opens the next level, gives no stars', () {
    const rich = SaveData(coins: 200);
    final s = Economy.skipLevel(rich, 1)!;
    expect(s.coins, 200 - Economy.skipCost);
    expect(s.progress.unlocked, 2);
    expect(s.progress.starsFor(1), 0);
    expect(Economy.skipLevel(const SaveData(coins: 10), 1), isNull);
  });

  Future<ProviderContainer> openLevel(WidgetTester tester, int coins) async {
    final level = parseAsciiLevel('^>.^');
    await pumpApp(
      tester,
      levels: [level, level, level],
      save: SaveData(coins: coins),
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    c.read(routerProvider).go(Routes.game(2));
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('skip button pays and moves on', (tester) async {
    final c = await openLevel(tester, 500);
    await tester.tap(find.byKey(const Key('skip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-skip')));
    await tester.pumpAndSettle();
    expect(c.read(saveProvider).coins, 500 - Economy.skipCost);
    expect(c.read(saveProvider).progress.unlocked, 3);
    expect(find.text('Level 3'), findsOneWidget);
  });

  testWidgets('without enough coins the dialog offers the shop', (
    tester,
  ) async {
    final c = await openLevel(tester, 20);
    await tester.tap(find.byKey(const Key('skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('confirm-skip')), findsNothing);
    expect(find.text('Shop'), findsOneWidget);
    expect(c.read(saveProvider).coins, 20);
  });
}
