import 'package:arrow_engine/arrow_engine.dart';

void main(List<String> args) {
  for (final n in [2, 3, 4, 5, 9, 10, 20, 49, 100, 300, 700, 1499]) {
    final sw = Stopwatch()..start();
    final l = Campaign.build(n);
    final st = analyzeLevel(l)!;
    final cells = l.mask.where((c) => c).length;
    final occ = l.pieces.fold<int>(0, (a, p) => a + p.cells.length);
    final lens = [for (final p in l.pieces) p.cells.length]..sort();
    print('L$n lens=${lens.join(',')}');
    print('L$n $st');
    print(
      'L$n ${l.meta.shape} ${l.width}x${l.height} target=${Campaign.targetDifficulty(n).toStringAsFixed(0)} got=${st.difficulty.toStringAsFixed(1)} pieces=${st.pieces} depth=${st.depth} fill=${(occ * 100 / cells).round()}% ${sw.elapsedMilliseconds}ms',
    );
  }
}
