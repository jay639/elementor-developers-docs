import 'dart:math' as math;

import 'level.dart';
import 'rng.dart';
import 'rules.dart';
import 'solver.dart';

/// Solver-derived facts about a level and the resulting difficulty score.
class LevelStats {
  const LevelStats({
    required this.solution,
    required this.pieces,
    required this.depth,
    required this.avgBranching,
    required this.blockedFraction,
    required this.avgBlockers,
    required this.solverStates,
    required this.difficulty,
  });

  /// One optimal play order. Every vehicle leaves exactly once, so the
  /// minimum number of moves equals the number of vehicles.
  final List<int> solution;
  final int pieces;

  /// Longest chain of vehicles that must wait for one another.
  final int depth;

  /// Average number of legal moves along the solution (fewer = harder).
  final double avgBranching;

  /// Share of vehicles that cannot move at the start.
  final double blockedFraction;

  /// Average number of other vehicles on each vehicle's path.
  final double avgBlockers;

  /// States the solver expanded (dead ends from lights / ambulance).
  final int solverStates;

  /// 0..100.
  final double difficulty;

  int get minMoves => solution.length;

  @override
  String toString() =>
      'pieces=$pieces depth=$depth branching=${avgBranching.toStringAsFixed(2)} '
      'blocked=${(blockedFraction * 100).round()}% '
      'blockers=${avgBlockers.toStringAsFixed(2)} states=$solverStates '
      'difficulty=${difficulty.toStringAsFixed(1)}';
}

/// Solves [level] and scores it. Returns null when it is unsolvable (or
/// too expensive to prove solvable).
LevelStats? analyzeLevel(Level level, {int maxStates = 200000}) {
  final rules = Rules(level);
  final solver = Solver.fromRules(rules, maxStates: maxStates);
  final solution = solver.solve();
  if (solution == null) return null;
  final n = level.pieces.length;

  // Branching along the found solution.
  var state = rules.initialState;
  var branchSum = 0;
  for (final move in solution) {
    branchSum += rules.legalMoves(state).length;
    state = state.without(move);
  }
  final avgBranching = n == 0 ? 1.0 : branchSum / n;
  // Blocked at the start by another vehicle or a light. Waiting for the
  // ambulance doesn't count: it tells the player what to do first.
  final start = rules.initialState;
  var initiallyBlocked = 0;
  for (var i = 0; i < n; i++) {
    final out = rules.evaluate(start, i);
    if (out is BlockedMove && out.reason != BlockReason.ambulanceFirst) {
      initiallyBlocked++;
    }
  }

  // Static "must wait for" graph: the vehicles on my path.
  final waitsFor = List.generate(n, (i) => rules.potentialBlockers(i).toSet());
  final ambulances = [
    for (var i = 0; i < n; i++)
      if (level.pieces[i].kind == PieceKind.ambulance) i,
  ];
  final memo = List<int>.filled(n, 0);
  final visiting = List<bool>.filled(n, false);
  int depthOf(int i) {
    if (memo[i] > 0) return memo[i];
    // A cycle can only be broken by lights changing; count it as one link.
    if (visiting[i]) return 1;
    visiting[i] = true;
    var best = 0;
    for (final d in waitsFor[i]) {
      best = math.max(best, depthOf(d));
    }
    visiting[i] = false;
    return memo[i] = best + 1;
  }

  var depth = 0;
  var blockerSum = 0;
  for (var i = 0; i < n; i++) {
    depth = math.max(depth, depthOf(i));
    blockerSum += rules.potentialBlockers(i).toSet().length;
  }
  final avgBlockers = n == 0 ? 0.0 : blockerSum / n;
  final blockedFraction = n == 0 ? 0.0 : initiallyBlocked / n;

  final difficulty = scoreDifficulty(
    pieces: n,
    depth: depth,
    avgBranching: avgBranching,
    blockedFraction: blockedFraction,
    avgBlockers: avgBlockers,
    solverStates: solver.visitedStates,
    lights: level.lights.length,
    gates: level.gates.length,
    trucks: level.pieces.where((p) => p.kind == PieceKind.truck).length,
    ambulance: ambulances.isNotEmpty,
  );

  return LevelStats(
    solution: solution,
    pieces: n,
    depth: depth,
    avgBranching: avgBranching,
    blockedFraction: blockedFraction,
    avgBlockers: avgBlockers,
    solverStates: solver.visitedStates,
    difficulty: difficulty,
  );
}

/// Blends the metrics into a 0..100 score. Weights were tuned against
/// generated samples: a tiny greedy-free board scores ~10, a crowded
/// 70-vehicle board with 9-deep chains ~85, mechanics add the rest.
double scoreDifficulty({
  required int pieces,
  required int depth,
  required double avgBranching,
  required double blockedFraction,
  required double avgBlockers,
  required int solverStates,
  int lights = 0,
  int gates = 0,
  int trucks = 0,
  bool ambulance = false,
}) {
  if (pieces <= 0) return 0;
  // More vehicles take longer to read.
  final size = 11 * detLn(math.max(1, pieces / 4));
  // Long waiting chains are the core of the challenge.
  final chain = 5 * math.max(0, depth - 2);
  final tight = 20 * math.max(0, blockedFraction - 0.25);
  final crowd = 6 * avgBlockers;
  // Dead ends (lights, ambulance) punish a wrong order.
  final dead = solverStates > pieces + 1
      ? 4 * detLn(solverStates / (pieces + 1))
      : 0.0;
  final mechanics =
      3.0 * math.min(lights, 3) +
      2.5 * math.min(gates, 3) +
      0.6 * math.min(trucks, 8) +
      (ambulance ? 5 : 0);
  return (size + chain + tight + crowd + dead + mechanics).clamp(0, 100);
}
