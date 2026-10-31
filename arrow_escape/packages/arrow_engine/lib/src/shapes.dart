import 'dart:math' as math;

/// A board outline. `true` cells are playable.
class ShapeMask {
  ShapeMask(this.name, this.width, this.height, List<bool> cells)
    : cells = List.unmodifiable(cells) {
    if (cells.length != width * height) {
      throw ArgumentError('mask size mismatch for $name');
    }
  }

  /// Parses pixel art: `#` playable, anything else empty. Rows are padded.
  factory ShapeMask.art(String name, String art) {
    final rows = [
      for (final r in art.split('\n'))
        if (r.trim().isNotEmpty) r.trimRight(),
    ];
    final w = rows.map((r) => r.length).reduce(math.max);
    return ShapeMask(name, w, rows.length, [
      for (final r in rows)
        for (var x = 0; x < w; x++) x < r.length && r[x] == '#',
    ]);
  }

  final String name;
  final int width;
  final int height;
  final List<bool> cells;

  int get area => cells.where((c) => c).length;

  /// Share of the bounding box that is playable.
  double get fillRatio => area / (width * height);

  double get aspect => width / height;

  bool at(int x, int y) =>
      x >= 0 && y >= 0 && x < width && y < height && cells[y * width + x];

  /// Resamples to [w] x [h] by supersampling each target cell; a cell is
  /// playable when at least half of it is covered. The result is trimmed
  /// to its bounding box.
  ShapeMask resample(int w, int h) {
    const samples = 4;
    final out = List<bool>.filled(w * h, false);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var hits = 0;
        for (var sy = 0; sy < samples; sy++) {
          for (var sx = 0; sx < samples; sx++) {
            final fx = (x + (sx + 0.5) / samples) / w * width;
            final fy = (y + (sy + 0.5) / samples) / h * height;
            if (at(fx.floor(), fy.floor())) hits++;
          }
        }
        out[y * w + x] = hits * 2 >= samples * samples;
      }
    }
    return ShapeMask(name, w, h, out).trimmed();
  }

  /// Fits the shape so it has roughly [targetCells] playable cells while
  /// keeping its aspect ratio, within the given bounds.
  ShapeMask fitTo(
    int targetCells, {
    int minSide = 3,
    int maxWidth = 10,
    int maxHeight = 14,
  }) {
    final box = targetCells / fillRatio;
    final w0 = math.sqrt(box * aspect);
    final h0 = w0 / aspect;
    // Shrink both sides together when either bound bites, so the picture
    // keeps its proportions.
    final scale = math.min(1.0, math.min(maxWidth / w0, maxHeight / h0));
    final w = (w0 * scale).round().clamp(minSide, maxWidth);
    final h = (h0 * scale).round().clamp(minSide, maxHeight);
    final result = resample(w, h);
    return result.area >= 4 ? result : ShapeMask.rect(w, h);
  }

  ShapeMask trimmed() {
    var minX = width, minY = height, maxX = -1, maxY = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!cells[y * width + x]) continue;
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      }
    }
    if (maxX < 0) return this;
    final w = maxX - minX + 1;
    final h = maxY - minY + 1;
    if (w == width && h == height) return this;
    return ShapeMask(name, w, h, [
      for (var y = minY; y <= maxY; y++)
        for (var x = minX; x <= maxX; x++) cells[y * width + x],
    ]);
  }

  static ShapeMask rect(int w, int h) =>
      ShapeMask('rect', w, h, List.filled(w * h, true));

  @override
  String toString() {
    final b = StringBuffer();
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        b.write(cells[y * width + x] ? '#' : '.');
      }
      if (y < height - 1) b.writeln();
    }
    return b.toString();
  }
}

/// Every board outline used by the generator, grouped by theme.
abstract final class Shapes {
  static ShapeMask byName(String name) => all.firstWhere(
    (s) => s.name == name,
    orElse: () => throw ArgumentError.value(name, 'name', 'unknown shape'),
  );

  /// Letters have thin strokes and need more cells to read well.
  static bool isLetter(ShapeMask s) => s.name.startsWith('letter_');

  static final List<ShapeMask> all = [
    ...basics,
    ...vehicles,
    ...animals,
    ...symbols,
    ...letters,
    ...landmarks,
  ];

  static final basics = [
    ShapeMask.rect(6, 8),
    _generated('diamond', 11, 11, (x, y) => (x - 5).abs() + (y - 5).abs() <= 5),
    _generated('circle', 12, 12, (x, y) {
      final dx = x - 5.5, dy = y - 5.5;
      return dx * dx + dy * dy <= 36;
    }),
    _generated(
      'plus',
      9,
      9,
      (x, y) => (x >= 3 && x <= 5) || (y >= 3 && y <= 5),
    ),
    _generated('hexagon', 11, 10, (x, y) {
      final inset = (y < 5 ? 4 - y : y - 5).clamp(0, 4) * 0.5;
      return x >= inset && x <= 10 - inset;
    }),
  ];

