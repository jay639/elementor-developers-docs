import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:arrow_escape/features/onboarding/tips.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';

@freezed
abstract class GameViewState with _$GameViewState {
  const GameViewState._();

  const factory GameViewState({
    required LevelRef levelRef,
    required PlaySession session,
    @Default(false) bool showPaths,

    /// Coins awarded for the win (0 until won).
    @Default(0) int coinsEarned,

    /// Whether the win reward was already doubled by a rewarded ad.
    @Default(false) bool coinsDoubled,

    /// Vehicle highlighted by a hint until the next move.
    int? hintPiece,

    /// Level-1 tutorial progress (none outside the tutorial).
    @Default(TutorialStep.none) TutorialStep tutorial,

    /// No order of moves can clear the board any more (traffic lights or
    /// the ambulance turned the last moves into a dead end).
    @Default(false) bool stuck,

    /// Picture puzzles this win unlocked (ids), announced on the win card.
    @Default(<String>[]) List<String> unlockedPuzzles,
  }) = _GameViewState;

  Level get level => session.level;
  SessionStatus get status => session.status;
}
