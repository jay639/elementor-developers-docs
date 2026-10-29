import 'board_state.dart';
import 'dir.dart';
import 'level.dart';

/// Why a tap did not let a vehicle leave.
enum BlockReason {
  /// Another vehicle is in the way.
  vehicle,

  /// A red traffic light is on the path.
  redLight,

  /// A one-way gate points back the way the vehicle came.
  wrongWay,

  /// Gates send the vehicle round in a circle, or into its own body.
  noExit,

  /// An ambulance is on the board and this vehicle is not in its lane.
  ambulanceFirst,
}

/// Result of trying to move a piece.
sealed class MoveOutcome {
  const MoveOutcome(this.piece);
  final int piece;
}

/// The piece drives off the board along [path] (cells after its head, in
/// order, until the edge).
final class ExitMove extends MoveOutcome {
  const ExitMove(super.piece, this.path);
  final List<int> path;
}

/// The piece cannot leave. It can still roll [freeSteps] cells along [path]
/// before hitting the obstacle at [blockerCell] (if any).
final class BlockedMove extends MoveOutcome {
  const BlockedMove(
    super.piece, {
    required this.reason,
    required this.freeSteps,
    required this.path,
    this.blockerCell,
    this.blockerPiece,
  });

  final BlockReason reason;
  final int freeSteps;
  final List<int> path;
  final int? blockerCell;
  final int? blockerPiece;
}

/// Something on a piece's path that may stop it, in path order.
class _Obstacle {
  const _Obstacle(this.step, this.cell, {this.piece = -1, this.light = -1});

  /// Index into the path (0 = first cell in front of the head).
  final int step;
  final int cell;
  final int piece;
  final int light;
}

/// Precomputed, level-specific rule evaluation.
///
/// Pieces never move until they exit, so every piece's path and the list of
/// things that may block it are static. Only which pieces remain, the light
/// parity and the ambulance rule change between states, which keeps
/// [evaluate] cheap enough for the solver.
class Rules {
  Rules(this.level) {
    final n = level.pieces.length;
    _occupant = List.filled(level.cellCount, -1);
    for (var i = 0; i < n; i++) {
      for (final c in level.pieces[i].cells) {
        _occupant[c] = i;
      }
    }
    _lightAt = List.filled(level.cellCount, -1);
    for (var i = 0; i < level.lights.length; i++) {
      _lightAt[level.lights[i].cell] = i;
    }
    _gateAt = List.filled(level.cellCount, null);
    for (final g in level.gates) {
      _gateAt[g.cell] = g.dir;
    }

    _paths = List.generate(n, (i) => _tracePath(i));
    _ambulances = [
      for (var i = 0; i < n; i++)
        if (level.pieces[i].kind == PieceKind.ambulance) i,
    ];
    _inLaneOf = List.generate(n, (i) {
      final cells = level.pieces[i].cells.toSet();
      return [
        for (final a in _ambulances)
          if (a != i && _paths[a].cells.any(cells.contains)) a,
      ];
    });
  }

  final Level level;
  late final List<int> _occupant;
  late final List<int> _lightAt;
  late final List<Dir?> _gateAt;
  late final List<_Path> _paths;
  late final List<int> _ambulances;
  late final List<List<int>> _inLaneOf;

  int get pieceCount => level.pieces.length;

  BoardState get initialState => BoardState.initial(pieceCount);

  /// Static path of [piece] (cells in front of the head, to the edge or to
  /// the point where it can never continue).
  List<int> pathOf(int piece) => _paths[piece].cells;

  /// Whether the path leaves the board when nothing is in the way.
  bool pathCanExit(int piece) => _paths[piece].terminal == null;

  /// Pieces that may block [piece] at some point (static).
  Iterable<int> potentialBlockers(int piece) sync* {
    for (final o in _paths[piece].obstacles) {
      if (o.piece >= 0) yield o.piece;
    }
  }

  /// Ambulances whose lane [piece] stands in.
  List<int> lanesOf(int piece) => _inLaneOf[piece];

  bool isGreen(int light, BoardState s) =>
      level.lights[light].isGreenAfter(s.exits);

  /// Whether [piece] is held back by the ambulance rule in [s].
  bool mustYieldToAmbulance(int piece, BoardState s) {
    if (_ambulances.isEmpty) return false;
    if (level.pieces[piece].kind == PieceKind.ambulance) return false;
    var ambulanceOnBoard = false;
    for (final a in _ambulances) {
      if (s.isOnBoard(a)) {
        ambulanceOnBoard = true;
        break;
      }
    }
    if (!ambulanceOnBoard) return false;
    for (final a in _inLaneOf[piece]) {
      if (s.isOnBoard(a)) return false;
    }
    return true;
  }

  MoveOutcome evaluate(BoardState s, int piece) {
    assert(s.isOnBoard(piece));
    final path = _paths[piece];
    if (mustYieldToAmbulance(piece, s)) {
      return BlockedMove(
        piece,
        reason: BlockReason.ambulanceFirst,
        freeSteps: 0,
        path: path.cells,
      );
    }
    for (final o in path.obstacles) {
      if (o.piece >= 0) {
        if (s.isOnBoard(o.piece)) {
          return BlockedMove(
            piece,
            reason: BlockReason.vehicle,
            freeSteps: o.step,
            path: path.cells,
            blockerCell: o.cell,
            blockerPiece: o.piece,
          );
        }
      } else if (!isGreen(o.light, s)) {
        return BlockedMove(
          piece,
          reason: BlockReason.redLight,
          freeSteps: o.step,
          path: path.cells,
          blockerCell: o.cell,
        );
      }
    }
    final terminal = path.terminal;
    if (terminal != null) {
      return BlockedMove(
        piece,
        reason: terminal,
        freeSteps: path.cells.length,
        path: path.cells,
        blockerCell: path.terminalCell,
      );
    }
    return ExitMove(piece, path.cells);
  }

  bool canExit(BoardState s, int piece) => evaluate(s, piece) is ExitMove;

  /// All pieces that can leave right now.
  List<int> legalMoves(BoardState s) => [
    for (final p in s.remaining)
      if (canExit(s, p)) p,
  ];

  _Path _tracePath(int piece) {
    final def = level.pieces[piece];
    final own = def.cells.toSet();
    final cells = <int>[];
    final obstacles = <_Obstacle>[];
    final seen = <int>{};
    var dir = def.dir;
    var cell = def.head;
    while (true) {
      final next = level.step(cell, dir);
      if (next == -1) return _Path(cells, obstacles);
      if (own.contains(next)) {
        return _Path(cells, obstacles, BlockReason.noExit, next);
      }
      final gate = _gateAt[next];
      if (gate != null && gate == dir.opposite) {
        return _Path(cells, obstacles, BlockReason.wrongWay, next);
      }
      // A loop through gates revisits a gate.
      if (gate != null && !seen.add(next)) {
        return _Path(cells, obstacles, BlockReason.noExit, next);
      }
      final step = cells.length;
      cells.add(next);
      final occupant = _occupant[next];
      if (occupant >= 0) {
        obstacles.add(_Obstacle(step, next, piece: occupant));
      }
      final light = _lightAt[next];
      if (light >= 0) obstacles.add(_Obstacle(step, next, light: light));
      if (gate != null) dir = gate;
      cell = next;
    }
  }
}

class _Path {
  _Path(this.cells, this.obstacles, [this.terminal, this.terminalCell]);

  final List<int> cells;
  final List<_Obstacle> obstacles;
  final BlockReason? terminal;
  final int? terminalCell;
}
