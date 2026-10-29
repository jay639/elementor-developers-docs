import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/services/haptics.dart';
import 'package:arrow_escape/core/services/sound.dart';
import 'package:arrow_escape/features/game/application/game_state.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/progress/application/progress_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Game logic for one level. Requires [levelProvider] for the same ref to
/// have loaded.
final gameControllerProvider = NotifierProvider.autoDispose
    .family<GameController, GameViewState, LevelRef>(GameController.new);

class GameController extends Notifier<GameViewState> {
  GameController(this.levelRef);

  final LevelRef levelRef;

  @override
  GameViewState build() {
    final level = ref.watch(levelProvider(levelRef)).requireValue;
    return GameViewState(levelRef: levelRef, session: PlaySession.start(level));
  }

  /// Applies a tap and plays feedback. Returns the outcome so the view can
  /// animate it, or null if the tap was ignored.
  MoveOutcome? tap(int piece) {
    final result = state.session.tap(piece);
    final outcome = result.outcome;
    if (outcome == null) return null;
    state = state.copyWith(session: result.session);

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
        final progress = ref.read(progressProvider.notifier);
        final stars = result.session.stars;
        switch (levelRef) {
          case CampaignLevelRef(:final number):
            progress.completeLevel(number, stars);
          case DailyLevelRef(:final dateKey):
            progress.completeDaily(dateKey, stars);
        }
        haptics.play(HapticKind.win);
        sound.play(Sfx.win);
      case SessionStatus.lost:
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
    state = state.copyWith(session: after);
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

  void restart() {
    state = GameViewState(
      levelRef: levelRef,
      session: PlaySession.start(state.level, rules: state.session.rules),
      showPaths: state.showPaths,
    );
  }
}
