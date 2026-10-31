import 'package:arrow_escape/features/daily/daily_screen.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/presentation/board_view.dart';
import 'package:arrow_escape/features/game/presentation/game_screen.dart';
import 'package:arrow_escape/features/home/home_screen.dart';
import 'package:arrow_escape/features/settings/presentation/settings_screen.dart';
import 'package:arrow_escape/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  testWidgets('splash animates then lands on home', (tester) async {
    await pumpApp(tester);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Arrow Escape'), findsOneWidget);
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Play  ·  Level 1'), findsOneWidget);
  });

  testWidgets('home opens real level 1 and back returns home', (tester) async {
    await pumpApp(tester);
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    // Decode the shipped pack for real (on an isolate, outside fake time);
    // the repository caches it for the screen.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await tester.runAsync(
      () => container.read(levelRepositoryProvider).load(1),
    );
    await tester.tap(find.byKey(const Key('play')));
    // The tutorial hand loops forever, so step time instead of settling.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.byType(BoardView), findsOneWidget);
    expect(find.byKey(const Key('skip-tutorial')), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('home opens the daily challenge', (tester) async {
    await pumpApp(tester);
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('daily')));
    await tester.pumpAndSettle();
    expect(find.byType(DailyScreen), findsOneWidget);
  });

  testWidgets('home opens settings', (tester) async {
    await pumpApp(tester);
    await tester.pump(SplashScreen.duration);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}
