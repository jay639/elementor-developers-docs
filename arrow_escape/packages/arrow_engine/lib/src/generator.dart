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
    this.turnChance = 0.45,
    this.longShare = 0.12,
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

  /// Share of arrows drawn from the long end of the length range (the rest
  /// are short or medium), so boards mix tiny arrows with long snakes.
  final double longShare;
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
    _pathPieces = List.generate(n, (_) => <int>[]);
    _frontOf = List.generate(n, (_) => <int>[]);
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

  /// Vehicles whose path crosses each cell.
  late final List<List<int>> _pathPieces;

  /// Vehicles whose head points straight at each cell (first road cell).
  late final List<List<int>> _frontOf;

  /// Vehicles whose path is already blocked by a later vehicle's body.
  final _blocked = <int>{};
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
    while (filled < target && failures < 80) {
      final piece = _bestCandidate(maskCells);
      if (piece == null) {
        failures++;
        continue;
      }
      _place(piece);
      filled += piece.length;
    }
    // Holes are filled by growing tails (see _extendTails), not by extra
    // arrows: arrows placed last always start free, which makes boards easy.
    if (config.pack) _packRemaining(maskCells, onlyIsolated: true);

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
    if (config.pack) {
      _extendTails();
      // Fill what is still empty with short arrows so the board reads as
      // one crowded knot, then let tails take any last single cells.
      _fillGaps(maskCells);
      _extendTails();
    }

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
  void _packRemaining(List<int> maskCells, {bool onlyIsolated = false}) {
    final order = [...maskCells];
    _rng.shuffle(order);
    for (final c in order) {
      if (!_isFree(c)) continue;
      // Leave cells next to an arrow's tail for tail growth.
      if (onlyIsolated && _nextToTail(c)) continue;
      final piece =
          _candidateAt(c, maxLength: config.maxLength) ??
          _candidateAt(c, maxLength: config.minLength + 1);
      if (piece != null) _place(piece);
    }
  }

  void _fillGaps(List<int> maskCells) {
    final order = [...maskCells];
    _rng.shuffle(order);
    for (final c in order) {
      if (!_isFree(c) || _gateAt[c] != null) continue;
      final piece = _candidateAt(c, maxLength: math.min(5, config.maxLength));
      if (piece != null && piece.cells.length >= 2) _place(piece);
    }
  }

  bool _nextToTail(int c) {
    for (final d in Dir.values) {
      final x = _neighbor(c, d);
      if (x < 0) continue;
      final o = _occupant[x];
      if (o >= 0 && _placed[o].cells.last == x) return true;
    }
    return false;
  }

  /// Grows arrows' tails into cells nothing else could use, so the board
  /// has no holes. Only the tail moves, so an arrow's own path is
  /// unchanged; a cell is taken only if every arrow whose path crosses it
  /// leaves after this one (was placed before it).
  void _extendTails() {
    // Long enough to fill leftover pockets (crowded boards), short enough
    // that arrows stay lines rather than blobs.
    final cap = [
      for (final p in _placed) math.min(p.cells.length + 10, config.maxLength),
    ];
    var grown = true;
    while (grown) {
      grown = false;
      for (var i = 0; i < _placed.length; i++) {
        final p = _placed[i];
        if (p.kind != PieceKind.car || p.cells.length >= cap[i]) continue;
        final tail = p.cells.last;
        final ahead = _trace(p).cells.toSet();
        // A one-cell arrow may only grow straight back (see _growBody).
        for (final d in p.cells.length == 1 ? [p.dir.opposite] : Dir.values) {
          final c = _neighbor(tail, d);
          if (c < 0 || !_isFree(c) || _gateAt[c] != null) continue;
          if (_lastCover[c] >= i || ahead.contains(c)) continue;
          if (p.cells.contains(c)) continue;
          final next = PieceDef(
            kind: p.kind,
            dir: p.dir,
            cells: [...p.cells, c],
          );
          _placed[i] = next;
          _occupant[c] = i;
          _blocked.addAll(_pathPieces[c]);
          grown = true;
          break;
        }
      }
    }
  }

  PieceDef? _bestCandidate(List<int> maskCells) {
    final hot = [
      for (final c in maskCells)
        if (_isFree(c) && _pathPieces[c].any((i) => !_blocked.contains(i))) c,
    ];
    PieceDef? best;
    var bestScore = double.negativeInfinity;
    var valid = 0;
    for (
      var tries = 0;
      tries < config.greed * 8 && valid < config.greed;
      tries++
    ) {
      // Mostly start on the road of an arrow that is still free.
      final head = hot.isNotEmpty && _rng.nextBool(0.75)
          ? _rng.pick(hot)
          : _rng.pick(maskCells);
      if (!_isFree(head)) continue;
      final piece = _candidateAt(head, maxLength: config.maxLength, minRoad: 2);
      if (piece == null) continue;
      valid++;
      // Above all, block arrows that would otherwise start free: every
      // free arrow left at the end is a move the player can make blindly.
      final newlyBlocked = <int>{};
      var cover = 0;
      var nose = 0;
      for (final c in piece.cells) {
        cover += _cover[c];
        for (final i in _pathPieces[c]) {
          if (!_blocked.contains(i)) newlyBlocked.add(i);
        }
        // An arrow's head pressed right against this body: the tight
        // head-into-tail chains that make boards read as one knot.
        nose += _frontOf[c].length;
      }
      final score =
          3.0 * newlyBlocked.length +
          1.5 * nose +
          0.3 * cover +
          0.08 * piece.cells.length +
          _rng.nextDouble() * 0.5;
      if (score > bestScore) {
        bestScore = score;
        best = piece;
      }
    }
    return best;
  }

  /// Arrow length: mostly short (2-4) or medium, sometimes a long snake
  /// up to [maxLength].
  int _sampleLength(int minLength, int maxLength) {
    final r = _rng.nextDouble();
    int between(int lo, int hi) {
      lo = lo.clamp(minLength, maxLength);
      hi = hi.clamp(lo, maxLength);
      return lo + _rng.nextInt(hi - lo + 1);
    }

    if (r < config.longShare) {
      return between(math.max(8, maxLength ~/ 2), maxLength);
    }
    if (r < config.longShare + 0.3) return between(4, 7);
    return between(minLength, 3);
  }

  /// A random arrow with its head at [head] whose path is clear, or null.
  /// [minRoad] is the fewest empty cells its road must cross: an arrow at
  /// the edge facing out can never be blocked, so the main pass avoids them
  /// and leaves edge cells to tail growth.
  PieceDef? _candidateAt(int head, {required int maxLength, int minRoad = 0}) {
    final dirs = [...Dir.values];
    _rng.shuffle(dirs);
    final int minLength = math.min<int>(
      math.max<int>(config.minLength, 1),
      maxLength,
    );
    for (final dir in dirs) {
      final length = _sampleLength(minLength, maxLength);
      // The body may not lie in front of its own head.
      final ahead = <int>{};
      for (var c = _neighbor(head, dir); c >= 0; c = _neighbor(c, dir)) {
        ahead.add(c);
      }
      final cells = [head];
      _growBody(cells, dir, length, ahead);
      if (cells.length < minLength) continue;
      final def = PieceDef(kind: PieceKind.car, dir: dir, cells: cells);
      if (minRoad > 0 && _trace(def).cells.length < minRoad) continue;
      if (_pathClear(def)) return def;
    }
    return null;
  }

  /// Taken cells around [c] (other arrows or this arrow's own body).
  int _crowding(int c, List<int> own) {
    var n = 0;
    for (final d in Dir.values) {
      final x = _neighbor(c, d);
      if (x < 0 || !_mask[x]) {
        n++;
      } else if (_occupant[x] >= 0) {
        n++;
      }
    }
    return n;
  }

  /// Extends [cells] backwards from the head as a winding walk. It turns
  /// often and prefers cells that hug other arrows (and its own body), so
  /// arrows wrap around and interlock instead of lying side by side.
  void _growBody(List<int> cells, Dir dir, int length, Set<int> forbidden) {
    var behind = dir.opposite;
    while (cells.length < length) {
      final options = <(int, Dir, double)>[];
      // The cell right behind the head is always straight behind it, so
      // the line runs into the arrowhead (a turn at the head reads as a
      // tilted, ambiguous arrow).
      final dirs = cells.length == 1
          ? [behind]
          : [behind, behind.clockwise, behind.counterClockwise];
      for (final d in dirs) {
        final next = _neighbor(cells.last, d);
        if (next < 0 ||
            !_isFree(next) ||
            cells.contains(next) ||
            forbidden.contains(next)) {
          continue;
        }
        final straight = d == behind;
        final weight =
            (straight ? 1 - config.turnChance : config.turnChance) *
            (1 + 0.6 * _crowding(next, cells));
        options.add((next, d, weight));
      }
      if (options.isEmpty) return;
      final total = options.fold<double>(0, (a, o) => a + o.$3);
      var pick = _rng.nextDouble() * total;
      var chosen = options.last;
      for (final o in options) {
        pick -= o.$3;
        if (pick <= 0) {
          chosen = o;
          break;
        }
      }
      cells.add(chosen.$1);
      behind = chosen.$2;
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
      _blocked.addAll(_pathPieces[c]);
    }
    final road = _trace(def).cells;
    for (final c in road) {
      _cover[c]++;
      _lastCover[c] = index;
      _pathPieces[c].add(index);
    }
    if (road.isNotEmpty) _frontOf[road.first].add(index);
  }
}
