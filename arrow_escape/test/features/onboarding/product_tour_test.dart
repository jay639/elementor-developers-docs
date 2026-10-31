import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  final levels = [parseAsciiLevel('^^')];

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

  Future<void> openHome(WidgetTester tester, SaveData save) async {
    await pumpApp(tester, levels: levels, save: save);
    await tester.pumpAndSettle();
  }

  testWidgets('tour walks streak, stars, coins, collection once', (
    tester,
  ) async {
    await openHome(tester, const SaveData(seenTips: [Tips.tutorial]));
    for (final title in ['Daily streak', 'Stars', 'Coins', 'Collection']) {
      expect(find.text(title), findsWidgets, reason: title);
      await tester.tap(find.byKey(const Key('tour-next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('product-tour')), findsNothing);
    expect(container(tester).read(saveProvider).hasSeen(Tips.homeTour), isTrue);
  });

  testWidgets('tour can be skipped', (tester) async {
    await openHome(tester, const SaveData(seenTips: [Tips.tutorial]));
    await tester.tap(find.byKey(const Key('tour-skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('product-tour')), findsNothing);
  });

  testWidgets('no tour before the tutorial or after it was seen', (
    tester,
  ) async {
    await openHome(tester, const SaveData());
    expect(find.byKey(const Key('product-tour')), findsNothing);
  });
}
