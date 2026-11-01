import 'package:arrow_engine/arrow_engine.dart';

/// Builds a few campaign levels and prints their solve effort vs target.
void main(List<String> args) {
  final ns = args.isEmpty
      ? [
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          10,
          11,
          12,
          18,
          40,
          49,
          100,
          500,
          1000,
          1499,
          1500,
        ]
      : args.map(int.parse).toList();
  for (final n in ns) {
    final sw = Stopwatch()..start();
    final l = Campaign.build(n);
    final s = analyzeLevel(l, maxStates: 60000)!;
    print(
      'L$n ${Campaign.tierFor(n).name} target=${Campaign.effortTarget(n).round()} '
      'effort=${s.effort.round()} arrows=${l.pieces.length} '
      '${l.width}x${l.height} free=${(s.pieces * (1 - s.blockedFraction)).round()} '
      '${sw.elapsedMilliseconds}ms',
    );
  }
}
