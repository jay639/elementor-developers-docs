import 'dart:math' as math;

import 'dir.dart';
import 'level.dart';
import 'path_tracer.dart';
import 'rng.dart';
import 'shapes.dart';
import 'solver.dart';

/// Knobs for one generated level.
class GeneratorConfig {
  const GeneratorConfig({
    required this.seed,
    required this.shape,
    this.id = 0,
    this.fill = 0.7,
    this.greed = 3,
    this.minLength = 2,
    this.maxLength = 6,
    this.turnChance = 0.35,
    this.lights = 0,
    this.gates = 0,
    this.ambulance = false,
    this.pack = true,
  });

  final int seed;
  final ShapeMask shape;
  final int id;

  /// Share of the free playable cells to cover with vehicles.
  final double fill;

  /// Candidates sampled per placement; the one that blocks the most already
  /// placed vehicles wins. Higher = longer dependency chains = harder.
  final int greed;

  /// Arrow length range in cells. Arrows are drawn as winding lines; longer
  /// arrows lie across more paths, which makes deeper blocking chains.
  final int minLength;
  final int maxLength;

  /// Chance per cell that an arrow's body turns a corner.
  final double turnChance;
  final int lights;
  final int gates;
  final bool ambulance;

  /// Pack leftover space after the main placement pass.
  final bool pack;
}

/// Seeded procedural level generator.
///
/// Works by *reverse placement*: vehicles are added one at a time, and each
/// new vehicle's path must be clear of every vehicle already placed. Played
/// forwards, the last vehicle placed leaves first, then the one before it,
/// and so on, so the board is solvable by construction. New vehicles are
/// preferably placed on the paths of earlier ones, which is what creates
/// blocking chains.
///
/// Traffic lights (which depend on move parity) are verified with the
/// [Solver] afterwards. The ambulance gets an empty lane reserved up front;
/// only vehicles placed after it, standing in that lane, leave before it.
class LevelGenerator {
  LevelGenerator(this.config)
    : _rng = Rng(config.seed),
      _w = config.shape.width,
      _h = config.shape.height {
    final n = _w * _h;
    _occupant = List.filled(n, -1);
    _reserved = List.filled(n, false);
    _gateAt = List.filled(n, null);
    _cover = List.filled(n, 0);
    _lastCover = List.filled(n, -1);
  }

  /// Generates a solvable level, or null if this seed can't make one.
  static Level? generate(GeneratorConfig config) =>
      LevelGenerator(config)._run();

  final GeneratorConfig config;
  final Rng _rng;
  final int _w;
  final int _h;

  late final List<int> _occupant;
  late final List<bool> _reserved;
  late final List<Dir?> _gateAt;

  /// How many placed vehicles' paths cross each cell.
  late final List<int> _cover;

  /// Index of the last placed vehicle whose path crosses each cell.
  late final List<int> _lastCover;
  final _placed = <PieceDef>[];

  List<bool> get _mask => config.shape.cells;

  bool _isFree(int c) => _mask[c] && _occupant[c] < 0 && !_reserved[c];

  int _neighbor(int c, Dir d) {
    final x = c % _w + d.dx;
    final y = c ~/ _w + d.dy;
    return (x < 0 || y < 0 || x >= _w || y >= _h) ? -1 : y * _w + x;
  }

