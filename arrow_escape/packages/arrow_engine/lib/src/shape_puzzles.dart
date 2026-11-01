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
    required this.chapter,
    required this.aspect,
    required this.inside,
  });

  final String id;
  final String name;

  /// Total stars (campaign + daily + puzzles) needed to open it.
  final int starsToUnlock;

  /// Group in the gallery: Garden, Land, Sky, Space — from small things
  /// to the cosmos. New wonders slot into a chapter; Galaxy stays last.
  final String chapter;

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

  /// Arrows in [layer] (1-based): later pictures are bigger (the ladybug
  /// starts at 28 arrows, the galaxy at 82) and each layer has ~25% more.
  int arrowsFor(int layer) {
    final index = ShapePuzzles.all.indexOf(this);
    final base = 28 + index * 54 / (ShapePuzzles.all.length - 1);
    return (base * (1 + (layer - 1) * 0.25)).round().clamp(10, 120);
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

  /// All layers of [shape], each with more arrows than the one before.
  static List<Level> buildLayers(PuzzleShape shape) {
    final rng = Rng(seed ^ stableHash(shape.id));
    final mask = shape.mask;
    final picks = <Level>[];
    // Wide or thin pictures hold fewer arrows on the biggest board.
    final capacity =
        mask
            .fitTo(
              100000,
              maxWidth: maxArrowBoardWidth,
              maxHeight: maxArrowBoardHeight,
            )
            .area /
        6.0;
    for (var layer = 1; layer <= PuzzleShape.layerCount; layer++) {
      Level? level;
      for (var attempt = 0; attempt < 6 && level == null; attempt++) {
        final l = generateForArrows(
          id: 0,
          arrows: math.min(
            shape.arrowsFor(layer),
            (capacity * (0.55 + 0.2 * layer)).round(),
          ),
          seed: rng.nextUint32(),
          // The mask's name, puzzle_<id>, is the level's shape.
          shape: mask,
          greed: 6 + layer * 2,
          maxLength: 16,
          tier: switch (layer) {
            1 => LevelTier.normal,
            2 => LevelTier.hard,
            _ => LevelTier.superHard,
          },
        );
        if (l != null &&
            (picks.isEmpty || l.pieces.length > picks.last.pieces.length)) {
          level = l;
        }
      }
      if (level == null) {
        throw StateError('Could not generate layer $layer of ${shape.id}');
      }
      picks.add(level);
    }
    return picks;
  }

  /// `{"mountain/1": level, …}` as JSON.
  static String encode(Map<String, Level> levels) =>
      jsonEncode({for (final e in levels.entries) e.key: e.value.toJson()});

  static Map<String, Level> decode(String json) => {
    for (final e in (jsonDecode(json) as Map).entries)
      e.key as String: Level.fromJson((e.value as Map).cast<String, Object?>()),
  };

  static final all = <PuzzleShape>[
    PuzzleShape(
      id: 'ladybug',
      name: 'Ladybug',
      starsToUnlock: 15,
      chapter: 'Garden',
      aspect: 1.0,
      inside: (x, y) {
        final shell = _sq(x / 0.85) + _sq((y - 0.15) / 0.8) <= 1;
        final head = _sq(x / 0.42) + _sq((y + 0.72) / 0.3) <= 1;
        // Spots and the line between the wings stay open.
        final split = x.abs() < 0.06 && y > -0.45;
        var spot = false;
        for (final (sx, sy) in const [
          (-0.42, -0.1),
          (0.42, -0.1),
          (-0.48, 0.4),
          (0.48, 0.4),
        ]) {
          if (_sq(x - sx) + _sq(y - sy) < 0.03) spot = true;
        }
        return (shell && !split && !spot) || head;
      },
    ),
    PuzzleShape(
      id: 'leaf',
      name: 'Leaf',
      starsToUnlock: 26,
      chapter: 'Garden',
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
      id: 'flower',
      name: 'Flower',
      starsToUnlock: 49,
      chapter: 'Garden',
      aspect: 1,
      inside: (x, y) {
        final r = math.sqrt(_sq(x) + _sq(y));
        final a = math.atan2(y, x);
        return r < 0.42 + 0.56 * math.cos(a * 2.5).abs();
      },
    ),
    PuzzleShape(
      id: 'butterfly',
      name: 'Butterfly',
      starsToUnlock: 80,
      chapter: 'Garden',
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
      id: 'mushroom',
      name: 'Mushroom',
      starsToUnlock: 119,
      chapter: 'Garden',
      aspect: 1.0,
      inside: (x, y) {
        final cap = y < 0.05 && _sq(x / 0.98) + _sq((y - 0.05) / 0.9) <= 1;
        final stem = y >= 0.05 && y < 0.95 && x.abs() < 0.3 + 0.08 * y;
        return cap || stem;
      },
    ),
    PuzzleShape(
      id: 'onion',
      name: 'Onion',
      starsToUnlock: 163,
      chapter: 'Garden',
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
      id: 'cactus',
      name: 'Cactus',
      starsToUnlock: 213,
      chapter: 'Land',
      aspect: 0.85,
      inside: (x, y) {
        final trunk = x.abs() < 0.24 && y > -0.95;
        final left =
            (x > -0.8 && x < -0.5 && y > -0.55 && y < 0.15) ||
            (x > -0.8 && x < -0.2 && y > 0.0 && y < 0.25);
        final right =
            (x > 0.5 && x < 0.8 && y > -0.75 && y < -0.05) ||
            (x > 0.2 && x < 0.8 && y > -0.2 && y < 0.05);
        final pot = y > 0.6 && x.abs() < 0.55 - (y - 0.6) * 0.3;
        return trunk || left || right || pot;
      },
    ),
    PuzzleShape(
      id: 'tree',
      name: 'Pine tree',
      starsToUnlock: 269,
      chapter: 'Land',
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
      id: 'volcano',
      name: 'Volcano',
      starsToUnlock: 329,
      chapter: 'Land',
      aspect: 1.3,
      inside: (x, y) {
        // A cone with a crater, and a plume above it.
        final cone = y > -0.35 && x.abs() <= 0.18 + (y + 0.35) * 0.62;
        final crater = y < -0.2 && x.abs() < 0.12;
        final plume = _sq((x + 0.1) / 0.32) + _sq((y + 0.75) / 0.2) <= 1;
        return (cone && !crater) || plume;
      },
    ),
    PuzzleShape(
      id: 'mountain',
      name: 'Mountain',
      starsToUnlock: 394,
      chapter: 'Land',
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
      id: 'raindrop',
      name: 'Raindrop',
      starsToUnlock: 464,
      chapter: 'Sky',
      aspect: 0.75,
      inside: (x, y) {
        final round = _sq(x / 0.95) + _sq((y - 0.35) / 0.62) <= 1;
        final point = y < 0.35 && y > -1 && x.abs() <= (y + 1) * 0.72;
        return round || point;
      },
    ),
    PuzzleShape(
      id: 'snowflake',
      name: 'Snowflake',
      starsToUnlock: 538,
      chapter: 'Sky',
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
      id: 'cloud',
      name: 'Cloud',
      starsToUnlock: 616,
      chapter: 'Sky',
      aspect: 1.6,
      inside: (x, y) =>
          _sq((x + 0.5) / 0.42) + _sq((y - 0.2) / 0.6) <= 1 ||
          _sq((x - 0.05) / 0.5) + _sq((y + 0.15) / 0.85) <= 1 ||
          _sq((x - 0.55) / 0.42) + _sq((y - 0.15) / 0.7) <= 1 ||
          (y > 0.1 && y < 0.8 && x.abs() < 0.85),
    ),
    PuzzleShape(
      id: 'bolt',
      name: 'Lightning',
      starsToUnlock: 698,
      chapter: 'Sky',
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
      id: 'rainbow',
      name: 'Rainbow',
      starsToUnlock: 784,
      chapter: 'Sky',
      aspect: 1.1,
      inside: (x, y) {
        // Two wide bands of a tall arch, with a gap between them.
        final r = math.sqrt(_sq(x) + _sq((y - 1) / 2));
        return (r > 0.25 && r < 0.58) || (r > 0.66 && r < 1.0);
      },
    ),
    PuzzleShape(
      id: 'tornado',
      name: 'Tornado',
      starsToUnlock: 874,
      chapter: 'Sky',
      aspect: 0.9,
      inside: (x, y) {
        // Stacked bands that narrow towards the ground and wander.
        final t = (y + 1) / 2;
        final centre = 0.25 * math.sin(t * 7);
        final half = 0.95 - 0.8 * t;
        final band = ((t * 7) % 1) < 0.78;
        return (x - centre).abs() <= half && band;
      },
    ),
    PuzzleShape(
      id: 'moon',
      name: 'Moon',
      starsToUnlock: 967,
      chapter: 'Space',
      aspect: 1,
      inside: (x, y) =>
          _sq(x) + _sq(y) <= 0.95 && _sq(x - 0.45) + _sq(y + 0.2) > 0.6,
    ),
    PuzzleShape(
      id: 'mars',
      name: 'Mars',
      starsToUnlock: 1064,
      chapter: 'Space',
      aspect: 1,
      inside: (x, y) {
        if (_sq(x) + _sq(y) > 0.97) return false;
        // Craters.
        if (_sq(x + 0.35) + _sq(y + 0.3) < 0.05) return false;
        if (_sq(x - 0.4) + _sq(y - 0.15) < 0.035) return false;
        if (_sq(x + 0.05) + _sq(y - 0.5) < 0.03) return false;
        return true;
      },
    ),
    PuzzleShape(
      id: 'earth',
      name: 'Earth',
      starsToUnlock: 1165,
      chapter: 'Space',
      aspect: 1,
      inside: (x, y) {
        if (_sq(x) + _sq(y) > 0.97) return false;
        // Oceans between the continents are left open.
        final america = _sq((x + 0.42) / 0.3) + _sq((y + 0.1) / 0.62) <= 1;
        final eurasia = _sq((x - 0.35) / 0.42) + _sq((y + 0.35) / 0.28) <= 1;
        final africa = _sq((x - 0.25) / 0.22) + _sq((y - 0.3) / 0.36) <= 1;
        return america || eurasia || africa || _sq(x) + _sq(y) > 0.62;
      },
    ),
    PuzzleShape(
      id: 'saturn',
      name: 'Saturn',
      starsToUnlock: 1269,
      chapter: 'Space',
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
      id: 'sun',
      name: 'Sun',
      starsToUnlock: 1376,
      chapter: 'Space',
      aspect: 1,
      inside: (x, y) {
        final r = math.sqrt(_sq(x) + _sq(y));
        final a = math.atan2(y, x);
        return r < 0.55 || (r < 0.98 && math.cos(a * 12) > 0.35);
      },
    ),
    PuzzleShape(
      id: 'nebula',
      name: 'Nebula',
      starsToUnlock: 1486,
      chapter: 'Space',
      aspect: 1.25,
      inside: (x, y) {
        final a = _sq((x + 0.35) / 0.6) + _sq((y + 0.15) / 0.55) <= 1;
        final b = _sq((x - 0.35) / 0.55) + _sq((y - 0.2) / 0.6) <= 1;
        final c = _sq((x - 0.05) / 0.35) + _sq((y + 0.6) / 0.3) <= 1;
        // Dark lanes of dust cut through the cloud.
        final lane = (y - 0.4 * x).abs() < 0.07;
        return (a || b || c) && !lane;
      },
    ),
    PuzzleShape(
      id: 'galaxy',
      name: 'Galaxy',
      starsToUnlock: 1600,
      chapter: 'Space',
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