  static final vehicles = [
    ShapeMask.art('car', '''
....######....
...########...
..##########..
##############
##############
##############
.###......###.
.###......###.
'''),
    ShapeMask.art('bus', '''
##############
##############
##############
##############
##############
.##.......##..
'''),
    ShapeMask.art('rocket', '''
....##....
...####...
..######..
..######..
..##..##..
..######..
..######..
.########.
##########
##.####.##
#...##...#
'''),
  ];

  static final animals = [
    ShapeMask.art('cat', '''
#..........#
##........##
###......###
############
############
##.######.##
############
############
#####..#####
############
.##########.
..########..
'''),
    ShapeMask.art('fish', '''
....#####.....
..#########..#
.###########.#
##.###########
##############
.###########.#
..#########..#
....#####.....
'''),
    ShapeMask.art('bird', '''
....###.....
...#####....
..######....
###.#####...
...#########
...##########
....########.
.....######..
......##.....
......##.....
'''),
    ShapeMask.art('rabbit', '''
.##....##.
.##....##.
.##....##.
.##....##.
.########.
##########
###.##.###
##########
####..####
.########.
..######..
'''),
    ShapeMask.art('turtle', '''
....####....
..########..
.##########.
############
############
.##########.
##.######.##
#...#..#...#
'''),
    ShapeMask.art('owl', '''
#..........#
############
############
##..####..##
##..####..##
############
############
.##########.
.##########.
..########..
...#....#...
'''),
  ];

  static final symbols = [
    ShapeMask.art('heart', '''
.###...###.
#####.#####
###########
###########
.#########.
..#######..
...#####...
....###....
.....#.....
'''),
    ShapeMask.art('star', '''
.....#.....
....###....
....###....
###########
.#########.
..#######..
..#######..
.####.####.
.###...###.
##.......##
'''),
    ShapeMask.art('arrow', '''
....##....
...####...
..######..
.########.
##########
...####...
...####...
...####...
...####...
'''),
  ];

  static final letters = [
    ShapeMask.art('letter_a', '''
..###..
.#####.
##...##
##...##
#######
#######
##...##
##...##
##...##
'''),
    ShapeMask.art('letter_h', '''
##...##
##...##
##...##
#######
#######
##...##
##...##
##...##
'''),
    ShapeMask.art('letter_t', '''
#######
#######
..###..
..###..
..###..
..###..
..###..
..###..
'''),
    ShapeMask.art('letter_x', '''
##...##
##...##
.##.##.
..###..
..###..
.##.##.
##...##
##...##
'''),
    ShapeMask.art('letter_o', '''
.#####.
#######
##...##
##...##
##...##
##...##
#######
.#####.
'''),
    ShapeMask.art('letter_e', '''
#######
#######
##.....
#####..
#####..
##.....
#######
#######
'''),
    ShapeMask.art('letter_z', '''
#######
#######
....##.
...##..
..##...
.##....
#######
#######
'''),
  ];

  static final landmarks = [
    ShapeMask.art('eiffel', '''
.....##.....
.....##.....
....####....
....####....
....####....
...######...
...##..##...
..########..
..########..
..##....##..
.###....###.
.##......##.
###......###
##........##
'''),
    ShapeMask.art('pyramid', '''
.....##.....
....####....
...######...
..########..
.##########.
############
'''),
    ShapeMask.art('castle', '''
#.#.#...#.#.#
#####...#####
#####.#.#####
#############
#############
#############
#####...#####
#####...#####
'''),
    ShapeMask.art('lighthouse', '''
....###....
...#####...
....###....
....###....
...#####...
...#####...
...#####...
..#######..
..#######..
.#########.
###########
'''),
    ShapeMask.art('clock_tower', '''
...#...
..###..
.#####.
.#####.
.##.##.
.#####.
.#####.
.#####.
.#####.
#######
#######
'''),
    ShapeMask.art('bridge', '''
##.........##
###.......###
#############
#############
##.##...##.##
##.#.....#.##
##.........##
'''),
  ];

  static ShapeMask _generated(
    String name,
    int w,
    int h,
    bool Function(int x, int y) inside,
  ) => ShapeMask(name, w, h, [
    for (var y = 0; y < h; y++)
      for (var x = 0; x < w; x++) inside(x, y),
  ]);
}