  Level? _run() {
    final maskCells = [
      for (var i = 0; i < _mask.length; i++)
        if (_mask[i]) i,
    ];
    if (maskCells.length < 2) return null;

    _placeGates(maskCells);
    PieceDef? ambulance;
    var lane = <int>[];
    if (config.ambulance) {
      final reserved = _reserveAmbulance(maskCells);
      if (reserved == null) return null;
      (ambulance, lane) = reserved;
    }

    final free = maskCells.where(_isFree).length;
    final target = (free * config.fill).round().clamp(1, free);
    var filled = 0;
    var failures = 0;
    while (filled < target && failures < 24) {
      final piece = _bestCandidate(maskCells);
      if (piece == null) {
        failures++;
        continue;
      }
      _place(piece);
      filled += piece.length;
    }
    if (config.pack) _packRemaining(maskCells);

    if (ambulance != null) {
      for (final c in [...ambulance.cells, ...lane]) {
        _reserved[c] = false;
      }
      if (!_pathClear(ambulance)) return null;
      _place(ambulance);
      // Vehicles placed now leave before the ambulance: lane only.
      final wanted = 1 + _rng.nextInt(3);
      var added = 0;
      final laneCells = [...lane]..removeWhere((c) => !_isFree(c));
      _rng.shuffle(laneCells);
      for (final c in laneCells) {
        if (added >= wanted) break;
        // An earlier lane arrow's body may have taken this cell.
        if (!_isFree(c)) continue;
        final piece = _candidateAt(c, maxLength: 3);
        if (piece != null) {
          _place(piece);
          added++;
        }
      }
      if (added == 0) return null;
    }
    if (_placed.length < 2) return null;
    if (config.pack) _extendTails();

    final gates = <OneWayGate>[
      for (var c = 0; c < _gateAt.length; c++)
        if (_gateAt[c] case final d? when _cover[c] > 0)
          OneWayGate(cell: c, dir: d),
    ];
    // Unused gates are dropped; they would only be decoration.
    for (var c = 0; c < _gateAt.length; c++) {
      if (_gateAt[c] != null && _cover[c] == 0) _gateAt[c] = null;
    }

    final lightCells = [
      for (final c in maskCells)
        if (_occupant[c] < 0 && _gateAt[c] == null && _cover[c] > 0) c,
    ];
    _rng.shuffle(lightCells);
    final lightCount = config.lights.clamp(0, lightCells.length);

    // Shuffle so piece order gives nothing away about the solution.
    final pieces = [..._placed];
    _rng.shuffle(pieces);

    for (var attempt = 0; attempt < 8; attempt++) {
      final lights = [
        for (var i = 0; i < lightCount; i++)
          TrafficLight(cell: lightCells[i], startsGreen: _rng.nextBool()),
      ];
      final level = Level(
        id: config.id,
        width: _w,
        height: _h,
        mask: _mask,
        pieces: pieces,
        lights: lights,
        gates: gates,
        meta: LevelMeta(shape: config.shape.name, seed: config.seed),
      );
      if (lights.isEmpty && !config.ambulance) return level;
      if (Solver(level, maxStates: 60000).solve() != null) return level;
    }
    return null;
  }

  /// Places each gate together with a "feeder" car whose path turns
  /// through it, so every gate matters. Feeders go first, so in play they
  /// leave last and later vehicles end up blocking them.
  void _placeGates(List<int> maskCells) {
    for (var i = 0; i < config.gates; i++) {
      for (var tries = 0; tries < 30; tries++) {
        final c = _rng.pick(maskCells);
        if (!_isFree(c)) continue;
        final gate = _rng.pick(Dir.values);
        _gateAt[c] = gate;
        _reserved[c] = true;
        final feeder = _feederFor(c, gate);
        if (feeder != null) {
          _place(feeder);
          break;
        }
        _gateAt[c] = null;
        _reserved[c] = false;
      }
    }
  }

  PieceDef? _feederFor(int gateCell, Dir gate) {
    // Enter from the side so the path visibly turns.
    final entries = [gate.clockwise, gate.counterClockwise];
    _rng.shuffle(entries);
    for (final enter in entries) {
      var head = gateCell;
      for (var back = 1; back <= 3; back++) {
        head = _neighbor(head, enter.opposite);
        if (head < 0) break;
        if (!_isFree(head)) continue;
        final def = PieceDef(kind: PieceKind.car, dir: enter, cells: [head]);
        final trace = _trace(def);
        if (trace.cells.contains(gateCell) && _pathClear(def)) return def;
      }
    }
    return null;
  }

  /// Picks the ambulance and keeps its lane empty during the main phase.
  (PieceDef, List<int>)? _reserveAmbulance(List<int> maskCells) {
    for (var tries = 0; tries < 60; tries++) {
      final head = _rng.pick(maskCells);
      final dir = _rng.pick(Dir.values);
      final tail = _neighbor(head, dir.opposite);
      if (!_isFree(head) || tail < 0 || !_isFree(tail)) continue;
      final def = PieceDef(
        kind: PieceKind.ambulance,
        dir: dir,
        cells: [head, tail],
      );
      final trace = _trace(def);
      if (!trace.exits || trace.cells.any((c) => _occupant[c] >= 0)) continue;
      final lane = [
        for (final c in trace.cells)
          if (_isFree(c)) c,
      ];
      if (lane.length < 2) continue;
      for (final c in [head, tail, ...lane]) {
        _reserved[c] = true;
      }
      return (def, lane);
    }
    return null;
  }

  /// Fills leftover space with any arrow that can still leave, longest
  /// first, so boards read as one dense drawing. These arrows are placed
  /// last, so in play they are the first ones free.
  void _packRemaining(List<int> maskCells) {
    final order = [...maskCells];
    _rng.shuffle(order);
    for (final c in order) {
      if (!_isFree(c)) continue;
      final piece =
          _candidateAt(c, maxLength: config.maxLength) ??
          _candidateAt(c, maxLength: config.minLength + 1);
      if (piece != null) _place(piece);
    }
  }

