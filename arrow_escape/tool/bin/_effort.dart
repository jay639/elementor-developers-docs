import 'package:arrow_engine/arrow_engine.dart';

/// Builds a few campaign levels and prints solve effort vs target, plus
/// the structure numbers compared with the genre leader (free share,
/// chain depth, arrow length).
void main(List<String> args) {
  final ns = args.isEmpty
      ? [3, 5, 8, 9, 10, 20, 50, 100, 300, 500, 1000, 1500]
      : args.map(int.parse).toList();
  for (final n in ns) {
    final sw = Stopwatch()..start();
    final l = Campaign.build(n);
    final s = analyzeLevel(l, maxStates: 60000)!;
    final lens = [for (final p in l.pieces) p.cells.length];
    final mean = lens.reduce((a, b) => a + b) / lens.length;
    print(
      'L$n ${Campaign.tierFor(n).name} target=${Campaign.effortTarget(n).round()} '
      'effort=${s.effort.round()} arrows=${l.pieces.length} ${l.width}x${l.height} '
      'free=${((1 - s.blockedFraction) * 100).round()}% depth=${s.depth} '
      'len=${mean.toStringAsFixed(1)} 10+=${(lens.where((x) => x >= 10).length * 100 / lens.length).round()}% '
      '${sw.elapsedMilliseconds}ms',
    );
  }
}
