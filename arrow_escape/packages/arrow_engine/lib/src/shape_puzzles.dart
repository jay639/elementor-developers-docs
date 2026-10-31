import 'dart:convert';
import 'dart:math' as math;

import 'campaign.dart';
import 'level.dart';
import 'rng.dart';
import 'shapes.dart';

/// A collectible picture puzzle: a board shape with [layerCount] levels of
/// rising difficulty, unlocked once the player has earned enough stars.
class PuzzleShape {
  const PuzzleShape({
    required this.id,
    required this.name,
    required this.starsToUnlock,
    required this.aspect,
    required this.inside,
  });

  final String id;
  final String name;

  /// Total stars (campaign + daily + puzzles) needed to open it.
  final int starsToUnlock;

  /// Width / height of the picture.
  final double aspect;

  /// The picture, in coordinates x, y in [-1, 1] (y grows downwards).
  final bool Function(double x, double y) inside;

  static const layerCount = 3;

  /// The outline rasterised at a fine resolution; the generator resamples
  /// it to the board size it needs.
  ShapeMask get mask {
    const h = 48;
    final w = math.max(8, (h * aspect).round());
    return ShapeMask('puzzle_$id', w, h, [
      for (var y = 0; y < h; y++)
        for (var x = 0; x < w; x++)
          inside((x + 0.5) / w * 2 - 1, (y + 0.5) / h * 2 - 1),
    ]).trimmed();
  }

  /// Difficulty target of [layer] (1-based). Later shapes start higher.
  double targetFor(int layer) {
    final index = ShapePuzzles.all.indexOf(this);
    final base = 56 + index * 1.6;
    return math.min(98.0, base + (layer - 1) * 12);
  }
}

/// Builds and stores the puzzle levels. Generated offline by the tool and
/// shipped as `assets/levels/puzzles.json.gz`, like the campaign.
abstract final class ShapePuzzles {
  static const seed = 0x5A9E;
  static const assetFile = 'puzzles.json.gz';

  static PuzzleShape byId(String id) => all.firstWhere(
    (s) => s.id == id,
    orElse: () => throw ArgumentError.value(id, 'id', 'unknown puzzle'),
  );

  /// Key of one layer, used in saves and analytics.
  static String key(String id, int layer) => '$id/$layer';

  /// All layers of [shape], each strictly harder than the one before.
  static List<Level> buildLayers(PuzzleShape shape) {
    final layers = <Level>[];
    var floor = 0.0;
    for (var layer = 1; layer <= PuzzleShape.layerCount; layer++) {
      final level = _build(shape, layer, floor);
      layers.add(level);
      floor = level.meta.difficulty;
    }
    return layers;
  }

  static Level _build(PuzzleShape shape, int layer, double floor) {
    final rng = Rng(seed ^ stableHash(key(shape.id, layer)));
    final mask = shape.mask;
    Level? fallback;
    for (var attempt = 0; attempt < 12; attempt++) {
      final level = generateForTarget(
        id: 0,
        // Aim higher after a too-easy attempt.
        target: math.min(99.0, shape.targetFor(layer) + attempt * 2),
        seed: rng.nextUint32(),
        shape: mask,
        // Layers grow bigger rather than only denser.
        minCells: 110 + layer * 50,
        tier: switch (layer) {
          1 => LevelTier.normal,
          2 => LevelTier.hard,
          _ => LevelTier.superHard,
        },
      );
      // The mask's name, puzzle_<id>, is the level's shape.
      if (level == null) continue;
      if (level.meta.difficulty > floor + 2) return level;
      if (fallback == null ||
          level.meta.difficulty > fallback.meta.difficulty) {
        fallback = level;
      }
    }
    if (fallback != null && fallback.meta.difficulty > floor) return fallback;
    throw StateError('Could not generate puzzle ${key(shape.id, layer)}');
  }

  /// `{"mountain/1": level, …}` as JSON.
  static String encode(Map<String, Level> levels) =>
      jsonEncode({for (final e in levels.entries) e.key: e.value.toJson()});

  static Map<String, Level> decode(String json) => {
    for (final e in (jsonDecode(json) as Map).entries)
      e.key as String: Level.fromJson(
        (e.value as Map).cast<String, Object?>(),
      ),
  };

