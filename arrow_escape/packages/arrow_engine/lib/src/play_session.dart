import 'board_state.dart';
import 'level.dart';
import 'rules.dart';

enum SessionStatus { playing, won, lost }

/// Result of a tap on a [PlaySession].
class TapResult {
  const TapResult(this.session, this.outcome);

  final PlaySession session;

  /// Null when the tap was ignored (game over, or the piece already left).
  final MoveOutcome? outcome;
}

/// One play-through of a level: board state, hearts and undo.
///
/// Immutable; every action returns a new session.
class PlaySession {
  PlaySession._({
    required this.rules,
    required this.board,
    required this.hearts,
    required this.maxHearts,
    required this.undosLeft,
    required this.mistakes,
    required List<BoardState> history,
  }) : _history = history;

  factory PlaySession.start(
    Level level, {
    int hearts = defaultHearts,
    int freeUndos = 1,
    Rules? rules,
  }) {
    final r = rules ?? Rules(level);
    return PlaySession._(
      rules: r,
      board: r.initialState,
      hearts: hearts,
      maxHearts: hearts,
      undosLeft: freeUndos,
      mistakes: 0,
      history: const [],
    );
  }

  /// Rebuilds a level the player left part-way: replays [exits] in order
  /// and restores hearts and mistakes. Anything that doesn't replay
  /// cleanly (a changed level, a corrupt record) starts the level fresh.
  factory PlaySession.resume(
    Level level, {
    required List<int> exits,
    required int hearts,
    required int mistakes,
    Rules? rules,
  }) {
    final fresh = PlaySession.start(level, rules: rules);
    var s = fresh;
    for (final p in exits) {
      if (p < 0 || p >= s.rules.pieceCount || !s.board.isOnBoard(p)) {
        return fresh;
      }
      if (s.rules.evaluate(s.board, p) is! ExitMove) return fresh;
      s = s._copy(board: s.board.without(p), history: [...s._history, s.board]);
    }
    if (hearts <= 0 || mistakes < 0 || s.board.isCleared) return fresh;
    return s._copy(hearts: hearts, mistakes: mistakes);
  }

  static const defaultHearts = 3;

  final Rules rules;
  final BoardState board;
  final int hearts;
  final int maxHearts;
  final int undosLeft;
  final int mistakes;
  final List<BoardState> _history;

  Level get level => rules.level;

  SessionStatus get status {
    if (board.isCleared) return SessionStatus.won;
    if (hearts <= 0) return SessionStatus.lost;
    return SessionStatus.playing;
  }

  bool get isOver => status != SessionStatus.playing;

  bool get canUndo => undosLeft > 0 && _history.isNotEmpty && !isOver;

  /// 3 stars for a clean run, minus one per heart lost (minimum 1).
  int get stars => (3 - mistakes).clamp(1, 3);

  TapResult tap(int piece) {
    if (isOver || piece < 0 || piece >= rules.pieceCount) {
      return TapResult(this, null);
    }
    if (!board.isOnBoard(piece)) return TapResult(this, null);
    final outcome = rules.evaluate(board, piece);
    switch (outcome) {
      case ExitMove():
        return TapResult(
          _copy(board: board.without(piece), history: [..._history, board]),
          outcome,
        );
      case BlockedMove():
        return TapResult(
          _copy(hearts: hearts - 1, mistakes: mistakes + 1),
          outcome,
        );
    }
  }

  /// Reverts the last exit. Hearts lost since are not refunded.
  PlaySession undo() {
    if (!canUndo) return this;
    return _copy(
      board: _history.last,
      history: _history.sublist(0, _history.length - 1),
      undosLeft: undosLeft - 1,
    );
  }

  /// Rewarded "extra heart": continue a lost level or top up.
  PlaySession addHeart() => _copy(hearts: hearts + 1);

  PlaySession _copy({
    BoardState? board,
    int? hearts,
    int? undosLeft,
    int? mistakes,
    List<BoardState>? history,
  }) => PlaySession._(
    rules: rules,
    board: board ?? this.board,
    hearts: hearts ?? this.hearts,
    maxHearts: maxHearts,
    undosLeft: undosLeft ?? this.undosLeft,
    mistakes: mistakes ?? this.mistakes,
    history: history ?? _history,
  );
}
