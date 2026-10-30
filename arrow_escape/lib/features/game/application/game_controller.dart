import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/core/services/haptics.dart';
import 'package:arrow_escape/core/services/sound.dart';
import 'package:arrow_escape/features/game/application/game_state.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Game logic for one level. Requires [levelProvider] for the same ref to
/// have loaded.
final gameControllerProvider = NotifierProvider.autoDispose
    .family<GameController, GameViewState, LevelRef>(GameController.new);

class GameController extends Notifier<GameViewState> {
  GameController(this.levelRef);

  final LevelRef levelRef;

  final _clock = Stopwatch();

  String get _label => switch (levelRef) {
    CampaignLevelRef(:final number) => '$number',
    DailyLevelRef(:final dateKey) => 'daily_$dateKey',
  };

  @override
  GameViewState build() {
    final level = ref.watch(levelProvider(levelRef)).requireValue;
    _clock
      ..reset()
      ..start();
    ref.read(analyticsProvider).levelStart(_label, daily: levelRef.isDaily);
    return GameViewState(levelRef: levelRef, session: PlaySession.start(level));
  }

  /// Applies a tap and plays feedback. Returns the outcome so the view can
  /// animate it, or null if the tap was ignored.
  MoveOutcome? tap(int piece) {
    final result = state.session.tap(piece);
    final outcome = result.outcome;
    if (outcome == null) return null;
    state = state.copyWith(session: result.session, hintPiece: null);

    final haptics = ref.read(hapticsProvider);
    final sound = ref.read(soundProvider);
    switch (outcome) {
      case ExitMove():
        haptics.play(HapticKind.exit);
        sound.play(Sfx.swoosh);
      case BlockedMove():
        haptics.play(HapticKind.bump);
        sound.play(Sfx.bump);
    }

    switch (result.session.status) {
      case SessionStatus.won:
        final save = ref.read(saveProvider.notifier);
        final stars = result.session.stars;
        final coins = switch (levelRef) {
          CampaignLevelRef(:final number) => save.winLevel(number, stars),
          DailyLevelRef(:final dateKey) => save.winDaily(dateKey, stars),
        };
        state = state.copyWith(coinsEarned: coins);
        ref
            .read(analyticsProvider)
            .levelComplete(
              _label,
              daily: levelRef.isDaily,
              stars: stars,
              mistakes: result.session.mistakes,
              seconds: _clock.elapsed.inSeconds,
            );
        haptics.play(HapticKind.win);
        sound.play(Sfx.win);
      case SessionStatus.lost:
        ref
            .read(analyticsProvider)
            .levelFail(
              _label,
              daily: levelRef.isDaily,
              seconds: _clock.elapsed.inSeconds,
            );
        haptics.play(HapticKind.lose);
        sound.play(Sfx.lose);
      case SessionStatus.playing:
        break;
    }
    return outcome;
  }

  /// Reverts the last exit; returns the piece that came back, if any.
  int? undo() {
    final before = state.session;
    final after = before.undo();
    if (identical(before, after)) return null;
    state = state.copyWith(session: after, hintPiece: null);
    ref.read(hapticsProvider).play(HapticKind.tap);
    for (final p in after.board.remaining) {
      if (!before.board.isOnBoard(p)) return p;
    }
    return null;
  }

  void togglePaths() {
    state = state.copyWith(showPaths: !state.showPaths);
    ref.read(hapticsProvider).play(HapticKind.tap);
  }

  /// Highlights a vehicle that keeps the board solvable. Returns false when
  /// there is none (game over or the solver gave up).
  bool showHint() {
    final session = state.session;
    if (session.isOver) return false;
    final piece = Solver.fromRules(
      session.rules,
      maxStates: 50000,
    ).hint(session.board);
    if (piece == null) return false;
    state = state.copyWith(hintPiece: piece);
    ref.read(hapticsProvider).play(HapticKind.tap);
    return true;
  }

  /// Rewarded "extra heart": continue after running out.
  void addHeart() {
    state = state.copyWith(session: state.session.addHeart());
    _clock.start();
  }

  /// Rewarded "double coins" on the win card; once per win.
  void doubleCoins() {
    if (state.coinsDoubled || state.coinsEarned == 0) return;
    ref.read(saveProvider.notifier).addCoins(state.coinsEarned);
    state = state.copyWith(
      coinsEarned: state.coinsEarned * 2,
      coinsDoubled: true,
    );
  }

  void restart() {
    _clock
      ..reset()
      ..start();
    state = GameViewState(
      levelRef: levelRef,
      session: PlaySession.start(state.level, rules: state.session.rules),
      showPaths: state.showPaths,
    );
  }
}
