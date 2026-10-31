import 'dart:math' as math;
import 'dart:ui';

import 'package:arrow_engine/arrow_engine.dart';

/// Maps board cells to pixels for a given canvas size, and back.
class BoardLayout {
  factory BoardLayout(Level level, Size size, {double padding = 16}) {
    final availW = math.max(1.0, size.width - padding * 2);
    final availH = math.max(1.0, size.height - padding * 2);
    final cell = math.min(
      maxCell,
      math.min(availW / level.width, availH / level.height),
    );
    final origin = Offset(
      (size.width - cell * level.width) / 2,
      (size.height - cell * level.height) / 2,
    );
    return BoardLayout._(level, cell, origin);
  }

  BoardLayout._(this.level, this.cell, this.origin);

  /// Cells never get bigger than this, so small boards don't look bloated.
  static const maxCell = 76.0;

  /// Taps this close (in cells) to a vehicle still select it…
  static const tapTolerance = 0.75;

  /// …or this close in logical pixels, whichever is larger, so thin arrows
  /// on dense boards stay easy to hit.
  static const minTapRadius = 22.0;

  final Level level;
  final double cell;
  final Offset origin;

  Rect get boardRect => origin & Size(cell * level.width, cell * level.height);

  /// Pixel position of a point given in cell units (cell centres sit at
  /// `x + 0.5, y + 0.5`).
  Offset toPixels(Offset cellUnits) => origin + cellUnits * cell;

  Offset centerUnits(int index) =>
      Offset(level.xOf(index) + 0.5, level.yOf(index) + 0.5);

  Offset centerOf(int index) => toPixels(centerUnits(index));

  Rect cellRect(int index) => Rect.fromLTWH(
    origin.dx + level.xOf(index) * cell,
    origin.dy + level.yOf(index) * cell,
    cell,
    cell,
  );

  /// Board cell under [position], or null outside the grid.
  int? cellAt(Offset position) {
    final units = (position - origin) / cell;
    final x = units.dx.floor();
    final y = units.dy.floor();
    return level.inBounds(x, y) ? level.indexOf(x, y) : null;
  }

  /// The vehicle under [position], or the nearest one within
  /// [tapTolerance] cells. [isOnBoard] filters pieces that already left.
  int? pieceAt(Offset position, bool Function(int piece) isOnBoard) {
    final units = (position - origin) / cell;
    int? best;
    var bestDist = math.max(tapTolerance, minTapRadius / cell);
    final pieces = level.pieces;
    for (var i = 0; i < pieces.length; i++) {
      if (!isOnBoard(i)) continue;
      for (final c in pieces[i].cells) {
        final center = centerUnits(c);
        // Inside the cell square counts as a direct hit.
        if ((units.dx - center.dx).abs() <= 0.5 &&
            (units.dy - center.dy).abs() <= 0.5) {
          return i;
        }
        final d = (units - center).distance;
        if (d < bestDist) {
          bestDist = d;
          best = i;
        }
      }
    }
    return best;
  }
}
