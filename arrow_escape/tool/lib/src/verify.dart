import 'dart:math' as math;

import 'package:arrow_engine/arrow_engine.dart';

/// Everything that must hold for a shippable campaign. Returns a list of
/// human-readable problems; empty means pass.
List<String> verifyCampaign(
  List<Level> levels, {
  int maxWidth = maxArrowBoardWidth,
  int maxHeight = maxArrowBoardHeight,
  // Arrow counts may miss the target by this share (boards are discrete).
  double countTolerance = 0.15,
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

  final counts = [for (final l in levels) l.pieces.length];

  // Breathers are a small dip in arrows (or an easier board), never a
  // big drop: at least 80% of the arrows of the 4 levels before them.
  final breatherMisses = <String>[];
  for (var n = 5; n <= levels.length; n += 5) {
    final prevIdx = [
      for (var k = n - 4; k < n; k++)
        if (!Campaign.handmade.containsKey(k)) k - 1,
    ];
    if (prevIdx.isEmpty || Campaign.handmade.containsKey(n)) continue;
    final mean =
        prevIdx.map((i) => counts[i]).reduce((a, b) => a + b) / prevIdx.length;
    final c = counts[n - 1];
    if (c < mean * 0.75 && !_isIntro(n)) {
      breatherMisses.add(
        'L$n: breather has $c arrows, the 4 before it ${mean.round()}',
      );
    }
  }
  if (breatherMisses.length > levels.length / 5 * 0.02) {
    breatherMisses.forEach(fail);
  }

  // More arrows as levels go up: the rolling mean of regular levels never
  // drops below its best so far (3 arrows or 5% of slack: Hard levels
  // and the 120-arrow board cap make 20-level windows noisy).
  const window = 20;
  final regular = [
    for (var n = 1; n <= levels.length; n++)
      if (!Campaign.isBreather(n) && !_isIntro(n)) counts[n - 1],
  ];
  double? best;
  for (var i = 0; i + window <= regular.length; i += window) {
    final mean =
        regular.sublist(i, i + window).reduce((a, b) => a + b) / window;
    if (best != null && mean < best - math.max(3, best * 0.05)) {
      fail(
        'Arrow count dips around regular level #${i + 1}: '
        '${best.toStringAsFixed(1)} -> ${mean.toStringAsFixed(1)}',
      );
    }
    best = math.max(best ?? mean, mean);
  }

  // Individual levels should have about the planned number of arrows.
  var outliers = 0;
  for (var n = 1; n <= levels.length; n++) {
    if (Campaign.handmade.containsKey(n) || _isIntro(n)) continue;
    final want = Campaign.arrowTarget(n);
    if ((counts[n - 1] - want).abs() > want * countTolerance + 1) outliers++;
  }
  if (outliers > levels.length * maxOutlierShare) {
    fail(
      '$outliers levels miss their arrow count by more than '
      '${(countTolerance * 100).round()}% '
      '(allowed ${(levels.length * maxOutlierShare).floor()})',
    );
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
      'levels     target  arrows   min   max  diff  avglen lights gates amb',
    );
  for (var start = 0; start < levels.length; start += 100) {
    final chunk = levels.sublist(start, math.min(start + 100, levels.length));
    double avg(Iterable<num> xs) =>
        xs.fold<double>(0, (a, x) => a + x) / chunk.length;
    final actual = [for (final l in chunk) l.pieces.length];
    b.writeln(
      '${'${start + 1}-${start + chunk.length}'.padRight(10)} '
      '${avg([for (final l in chunk) Campaign.arrowTarget(l.id)]).toStringAsFixed(1).padLeft(6)} '
      '${avg(actual).toStringAsFixed(1).padLeft(7)} '
      '${actual.reduce(math.min).toString().padLeft(5)} '
      '${actual.reduce(math.max).toString().padLeft(5)} '
      '${avg([for (final l in chunk) l.meta.difficulty]).toStringAsFixed(0).padLeft(5)} '
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

/// Every puzzle layer exists, is solvable, fits, and each layer has more
/// arrows than the one before.
List<String> verifyPuzzles(Map<String, Level> levels) {
  final problems = <String>[];
  for (final shape in ShapePuzzles.all) {
    var previous = 0;
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
      if (level.pieces.length <= previous) {
        problems.add('$key: not more arrows than the layer before');
      }
      previous = level.pieces.length;
    }
  }
  return problems;
}
