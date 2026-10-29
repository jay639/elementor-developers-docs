import 'package:arrow_engine/arrow_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Level', () {
    test('json round trip keeps everything', () {
      final level = parseAsciiLevel(
        id: 42,
        meta: const LevelMeta(shape: 'x', seed: 9, difficulty: 12.5, breather: true),
        vehicles: [
          (kind: PieceKind.truck, dir: Dir.up, cells: [(0, 1), (0, 2)]),
        ],
        '''
#>g
..6
..#
''',
      );
      final copy = Level.fromJson(level.toJson());
      expect(copy.id, 42);
      expect(copy.width, level.width);
      expect(copy.height, level.height);
      expect(copy.mask, level.mask);
      expect(copy.pieces, level.pieces);
      expect(copy.lights, level.lights);
      expect(copy.gates, level.gates);
      expect(copy.meta.shape, 'x');
      expect(copy.meta.seed, 9);
      expect(copy.meta.difficulty, 12.5);
      expect(copy.meta.breather, isTrue);
    });

    test('full rectangles omit the mask', () {
      final level = parseAsciiLevel('>.');
      expect(level.toJson().containsKey('m'), isFalse);
    });

    test('rejects overlapping pieces', () {
      expect(
        () => Level(
          id: 1,
          width: 2,
          height: 1,
          pieces: [
            PieceDef(kind: PieceKind.car, dir: Dir.up, cells: [0]),
            PieceDef(kind: PieceKind.car, dir: Dir.up, cells: [0]),
          ],
        ),
        throwsFormatException,
      );
    });

    test('rejects pieces outside the shape', () {
      expect(
        () => Level(
          id: 1,
          width: 2,
          height: 1,
          mask: [true, false],
          pieces: [PieceDef(kind: PieceKind.car, dir: Dir.up, cells: [1])],
        ),
        throwsFormatException,
      );
    });

    test('rejects non-adjacent truck cells', () {
      expect(
        () => Level(
          id: 1,
          width: 3,
          height: 1,
          pieces: [PieceDef(kind: PieceKind.truck, dir: Dir.up, cells: [0, 2])],
        ),
        throwsFormatException,
      );
    });

    test('rejects multi-cell cars', () {
      expect(
        () => Level(
          id: 1,
          width: 2,
          height: 1,
          pieces: [PieceDef(kind: PieceKind.car, dir: Dir.up, cells: [0, 1])],
        ),
        throwsFormatException,
      );
    });

    test('rejects lights on vehicles', () {
      expect(
        () => Level(
          id: 1,
          width: 1,
          height: 1,
          pieces: [PieceDef(kind: PieceKind.car, dir: Dir.up, cells: [0])],
          lights: [const TrafficLight(cell: 0, startsGreen: true)],
        ),
        throwsFormatException,
      );
    });

    test('ray walks to the edge', () {
      final level = parseAsciiLevel('''
...
...
...
''');
      expect(level.ray(4, Dir.up), [1]);
      expect(level.ray(3, Dir.right), [4, 5]);
      expect(level.ray(2, Dir.right), isEmpty);
    });

    test('ascii parser rejects unknown symbols', () {
      expect(() => parseAsciiLevel('>?'), throwsFormatException);
    });
  });

  group('BoardState', () {
    test('tracks remaining pieces across word boundaries', () {
      var s = BoardState.initial(70);
      expect(s.remainingCount, 70);
      expect(s.isOnBoard(65), isTrue);
      s = s.without(65).without(3);
      expect(s.isOnBoard(65), isFalse);
      expect(s.isOnBoard(3), isFalse);
      expect(s.remaining.length, 68);
      expect(s.exits, 2);
      expect(s.remaining, isNot(contains(65)));
    });

    test('equality and solver key', () {
      final a = BoardState.initial(5).without(1).without(2);
      final b = BoardState.initial(5).without(2).without(1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.solverKey, b.solverKey);
      expect(BoardState.initial(5).without(1).solverKey, isNot(a.solverKey));
    });

    test('cleared when everything left', () {
      expect(BoardState.initial(1).without(0).isCleared, isTrue);
      expect(BoardState.initial(0).isCleared, isTrue);
    });
  });
}
