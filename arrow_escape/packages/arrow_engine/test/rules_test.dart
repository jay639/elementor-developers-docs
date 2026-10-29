import 'package:arrow_engine/arrow_engine.dart';
import 'package:test/test.dart';

Rules parseRules(String drawing) => Rules(parseAsciiLevel(drawing));

void main() {
  group('Dir', () {
    test('opposite and rotation', () {
      expect(Dir.up.opposite, Dir.down);
      expect(Dir.left.opposite, Dir.right);
      expect(Dir.up.clockwise, Dir.right);
      expect(Dir.up.counterClockwise, Dir.left);
    });

    test('code round trip', () {
      for (final d in Dir.values) {
        expect(Dir.fromCode(d.code), d);
      }
      expect(() => Dir.fromCode('x'), throwsFormatException);
    });

    test('between adjacent cells', () {
      expect(Dir.between(1, 1, 1, 0), Dir.up);
      expect(Dir.between(1, 1, 2, 1), Dir.right);
      expect(Dir.between(1, 1, 2, 2), isNull);
    });
  });

  group('Rules: vehicles', () {
    test('free car exits along a straight path', () {
      final level = parseAsciiLevel('..>..');
      final rules = Rules(level);
      final out = rules.evaluate(rules.initialState, 0);
      expect(out, isA<ExitMove>());
      expect((out as ExitMove).path, [3, 4]);
    });

    test('car blocked by another car reports blocker and free steps', () {
      final level = parseAsciiLevel('>..^');
      final rules = Rules(level);
      final out = rules.evaluate(rules.initialState, 0) as BlockedMove;
      expect(out.reason, BlockReason.vehicle);
      expect(out.blockerPiece, 1);
      expect(out.blockerCell, 3);
      expect(out.freeSteps, 2);
    });

    test('path is clear once the blocker has left', () {
      final level = parseAsciiLevel('>..^');
      final rules = Rules(level);
      final s = rules.initialState.without(1);
      expect(rules.canExit(s, 0), isTrue);
    });

    test('cells outside the mask are passable empty space', () {
      final level = parseAsciiLevel('>##.');
      final rules = Rules(level);
      expect(rules.canExit(rules.initialState, 0), isTrue);
      expect(rules.pathOf(0), [1, 2, 3]);
    });

    test('truck moves by its head only', () {
      final level = parseAsciiLevel(
        '''
...
...
''',
        vehicles: [
          (kind: PieceKind.truck, dir: Dir.up, cells: [(1, 0), (1, 1), (0, 1)]),
        ],
      );
      final rules = Rules(level);
      expect(rules.canExit(rules.initialState, 0), isTrue);
      expect(rules.pathOf(0), isEmpty);
    });

    test('vehicle facing its own body can never exit', () {
      final level = parseAsciiLevel(
        '''
...
...
''',
        vehicles: [
          (
            kind: PieceKind.truck,
            dir: Dir.right,
            cells: [(0, 0), (0, 1), (1, 1), (1, 0)],
          ),
        ],
      );
      final rules = Rules(level);
      final out = rules.evaluate(rules.initialState, 0) as BlockedMove;
      expect(out.reason, BlockReason.noExit);
      expect(rules.pathCanExit(0), isFalse);
    });

    test('legalMoves lists every free piece', () {
      final level = parseAsciiLevel('<>.<');
      final rules = Rules(level);
      expect(rules.legalMoves(rules.initialState), [0]);
      expect(rules.legalMoves(parseRules('<.>.').initialState), [0, 1]);
    });
  });

  group('Rules: traffic lights', () {
    test('red light blocks, then turns green after one exit', () {
      final level = parseAsciiLevel('''
>r.
...
^..
''');
      final rules = Rules(level);
      var s = rules.initialState;
      final blocked = rules.evaluate(s, 0) as BlockedMove;
      expect(blocked.reason, BlockReason.redLight);
      expect(blocked.blockerCell, 1);
      expect(blocked.freeSteps, 0);
      s = s.without(1); // the other car leaves, lights toggle
      expect(rules.canExit(s, 0), isTrue);
    });

    test('green light lets traffic through and toggles to red', () {
      final light = const TrafficLight(cell: 0, startsGreen: true);
      expect(light.isGreenAfter(0), isTrue);
      expect(light.isGreenAfter(1), isFalse);
      expect(light.isGreenAfter(2), isTrue);
    });
  });

  group('Rules: one-way gates', () {
    test('gate bends the path', () {
      // Car at (0,1) drives right into an up-gate at (2,1).
      final level = parseAsciiLevel('''
...
>.8
...
''');
      final rules = Rules(level);
      expect(rules.pathOf(0), [4, 5, 2]);
      expect(rules.canExit(rules.initialState, 0), isTrue);
    });

    test('vehicles on the bent path block it', () {
      final level = parseAsciiLevel('''
..<
>.8
...
''');
      final rules = Rules(level);
      final out = rules.evaluate(rules.initialState, 1) as BlockedMove;
      expect(out.blockerPiece, 0);
    });

    test('entering a gate against its direction is a wrong way', () {
      final level = parseAsciiLevel('>.4');
      final rules = Rules(level);
      final out = rules.evaluate(rules.initialState, 0) as BlockedMove;
      expect(out.reason, BlockReason.wrongWay);
      expect(out.blockerCell, 2);
    });

    test('gate loops never exit', () {
      final level = parseAsciiLevel('''
....
>62.
.84.
....
''');
      final rules = Rules(level);
      final out = rules.evaluate(rules.initialState, 0) as BlockedMove;
      expect(out.reason, BlockReason.noExit);
    });
  });

  group('Rules: ambulance', () {
    Level build() => parseAsciiLevel(
      '''
.^.
...
>..
''',
      vehicles: [
        (kind: PieceKind.ambulance, dir: Dir.right, cells: [(0, 1)]),
      ],
    );

    test('vehicles outside the lane must wait for the ambulance', () {
      final level = build();
      final rules = Rules(level);
      final s = rules.initialState;
      // Piece 1 (bottom car) is free but not in the lane.
      final out = rules.evaluate(s, 1) as BlockedMove;
      expect(out.reason, BlockReason.ambulanceFirst);
    });

    test('ambulance can go, then everyone else', () {
      final level = build();
      final rules = Rules(level);
      var s = rules.initialState;
      expect(rules.canExit(s, 2), isTrue);
      s = s.without(2);
      expect(rules.canExit(s, 0), isTrue);
      expect(rules.canExit(s, 1), isTrue);
    });

    test('vehicles in the lane may clear it', () {
      final level = parseAsciiLevel(
        '''
...
.^.
...
''',
        vehicles: [
          (kind: PieceKind.ambulance, dir: Dir.right, cells: [(0, 1)]),
        ],
      );
      final rules = Rules(level);
      expect(rules.lanesOf(0), [1]);
      expect(rules.canExit(rules.initialState, 0), isTrue);
      expect(rules.canExit(rules.initialState, 1), isFalse);
    });
  });
}
