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
  }) = _GameViewState;

  Level get level => session.level;
  SessionStatus get status => session.status;
}
