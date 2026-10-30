import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/game/presentation/widgets/hearts_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  final level = parseAsciiLevel('''
>.^
.r.
''');

  Future<void> open(WidgetTester tester, String route) async {
    await pumpApp(tester, levels: [level, level]);
    final c = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    c.read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }

  testWidgets('every vehicle and light is an accessible node', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, Routes.game(1));
    expect(
      find.semantics.byLabel('Car facing right, row 1, column 1'),
      findsOneWidget,
    );
    expect(
      find.semantics.byLabel('Car facing up, row 1, column 3'),
      findsOneWidget,
    );
    expect(find.semantics.byLabel('Traffic light, red'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('screen readers can move a vehicle', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, Routes.game(1));
    tester.semantics.tap(
      find.semantics.byLabel('Car facing up, row 1, column 3'),
    );
    await settle(tester);
    expect(
      find.semantics.byLabel('Car facing up, row 1, column 3'),
      findsNothing,
      reason: 'it drove away',
    );
    expect(tester.widget<HeartsBar>(find.byType(HeartsBar)).hearts, 3);
    handle.dispose();
  });

  testWidgets('road state is announced only with show paths on', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, Routes.game(1));
    await tester.tap(find.byKey(const Key('paths')));
    await tester.pumpAndSettle();
    expect(
      find.semantics.byLabel('Car facing right, row 1, column 1, blocked'),
      findsOneWidget,
    );
    expect(
      find.semantics.byLabel('Car facing up, row 1, column 3, road clear'),
      findsOneWidget,
    );
    handle.dispose();
  });

  for (final (name, route) in [
    ('home', Routes.home),
    ('game', Routes.game(1)),
    ('map', Routes.map),
    ('settings', Routes.settings),
    ('daily', Routes.daily),
    ('shop', Routes.shop),
    ('skins', Routes.skins),
  ]) {
    testWidgets('$name meets tap-target and labelling guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, route);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  }
}
