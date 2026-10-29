import 'dart:ui';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/presentation/board_geometry.dart';
import 'package:arrow_escape/features/game/presentation/track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Track', () {
    test('car track runs from behind the car, through its path, off board', () {
      final level = parseAsciiLevel('>..');
      final track = Track.forPiece(level, 0, const [1, 2]);
      expect(track.points.first, const Offset(-0.5, 0.5));
      expect(track.points[1], const Offset(0.5, 0.5));
      expect(track.points[3], const Offset(2.5, 0.5));
      // Extends length + 3 cells beyond the last path cell.
      expect(track.points.last, const Offset(6.5, 0.5));
      expect(track.tailArc, 1);
      expect(track.headArc, 1);
    });

    test('truck track keeps body order tail to head', () {
      final level = parseAsciiLevel(
        '''
...
...
''',
        vehicles: [
          (kind: PieceKind.truck, dir: Dir.up, cells: [(1, 0), (1, 1), (0, 1)]),
        ],
      );
      final track = Track.forPiece(level, 0, const []);
      expect(track.points[1], const Offset(0.5, 1.5)); // tail
      expect(track.points[3], const Offset(1.5, 0.5)); // head
      expect(track.headArc - track.tailArc, 2);
      // Body follows the head: halfway along, the tail has turned the corner.
      expect(track.pointAt(track.tailArc + 1), const Offset(1.5, 1.5));
    });

    test('pointAt and tangentAt follow corners', () {
      final level = parseAsciiLevel('''
...
>.8
...
''');
      final track = Track.forPiece(level, 0, const [4, 5, 2]);
      expect(track.pointAt(track.headArc + 2), const Offset(2.5, 1.5));
      expect(track.tangentAt(track.headArc + 2.5), const Offset(0, -1));
      final slice = track.slice(track.headArc + 1.5, track.headArc + 2.5);
      expect(slice, contains(const Offset(2.5, 1.5)));
    });

    test('exit travel moves the tail past the board edge', () {
      final level = parseAsciiLevel('>...');
      final track = Track.forPiece(level, 0, const [1, 2, 3]);
      final tail = track.pointAt(track.tailArc - 0.34 + track.exitTravel);
      expect(tail.dx, greaterThan(level.width + 0.5));
    });
  });

  group('BoardLayout', () {
    final level = parseAsciiLevel('''
>...
....
...^
''');

    test('fits and centres the board', () {
      final layout = BoardLayout(level, const Size(432, 400), padding: 16);
      expect(layout.cell, 76); // capped by maxCell
      expect(layout.boardRect.center, const Offset(216, 200));
    });

    test('direct hits and tolerant near-misses select vehicles', () {
      final layout = BoardLayout(level, const Size(400, 300), padding: 0);
      bool all(int _) => true;
      final c0 = layout.centerOf(0);
      expect(layout.pieceAt(c0, all), 0);
      // Neighbouring empty cell, close to the car: still selects it.
      expect(layout.pieceAt(c0 + Offset(layout.cell * 0.65, 0), all), 0);
      // Far from every vehicle: nothing.
      expect(layout.pieceAt(layout.centerOf(5), all), isNull);
    });

    test('vehicles that left cannot be hit', () {
      final layout = BoardLayout(level, const Size(400, 300), padding: 0);
      expect(layout.pieceAt(layout.centerOf(0), (p) => p != 0), isNull);
    });
  });
}
