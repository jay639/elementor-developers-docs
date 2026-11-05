import 'package:arrow_engine/arrow_engine.dart';

/// Builds a few campaign levels and prints solve effort vs target.
void main(List<String> args) {
  final ns = args.isEmpty ? [2, 3, 5, 8, 9, 10, 15, 19, 20, 21, 22] : args.map(int.parse).toList();
  for (final n in ns) {
    final l = Campaign.build(n);
    final s = analyzeLevel(l, maxStates: 60000)!;
    print('L$n ${Campaign.tierFor(n).name} target=${Campaign.effortTarget(n).round()} '
        'effort=${s.effort.round()} arrows=${l.pieces.length} ${l.width}x${l.height} '
        'free=${((1 - s.blockedFraction) * 100).round()}%');
  }
}
