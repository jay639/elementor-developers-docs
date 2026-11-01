import 'dart:math' as math;

import 'package:arrow_engine/arrow_engine.dart';

/// Everything that must hold for a shippable campaign. Returns a list of
/// human-readable problems; empty means pass.
List<String> verifyCampaign(
  List<Level> levels, {
  int maxWidth = maxArrowBoardWidth,
  int maxHeight = maxArrowBoardHeight,
  // Solve effort may miss its target by this share.
  double effortTolerance = 0.15,
  double maxOutlierShare = 0.04,
}) {
  final problems = <String>[];
  void fail(String msg) => problems.add(msg);

  final stats = <LevelStats?>[];
  for (var i = 0; i < levels.length; i++) {
    final level = levels[i];
    final n = i + 1;
    if (level.id != n) fail('L$n: id is ${level.id}');
    if (level.width > maxWidth || level.height > maxHeight) {
      fail('L$n: board ${level.width}x${level.height} is too big');
    }
    if (level.pieces.length < 2) {
      fail('L$n: only ${level.pieces.length} pieces');
    }

    if (n < MechanicUnlocks.trafficLights && level.lights.isNotEmpty) {
      fail('L$n: lights before L${MechanicUnlocks.trafficLights}');
    }
    if (n < MechanicUnlocks.gates && level.gates.isNotEmpty) {
      fail('L$n: gates before L${MechanicUnlocks.gates}');
    }
    if (n < MechanicUnlocks.ambulance && level.hasAmbulance) {
      fail('L$n: ambulance before L${MechanicUnlocks.ambulance}');
    }
    if (level.meta.breather != Campaign.isBreather(n)) {
      fail('L$n: breather flag is ${level.meta.breather}');
    }
    if (level.meta.tier != Campaign.tierFor(n)) {
      fail('L$n: tier is ${level.meta.tier.name}');
    }

    final s = analyzeLevel(level);
    stats.add(s);
    if (s == null) {
      fail('L$n: unsolvable');
      continue;
    }
    // The solver's answer must replay as a win under the real rules.
    var session = PlaySession.start(level);
    for (final p in s.solution) {
      session = session.tap(p).session;
    }
    if (session.status != SessionStatus.won) {
      fail('L$n: solution does not replay to a win');
    }
    if ((s.difficulty - level.meta.difficulty).abs() > 0.11) {
      fail(
        'L$n: stored difficulty ${level.meta.difficulty} != '
        '${s.difficulty.toStringAsFixed(1)}',
      );
    }
  }
  if (problems.isNotEmpty) return problems;

  final effort = [for (final st in stats) st!.effort];
  bool regular(int n) =>
      !Campaign.handmade.containsKey(n) &&
      !_isIntro(n) &&
      Campaign.tierFor(n) == LevelTier.normal;

  // Every level takes about as long as planned (solve effort, roughly
  // solve time): within [effortTolerance] of its target.
  var outliers = 0;
  for (var n = 2; n <= levels.length; n++) {
    if (Campaign.handmade.containsKey(n) || _isIntro(n)) continue;
    final want = Campaign.effortTarget(n);
    final e = effort[n - 1];
    final miss = e > want ? e / want - 1 : want / e - 1;
    if (miss > effortTolerance) outliers++;
  }
  if (outliers > levels.length * maxOutlierShare) {
    fail(
      '$outliers levels miss their solve effort by more than '
      '${(effortTolerance * 100).round()}% '
      '(allowed ${(levels.length * maxOutlierShare).floor()})',
    );
  }

  // Each regular level is built to a longer solve time than the one
  // before; boards land within a few percent of it, so a level may take
  // up to 6% less than its neighbour in the first 60 (10% later), never
  // more. Hard / Super Hard levels spike above.
  int? prev;
  var dips = 0;
  for (var n = 2; n <= levels.length; n++) {
    if (!regular(n)) continue;
    final p = prev;
    prev = n;
    if (p == null) continue;
    final slack = n <= 60 ? 0.94 : 0.9;
    if (effort[n - 1] < effort[p - 1] * slack) {
      dips++;
      if (n <= 60) {
        fail(
          'L$n takes less effort (${effort[n - 1].round()}) than '
          'L$p (${effort[p - 1].round()})',
        );
      }
    }
  }
  if (dips > levels.length * 0.03) {
    fail('$dips regular levels are clearly easier than the one before');
  }

  // The rolling mean of regular levels never drops below its best so far.
  const window = 20;
  final regularEffort = [
    for (var n = 2; n <= levels.length; n++)
      if (regular(n)) effort[n - 1],
  ];
  double? best;
  for (var i = 0; i + window <= regularEffort.length; i += window) {
    final mean =
        regularEffort.sublist(i, i + window).reduce((a, b) => a + b) / window;
    if (best != null && mean < best * 0.97) {
      fail(
        'Solve effort dips around regular level #${i + 1}: '
        '${best.round()} -> ${mean.round()}',
      );
    }
    best = math.max(best ?? mean, mean);
  }
  return problems;
}

