// Renders the main screens to PNG for design review (not part of CI):
//   flutter test test_screens --update-goldens
import 'dart:convert';
import 'dart:io';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/router.dart';
import 'package:arrow_escape/app/routes.dart';
import 'package:arrow_escape/features/progress/domain/progress.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('Fredoka', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      'assets/fonts/Fredoka-$w.ttf',
  ]);
  await load('MaterialIcons', [
    '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

List<Level> _campaign() {
  final bytes = File('assets/levels/pack_01.json.gz').readAsBytesSync();
  return decodeLevelPack(utf8.decode(gzip.decode(bytes)));
}

void main() {
  setUpAll(_loadFonts);
  final levels = _campaign();
  final save = SaveData(
    coins: 1250,
    streak: 4,
    progress: Progress(
      unlocked: 13,
      stars: {for (var i = 1; i <= 12; i++) i: 3 - i % 2},
    ),
    seenTips: const [
      'tutorial',
      'pinch',
      'mechanic_lights',
      'mechanic_gates',
      'mechanic_ambulance',
    ],
  );

  Future<void> shot(
    WidgetTester tester,
    String name,
    String route, {
    Brightness brightness = Brightness.light,
    Future<void> Function(WidgetTester)? then,
  }) async {
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester, levels: levels, save: save);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.read(routerProvider).go(route);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (then != null) {
      await then(tester);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('out/$name.png'),
    );
  }

  testWidgets('home', (t) => shot(t, 'home', Routes.home));
  testWidgets('home dark', (t) {
    return shot(t, 'home_dark', Routes.home, brightness: Brightness.dark);
  });
  testWidgets('game 3', (t) => shot(t, 'game_3', Routes.game(3)));
  testWidgets('game 9', (t) => shot(t, 'game_9', Routes.game(9)));
  testWidgets('game 11', (t) => shot(t, 'game_11', Routes.game(11)));
  testWidgets('game 5', (t) => shot(t, 'game_5', Routes.game(5)));
  testWidgets('map', (t) => shot(t, 'map', Routes.map));
  testWidgets('collection', (t) => shot(t, 'collection', Routes.collection));
  testWidgets('skins', (t) {
    return shot(
      t,
      'skins',
      Routes.collection,
      then: (t) => t.tap(find.byKey(const Key('tab-skins'))),
    );
  });
  testWidgets('skins bottom', (t) {
    return shot(
      t,
      'skins_bottom',
      Routes.collection,
      then: (t) async {
        await t.tap(find.byKey(const Key('tab-skins')));
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await t.drag(find.text('Clean pen lines'), const Offset(0, -1500));
      },
    );
  });
  testWidgets('skins dark', (t) {
    return shot(
      t,
      'skins_dark',
      Routes.collection,
      brightness: Brightness.dark,
      then: (t) => t.tap(find.byKey(const Key('tab-skins'))),
    );
  });
  testWidgets('daily', (t) => shot(t, 'daily', Routes.daily));
  testWidgets(
    'puzzle',
    (t) => shot(t, 'puzzle', Routes.puzzleGame('mountain', 1)),
  );
  testWidgets('settings', (t) => shot(t, 'settings', Routes.settings));
}
