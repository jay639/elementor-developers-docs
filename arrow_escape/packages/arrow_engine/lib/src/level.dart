import 'dir.dart';

/// Vehicle types. Every kind may span several cells and bend; `car` is the
/// plain arrow. `truck` is kept for older hand-made levels.
enum PieceKind {
  car('c'),
  truck('t'),
  ambulance('a');

  const PieceKind(this.code);

  final String code;

  static PieceKind fromCode(String code) => PieceKind.values.firstWhere(
    (k) => k.code == code,
    orElse: () => throw FormatException('Unknown piece kind "$code"'),
  );
}

/// A vehicle on the board.
///
/// [cells] are cell indexes, head first. Consecutive cells are orthogonally
/// adjacent. The vehicle drives in [dir] from its head; the body follows the
/// head like a snake, so only the head's ray decides whether it can leave.
class PieceDef {
  PieceDef({required this.kind, required this.dir, required List<int> cells})
    : cells = List.unmodifiable(cells);

  final PieceKind kind;
  final Dir dir;
  final List<int> cells;

  int get head => cells.first;
  int get length => cells.length;

  List<Object> toJson() => [kind.code, dir.code, cells];

  static PieceDef fromJson(Object? json) {
    if (json is! List || json.length != 3) {
      throw const FormatException('Piece must be [kind, dir, cells]');
    }
    return PieceDef(
      kind: PieceKind.fromCode(json[0] as String),
      dir: Dir.fromCode(json[1] as String),
      cells: (json[2] as List).cast<int>(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PieceDef &&
      other.kind == kind &&
      other.dir == dir &&
      _listEquals(other.cells, cells);

  @override
  int get hashCode => Object.hash(kind, dir, Object.hashAll(cells));

  @override
  String toString() => 'PieceDef(${kind.name}, ${dir.name}, $cells)';
}

/// A traffic light on an empty cell. All lights toggle after every exit.
/// A red light blocks any path crossing its cell.
class TrafficLight {
  const TrafficLight({required this.cell, required this.startsGreen});

  final int cell;
  final bool startsGreen;

  /// Lights toggle once per exit, so the colour only depends on parity.
  bool isGreenAfter(int exits) => startsGreen == exits.isEven;

  List<Object> toJson() => [cell, startsGreen ? 1 : 0];

  static TrafficLight fromJson(Object? json) {
    final list = json as List;
    return TrafficLight(cell: list[0] as int, startsGreen: list[1] == 1);
  }

  @override
  bool operator ==(Object other) =>
      other is TrafficLight &&
      other.cell == cell &&
      other.startsGreen == startsGreen;

  @override
  int get hashCode => Object.hash(cell, startsGreen);
}

/// A one-way gate on an empty cell. Traffic entering the gate is forced to
/// continue in [dir]; entering against it (a U-turn) is impossible.
class OneWayGate {
  const OneWayGate({required this.cell, required this.dir});

  final int cell;
  final Dir dir;

  List<Object> toJson() => [cell, dir.code];

  static OneWayGate fromJson(Object? json) {
    final list = json as List;
    return OneWayGate(
      cell: list[0] as int,
      dir: Dir.fromCode(list[1] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OneWayGate && other.cell == cell && other.dir == dir;

  @override
  int get hashCode => Object.hash(cell, dir);
}

/// Generator/solver metadata stored with each level.
/// How a level is presented and rewarded.
enum LevelTier {
  normal,
  hard,
  superHard;

  /// Coin reward multiplier.
  int get rewardMultiplier => index + 1;
}

class LevelMeta {
  const LevelMeta({
    this.shape = 'rect',
    this.seed = 0,
    this.difficulty = 0,
    this.breather = false,
    this.tier = LevelTier.normal,
  });

  LevelMeta copyWith({double? difficulty, bool? breather, LevelTier? tier}) =>
      LevelMeta(
        shape: shape,
        seed: seed,
        difficulty: difficulty ?? this.difficulty,
        breather: breather ?? this.breather,
        tier: tier ?? this.tier,
      );

  final String shape;
  final int seed;

  /// 0..100 difficulty score from the solver.
  final double difficulty;
  final bool breather;
  final LevelTier tier;

  Map<String, Object> toJson() => {
    's': shape,
    'seed': seed,
    'df': difficulty,
    if (breather) 'b': 1,
    if (tier != LevelTier.normal) 't': tier.index,
  };

  static LevelMeta fromJson(Object? json) {
    if (json is! Map) return const LevelMeta();
    final t = json['t'] as int? ?? 0;
    return LevelMeta(
      shape: json['s'] as String? ?? 'rect',
      seed: json['seed'] as int? ?? 0,
      difficulty: (json['df'] as num?)?.toDouble() ?? 0,
      breather: json['b'] == 1,
      tier: LevelTier.values[t.clamp(0, LevelTier.values.length - 1)],
    );
  }
}

/// An immutable puzzle definition.
///
/// The board is a [width] x [height] grid; cells are addressed by index
/// `y * width + x`. [mask] marks the playable cells of the shape. Vehicles
/// leave once their head passes the bounding box; cells outside the mask are
/// empty space they can drive through.
class Level {
  Level({
    required this.id,
    required this.width,
    required this.height,
    List<bool>? mask,
    required List<PieceDef> pieces,
    List<TrafficLight> lights = const [],
    List<OneWayGate> gates = const [],
    this.meta = const LevelMeta(),
  }) : mask = List.unmodifiable(mask ?? List.filled(width * height, true)),
       pieces = List.unmodifiable(pieces),
       lights = List.unmodifiable(lights),
       gates = List.unmodifiable(gates) {
    _validate();
  }

  final int id;
  final int width;
  final int height;
  final List<bool> mask;
  final List<PieceDef> pieces;
  final List<TrafficLight> lights;
  final List<OneWayGate> gates;
  final LevelMeta meta;

  int get cellCount => width * height;
  int xOf(int cell) => cell % width;
  int yOf(int cell) => cell ~/ width;
  int indexOf(int x, int y) => y * width + x;
  bool inBounds(int x, int y) => x >= 0 && y >= 0 && x < width && y < height;

  bool get hasAmbulance => pieces.any((p) => p.kind == PieceKind.ambulance);

  bool get hasTrucks => pieces.any((p) => p.kind == PieceKind.truck);

  Level copyWith({int? id, LevelMeta? meta}) => Level(
    id: id ?? this.id,
    width: width,
    height: height,
    mask: mask,
    pieces: pieces,
    lights: lights,
    gates: gates,
    meta: meta ?? this.meta,
  );

  /// Cell reached by stepping once from [cell] in [dir], or -1 if that
  /// leaves the board.
  int step(int cell, Dir dir) {
    final x = xOf(cell) + dir.dx;
    final y = yOf(cell) + dir.dy;
    return inBounds(x, y) ? indexOf(x, y) : -1;
  }

  /// Cells from the one in front of [cell] to the board edge, in order.
  List<int> ray(int cell, Dir dir) {
    final out = <int>[];
    var c = step(cell, dir);
    while (c != -1) {
      out.add(c);
      c = step(c, dir);
    }
    return out;
  }

  void _validate() {
    if (width <= 0 || height <= 0) {
      throw const FormatException('Board must have a positive size');
    }
    if (mask.length != cellCount) {
      throw const FormatException('Mask size does not match board');
    }
    final used = <int>{};
    void claim(int cell, String what) {
      if (cell < 0 || cell >= cellCount || !mask[cell]) {
        throw FormatException('$what at $cell is outside the board shape');
      }
      if (!used.add(cell)) {
        throw FormatException('$what at $cell overlaps another object');
      }
    }

    for (final p in pieces) {
      if (p.cells.isEmpty) throw const FormatException('Empty piece');
      for (var i = 0; i < p.length; i++) {
        claim(p.cells[i], 'Piece');
        if (i > 0) {
          final a = p.cells[i - 1];
          final b = p.cells[i];
          if (Dir.between(xOf(a), yOf(a), xOf(b), yOf(b)) == null) {
            throw FormatException('Piece cells $a and $b are not adjacent');
          }
        }
      }
    }
    for (final l in lights) {
      claim(l.cell, 'Traffic light');
    }
    for (final g in gates) {
      claim(g.cell, 'Gate');
    }
  }

  Map<String, Object> toJson() => {
    'id': id,
    'w': width,
    'h': height,
    if (mask.contains(false)) 'm': mask.map((b) => b ? '1' : '0').join(),
    'p': [for (final p in pieces) p.toJson()],
    if (lights.isNotEmpty) 'l': [for (final l in lights) l.toJson()],
    if (gates.isNotEmpty) 'g': [for (final g in gates) g.toJson()],
    'meta': meta.toJson(),
  };

  static Level fromJson(Map<String, Object?> json) {
    final w = json['w'] as int;
    final h = json['h'] as int;
    final m = json['m'] as String?;
    return Level(
      id: json['id'] as int,
      width: w,
      height: h,
      mask: m == null ? null : [for (final ch in m.split('')) ch == '1'],
      pieces: [for (final p in json['p'] as List) PieceDef.fromJson(p)],
      lights: [
        for (final l in (json['l'] as List?) ?? const [])
          TrafficLight.fromJson(l),
      ],
      gates: [
        for (final g in (json['g'] as List?) ?? const [])
          OneWayGate.fromJson(g),
      ],
      meta: LevelMeta.fromJson(json['meta']),
    );
  }
}

bool _listEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
