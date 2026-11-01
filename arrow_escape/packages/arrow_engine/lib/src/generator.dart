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
    this.midShare = 0.3,
    this.tinyShare = 0,
    this.tailGrowth = 10,
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

  /// Share of medium arrows (4-7 cells, or 5-9 when [tinyShare] > 0).
  final double midShare;

  /// Share of the shortest arrows (exactly [minLength] cells). When > 0
  /// the mix has four bands: tiny, short (3-4), medium (5-9) and long
  /// (10+ up to [maxLength]).
  final double tinyShare;

  /// Most cells a tail may grow into leftover space after placement.
  /// Small values keep the length mix; large ones fill pockets with
  /// long snakes.
  final int tailGrowth;
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

  /// Vehicles whose path crosses each cell.
  late final List<List<int>> _pathPieces;

  /// Vehicles whose head points straight at each cell (first road cell).
  late final List<List<int>> _frontOf;

  /// Vehicles whose path is already blocked by a later vehicle's body.
  final _blocked = <int>{};
  final _placed = <PieceDef>[];

  /// Play order of each placed vehicle: higher leaves earlier. Normally
  /// the placement index, but gap arrows are slotted in earlier in the
  /// order (see [_insertRank]) so they start blocked.
  final _rank = <double>[];
  double _topRank = -1;

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
        if (piece != null && _sameDirNeighbours(piece) == 0) {
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
      // Last cells: tails may grow a bit further so no holes are left.
      _extendTails(growth: math.max(config.tailGrowth, 8));
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
        // Give the feeder a body (a lone dot reads as no arrow at all).
        final tail = _neighbor(head, enter.opposite);
        if (tail < 0 || !_isFree(tail)) continue;
        final def = PieceDef(
          kind: PieceKind.car,
          dir: enter,
          cells: [head, tail],
        );
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

  /// Fills leftover cells with short arrows slotted into the play order
  /// as late as possible, so they start blocked instead of being free
  /// first moves. Prefers arrows whose road is already occupied, never
  /// lines them up behind or beside a same-direction arrow.
  void _fillGaps(List<int> maskCells) {
    final order = [...maskCells];
    _rng.shuffle(order);
    final maxLength = math.min(6, config.maxLength);
    for (final c in order) {
      if (!_isFree(c) || _gateAt[c] != null) continue;
      PieceDef? best;
      double? bestRank;
      var bestScore = double.negativeInfinity;
      for (var t = 0; t < 8; t++) {
        final dir = Dir.values[t % 4];
        final length = 2 + _rng.nextInt(maxLength - 1);
        final ahead = <int>{};
        for (var x = _neighbor(c, dir); x >= 0; x = _neighbor(x, dir)) {
          ahead.add(x);
        }
        final cells = [c];
        _growBody(cells, dir, length, ahead);
        if (cells.length < 2) continue;
        final def = PieceDef(kind: PieceKind.car, dir: dir, cells: cells);
        final trace = _trace(def);
        if (_sameDirNeighbours(def) > 0) continue;
        final rank = _insertRank(def, trace);
        if (rank == null) continue;
        var blockers = 0;
        for (final x in trace.cells) {
          if (_occupant[x] >= 0) blockers++;
        }
        final score =
            (blockers > 0 ? 4.0 + blockers : -6.0) +
            0.1 * cells.length +
            _rng.nextDouble() * 0.3;
        if (score > bestScore) {
          bestScore = score;
          best = def;
          bestRank = rank;
        }
      }
      if (best != null) _place(best, rank: bestRank);
    }
  }

  /// Same-direction arrows right in front of this head (a queue that
  /// clears itself) or right beside it (soldiers in a row). Both read as
  /// "tap them all", so placement avoids them.
  int _sameDirNeighbours(PieceDef def) {
    var n = 0;
    final front = _neighbor(def.head, def.dir);
    if (front >= 0) {
      final o = _occupant[front];
      if (o >= 0 && _placed[o].dir == def.dir) n++;
    }
    for (final side in [def.dir.clockwise, def.dir.counterClockwise]) {
      final x = _neighbor(def.head, side);
      if (x < 0) continue;
      final o = _occupant[x];
      if (o >= 0 && _placed[o].head == x && _placed[o].dir == def.dir) n++;
    }
    // An arrow pressing its head into this one's tail, same way.
    final behind = _neighbor(def.cells.last, def.dir.opposite);
    if (behind >= 0) {
      final o = _occupant[behind];
      if (o >= 0 && _placed[o].head == behind && _placed[o].dir == def.dir) {
        n++;
      }
    }
    for (final c in def.cells) {
      for (final i in _frontOf[c]) {
        if (_placed[i].dir == def.dir) n++;
      }
    }
    return n;
  }

  /// Grows arrows' tails into cells nothing else could use, so the board
  /// has no holes. Only the tail moves, so an arrow's own path is
  /// unchanged; a cell is taken only if every arrow whose path crosses it
  /// leaves after this one (was placed before it).
  void _extendTails({int? growth}) {
    // Long enough to fill leftover pockets (crowded boards), short enough
    // that arrows stay lines rather than blobs.
    final cap = [
      for (final p in _placed)
        math.min(
          p.cells.length + (growth ?? config.tailGrowth),
          config.maxLength,
        ),
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
          if (ahead.contains(c) || _leavesBefore(c, i)) continue;
          if (p.cells.contains(c)) continue;
          // Don't grow into the cell right in front of a same-way head:
          // that turns two arrows into a queue that clears itself.
          if (_frontOf[c].any((j) => j != i && _placed[j].dir == p.dir)) {
            continue;
          }
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
      if (piece == null || _sameDirNeighbours(piece) > 0) continue;
      valid++;
      // Above all, block arrows that would otherwise start free: every
      // free arrow left at the end is a move the player can make blindly.
      final newlyBlocked = <int>{};
      var cover = 0;
      var nose = 0;
      // (Same-way queues and rows were rejected above.)
      for (final c in piece.cells) {
        cover += _cover[c];
        for (final i in _pathPieces[c]) {
          if (!_blocked.contains(i)) newlyBlocked.add(i);
        }
        // An arrow's head pressed right against this body: the tight
        // head-into-tail chains that make boards read as one knot (only
        // when they point different ways; same way is a trivial queue).
        for (final i in _frontOf[c]) {
          if (_placed[i].dir != piece.dir) nose++;
        }
      }
      // Blocking an arrow that points the same way just makes a queue.
      var blockScore = 0.0;
      for (final i in newlyBlocked) {
        blockScore += _placed[i].dir == piece.dir ? 0.8 : 3.0;
      }
      final score =
          blockScore +
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

    if (config.tinyShare > 0) {
      // Four bands, like a hand-drawn board: tiny stubs, short arrows,
      // medium bends and a few very long snakes.
      if (r < config.longShare) return between(10, maxLength);
      if (r < config.longShare + config.midShare) return between(5, 9);
      if (r < config.longShare + config.midShare + config.tinyShare) {
        return minLength;
      }
      return between(3, 4);
    }
    if (r < config.longShare) {
      return between(math.max(8, maxLength ~/ 2), maxLength);
    }
    if (r < config.longShare + config.midShare) return between(4, 7);
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

  /// Whether a vehicle that leaves before [i] drives over [c].
  bool _leavesBefore(int c, int i) {
    for (final j in _pathPieces[c]) {
      if (j != i && _rank[j] > _rank[i]) return true;
    }
    return false;
  }

  /// Where [def] can go in the play order, or null: it must leave after
  /// every vehicle whose road crosses its body and before every vehicle
  /// standing on its own road (and before the ambulance, which only lets
  /// lane arrows go first). Returns the latest such slot, so the arrow
  /// starts as blocked as possible.
  double? _insertRank(PieceDef def, PathTrace trace) {
    if (!trace.exits) return null;
    var lo = double.negativeInfinity;
    for (final c in def.cells) {
      for (final j in _pathPieces[c]) {
        if (_rank[j] > lo) lo = _rank[j];
      }
    }
    var hi = double.infinity;
    for (final c in trace.cells) {
      final o = _occupant[c];
      if (o >= 0 && _rank[o] < hi) hi = _rank[o];
    }
    for (var j = 0; j < _placed.length; j++) {
      if (_placed[j].kind == PieceKind.ambulance && _rank[j] < hi) {
        hi = _rank[j];
      }
    }
    if (lo >= hi) return null;
    if (lo == double.negativeInfinity) {
      return hi == double.infinity ? _topRank + 1 : hi - 1;
    }
    if (hi == double.infinity) return lo + 0.5;
    final r = lo + (hi - lo) / 2;
    // Out of floating-point room between the two neighbours.
    return (r > lo && r < hi) ? r : null;
  }

  void _place(PieceDef def, {double? rank}) {
    final index = _placed.length;
    final r = rank ?? _topRank + 1;
    _rank.add(r);
    if (r > _topRank) _topRank = r;
    _placed.add(def);
    for (final c in def.cells) {
      _occupant[c] = index;
      _blocked.addAll(_pathPieces[c]);
    }
    final road = _trace(def).cells;
    for (final c in road) {
      _cover[c]++;
      _pathPieces[c].add(index);
    }
    if (road.isNotEmpty) _frontOf[road.first].add(index);
  }
}