  static final all = <PuzzleShape>[
    PuzzleShape(
      id: 'mountain',
      name: 'Mountain',
      starsToUnlock: 15,
      aspect: 1.3,
      inside: (x, y) {
        final height = math.max(
          0.95 - 1.45 * (x + 0.25).abs(),
          0.72 - 1.3 * (x - 0.5).abs(),
        );
        return (1 - y) / 2 <= height + 0.04;
      },
    ),
    PuzzleShape(
      id: 'onion',
      name: 'Onion',
      starsToUnlock: 40,
      aspect: 0.8,
      inside: (x, y) {
        final bulb = _sq(x / 0.85) + _sq((y - 0.3) / 0.68) <= 1;
        // Pointed top that widens into the bulb.
        final sprout = y > -1 && y < -0.2 && x.abs() <= 0.06 + (y + 1) * 0.42;
        final roots = y > 0.9 && x.abs() < 0.3;
        return bulb || sprout || roots;
      },
    ),
    PuzzleShape(
      id: 'moon',
      name: 'Moon',
      starsToUnlock: 70,
      aspect: 1,
      inside: (x, y) =>
          _sq(x) + _sq(y) <= 0.95 &&
          _sq(x - 0.45) + _sq(y + 0.2) > 0.6,
    ),
    PuzzleShape(
      id: 'sun',
      name: 'Sun',
      starsToUnlock: 110,
      aspect: 1,
      inside: (x, y) {
        final r = math.sqrt(_sq(x) + _sq(y));
        final a = math.atan2(y, x);
        return r < 0.55 || (r < 0.98 && math.cos(a * 12) > 0.35);
      },
    ),
    PuzzleShape(
      id: 'tree',
      name: 'Pine tree',
      starsToUnlock: 160,
      aspect: 0.75,
      inside: (x, y) {
        bool tier(double top, double bottom, double width) =>
            y >= top &&
            y <= bottom &&
            x.abs() <= width * (y - top) / (bottom - top) + 0.04;
        final trunk = y > 0.7 && x.abs() < 0.18;
        return tier(-1, -0.3, 0.55) ||
            tier(-0.55, 0.25, 0.8) ||
            tier(-0.1, 0.72, 1) ||
            trunk;
      },
    ),
    PuzzleShape(
      id: 'flower',
      name: 'Flower',
      starsToUnlock: 220,
      aspect: 1,
      inside: (x, y) {
        final r = math.sqrt(_sq(x) + _sq(y));
        final a = math.atan2(y, x);
        return r < 0.42 + 0.56 * math.cos(a * 2.5).abs();
      },
    ),
    PuzzleShape(
      id: 'cloud',
      name: 'Cloud',
      starsToUnlock: 290,
      aspect: 1.6,
      inside: (x, y) =>
          _sq((x + 0.5) / 0.42) + _sq((y - 0.2) / 0.6) <= 1 ||
          _sq((x - 0.05) / 0.5) + _sq((y + 0.15) / 0.85) <= 1 ||
          _sq((x - 0.55) / 0.42) + _sq((y - 0.15) / 0.7) <= 1 ||
          (y > 0.1 && y < 0.8 && x.abs() < 0.85),
    ),
    PuzzleShape(
      id: 'butterfly',
      name: 'Butterfly',
      starsToUnlock: 370,
      aspect: 1.25,
      inside: (x, y) {
        final ax = x.abs();
        final upper = _sq((ax - 0.5) / 0.48) + _sq((y + 0.3) / 0.62) <= 1;
        final lower = _sq((ax - 0.4) / 0.38) + _sq((y - 0.5) / 0.45) <= 1;
        final body = ax < 0.09 && y.abs() < 0.85;
        return upper || lower || body;
      },
    ),
    PuzzleShape(
      id: 'crown',
      name: 'Crown',
      starsToUnlock: 460,
      aspect: 1.35,
      inside: (x, y) {
        final band = y > 0.25 && y < 0.9 && x.abs() < 0.92;
        var spike = false;
        for (final px in const [-0.72, 0.0, 0.72]) {
          final half = 0.3 * (y + 0.95) / 1.2;
          if (y > -0.95 && y <= 0.3 && (x - px).abs() <= half) spike = true;
        }
        return band || spike;
      },
    ),
    PuzzleShape(
      id: 'gem',
      name: 'Gem',
      starsToUnlock: 560,
      aspect: 1.2,
      inside: (x, y) {
        if (y < -0.75) return false;
        if (y < -0.25) return x.abs() <= 0.55 + (y + 0.75) * 0.85;
        return x.abs() <= 0.98 * (0.95 - y) / 1.2;
      },
    ),
    PuzzleShape(
      id: 'snowflake',
      name: 'Snowflake',
      starsToUnlock: 680,
      aspect: 1,
      inside: (x, y) {
        final r = math.sqrt(_sq(x) + _sq(y));
        if (r > 0.98) return false;
        if (r < 0.28) return true;
        for (var k = 0; k < 6; k++) {
          final a = k * math.pi / 3;
          final along = x * math.cos(a) + y * math.sin(a);
          final across = (-x * math.sin(a) + y * math.cos(a)).abs();
          if (along > 0 && across < 0.13) return true;
          // Side branches.
          if (along > 0.45 && along < 0.8 && across < 0.13 + (along - 0.45)) {
            if (across > 0.1 && (along - 0.45 - across + 0.1).abs() < 0.12) {
              return true;
            }
          }
        }
        return false;
      },
    ),
    PuzzleShape(
      id: 'bolt',
      name: 'Lightning',
      starsToUnlock: 820,
      aspect: 0.7,
      inside: (x, y) => _inPolygon(x, y, const [
        (0.25, -1.0),
        (-0.75, 0.15),
        (-0.05, 0.15),
        (-0.35, 1.0),
        (0.8, -0.25),
        (0.1, -0.25),
        (0.55, -1.0),
      ]),
    ),
    PuzzleShape(
      id: 'umbrella',
      name: 'Umbrella',
      starsToUnlock: 980,
      aspect: 1.15,
      inside: (x, y) {
        final canopy = y <= 0.05 && _sq(x) + _sq((y - 0.05) / 0.95) <= 1;
        final shaft = x.abs() < 0.07 && y > 0 && y < 0.8;
        final hook =
            y > 0.6 &&
            _sq(x + 0.18) + _sq(y - 0.75) < 0.05 &&
            _sq(x + 0.18) + _sq(y - 0.75) > 0.01;
        return canopy || shaft || hook;
      },
    ),
    PuzzleShape(
      id: 'planet',
      name: 'Planet',
      starsToUnlock: 1160,
      aspect: 1.5,
      inside: (x, y) {
        final body = _sq(x / 0.55) + _sq(y / 0.82) <= 1;
        // A tilted ring around it.
        final rx = x * 0.96 + y * 0.28;
        final ry = -x * 0.28 + y * 0.96;
        final ring = _sq(rx / 0.98) + _sq(ry / 0.3);
        return body || (ring <= 1 && ring >= 0.55);
      },
    ),
    PuzzleShape(
      id: 'leaf',
      name: 'Leaf',
      starsToUnlock: 1360,
      aspect: 1,
      inside: (x, y) {
        // A lens along the diagonal, with a short stem.
        final u = (x + y) / math.sqrt2;
        final v = (x - y) / math.sqrt2;
        final lens = _sq(v) + _sq(u.abs() + 0.55) <= 1.6 && u.abs() < 0.98;
        final stem = v.abs() < 0.07 && u > 0.9 && u < 1.3;
        return lens || stem;
      },
    ),
    PuzzleShape(
      id: 'galaxy',
      name: 'Galaxy',
      starsToUnlock: 1600,
      aspect: 1,
      inside: (x, y) {
        final r = math.sqrt(_sq(x) + _sq(y));
        if (r > 0.99) return false;
        if (r < 0.26) return true;
        final a = math.atan2(y, x);
        // Two spiral arms that thin out towards the rim.
        return math.sin(2 * a - 6 * r) > -0.1 + r * 0.5;
      },
    ),
  ];

  static double _sq(double v) => v * v;

  static bool _inPolygon(double x, double y, List<(double, double)> pts) {
    var inside = false;
    for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      final (xi, yi) = pts[i];
      final (xj, yj) = pts[j];
      if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
        inside = !inside;
      }
    }
    return inside;
  }
}