  /// Grows arrows' tails into cells nothing else could use, so the board
  /// has no holes. Only the tail moves, so an arrow's own path is
  /// unchanged; a cell is taken only if every arrow whose path crosses it
  /// leaves after this one (was placed before it).
  void _extendTails() {
    final cap = config.maxLength + 4;
    var grown = true;
    while (grown) {
      grown = false;
      for (var i = 0; i < _placed.length; i++) {
        final p = _placed[i];
        if (p.kind != PieceKind.car || p.cells.length >= cap) continue;
        final tail = p.cells.last;
        final ahead = _trace(p).cells.toSet();
        for (final d in Dir.values) {
          final c = _neighbor(tail, d);
          if (c < 0 || !_isFree(c) || _gateAt[c] != null) continue;
          if (_lastCover[c] >= i || ahead.contains(c)) continue;
          if (p.cells.contains(c)) continue;
          final next = PieceDef(kind: p.kind, dir: p.dir, cells: [...p.cells, c]);
          _placed[i] = next;
          _occupant[c] = i;
          grown = true;
          break;
        }
      }
    }
  }

  PieceDef? _bestCandidate(List<int> maskCells) {
    PieceDef? best;
    var bestScore = double.negativeInfinity;
    var valid = 0;
    for (
      var tries = 0;
      tries < config.greed * 8 && valid < config.greed;
      tries++
    ) {
      final head = _rng.pick(maskCells);
      if (!_isFree(head)) continue;
      final piece = _candidateAt(head, maxLength: config.maxLength);
      if (piece == null) continue;
      valid++;
      var score = _rng.nextDouble() * 0.5;
      for (final c in piece.cells) {
        score += _cover[c];
      }
      if (score > bestScore) {
        bestScore = score;
        best = piece;
      }
    }
    return best;
  }

  /// A random arrow with its head at [head] whose path is clear, or null.
  /// Lengths are uniform in the configured range.
  PieceDef? _candidateAt(int head, {required int maxLength}) {
    final dirs = [...Dir.values];
    _rng.shuffle(dirs);
    final int minLength = math.min<int>(
      math.max<int>(config.minLength, 1),
      maxLength,
    );
    for (final dir in dirs) {
      final span = maxLength - minLength + 1;
      final int length = minLength + _rng.nextInt(span);
      // The body may not lie in front of its own head.
      final ahead = <int>{};
      for (var c = _neighbor(head, dir); c >= 0; c = _neighbor(c, dir)) {
        ahead.add(c);
      }
      final cells = [head];
      _growBody(cells, dir, length, ahead);
      if (cells.length < minLength) continue;
      final def = PieceDef(kind: PieceKind.car, dir: dir, cells: cells);
      if (_pathClear(def)) return def;
    }
    return null;
  }

  /// Extends [cells] backwards from the head as a random walk that mostly
  /// goes straight and sometimes turns.
  void _growBody(List<int> cells, Dir dir, int length, Set<int> forbidden) {
    var behind = dir.opposite;
    while (cells.length < length) {
      final turn = _rng.nextBool(config.turnChance);
      final sides = [behind.clockwise, behind.counterClockwise];
      _rng.shuffle(sides);
      final options = turn ? [...sides, behind] : [behind, ...sides];
      var grown = false;
      for (final d in options) {
        final next = _neighbor(cells.last, d);
        if (next < 0 ||
            !_isFree(next) ||
            cells.contains(next) ||
            forbidden.contains(next)) {
          continue;
        }
        cells.add(next);
        behind = d;
        grown = true;
        break;
      }
      if (!grown) return;
    }
  }

  PathTrace _trace(PieceDef def) => tracePath(
    width: _w,
    height: _h,
    gateAt: _gateAt,
    head: def.head,
    dir: def.dir,
    isOwn: def.cells.contains,
  );

  bool _pathClear(PieceDef def) {
    final trace = _trace(def);
    if (!trace.exits) return false;
    for (final c in trace.cells) {
      if (_occupant[c] >= 0) return false;
    }
    return true;
  }

  void _place(PieceDef def) {
    final index = _placed.length;
    _placed.add(def);
    for (final c in def.cells) {
      _occupant[c] = index;
    }
    for (final c in _trace(def).cells) {
      _cover[c]++;
      _lastCover[c] = index;
    }
  }
}
