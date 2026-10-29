import 'package:arrow_engine/arrow_engine.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_state.freezed.dart';

@freezed
abstract class GameViewState with _$GameViewState {
  const GameViewState._();

  const factory GameViewState({
    required int levelNumber,
    required PlaySession session,
    @Default(false) bool showPaths,
  }) = _GameViewState;

  Level get level => session.level;
  SessionStatus get status => session.status;
}
