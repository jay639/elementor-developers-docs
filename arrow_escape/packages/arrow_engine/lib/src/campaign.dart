import 'dart:convert';
import 'dart:math' as math;

import 'analyzer.dart';
import 'generator.dart';
import 'level.dart';
import 'rng.dart';
import 'samples.dart';
import 'shapes.dart';

/// Which special mechanics a generated level must contain.
class MechanicSet {
  const MechanicSet({
    this.trucks = false,
    this.lights = 0,
    this.gates = 0,
    this.ambulance = false,
    this.maxTruckLength = 3,
  });

  final bool trucks;
  final int lights;
  final int gates;
  final bool ambulance;
  final int maxTruckLength;

  /// Rough difficulty the mechanics add on their own (see
  /// [scoreDifficulty]); subtracted when sizing the board.
  double get expectedBonus =>
      (trucks ? 2.5 : 0) +
      3.0 * math.min(lights, 3) +
      2.5 * math.min(gates, 3) +
      (ambulance ? 5 : 0);

  bool satisfiedBy(Level level) =>
      (!trucks || level.hasTrucks) &&
      level.lights.length >= lights &&
      level.gates.length >= gates &&
      (!ambulance || level.hasAmbulance);

  @override
  String toString() =>
      'trucks=$trucks lights=$lights gates=$gates ambulance=$ambulance';
}

/// Generates candidates of varying size and density and keeps the one
/// whose solver-measured difficulty is closest to [target].
Level? generateForTarget({
  required int id,
  required double target,
  required int seed,
  required ShapeMask shape,
  MechanicSet mechanics = const MechanicSet(),
  bool breather = false,
  int candidates = 10,
}) {
  final rng = Rng(seed);
  // `scale` drives board size and density together. It starts from a
  // calibrated guess and is corrected after every candidate, so the search
  // homes in on the target instead of sampling blindly.
  var scale = math.max(3.0, target - mechanics.expectedBonus);
  final minCells = Shapes.isLetter(shape) ? 40 : 0;
  Level? best;
  var bestError = double.infinity;
  for (var i = 0; i < candidates; i++) {
    final jitter = 0.92 + 0.16 * rng.nextDouble();
    final s = scale * jitter;
    final cells = (8 + s * 1.05).round();
    final greed = (1 + s / 12).round().clamp(1, 10);
    final fill = (0.5 + s / 300).clamp(0.45, 0.88);
    final fitted = shape.fitTo(math.max(cells, minCells));
    final level = LevelGenerator.generate(
      GeneratorConfig(
        seed: rng.nextUint32(),
        shape: fitted,
        id: id,
        fill: fill,
        greed: greed,
        truckChance: mechanics.trucks ? 0.3 : 0,
        minTrucks: mechanics.trucks ? 1 : 0,
        maxTruckLength: mechanics.maxTruckLength,
        lights: mechanics.lights,
        gates: mechanics.gates,
        ambulance: mechanics.ambulance,
      ),
    );
    if (level == null || !mechanics.satisfiedBy(level)) continue;
    final stats = analyzeLevel(level, maxStates: 60000);
    if (stats == null) continue;
    final error = (stats.difficulty - target).abs();
    if (error < bestError) {
      bestError = error;
      best = level.copyWith(
        meta: level.meta.copyWith(
          difficulty: double.parse(stats.difficulty.toStringAsFixed(1)),
          breather: breather,
        ),
      );
      if (error < 1.5) break;
    }
    // Plain arithmetic only (no pow/log): dailies must be bit-identical on
    // every platform.
    final ratio = target / math.max(1.0, stats.difficulty);
    scale = (scale * ratio * ratio).clamp(2.0, 140.0);
  }
  return best;
}

/// What the campaign wants at one level number.
class LevelSpec {
  const LevelSpec({
    required this.number,
    required this.target,
    required this.breather,
    required this.shape,
    required this.mechanics,
    required this.seed,
  });

  final int number;
  final double target;
  final bool breather;
  final ShapeMask shape;
  final MechanicSet mechanics;
  final int seed;
}

/// The 1500-level campaign: difficulty curve, breathers, mechanic unlocks.
abstract final class Campaign {
  static const levelCount = 1500;
  static const packSize = 100;

  /// Bump to regenerate the whole campaign with a new seed.
  static const seed = 0xA77035;

