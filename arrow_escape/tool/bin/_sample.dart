import 'package:arrow_engine/arrow_engine.dart';

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
          15,
          20,
          40,
          49,
          50,
          70,
          100,
          200,
          500,
          1000,
          1499,
          1500,
        ]
      : args.map(int.parse).toList();
  for (final n in ns) {
    final sw = Stopwatch()..start();
    final l = Campaign.build(n);
    final st = analyzeLevel(l)!;
    final lens = [for (final p in l.pieces) p.cells.length]..sort();
    print(
      'L$n want=${Campaign.arrowTarget(n)} got=${lens.length} ${l.width}x${l.height} ${l.meta.shape} d=${l.meta.difficulty} h=${hardness(st).toStringAsFixed(0)} free=${(st.pieces * (1 - st.blockedFraction)).round()} depth=${st.depth} 2:${lens.where((x) => x == 2).length} 3-4:${lens.where((x) => x > 2 && x < 5).length} 5-9:${lens.where((x) => x > 4 && x < 10).length} 10+:${lens.where((x) => x >= 10).length} L${l.lights.length}G${l.gates.length}A${l.hasAmbulance ? 1 : 0} ${sw.elapsedMilliseconds}ms',
    );
  }
  for (final d in [
    DateTime(2026, 11, 1),
    DateTime(2026, 11, 2),
    DateTime(2027, 6, 1),
  ]) {
    final sw = Stopwatch()..start();
    final l = DailyChallenge.levelFor(d);
    print(
      'daily $d want=${DailyChallenge.arrowsFor(d)} got=${l.pieces.length} ${l.width}x${l.height} ${sw.elapsedMilliseconds}ms',
    );
  }
}
