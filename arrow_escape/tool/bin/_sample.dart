import 'package:arrow_engine/arrow_engine.dart';

/// Quick look at generated levels: size, arrow mix, and how many "free
/// thinking" patterns a board has (free arrows, same-way queues, rows of
/// parallel heads).
void main(List<String> args) {
  final ns = args.isEmpty
      ? [3, 4, 5, 6, 8, 10, 11, 20, 49, 100, 500, 1500]
      : args.map(int.parse).toList();
  for (final n in ns) {
    final sw = Stopwatch()..start();
    report('L$n want=${Campaign.arrowTarget(n)}', Campaign.build(n), sw);
  }
  for (final d in [DateTime(2026, 11, 1), DateTime(2026, 11, 2)]) {
    final sw = Stopwatch()..start();
    report(
      'daily ${DailyChallenge.keyFor(d)} want=${DailyChallenge.arrowsFor(d)}',
      DailyChallenge.levelFor(d),
      sw,
    );
  }
}

void report(String name, Level l, Stopwatch sw) {
  final st = analyzeLevel(l)!;
  final lens = [for (final p in l.pieces) p.cells.length];
  final at = <int, int>{};
  for (var i = 0; i < l.pieces.length; i++) {
    for (final c in l.pieces[i].cells) {
      at[c] = i;
    }
  }
  int? n(int c, Dir d) {
    final x = l.xOf(c) + d.dx, y = l.yOf(c) + d.dy;
    return l.inBounds(x, y) ? l.indexOf(x, y) : null;
  }

  var queue = 0, rows = 0;
  for (final p in l.pieces) {
    final f = n(p.head, p.dir);
    if (f != null && at[f] != null && l.pieces[at[f]!].dir == p.dir) queue++;
    final s = n(p.head, p.dir.clockwise);
    if (s != null && at[s] != null) {
      final o = l.pieces[at[s]!];
      if (o.head == s && o.dir == p.dir) rows++;
    }
  }
  final free = (st.pieces * (1 - st.blockedFraction)).round();
  print(
    '$name got=${lens.length} ${l.width}x${l.height} free=$free '
    'queue=$queue rows=$rows depth=${st.depth} h=${hardness(st).toStringAsFixed(0)} '
    '2:${lens.where((x) => x == 2).length} 3-4:${lens.where((x) => x > 2 && x < 5).length} '
    '5-9:${lens.where((x) => x > 4 && x < 10).length} 10+:${lens.where((x) => x >= 10).length} '
    '${sw.elapsedMilliseconds}ms',
  );
}
