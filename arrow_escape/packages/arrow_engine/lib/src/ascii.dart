import 'dir.dart';
import 'level.dart';

/// A multi-cell vehicle for [parseAsciiLevel]: `(x, y)` cells, head first.
typedef AsciiVehicle = ({PieceKind kind, Dir dir, List<(int, int)> cells});

/// Builds a level from a compact text drawing. Handy for tests and
/// hand-made levels.
///
/// Legend: `.` empty cell, space or `#` outside the shape, `^ > v <` a car
/// facing that way, `g` / `r` a traffic light starting green / red,
/// `8 6 2 4` a one-way gate pointing up / right / down / left (numpad).
/// Trucks and ambulances go in [vehicles]; their cells must be `.`.
Level parseAsciiLevel(
  String drawing, {
  int id = 0,
  List<AsciiVehicle> vehicles = const [],
  LevelMeta meta = const LevelMeta(),
}) {
  final rows = drawing.split('\n');
  while (rows.isNotEmpty && rows.first.trim().isEmpty) {
    rows.removeAt(0);
  }
  while (rows.isNotEmpty && rows.last.trim().isEmpty) {
    rows.removeLast();
  }
  if (rows.isEmpty) throw const FormatException('Empty drawing');
  final height = rows.length;
  final width = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);

  final mask = List<bool>.filled(width * height, false);
  final pieces = <PieceDef>[];
  final lights = <TrafficLight>[];
  final gates = <OneWayGate>[];
  const arrows = {'^': Dir.up, '>': Dir.right, 'v': Dir.down, '<': Dir.left};
  const gateDirs = {'8': Dir.up, '6': Dir.right, '2': Dir.down, '4': Dir.left};

  for (var y = 0; y < height; y++) {
    final row = rows[y];
    for (var x = 0; x < width; x++) {
      final ch = x < row.length ? row[x] : ' ';
      final cell = y * width + x;
      if (ch == ' ' || ch == '#') continue;
      mask[cell] = true;
      if (arrows[ch] case final dir?) {
        pieces.add(PieceDef(kind: PieceKind.car, dir: dir, cells: [cell]));
      } else if (gateDirs[ch] case final dir?) {
        gates.add(OneWayGate(cell: cell, dir: dir));
      } else if (ch == 'g' || ch == 'r') {
        lights.add(TrafficLight(cell: cell, startsGreen: ch == 'g'));
      } else if (ch != '.') {
        throw FormatException('Unknown symbol "$ch" at ($x, $y)');
      }
    }
  }
  for (final v in vehicles) {
    pieces.add(
      PieceDef(
        kind: v.kind,
        dir: v.dir,
        cells: [for (final (x, y) in v.cells) y * width + x],
      ),
    );
  }
  return Level(
    id: id,
    width: width,
    height: height,
    mask: mask,
    pieces: pieces,
    lights: lights,
    gates: gates,
    meta: meta,
  );
}
