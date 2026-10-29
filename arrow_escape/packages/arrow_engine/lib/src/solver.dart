import 'board_state.dart';
import 'level.dart';
import 'rules.dart';

/// Depth-first solver with memoised dead states.
///
/// Without traffic lights the puzzle is monotone (an exit never blocks
/// anyone), so the first legal move is always safe and the search is linear.
/// Lights and the ambulance rule can create dead ends, which the memo of
/// failed states keeps cheap.
class Solver {
  Solver(Level level, {this.maxStates = 200000}) : rules = Rules(level);

  Solver.fromRules(this.rules, {this.maxStates = 200000});

  final Rules rules;

  /// Search budget; [solve] returns null when it is exhausted.
  final int maxStates;

  int _visited = 0;

  /// Number of states expanded by the last [solve] call.
  int get visitedStates => _visited;

  /// A sequence of piece indexes that clears the board, or null if none
  /// exists (or the budget ran out).
  List<int>? solve([BoardState? from]) {
    _visited = 0;
    final dead = <String>{};
    final path = <int>[];

    bool search(BoardState s) {
      if (s.isCleared) return true;
      if (++_visited > maxStates) return false;
      final key = s.solverKey;
      if (dead.contains(key)) return false;
      for (final move in rules.legalMoves(s)) {
        path.add(move);
        if (search(s.without(move))) return true;
        path.removeLast();
      }
      dead.add(key);
      return false;
    }

    return search(from ?? rules.initialState) ? path : null;
  }

  /// A piece that keeps the board solvable from [s], for hints.
  int? hint(BoardState s) {
    final solution = solve(s);
    return (solution == null || solution.isEmpty) ? null : solution.first;
  }
}
