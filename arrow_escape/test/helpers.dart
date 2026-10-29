import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/app/app.dart';
import 'package:arrow_escape/core/services/haptics.dart';
import 'package:arrow_escape/core/services/sound.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/game/presentation/board_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

class RecordingHaptics implements HapticsService {
  final played = <HapticKind>[];

  @override
  void play(HapticKind kind) => played.add(kind);
}

class RecordingSound implements SoundService {
  final played = <Sfx>[];

  @override
  void play(Sfx sfx) => played.add(sfx);

  @override
  void warmUp() {}

  @override
  Future<void> dispose() async {}
}

/// Serves fixed levels, so tests don't depend on the shipped content.
class FakeLevelRepository implements LevelRepository {
  FakeLevelRepository(this.levels);

  final List<Level> levels;

  @override
  int get count => levels.length;

  @override
  Future<Level> load(int number) async => levels[number - 1];
}

List<Override> testOverrides({
  RecordingHaptics? haptics,
  RecordingSound? sound,
  List<Level>? levels,
}) => [
  hapticsProvider.overrideWithValue(haptics ?? RecordingHaptics()),
  soundProvider.overrideWithValue(sound ?? RecordingSound()),
  if (levels != null)
    levelRepositoryProvider.overrideWithValue(FakeLevelRepository(levels)),
];

Future<void> pumpApp(
  WidgetTester tester, {
  List<Override> overrides = const [],
  List<Level>? levels,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(levels: levels),
        ...overrides,
      ],
      child: const ArrowEscapeApp(),
    ),
  );
}

/// Taps the centre of [piece]'s head cell on the visible board.
Future<void> tapPiece(WidgetTester tester, Level level, int piece) async {
  final finder = find.byType(BoardView);
  final box = tester.renderObject<RenderBox>(finder);
  final layout = BoardLayout(level, box.size);
  final local = layout.centerOf(level.pieces[piece].head);
  await tester.tapAt(box.localToGlobal(local));
  await tester.pump();
}

/// Lets animations and the result-card delay finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
