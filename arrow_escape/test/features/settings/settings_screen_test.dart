import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  testWidgets('toggles update settings and theme mode', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(routerProvider).go(Routes.settings);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('thick-arrows')));
    await tester.tap(find.byKey(const Key('colorblind')));
    await tester.pump();
    var s = container.read(settingsProvider);
    expect(s.thickArrows, isTrue);
    expect(s.colorblind, isTrue);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    s = container.read(settingsProvider);
    expect(s.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('Settings'))).brightness,
      Brightness.dark,
    );

    await tester.ensureVisible(find.byKey(const Key('haptics')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('haptics')));
    await tester.pump();
    expect(container.read(settingsProvider).haptics, isFalse);
  });

  testWidgets('high contrast applies to the theme', (tester) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(routerProvider).go(Routes.settings);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('high-contrast')));
    await tester.pumpAndSettle();
    final theme = Theme.of(tester.element(find.text('Settings')));
    expect(theme.colorScheme.surface, anyOf(Colors.white, Colors.black));
  });
}
