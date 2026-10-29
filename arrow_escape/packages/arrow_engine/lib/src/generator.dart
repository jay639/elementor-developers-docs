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
    this.truckChance = 0,
    this.minTrucks = 0,
    this.maxTruckLength = 3,
    this.lights = 0,
    this.gates = 0,
    this.ambulance = false,
  });

  final int seed;
  final ShapeMask shape;
  final int id;

  /// Share of the free playable cells to cover with vehicles.
  final double fill;

  /// Candidates sampled per placement; the one that blocks the most already
  /// placed vehicles wins. Higher = longer dependency chains = harder.
  final int greed;

  /// Chance that a placed vehicle is a multi-cell truck.
  final double truckChance;

  /// The first placements are trucks until this many exist.
  final int minTrucks;
  final int maxTruckLength;
  final int lights;
  final int gates;
  final bool ambulance;
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
  final _placed = <PieceDef>[];
  var _trucks = 0;

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
        final piece = _candidateAt(c, allowTruck: false);
        if (piece != null) {
          _place(piece);
          added++;
        }
      }
      if (added == 0) return null;
    }
    if (_placed.length < 2) return null;

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
      final piece = _candidateAt(head, allowTruck: true);
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

  /// A random vehicle with its head at [head] whose path is clear, or null.
  PieceDef? _candidateAt(int head, {required bool allowTruck}) {
    final dirs = [...Dir.values];
    _rng.shuffle(dirs);
    for (final dir in dirs) {
      final cells = [head];
      final wantTruck =
          _trucks < config.minTrucks || _rng.nextBool(config.truckChance);
      if (allowTruck && config.truckChance > 0 && wantTruck) {
        final length = 2 + _rng.nextInt(config.maxTruckLength - 1);
        _growBody(cells, dir, length);
      }
      final def = PieceDef(
        kind: cells.length > 1 ? PieceKind.truck : PieceKind.car,
        dir: dir,
        cells: cells,
      );
      if (_pathClear(def)) return def;
    }
    return null;
  }

  /// Extends [cells] backwards from the head, preferring straight bodies.
  void _growBody(List<int> cells, Dir dir, int length) {
    var behind = dir.opposite;
    while (cells.length < length) {
      final options = <Dir>[
        behind,
        if (_rng.nextBool(0.45)) ...[behind.clockwise, behind.counterClockwise],
      ];
      _rng.shuffle(options);
      if (options.first != behind && _rng.nextBool(0.5)) {
        options
          ..remove(behind)
          ..insert(0, behind);
      }
      var grown = false;
      for (final d in options) {
        final next = _neighbor(cells.last, d);
        if (next < 0 || !_isFree(next) || cells.contains(next)) continue;
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
    if (def.kind == PieceKind.truck) _trucks++;
    final index = _placed.length;
    _placed.add(def);
    for (final c in def.cells) {
      _occupant[c] = index;
    }
    for (final c in _trace(def).cells) {
      _cover[c]++;
    }
  }
}
