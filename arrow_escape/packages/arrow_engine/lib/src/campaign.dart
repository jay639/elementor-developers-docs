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
  const MechanicSet({this.lights = 0, this.gates = 0, this.ambulance = false});

  final int lights;
  final int gates;
  final bool ambulance;

  bool get isEmpty => lights == 0 && gates == 0 && !ambulance;

  /// Rough difficulty the mechanics add on their own (see
  /// [scoreDifficulty]); subtracted when sizing the board.
  double get expectedBonus =>
      3.0 * math.min(lights, 3) +
      2.5 * math.min(gates, 3) +
      (ambulance ? 5 : 0);

  bool satisfiedBy(Level level) =>
      level.lights.length >= lights &&
      level.gates.length >= gates &&
      (!ambulance || level.hasAmbulance);

  @override
  String toString() => 'lights=$lights gates=$gates ambulance=$ambulance';
}

/// Board and arrow parameters for a given search `scale` (roughly the
/// difficulty the board itself must provide). Plain arithmetic only: the
/// daily challenge must be bit-identical on every platform.
({int cells, int greed, double fill, int maxLength}) _shapeFor(double s) => (
  cells: (10 + s * 2.2).round(),
  greed: (1 + s / 10).round().clamp(1, 12),
  fill: (0.62 + s / 400).clamp(0.6, 0.9),
  maxLength: (3 + s / 7).round().clamp(3, 16),
);

/// Generates candidates of varying size and density and keeps the one
/// whose solver-measured difficulty is closest to [target].
Level? generateForTarget({
  required int id,
  required double target,
  required int seed,
  required ShapeMask shape,
  MechanicSet mechanics = const MechanicSet(),
  bool breather = false,
  LevelTier tier = LevelTier.normal,
  int candidates = 10,
}) {
  final rng = Rng(seed);
  // `scale` drives board size, density and arrow length together. It starts
  // from a calibrated guess and is corrected after every candidate, so the
  // search homes in on the target instead of sampling blindly.
  var scale = math.max(3.0, target - mechanics.expectedBonus);
  final minCells = Shapes.isLetter(shape) ? 60 : 0;
  Level? best;
  var bestError = double.infinity;
  for (var i = 0; i < candidates; i++) {
    final jitter = 0.92 + 0.16 * rng.nextDouble();
    final p = _shapeFor(scale * jitter);
    final fitted = shape.fitTo(
      math.max(p.cells, minCells),
      maxWidth: 16,
      maxHeight: 22,
    );
    final level = LevelGenerator.generate(
      GeneratorConfig(
        seed: rng.nextUint32(),
        shape: fitted,
        id: id,
        fill: p.fill,
        greed: p.greed,
        minLength: 2,
        maxLength: p.maxLength,
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
          tier: tier,
        ),
      );
      if (error < 1.5) break;
    }
    final ratio = target / math.max(1.0, stats.difficulty);
    scale = (scale * ratio * ratio).clamp(2.0, 320.0);
  }
  return best;
}

/// What the campaign wants at one level number.
class LevelSpec {
  const LevelSpec({
    required this.number,
    required this.target,
    required this.breather,
    required this.tier,
    required this.shape,
    required this.mechanics,
    required this.seed,
  });

  final int number;
  final double target;
  final bool breather;
  final LevelTier tier;
  final ShapeMask shape;
  final MechanicSet mechanics;
  final int seed;
}

/// The 1500-level campaign: difficulty curve, tiers, breathers, unlocks.
abstract final class Campaign {
  static const levelCount = 1500;
  static const packSize = 100;

  /// Bump to regenerate the whole campaign with a new seed.
  static const seed = 0xA77036;

  static int get packCount => (levelCount + packSize - 1) ~/ packSize;
  static int packOf(int level) => (level - 1) ~/ packSize + 1;
  static String packFile(int pack) =>
      'pack_${pack.toString().padLeft(2, '0')}.json.gz';

  /// Every 5th level is noticeably easier.
  static bool isBreather(int n) => n % 5 == 0;

  /// Levels ending in 9 are Hard and every 50th (49, 99, …) Super Hard,
  /// each followed by a breather. Tiers start once the basics are learned.
  static LevelTier tierFor(int n) {
    if (n < 12) return LevelTier.normal;
    if (n % 50 == 49) return LevelTier.superHard;
    if (n % 10 == 9) return LevelTier.hard;
    return LevelTier.normal;
  }

  /// Only the tutorial is hand-made; every mechanic is introduced by
  /// generated levels so the art style stays consistent.
  static final Map<int, Level> handmade = {1: tutorialLevel};

  /// Steep early rise that levels off, a gentle wave for variety, tier
  /// spikes and breather dips. Only used by the offline tool, so platform
  /// `exp`/`sin` are fine here.
  static double targetDifficulty(int n) {
    final rise = 1 - math.exp(-(n - 1) / 240);
    final base = 14 + 54 * rise + 2.0 * math.sin(n * 0.9);
    if (isBreather(n)) return math.max(8, base * 0.65);
    return switch (tierFor(n)) {
      LevelTier.normal => base,
      LevelTier.hard => math.min(86, base * 1.2 + 4),
      LevelTier.superHard => math.min(92, base * 1.3 + 8),
    };
  }

  static LevelSpec spec(int n) {
    final rng = Rng(seed ^ stableHash('campaign-$n'));
    final breather = isBreather(n);

    // A new mechanic is in its unlock level and the 4 after it (gently),
    // then in a share of later levels.
    bool use(int unlock, double chance) {
      if (n < unlock) return false;
      if (n <= unlock + 4) return true;
      return rng.nextBool(breather ? chance / 2 : chance);
    }

    final lights = use(MechanicUnlocks.trafficLights, 0.3)
        ? 1 + (n > 250 ? 1 : 0) + (n > 700 ? 1 : 0)
        : 0;
    final gates = use(MechanicUnlocks.gates, 0.25)
        ? 1 + (n > 300 ? 1 : 0) + (n > 800 ? 1 : 0)
        : 0;
    final ambulance = use(MechanicUnlocks.ambulance, 0.15);

    // The unlock level itself is an easy showcase of the new mechanic.
    final isIntro =
        n == MechanicUnlocks.trafficLights ||
        n == MechanicUnlocks.gates ||
        n == MechanicUnlocks.ambulance;
    final target = isIntro ? targetDifficulty(n) * 0.6 : targetDifficulty(n);
    // Letters need ~60 cells to read, too big for easy levels.
    final pool = [
      for (final s in Shapes.all)
        if (!Shapes.isLetter(s) || target >= 35) s,
    ];
    return LevelSpec(
      number: n,
      target: target,
      breather: breather,
      tier: tierFor(n),
      shape: rng.pick(pool),
      mechanics: MechanicSet(
        lights: lights,
        gates: gates,
        ambulance: ambulance,
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
          tier: tierFor(n),
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
        shape: attempt < 3 ? s.shape : ShapeMask.rect(8, 10),
        // Last resort: drop the mechanics rather than fail the build.
        mechanics: attempt < 6 ? s.mechanics : const MechanicSet(),
        breather: s.breather,
        tier: s.tier,
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
