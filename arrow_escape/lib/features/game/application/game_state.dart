import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
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
  }) = _GameViewState;

  Level get level => session.level;
  SessionStatus get status => session.status;
}
