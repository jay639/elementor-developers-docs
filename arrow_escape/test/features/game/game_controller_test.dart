import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/services/haptics.dart';
import 'package:arrow_escape/core/services/sound.dart';
import 'package:arrow_escape/features/game/application/game_controller.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/progress/application/progress_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late ProviderContainer container;
  late RecordingHaptics haptics;
  late RecordingSound sound;
  // Three cars; piece 1 waits for piece 2.
  final level = parseAsciiLevel('^>.^');

  setUp(() async {
    haptics = RecordingHaptics();
    sound = RecordingSound();
    container = ProviderContainer(
      overrides: testOverrides(
        haptics: haptics,
        sound: sound,
        levels: [level, level],
      ),
    );
    addTearDown(container.dispose);
    await container.read(levelProvider(1).future);
  });

  GameController controller() =>
      container.read(gameControllerProvider(1).notifier);

  // autoDispose: keep the provider alive for the duration of a test.
  void keepAlive() => container.listen(gameControllerProvider(1), (_, _) {});

  test('exit plays swoosh + light haptic', () {
    keepAlive();
    expect(controller().tap(0), isA<ExitMove>());
    expect(sound.played, [Sfx.swoosh]);
    expect(haptics.played, [HapticKind.exit]);
  });

  test('bump costs a heart and plays bump feedback', () {
    keepAlive();
    expect(controller().tap(1), isA<BlockedMove>());
    expect(container.read(gameControllerProvider(1)).session.hearts, 2);
    expect(sound.played, [Sfx.bump]);
    expect(haptics.played, [HapticKind.bump]);
  });

  test('ignored taps give no feedback', () {
    keepAlive();
    controller().tap(0);
    sound.played.clear();
    expect(controller().tap(0), isNull);
    expect(sound.played, isEmpty);
  });

  test('winning records stars and unlocks the next level', () {
    keepAlive();
    controller()
      ..tap(0)
      ..tap(1) // mistake
      ..tap(2)
      ..tap(1);
    final state = container.read(gameControllerProvider(1));
    expect(state.status, SessionStatus.won);
    final progress = container.read(progressProvider);
    expect(progress.starsFor(1), 2);
    expect(progress.unlocked, 2);
    expect(sound.played.last, Sfx.win);
  });

  test('best stars are kept on replay', () {
    container.read(progressProvider.notifier)
      ..completeLevel(1, 3)
      ..completeLevel(1, 1);
    expect(container.read(progressProvider).starsFor(1), 3);
    expect(container.read(progressProvider).unlocked, 2);
  });

  test('losing plays the lose sound', () {
    keepAlive();
    controller()
      ..tap(1)
      ..tap(1)
      ..tap(1);
    expect(
      container.read(gameControllerProvider(1)).status,
      SessionStatus.lost,
    );
    expect(sound.played.last, Sfx.lose);
  });

  test('undo returns the piece that came back', () {
    keepAlive();
    controller()
      ..tap(0)
      ..tap(2);
    expect(controller().undo(), 2);
    expect(controller().undo(), isNull); // only one free undo
  });

  test('restart resets the session but keeps the paths toggle', () {
    keepAlive();
    controller()
      ..togglePaths()
      ..tap(0)
      ..tap(1)
      ..restart();
    final state = container.read(gameControllerProvider(1));
    expect(state.session.hearts, 3);
    expect(state.session.board.remainingCount, 3);
    expect(state.showPaths, isTrue);
  });
}
