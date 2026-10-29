import 'dart:math' as math;

import 'package:arrow_engine/arrow_engine.dart';

/// Everything that must hold for a shippable campaign. Returns a list of
/// human-readable problems; empty means pass.
List<String> verifyCampaign(
  List<Level> levels, {
  int maxWidth = 10,
  int maxHeight = 14,
  double targetTolerance = 15,
  double maxOutlierShare = 0.05,
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

    if (n < MechanicUnlocks.trucks && level.hasTrucks) {
      fail('L$n: trucks before L${MechanicUnlocks.trucks}');
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

  final d = [for (final s in stats) s!.difficulty];

  // Breathers must be easier than the levels leading up to them.
  for (var n = 5; n <= levels.length; n += 5) {
    final prev = [
      for (var k = n - 4; k < n; k++)
        if (!Campaign.handmade.containsKey(k)) d[k - 1],
    ];
    if (prev.isEmpty || Campaign.handmade.containsKey(n)) continue;
    final mean = prev.reduce((a, b) => a + b) / prev.length;
    if (d[n - 1] >= mean) {
      fail(
        'L$n: breather (${d[n - 1].toStringAsFixed(1)}) is not easier than '
        'the 4 before it (${mean.toStringAsFixed(1)})',
      );
    }
  }

  // Smooth curve: the rolling mean of regular levels never drops much.
  const window = 25;
  final regular = [
    for (var n = 1; n <= levels.length; n++)
      if (!Campaign.isBreather(n)) d[n - 1],
  ];
  double? lastMean;
  for (var i = 0; i + window <= regular.length; i += window) {
    final mean =
        regular.sublist(i, i + window).reduce((a, b) => a + b) / window;
    if (lastMean != null && mean < lastMean - 3) {
      fail(
        'Difficulty curve dips around regular level #${i + 1}: '
        '${lastMean.toStringAsFixed(1)} -> ${mean.toStringAsFixed(1)}',
      );
    }
    lastMean = math.max(lastMean ?? mean, mean);
  }

  // Individual levels should track the target.
  var outliers = 0;
  for (var n = 1; n <= levels.length; n++) {
    if (Campaign.handmade.containsKey(n)) continue;
    if ((d[n - 1] - Campaign.targetDifficulty(n)).abs() > targetTolerance) {
      outliers++;
    }
  }
  if (outliers > levels.length * maxOutlierShare) {
    fail(
      '$outliers levels are more than $targetTolerance points off target '
      '(allowed ${(levels.length * maxOutlierShare).floor()})',
    );
  }
  return problems;
}

/// Per-100-level summary table.
String campaignReport(List<Level> levels) {
  final b = StringBuffer()
    ..writeln(
      'levels     target  actual   min   max  pieces  trucks lights gates amb',
    );
  for (var start = 0; start < levels.length; start += 100) {
    final chunk = levels.sublist(start, math.min(start + 100, levels.length));
    double avg(Iterable<num> xs) =>
        xs.fold<double>(0, (a, x) => a + x) / chunk.length;
    final actual = [for (final l in chunk) l.meta.difficulty];
    b.writeln(
      '${'${start + 1}-${start + chunk.length}'.padRight(10)} '
      '${avg([for (final l in chunk) Campaign.targetDifficulty(l.id)]).toStringAsFixed(1).padLeft(6)} '
      '${avg(actual).toStringAsFixed(1).padLeft(7)} '
      '${actual.reduce(math.min).toStringAsFixed(0).padLeft(5)} '
      '${actual.reduce(math.max).toStringAsFixed(0).padLeft(5)} '
      '${avg([for (final l in chunk) l.pieces.length]).toStringAsFixed(1).padLeft(7)} '
      '${chunk.where((l) => l.hasTrucks).length.toString().padLeft(7)} '
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