/// First level of a mechanic: a deliberately small showcase.
bool _isIntro(int n) =>
    n == MechanicUnlocks.trafficLights ||
    n == MechanicUnlocks.gates ||
    n == MechanicUnlocks.ambulance;

/// Per-100-level summary table.
String campaignReport(List<Level> levels) {
  final b = StringBuffer()
    ..writeln(
      'levels     effort target  arrows   min   max  avglen lights gates amb',
    );
  for (var start = 0; start < levels.length; start += 100) {
    final chunk = levels.sublist(start, math.min(start + 100, levels.length));
    double avg(Iterable<num> xs) =>
        xs.fold<double>(0, (a, x) => a + x) / chunk.length;
    final actual = [for (final l in chunk) l.pieces.length];
    final effort = [
      for (final l in chunk) analyzeLevel(l, maxStates: 60000)?.effort ?? 0,
    ];
    b.writeln(
      '${'${start + 1}-${start + chunk.length}'.padRight(10)} '
      '${avg(effort).toStringAsFixed(0).padLeft(6)} '
      '${avg([for (final l in chunk) Campaign.effortTarget(l.id)]).toStringAsFixed(0).padLeft(6)} '
      '${avg(actual).toStringAsFixed(1).padLeft(7)} '
      '${actual.reduce(math.min).toString().padLeft(5)} '
      '${actual.reduce(math.max).toString().padLeft(5)} '
      '${(chunk.fold<int>(0, (a, l) => a + l.pieces.fold<int>(0, (b, p) => b + p.length)) / chunk.fold<int>(0, (a, l) => a + l.pieces.length)).toStringAsFixed(1).padLeft(7)} '
      '${chunk.where((l) => l.lights.isNotEmpty).length.toString().padLeft(6)} '
      '${chunk.where((l) => l.gates.isNotEmpty).length.toString().padLeft(5)} '
      '${chunk.where((l) => l.hasAmbulance).length.toString().padLeft(4)}',
    );
  }
  return b.toString();
}

/// Text drawing of a level (inverse of `parseAsciiLevel`, trucks shown as
/// letters with their head as an arrow).
String drawLevel(Level level) {
  const arrows = {Dir.up: '^', Dir.right: '>', Dir.down: 'v', Dir.left: '<'};
  const gates = {Dir.up: '8', Dir.right: '6', Dir.down: '2', Dir.left: '4'};
  final grid = [for (final m in level.mask) m ? '.' : ' '];
  for (final g in level.gates) {
    grid[g.cell] = gates[g.dir]!;
  }
  for (final l in level.lights) {
    grid[l.cell] = l.startsGreen ? 'g' : 'r';
  }
  var truck = 0;
  for (final p in level.pieces) {
    final body = p.kind == PieceKind.ambulance
        ? '+'
        : String.fromCharCode(0x61 + truck++ % 26).toUpperCase();
    for (final c in p.cells.skip(1)) {
      grid[c] = body;
    }
    grid[p.head] = arrows[p.dir]!;
  }
  return [
    for (var y = 0; y < level.height; y++)
      grid.sublist(y * level.width, (y + 1) * level.width).join(),
  ].join('\n');
}

/// Every puzzle layer exists, is solvable, fits, and each layer takes at
/// least 20% more solve effort than the one before.
List<String> verifyPuzzles(Map<String, Level> levels) {
  final problems = <String>[];
  for (final shape in ShapePuzzles.all) {
    var previous = 0.0;
    for (var layer = 1; layer <= PuzzleShape.layerCount; layer++) {
      final key = ShapePuzzles.key(shape.id, layer);
      final level = levels[key];
      if (level == null) {
        problems.add('$key: missing');
        continue;
      }
      if (level.width > maxArrowBoardWidth ||
          level.height > maxArrowBoardHeight) {
        problems.add('$key: board ${level.width}x${level.height} is too big');
      }
      final s = analyzeLevel(level);
      if (s == null) {
        problems.add('$key: unsolvable');
        continue;
      }
      if (s.effort < previous * 1.2) {
        problems.add(
          '$key: does not take clearly longer than the layer before',
        );
      }
      previous = s.effort;
    }
  }
  return problems;
}
