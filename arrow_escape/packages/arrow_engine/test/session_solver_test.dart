import 'package:arrow_engine/arrow_engine.dart';
import 'package:test/test.dart';

void main() {
  group('PlaySession', () {
    final level = parseAsciiLevel('>.^'); // piece 0 blocked by piece 1

    test('blocked tap costs a heart and keeps the board', () {
      final s0 = PlaySession.start(level);
      final r = s0.tap(0);
      expect(r.outcome, isA<BlockedMove>());
      expect(r.session.hearts, 2);
      expect(r.session.mistakes, 1);
      expect(r.session.board, s0.board);
    });

    test('three mistakes lose the level and further taps are ignored', () {
      var s = PlaySession.start(level);
      for (var i = 0; i < 3; i++) {
        s = s.tap(0).session;
      }
      expect(s.status, SessionStatus.lost);
      final r = s.tap(1);
      expect(r.outcome, isNull);
      expect(r.session, same(s));
    });

    test('clearing the board wins with stars from mistakes', () {
      var s = PlaySession.start(level);
      s = s.tap(0).session; // mistake
      s = s.tap(1).session;
      s = s.tap(0).session;
      expect(s.status, SessionStatus.won);
      expect(s.stars, 2);
    });

    test('a clean run earns 3 stars, two mistakes earn 1', () {
      var clean = PlaySession.start(level);
      clean = clean.tap(1).session.tap(0).session;
      expect(clean.stars, 3);

      var messy = PlaySession.start(level, hearts: 5);
      messy = messy.tap(0).session.tap(0).session.tap(0).session;
      messy = messy.tap(1).session.tap(0).session;
      expect(messy.stars, 1);
    });

    test('tapping a piece that already left is ignored', () {
      final s = PlaySession.start(level).tap(1).session;
      final r = s.tap(1);
      expect(r.outcome, isNull);
      expect(r.session.hearts, 3);
    });

    test('out-of-range taps are ignored', () {
      final s = PlaySession.start(level);
      expect(s.tap(-1).outcome, isNull);
      expect(s.tap(99).outcome, isNull);
    });

    test('one free undo reverts the last exit but not hearts', () {
      var s = PlaySession.start(parseAsciiLevel('^>.^'));
      expect(s.canUndo, isFalse);
      s = s.tap(0).session;
      s = s.tap(0).session; // ignored, already left
      s = s.tap(1).session; // blocked, costs a heart
      s = s.tap(2).session;
      expect(s.canUndo, isTrue);
      s = s.undo();
      expect(s.board.isOnBoard(0), isFalse);
      expect(s.board.isOnBoard(2), isTrue);
      expect(s.hearts, 2);
      expect(s.undosLeft, 0);
      expect(s.canUndo, isFalse);
      expect(s.undo(), same(s));
    });

    test('undo is unavailable once the level is won', () {
      final s = PlaySession.start(level).tap(1).session.tap(0).session;
      expect(s.status, SessionStatus.won);
      expect(s.canUndo, isFalse);
    });

    test('undo restores light parity', () {
      final lit = parseAsciiLevel('''
>r.
..^
''');
      var s = PlaySession.start(lit);
      s = s.tap(1).session; // lights go green
      expect(s.tap(0).outcome, isA<ExitMove>());
      s = s.undo(); // back to red
      expect(s.board.exits, 0);
      expect(s.tap(0).outcome, isA<BlockedMove>());
    });

    test('extra heart revives a lost session', () {
      var s = PlaySession.start(level, hearts: 1).tap(0).session;
      expect(s.status, SessionStatus.lost);
      s = s.addHeart();
      expect(s.status, SessionStatus.playing);
    });
  });

  group('Solver', () {
    test('solves every sample level, and its solution replays as a win', () {
      for (final level in sampleLevels) {
        final solution = Solver(level).solve();
        expect(solution, isNotNull, reason: 'level ${level.id}');
        var s = PlaySession.start(level);
        for (final p in solution!) {
          final r = s.tap(p);
          expect(r.outcome, isA<ExitMove>(), reason: 'level ${level.id}');
          s = r.session;
        }
        expect(s.status, SessionStatus.won, reason: 'level ${level.id}');
      }
    });

    test('detects head-on deadlock', () {
      expect(Solver(parseAsciiLevel('>.<')).solve(), isNull);
    });

    test('backtracks out of a traffic light dead end', () {
      // Greedy order fails on this sample, the solver must still succeed.
      final level = sampleLevels.firstWhere((l) => l.meta.shape == 'lights');
      expect(Solver(level).solve(), isNotNull);
    });

    test('ambulance lane deadlock is unsolvable', () {
      final level = parseAsciiLevel(
        '''
.v.
.^.
''',
        vehicles: [
          (kind: PieceKind.ambulance, dir: Dir.right, cells: [(0, 1)]),
        ],
      );
      // The lane car at (1,1) is blocked by (1,0), which must yield.
      expect(Solver(level).solve(), isNull);
    });

    test('hint returns a move that keeps the board solvable', () {
      final level = sampleLevels[1];
      final solver = Solver(level);
      final hint = solver.hint(solver.rules.initialState);
      expect(hint, isNotNull);
      final next = solver.rules.initialState.without(hint!);
      expect(solver.solve(next), isNotNull);
    });

    test('returns null when the budget is exhausted', () {
      final solver = Solver(sampleLevels[2], maxStates: 1);
      expect(solver.solve(), isNull);
    });
  });
}