  static int get packCount => (levelCount + packSize - 1) ~/ packSize;
  static int packOf(int level) => (level - 1) ~/ packSize + 1;
  static String packFile(int pack) =>
      'pack_${pack.toString().padLeft(2, '0')}.json.gz';

  /// Every 5th level is noticeably easier.
  static bool isBreather(int n) => n % 5 == 0;

  /// Hand-made levels: the tutorial, and the first level of each mechanic.
  static final Map<int, Level> handmade = {
    1: sampleLevels[0],
    2: sampleLevels[1],
    3: sampleLevels[2],
    MechanicUnlocks.trucks: sampleLevels[3],
    MechanicUnlocks.trafficLights: sampleLevels[4],
    MechanicUnlocks.gates: sampleLevels[5],
    MechanicUnlocks.ambulance: sampleLevels[6],
  };

  /// Smooth rising curve (fast early growth that levels off), a gentle
  /// wave for variety, and a dip on breather levels. Only used by the
  /// offline tool, so platform `exp`/`sin` are fine here.
  static double targetDifficulty(int n) {
    final rise = 1 - math.exp(-(n - 1) / 520);
    final base = 10 + 68 * rise + 2.5 * math.sin(n * 0.9);
    return isBreather(n) ? math.max(6, base * 0.6) : base;
  }

  static LevelSpec spec(int n) {
    final rng = Rng(seed ^ stableHash('campaign-$n'));
    final breather = isBreather(n);

    // A new mechanic shows up in every one of the few levels right after
    // its hand-made introduction, then in a share of later levels.
    bool use(int unlock, double chance) {
      if (n <= unlock) return false;
      if (n <= unlock + 4) return true;
      return rng.nextBool(breather ? chance / 2 : chance);
    }

    final trucks = use(MechanicUnlocks.trucks, 0.55);
    final lights = use(MechanicUnlocks.trafficLights, 0.3)
        ? 1 + (n > 250 ? 1 : 0) + (n > 700 ? 1 : 0)
        : 0;
    final gates = use(MechanicUnlocks.gates, 0.25)
        ? 1 + (n > 300 ? 1 : 0) + (n > 800 ? 1 : 0)
        : 0;
    final ambulance = use(MechanicUnlocks.ambulance, 0.15);

    final target = targetDifficulty(n);
    // Letters need ~40 cells to read, too big for easy levels.
    final pool = [
      for (final s in Shapes.all)
        if (!Shapes.isLetter(s) || target >= 32) s,
    ];
    return LevelSpec(
      number: n,
      target: target,
      breather: breather,
      shape: rng.pick(pool),
      mechanics: MechanicSet(
        trucks: trucks,
        lights: lights,
        gates: gates,
        ambulance: ambulance,
        maxTruckLength: n > 300 ? 4 : 3,
      ),
      seed: rng.nextUint32(),
    );
  }

  /// Builds level [n]. Deterministic for a given engine version.
  static Level build(int n) {
    final made = handmade[n];
    if (made != null) {
      return made.copyWith(
        id: n,
        meta: LevelMeta(
          shape: made.meta.shape,
          difficulty: double.parse(
            analyzeLevel(made)!.difficulty.toStringAsFixed(1),
          ),
          breather: isBreather(n),
        ),
      );
    }
    final s = spec(n);
    // Relax gradually if the spec turns out to be too demanding.
    for (var attempt = 0; attempt < 8; attempt++) {
      final level = generateForTarget(
        id: n,
        target: s.target,
        seed: s.seed + attempt * 7919,
        shape: attempt < 3 ? s.shape : ShapeMask.rect(6, 8),
        // Last resort: keep only trucks rather than fail the build.
        mechanics: attempt < 6
            ? s.mechanics
            : MechanicSet(trucks: s.mechanics.trucks),
        breather: s.breather,
      );
      if (level != null) return level;
    }
    throw StateError('Could not generate campaign level $n');
  }
}

/// Encodes levels as the compact JSON used in asset packs.
String encodeLevelPack(List<Level> levels) =>
    jsonEncode([for (final l in levels) l.toJson()]);

List<Level> decodeLevelPack(String json) => [
  for (final l in jsonDecode(json) as List)
    Level.fromJson((l as Map).cast<String, Object?>()),
];
