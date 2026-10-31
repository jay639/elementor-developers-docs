import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/services/haptics.dart';
import 'package:arrow_escape/core/services/sound.dart';
import 'package:arrow_escape/features/game/application/game_controller.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/progress/application/progress_controller.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

const one = LevelRef.campaign(1);

void main() {
  late ProviderContainer container;
  late RecordingHaptics haptics;
  late RecordingSound sound;
  late RecordingAnalytics analytics;
  // Three cars; piece 1 waits for piece 2.
  final level = parseAsciiLevel('^>.^');

  setUp(() async {
    haptics = RecordingHaptics();
    sound = RecordingSound();
    analytics = RecordingAnalytics();
    container = ProviderContainer(
      overrides: testOverrides(
        haptics: haptics,
        sound: sound,
        levels: [level, level],
        analytics: analytics,
      ),
    );
    addTearDown(container.dispose);
    await container.read(levelProvider(one).future);
  });

  GameController controller() =>
      container.read(gameControllerProvider(one).notifier);

  // autoDispose: keep the provider alive for the duration of a test.
  void keepAlive() => container.listen(gameControllerProvider(one), (_, _) {});

  test('exit plays swoosh + light haptic', () {
    keepAlive();
    expect(controller().tap(0), isA<ExitMove>());
    expect(sound.played, [Sfx.swoosh]);
    expect(haptics.played, [HapticKind.exit]);
  });

  test('bump costs a heart and plays bump feedback', () {
    keepAlive();
    expect(controller().tap(1), isA<BlockedMove>());
    expect(container.read(gameControllerProvider(one)).session.hearts, 2);
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
    final state = container.read(gameControllerProvider(one));
    expect(state.status, SessionStatus.won);
    final progress = container.read(progressProvider);
    expect(progress.starsFor(1), 2);
    expect(progress.unlocked, 2);
    expect(sound.played.last, Sfx.win);
  });

  test('best stars are kept on replay', () {
    container.read(saveProvider.notifier)
      ..winLevel(1, 3)
      ..winLevel(1, 1);
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
      container.read(gameControllerProvider(one)).status,
      SessionStatus.lost,
    );
    expect(sound.played.last, Sfx.lose);
  });

  test('restart resets the session but keeps the paths toggle', () {
    keepAlive();
    controller()
      ..togglePaths()
      ..tap(0)
      ..tap(1)
      ..restart();
    final state = container.read(gameControllerProvider(one));
    expect(state.session.hearts, 3);
    expect(state.session.board.remainingCount, 3);
    expect(state.showPaths, isTrue);
  });

  test('winning a daily records daily stars, not campaign progress', () async {
    const daily = LevelRef.daily('2026-10-29');
    await container.read(levelProvider(daily).future);
    container.listen(gameControllerProvider(daily), (_, _) {});
    final c = container.read(gameControllerProvider(daily).notifier);
    for (final p in [0, 2, 1]) {
      c.tap(p);
    }
    expect(
      container.read(gameControllerProvider(daily)).status,
      SessionStatus.won,
    );
    final progress = container.read(progressProvider);
    expect(progress.dailyStarsFor('2026-10-29'), 3);
    expect(progress.unlocked, 1);
  });

  test('daily stars keep the best result', () {
    container.read(saveProvider.notifier)
      ..winDaily('2026-10-29', 3)
      ..winDaily('2026-10-29', 1);
    expect(container.read(progressProvider).dailyStarsFor('2026-10-29'), 3);
  });

  test('a win awards coins and they show in the game state', () {
    keepAlive();
    controller()
      ..tap(0)
      ..tap(2)
      ..tap(1);
    final state = container.read(gameControllerProvider(one));
    expect(state.coinsEarned, 25); // first clear, 3 stars
    expect(container.read(saveProvider).coins, 25);
  });

  test('double coins pays the win reward again, once', () {
    keepAlive();
    controller()
      ..tap(0)
      ..tap(2)
      ..tap(1)
      ..doubleCoins()
      ..doubleCoins();
    expect(container.read(gameControllerProvider(one)).coinsEarned, 50);
    expect(container.read(saveProvider).coins, 50);
  });

  test('hint picks a vehicle that can leave and clears on the next move', () {
    keepAlive();
    expect(controller().showHint(), isTrue);
    final hint = container.read(gameControllerProvider(one)).hintPiece;
    expect(hint, isNotNull);
    final rules = container.read(gameControllerProvider(one)).session.rules;
    expect(rules.canExit(rules.initialState, hint!), isTrue);
    controller().tap(hint);
    expect(container.read(gameControllerProvider(one)).hintPiece, isNull);
  });

  test('extra heart continues a lost level', () {
    keepAlive();
    controller()
      ..tap(1)
      ..tap(1)
      ..tap(1);
    expect(
      container.read(gameControllerProvider(one)).status,
      SessionStatus.lost,
    );
    controller().addHeart();
    expect(
      container.read(gameControllerProvider(one)).status,
      SessionStatus.playing,
    );
  });

  test('analytics: start, complete and fail events', () {
    keepAlive();
    expect(analytics.events.first.name, 'level_start');
    controller()
      ..tap(1)
      ..tap(1)
      ..tap(1);
    expect(analytics.events.last.name, 'level_fail');
    controller()
      ..restart()
      ..tap(0)
      ..tap(2)
      ..tap(1);
    final done = analytics.events.last;
    expect(done.name, 'level_complete');
    expect(done.params['stars'], 3);
  });
}
