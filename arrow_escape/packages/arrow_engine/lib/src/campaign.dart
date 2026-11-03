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
/// difficulty the board itself must provide). Boards are always packed:
/// difficulty comes from size and how greedily arrows block each other,
/// never from empty space. Plain arithmetic only: the daily challenge must
/// be bit-identical on every platform.
({
  int cells,
  int greed,
  double fill,
  int maxLength,
  double longShare,
  double turnChance,
})
_shapeFor(double s, double target) => (
  // Size follows the target, so every level is a crowded board; the
  // search scale only nudges it.
  cells: (30 + (0.3 * target + 0.7 * s) * 2.4).round().clamp(30, 300),
  greed: (2 + s / 7).round().clamp(2, 20),
  fill: 0.9,
  // Longer, more winding snakes as levels go up (up to 30 cells).
  maxLength: (8 + s / 3).round().clamp(8, 36),
  longShare: (0.06 + s / 500).clamp(0.06, 0.2),
  turnChance: (0.35 + s / 400).clamp(0.35, 0.55),
);

/// Largest board the campaign uses (cells stay ~24 dp wide on a phone, so
/// boards fit the screen without zooming).
const maxBoardWidth = 15;
const maxBoardHeight = 20;

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
  int candidates = 14,
  int minCells = 0,
}) {
  final rng = Rng(seed);
  // `scale` drives board size, density and arrow length together. It starts
  // from a calibrated guess and is corrected after every candidate, so the
  // search homes in on the target instead of sampling blindly.
  var scale = math.max(3.0, target - mechanics.expectedBonus);
  final floor = math.max(minCells, Shapes.isLetter(shape) ? 60 : 0);
  Level? best;
  var bestError = double.infinity;
  for (var i = 0; i < candidates; i++) {
    final jitter = 0.92 + 0.16 * rng.nextDouble();
    final p = _shapeFor(scale * jitter, target);
    final fitted = shape.fitTo(
      math.max(p.cells, floor),
      maxWidth: maxBoardWidth,
      maxHeight: maxBoardHeight,
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
        longShare: p.longShare,
        turnChance: p.turnChance,
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
    scale = (scale * ratio * ratio).clamp(2.0, 140.0);
  }
  return best;
}

/// Generates boards with about [arrows] arrows and keeps the hardest one
/// (the easiest for breathers) whose count is within a few percent.
///
/// Arrow count is what players feel first ("more arrows every level"), so
/// it is the main progression axis; solver difficulty picks between
/// candidates of the right size. Board size follows the count: the length
/// mix averages ~5 cells per arrow, so big levels need boards larger than
/// a phone screen (the game opens them zoomed out, then zooms in).
Level? generateForArrows({
  required int id,
  required int arrows,
  required int seed,
  required ShapeMask shape,
  MechanicSet mechanics = const MechanicSet(),
  bool breather = false,
  LevelTier tier = LevelTier.normal,
  int candidates = 8,
  int greed = 6,
  double turnChance = 0.45,
  double longShare = 0.08,
  double midShare = 0.22,
  double tinyShare = 0.32,
  int maxLength = 18,
  int maxWidth = maxArrowBoardWidth,
  int maxHeight = maxArrowBoardHeight,
  int analyzeStates = 60000,
}) {
  final rng = Rng(seed);
  // Cells per arrow, corrected after every candidate.
  var perArrow = 5.6;
  // Shrinks medium and long arrows when even the biggest board is too
  // small for the count.
  var squeeze = 1.0;
  Level? best;
  var bestKey = double.negativeInfinity;
  final tolerance = math.max(2, (arrows * 0.06).round());
  for (var i = 0; i < candidates; i++) {
    final cells = (arrows * perArrow).round();
    final fitted = shape.fitTo(cells, maxWidth: maxWidth, maxHeight: maxHeight);
    final level = LevelGenerator.generate(
      GeneratorConfig(
        seed: rng.nextUint32(),
        shape: fitted,
        id: id,
        fill: 0.92,
        greed: greed,
        minLength: 2,
        maxLength: maxLength,
        tinyShare: tinyShare,
        midShare: midShare * squeeze,
        longShare: longShare * squeeze,
        turnChance: turnChance,
        tailGrowth: 3,
        lights: mechanics.lights,
        gates: mechanics.gates,
        ambulance: mechanics.ambulance,
      ),
    );
    if (level == null || !mechanics.satisfiedBy(level)) continue;
    final got = level.pieces.length;
    final usable = fitted.area;
    perArrow = (perArrow * arrows / got).clamp(3.0, 9.0);
    // Ignore the size miss when the board is already as big as allowed.
    final capped = fitted.width >= maxWidth || fitted.height >= maxHeight;
    if (capped && got < arrows - tolerance) {
      squeeze = math.max(0.3, squeeze * 0.7);
    }
    final miss = (got - arrows).abs();
    if (miss > tolerance && !(capped && got < arrows)) continue;
    final stats = analyzeLevel(level, maxStates: analyzeStates);
    if (stats == null) continue;
    final d = stats.difficulty;
    // Prefer the right count, then hard boards (easy ones for breathers).
    // The 0-100 score saturates on big boards, so rank by what makes a
    // board slow to read: few free arrows, long waiting chains.
    final h = hardness(stats);
    final key =
        -miss * 4.0 + (breather ? -h : h) - (usable > cells * 1.6 ? 5 : 0);
    if (key > bestKey) {
      bestKey = key;
      best = level.copyWith(
        meta: level.meta.copyWith(
          difficulty: double.parse(d.toStringAsFixed(1)),
          breather: breather,
          tier: tier,
        ),
      );
    }
  }
  return best;
}

/// Generates a board whose solve effort ([LevelStats.effort], roughly the
/// time a person needs) lands close to [effort]. The arrow count starts at
/// [arrows] and is corrected after every candidate (effort grows a bit
/// faster than linearly with arrows), the board size follows the count,
/// and the candidate closest to the target wins; it stops early once one
/// is within [band] (a share of the target). Plain arithmetic only (no
/// `pow`/`log`), so dailies stay bit-identical on every device.
Level? generateForEffort({
  required int id,
  required double effort,
  required int arrows,
  required int seed,
  required ShapeMask shape,
  MechanicSet mechanics = const MechanicSet(),
  LevelTier tier = LevelTier.normal,
  int candidates = 16,
  int greed = 6,
  double turnChance = 0.45,
  double longShare = 0.08,
  double midShare = 0.22,
  double tinyShare = 0.32,
  int maxLength = 18,
  int maxWidth = maxArrowBoardWidth,
  int maxHeight = maxArrowBoardHeight,
  int maxArrows = 160,
  double band = 0.06,
  int analyzeStates = 60000,
}) {
  final rng = Rng(seed);
  var want = arrows.toDouble();
  var perArrow = 5.6;
  var squeeze = 1.0;
  Level? best;
  var bestMiss = double.infinity;
  for (var i = 0; i < candidates; i++) {
    final count = want.round().clamp(4, maxArrows);
    final cells = (count * perArrow).round();
    final fitted = shape.fitTo(cells, maxWidth: maxWidth, maxHeight: maxHeight);
    final level = LevelGenerator.generate(
      GeneratorConfig(
        seed: rng.nextUint32(),
        shape: fitted,
        id: id,
        fill: 0.92,
        greed: greed,
        minLength: 2,
        maxLength: maxLength,
        tinyShare: tinyShare,
        midShare: midShare * squeeze,
        longShare: longShare * squeeze,
        turnChance: turnChance,
        tailGrowth: 3,
        lights: mechanics.lights,
        gates: mechanics.gates,
        ambulance: mechanics.ambulance,
      ),
    );
    if (level == null || !mechanics.satisfiedBy(level)) continue;
    final got = level.pieces.length;
    perArrow = (perArrow * count / got).clamp(3.0, 9.0);
    final capped = fitted.width >= maxWidth || fitted.height >= maxHeight;
    if (capped && got < count * 0.94) squeeze = math.max(0.3, squeeze * 0.7);
    final stats = analyzeLevel(level, maxStates: analyzeStates);
    if (stats == null) continue;
    final e = math.max(1.0, stats.effort);
    // Relative miss, symmetric for over and under (ratio-based).
    final miss = e > effort ? e / effort - 1 : effort / e - 1;
    if (miss < bestMiss) {
      bestMiss = miss;
      best = level.copyWith(
        meta: level.meta.copyWith(
          difficulty: double.parse(stats.difficulty.toStringAsFixed(1)),
          tier: tier,
        ),
      );
      if (miss <= band) break;
    }
    // Effort grows a little faster than the arrow count: correct the
    // count by the square root of the miss.
    final ratio = effort / e;
    final step = math.sqrt(ratio.clamp(0.25, 4.0));
    want = (got * step).clamp(4.0, maxArrows.toDouble());
  }
  return best;
}

/// How hard a board is to read, without the 0-100 cap: share of arrows
/// blocked at the start, the longest waiting chain and how few moves are
/// open on average.
double hardness(LevelStats s) =>
    60 * s.blockedFraction +
    1.5 * s.depth -
    40 * (s.avgBranching / math.max(1, s.pieces));

/// Largest arrow-count board (cells ~15 dp wide when fully zoomed out on
/// a phone; the game zooms in after showing the whole board).
const maxArrowBoardWidth = 26;
const maxArrowBoardHeight = 34;

/// What the campaign wants at one level number.
class LevelSpec {
  const LevelSpec({
    required this.number,
    required this.arrows,
    required this.effort,
    required this.breather,
    required this.tier,
    required this.shape,
    required this.mechanics,
    required this.seed,
  });

  final int number;
  final int arrows;

  /// Solve effort the level is built to (see [Campaign.effortTarget]).
  final double effort;
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

  /// No easier "breather" levels any more: every level takes at least as
  /// long as the one before it (Hard / Super Hard levels spike above).
  static bool isBreather(int n) => false;

  /// Levels ending in 9 are Hard and every 50th (49, 99, …) Super Hard,
  /// each followed by a breather.
  static LevelTier tierFor(int n) {
    if (n < 9) return LevelTier.normal;
    if (n % 50 == 49) return LevelTier.superHard;
    if (n % 10 == 9) return LevelTier.hard;
    return LevelTier.normal;
  }

  /// Only the tutorial is hand-made; every mechanic is introduced by
  /// generated levels so the art style stays consistent.
  static final Map<int, Level> handmade = {1: tutorialLevel};

  /// How many arrows level [n] has: the main progression axis. Level 2
  /// is a 14-arrow warm-up, then it climbs fast: level 3 ~27, level 5
  /// ~40, level 8 ~47, level 100 ~60, level 500 ~91, level 1000 ~110. It never goes down between regular levels;
  /// breathers dip a little (to about the count 3 levels earlier), Hard
  /// levels have 12% more and Super Hard 25% more. Only used by the
  /// offline tool, so platform `exp` is fine here.
  static int arrowTarget(int n) {
    if (n <= 1) return 6;
    final base = _baseArrows(n);
    final factor = isBreather(n)
        ? 0.92
        : switch (tierFor(n)) {
            LevelTier.normal => 1.0,
            LevelTier.hard => 1.12,
            LevelTier.superHard => 1.25,
          };
    // The biggest board holds about 120 arrows.
    return (base * factor).round().clamp(6, 120);
  }

  /// Arrow count before tier factors: rises with every level.
  static double _baseArrows(int n) =>
      14 +
      32 * (1 - math.exp(-(n - 2) / 2)) +
      40 * (1 - math.exp(-n / 300)) +
      0.025 * n;

  /// Solve effort level [n] is built to ([LevelStats.effort], roughly
  /// solve time): rises with every level, ~180 at level 3, ~350 at level
  /// 8, ~500 at level 100, ~880 at level 500, ~1045 at level 1500 (slower
  /// past 900, as the biggest board fills up). Hard levels need 25% more,
  /// Super Hard 45% more (capped at 1250). Offline tool only, so `pow` is fine.
  static double effortTarget(int n) {
    if (n <= 1) return 10;
    // 1.5x the Sprint 7 curve: harder from level 3 on.
    var base = 1.5 * 1.69 * math.pow(_baseArrows(n), 1.29);
    // Past ~900 the biggest board runs out of room: keep rising, slower.
    if (base > 900) base = 900 + (base - 900) * 0.4;
    final factor = switch (tierFor(n)) {
      LevelTier.normal => 1.0,
      LevelTier.hard => 1.25,
      LevelTier.superHard => 1.45,
    };
    return math.min(1250.0, base * factor);
  }

  /// Longest arrow at level [n]: short snakes early, very long later.
  static int maxLengthFor(int n) => (6 + n * 0.8).round().clamp(6, 22);

  /// Placement greed: later levels block more arrows per placement.
  static int greedFor(int n) => (4 + n / 60).round().clamp(4, 12);

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
    final arrows = isIntro ? (arrowTarget(n) * 0.6).round() : arrowTarget(n);
    final effort = isIntro ? effortTarget(n) * 0.5 : effortTarget(n);
    // Mostly plain rectangles of varied proportions (they read cleanly and
    // every edge cell is playable); sometimes a compact picture shape.
    final shapes = [
      for (final s in [...Shapes.basics, ...Shapes.animals, ...Shapes.symbols])
        if (s.name != 'rect') s,
    ];
    // Portrait-ish proportions (phones are tall).
    final aspects = [(3, 4), (4, 5), (5, 7), (2, 3), (3, 5)];
    final (aw, ah) = rng.pick(aspects);
    final picture = rng.pick(shapes);
    final plain = rng.nextBool(0.65);
    // Pictures and squares waste the bottom of a tall screen, so big
    // boards are always portrait rectangles.
    final shape = arrows > 50
        ? ShapeMask.rect(aw, ah)
        : plain
        ? ShapeMask.rect(aw, ah)
        : picture;
    return LevelSpec(
      number: n,
      arrows: arrows,
      effort: effort,
      breather: breather,
      tier: tierFor(n),
      shape: shape,
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
      final level = generateForEffort(
        id: n,
        effort: s.effort,
        arrows: s.arrows,
        seed: s.seed + attempt * 7919,
        shape: attempt < 3 ? s.shape : ShapeMask.rect(3, 4),
        // Last resort: drop the mechanics rather than fail the build.
        mechanics: attempt < 6 ? s.mechanics : const MechanicSet(),
        tier: s.tier,
        greed: greedFor(n),
        maxLength: maxLengthFor(n),
        // Big late boards need more, shorter arrows to fit the screen.
        longShare: (0.1 - n / 30000).clamp(0.05, 0.1),
        midShare: (0.24 - n / 20000).clamp(0.16, 0.24),
        candidates: attempt < 4 ? 30 : 40,
        // Tight: neighbouring levels differ by only a few percent.
        band: 0.03,
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
