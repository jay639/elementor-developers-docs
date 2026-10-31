import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/daily/daily_screen.dart';
import 'package:arrow_escape/features/progress/application/progress_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  final daily = parseAsciiLevel('>.^'); // tap 1 then 0

  Future<ProviderContainer> openDaily(WidgetTester tester) async {
    await pumpApp(tester, daily: daily);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(routerProvider).go(Routes.daily);
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows today, its difficulty and the countdown', (tester) async {
    await openDaily(tester);
    expect(find.byType(DailyScreen), findsOneWidget);
    expect(find.text('Thursday, October 29, 2026'), findsOneWidget);
    expect(find.text('Hard'), findsOneWidget);
    expect(find.text('Next challenge in 2:30:00'), findsOneWidget);
    expect(find.text('Play today'), findsOneWidget);
  });

  testWidgets('playing and winning marks today done', (tester) async {
    final container = await openDaily(tester);
    await tester.tap(find.byKey(const Key('play-daily')));
    await tester.pumpAndSettle();
    expect(find.text('Daily · Oct 29'), findsOneWidget);

    await tapPiece(tester, daily, 1);
    await settle(tester);
    await tapPiece(tester, daily, 0);
    await settle(tester);
    expect(find.text('Daily challenge done!'), findsOneWidget);
    expect(container.read(progressProvider).dailyStarsFor('2026-10-29'), 3);

    await tester.tap(find.byKey(const Key('result-primary')));
    await tester.pumpAndSettle();
    expect(find.byType(DailyScreen), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
  });

  testWidgets('bad daily routes fall back to the daily screen', (tester) async {
    await pumpApp(tester, daily: daily);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(routerProvider).go('/daily/not-a-date');
    await tester.pumpAndSettle();
    expect(find.byType(DailyScreen), findsOneWidget);
  });

  test('difficulty labels rise over time', () {
    expect(DailyScreen.difficultyLabel(DateTime(2026, 11, 2)), 'Hard');
    expect(DailyScreen.difficultyLabel(DateTime(2027, 3, 1)), 'Expert');
    expect(DailyScreen.difficultyLabel(DateTime(2027, 9, 1)), 'Master');
  });
}
