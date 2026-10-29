import 'dir.dart';
import 'rules.dart';

/// Where a vehicle would drive from its head, ignoring other vehicles and
/// lights (those are dynamic). Shared by [Rules] and the generator so they
/// can never disagree.
class PathTrace {
  const PathTrace(this.cells, [this.terminal, this.terminalCell]);

  /// Cells in front of the head, in driving order.
  final List<int> cells;

  /// Why the path can never leave the board, or null if it can.
  final BlockReason? terminal;
  final int? terminalCell;

  bool get exits => terminal == null;
}

/// Traces from [head] in [dir] on a [width] x [height] board. Gates
/// ([gateAt], indexed by cell) turn traffic; [isOwn] marks the vehicle's own
/// body cells.
PathTrace tracePath({
  required int width,
  required int height,
  required List<Dir?> gateAt,
  required int head,
  required Dir dir,
  required bool Function(int cell) isOwn,
}) {
  final cells = <int>[];
  final seenGates = <int>{};
  var x = head % width;
  var y = head ~/ width;
  var d = dir;
  while (true) {
    x += d.dx;
    y += d.dy;
    if (x < 0 || y < 0 || x >= width || y >= height) return PathTrace(cells);
    final next = y * width + x;
    if (isOwn(next)) return PathTrace(cells, BlockReason.noExit, next);
    final gate = gateAt[next];
    if (gate != null) {
      if (gate == d.opposite) {
        return PathTrace(cells, BlockReason.wrongWay, next);
      }
      // Gates always send traffic the same way, so revisiting one loops.
      if (!seenGates.add(next)) {
        return PathTrace(cells, BlockReason.noExit, next);
      }
      d = gate;
    }
    cells.add(next);
  }
}
