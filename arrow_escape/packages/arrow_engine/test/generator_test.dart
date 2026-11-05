import 'dart:convert';
import 'dart:math' as math;

import 'package:arrow_engine/arrow_engine.dart';
import 'package:test/test.dart';

void main() {
  group('Rng', () {
    test('same seed, same sequence; different seeds diverge', () {
      final a = Rng(42), b = Rng(42), c = Rng(43);
      final sa = [for (var i = 0; i < 20; i++) a.nextUint32()];
      final sb = [for (var i = 0; i < 20; i++) b.nextUint32()];
      final sc = [for (var i = 0; i < 20; i++) c.nextUint32()];
      expect(sa, sb);
      expect(sa, isNot(sc));
    });

    test('golden values stay fixed (daily challenge depends on it)', () {
      final r = Rng(1);
      expect([r.nextUint32(), r.nextUint32(), r.nextUint32()], _goldenRng);
    });

    test('ranges', () {
      final r = Rng(7);
      for (var i = 0; i < 1000; i++) {
        final v = r.nextInt(5);
        expect(v, inInclusiveRange(0, 4));
        final d = r.nextDouble();
        expect(d, greaterThanOrEqualTo(0));
        expect(d, lessThan(1));
      }
      expect(() => r.nextInt(0), throwsArgumentError);
    });

    test('detLn matches math.log closely', () {
      for (final x in [1e-9, 0.01, 0.5, 1.0, 1.5, 2.0, 3.7, 10.0, 12345.6]) {
        expect(detLn(x), closeTo(math.log(x), 1e-12 * (1 + math.log(x).abs())));
      }
      expect(detLn(1), 0);
      expect(() => detLn(0), throwsArgumentError);
    });

    test('stableHash is FNV-1a', () {
      expect(stableHash(''), 0x811C9DC5);
      expect(stableHash('a'), 0xE40C292C);
    });
  });

  group('ShapeMask', () {
    test('art parsing pads rows', () {
      final s = ShapeMask.art('t', '''
##
#
''');
      expect(s.width, 2);
      expect(s.height, 2);
      expect(s.cells, [true, true, true, false]);
    });

    test('resample keeps a full rectangle full and trims empty borders', () {
      expect(ShapeMask.rect(4, 4).resample(7, 9).area, 63);
      final framed = ShapeMask.art('f', '''
.....
.###.
.....
''');
      final t = framed.trimmed();
      expect((t.width, t.height), (3, 1));
    });

    test('fitTo lands near the requested size within bounds', () {
      for (final shape in Shapes.all) {
        for (final cells in [16, 40, 90]) {
          final f = shape.fitTo(cells);
          expect(f.width, lessThanOrEqualTo(10), reason: shape.name);
          expect(f.height, lessThanOrEqualTo(14), reason: shape.name);
          expect(f.area, greaterThanOrEqualTo(4), reason: shape.name);
        }
      }
    });

    test('library has cars, animals, hearts, letters and landmarks', () {
      final names = Shapes.all.map((s) => s.name).toSet();
      expect(names, containsAll(['car', 'cat', 'heart', 'letter_a', 'eiffel']));
      expect(names.length, Shapes.all.length, reason: 'unique names');
      expect(() => Shapes.byName('nope'), throwsArgumentError);
    });
  });

  group('LevelGenerator', () {
    Level? gen(
      int seed, {
      MechanicSet m = const MechanicSet(),
      int cells = 40,
    }) {
      final shape = Shapes.all[seed % Shapes.all.length].fitTo(cells);
      return LevelGenerator.generate(
        GeneratorConfig(
          seed: seed,
          shape: shape,
          greed: 1 + seed % 6,
          fill: 0.5 + (seed % 4) * 0.1,
          maxLength: 2 + seed % 8,
          lights: m.lights,
          gates: m.gates,
          ambulance: m.ambulance,
        ),
      );
    }

    test('is deterministic', () {
      expect(gen(5)!.toJson(), gen(5)!.toJson());
      expect(gen(5)!.toJson(), isNot(gen(6)!.toJson()));
    });

    test('plain levels are always solvable (reverse placement)', () {
      for (var seed = 0; seed < 150; seed++) {
        final level = gen(seed);
        expect(level, isNotNull, reason: 'seed $seed');
        expect(Solver(level!).solve(), isNotNull, reason: 'seed $seed');
      }
    });

    test('pieces stay inside the shape mask', () {
      for (var seed = 0; seed < 40; seed++) {
        final level = gen(seed)!;
        for (final p in level.pieces) {
          for (final c in p.cells) {
            expect(level.mask[c], isTrue);
          }
        }
      }
    });

    for (final (name, m) in [
      ('lights', const MechanicSet(lights: 2)),
      ('gates', const MechanicSet(gates: 2)),
      ('ambulance', const MechanicSet(ambulance: true)),
      ('everything', const MechanicSet(lights: 2, gates: 2, ambulance: true)),
    ]) {
      test('$name levels are solvable and contain the mechanic', () {
        var produced = 0;
        for (var seed = 0; seed < 80; seed++) {
          final level = gen(seed, m: m, cells: 50);
          if (level == null) continue;
          produced++;
          expect(Solver(level).solve(), isNotNull, reason: 'seed $seed');
          if (m.ambulance) expect(level.hasAmbulance, isTrue);
        }
        expect(produced, greaterThan(40), reason: 'too many failed seeds');
      });
    }

    test('every gate is on some vehicle path', () {
      for (var seed = 0; seed < 60; seed++) {
        final level = gen(seed, m: const MechanicSet(gates: 3), cells: 50);
        if (level == null) continue;
        final rules = Rules(level);
        for (final g in level.gates) {
          expect(
            [for (var i = 0; i < rules.pieceCount; i++) ...rules.pathOf(i)],
            contains(g.cell),
            reason: 'seed $seed',
          );
        }
      }
    });
  });

  group('analyzeLevel', () {
    test('null for unsolvable', () {
      expect(analyzeLevel(parseAsciiLevel('>.<')), isNull);
    });

    test('a chain is deeper and harder than free cars', () {
      final free = analyzeLevel(
        parseAsciiLevel('''
^^^^
....
vvvv
'''),
      )!;
      final chain = analyzeLevel(
        parseAsciiLevel('''
>>>>
^...
^...
'''),
      )!;
      expect(free.depth, 1);
      expect(chain.depth, greaterThan(free.depth));
      expect(chain.difficulty, greaterThan(free.difficulty));
      expect(free.minMoves, 8);
      expect(free.blockedFraction, 0);
    });

    test('ambulance waiting is not counted as blocked', () {
      final level = parseAsciiLevel(
        '''
...
.^.
v..
''',
        vehicles: [
          (kind: PieceKind.ambulance, dir: Dir.right, cells: [(0, 1)]),
        ],
      );
      expect(analyzeLevel(level)!.blockedFraction, closeTo(1 / 3, 1e-9));
    });
  });

  group('Campaign', () {
    test('no easier breather levels', () {
      for (var n = 1; n <= 1500; n++) {
        expect(Campaign.isBreather(n), isFalse);
      }
    });

    test('solve effort target rises every regular level', () {
      // Gentle start after the tutorial, then the main curve from L21.
      expect(Campaign.effortTarget(2), 60);
      expect(Campaign.effortTarget(3), 100);
      expect(Campaign.effortTarget(9), 440); // Hard
      expect(Campaign.effortTarget(21), greaterThan(Campaign.effortTarget(20)));
      expect(Campaign.effortTarget(8), greaterThan(Campaign.effortTarget(5)));
      expect(Campaign.effortTarget(1500), greaterThan(800));
      var last = 0.0;
      for (var n = 2; n <= 1500; n++) {
        if (Campaign.tierFor(n) != LevelTier.normal) {
          // Hard levels spike above their neighbours.
          expect(
            Campaign.effortTarget(n),
            greaterThan(Campaign.effortTarget(n - 1)),
          );
          continue;
        }
        expect(Campaign.effortTarget(n), greaterThan(last), reason: 'L$n');
        last = Campaign.effortTarget(n);
      }
    });

    test('mechanics only after they unlock, and right after their intro', () {
      for (var n = 1; n <= 400; n++) {
        if (Campaign.handmade.containsKey(n)) continue;
        final m = Campaign.spec(n).mechanics;
        if (n < MechanicUnlocks.trafficLights) expect(m.lights, 0);
        if (n < MechanicUnlocks.gates) expect(m.gates, 0);
        if (n < MechanicUnlocks.ambulance) expect(m.ambulance, isFalse);
      }
      // The unlock level itself shows the new mechanic.
      expect(
        Campaign.spec(MechanicUnlocks.trafficLights).mechanics.lights,
        greaterThan(0),
      );
      expect(
        Campaign.spec(MechanicUnlocks.trafficLights + 2).mechanics.lights,
        greaterThan(0),
      );
      expect(Campaign.spec(MechanicUnlocks.gates + 3).mechanics.gates, 1);
      expect(
        Campaign.spec(MechanicUnlocks.ambulance + 4).mechanics.ambulance,
        isTrue,
      );
    });

    test('level 1 is the hand-made tutorial', () {
      final l = Campaign.build(1);
      expect(l.id, 1);
      expect(l.pieces, tutorialLevel.pieces);
    });

    test('tiers: hard on 9s, super hard every 50th, from level 9', () {
      expect(Campaign.tierFor(8), LevelTier.normal);
      expect(Campaign.tierFor(9), LevelTier.hard);
      expect(Campaign.tierFor(19), LevelTier.hard);
      expect(Campaign.tierFor(49), LevelTier.superHard);
      expect(Campaign.tierFor(99), LevelTier.superHard);
      expect(Campaign.tierFor(20), LevelTier.normal);
      expect(Campaign.effortTarget(29), greaterThan(Campaign.effortTarget(28)));
      expect(Campaign.effortTarget(49), greaterThan(Campaign.effortTarget(39)));
      expect(Campaign.build(29).meta.tier, LevelTier.hard);
      expect(LevelTier.superHard.rewardMultiplier, 3);
    });

    test('generated arrows are long and fill the board', () {
      for (final n in [30, 300, 900]) {
        final l = Campaign.build(n);
        final cells = l.pieces.fold<int>(0, (a, p) => a + p.length);
        expect(cells / l.pieces.length, greaterThan(2.2), reason: 'L$n');
        expect(
          cells / l.mask.where((m) => m).length,
          greaterThan(0.6),
          reason: 'L$n coverage',
        );
        for (final p in l.pieces) {
          if (p.kind == PieceKind.car) {
            expect(p.length, greaterThanOrEqualTo(2), reason: 'L$n');
          }
        }
      }
    });

    test('build is deterministic and takes about the planned effort', () {
      for (final n in [7, 33, 250, 900]) {
        final a = Campaign.build(n);
        expect(a.toJson(), Campaign.build(n).toJson());
        expect(a.id, n);
        final want = Campaign.effortTarget(n);
        final got = analyzeLevel(a, maxStates: 60000)!.effort;
        expect(got, inInclusiveRange(want * 0.85, want * 1.15), reason: 'L$n');
        expect(a.width, lessThanOrEqualTo(maxArrowBoardWidth));
        expect(a.height, lessThanOrEqualTo(maxArrowBoardHeight));
      }
    });

    test('boards mix very short, short, long and very long arrows', () {
      final l = Campaign.build(300);
      final lens = [for (final p in l.pieces) p.length];
      expect(lens.where((x) => x == 2), isNotEmpty);
      expect(lens.where((x) => x >= 3 && x <= 4), isNotEmpty);
      expect(lens.where((x) => x >= 5 && x <= 9), isNotEmpty);
      expect(lens.where((x) => x >= 10), isNotEmpty);
    });

    test('pack codec round trip', () {
      final levels = [Campaign.build(4), Campaign.build(140)];
      final back = decodeLevelPack(encodeLevelPack(levels));
      expect(
        [for (final l in back) l.toJson()],
        [for (final l in levels) l.toJson()],
      );
      expect(Campaign.packOf(1), 1);
      expect(Campaign.packOf(100), 1);
      expect(Campaign.packOf(101), 2);
      expect(Campaign.packFile(3), 'pack_03.json.gz');
      expect(Campaign.packCount, 15);
    });
  });

  group('DailyChallenge', () {
    test('same date gives the same level, other dates differ', () {
      final a = DailyChallenge.levelFor(DateTime(2026, 10, 29, 8));
      final b = DailyChallenge.levelFor(DateTime(2026, 10, 29, 23, 59));
      final c = DailyChallenge.levelFor(DateTime(2026, 10, 30));
      expect(a.toJson(), b.toJson());
      expect(a.toJson(), isNot(c.toJson()));
      expect(a.id, 20261029);
    });

    test('a year of dailies is solvable and takes the planned effort', () {
      var day = DateTime(2027, 1, 1);
      for (var i = 0; i < 20; i++) {
        final level = DailyChallenge.levelFor(day);
        final want = DailyChallenge.effortFor(day);
        final got = analyzeLevel(level, maxStates: 60000)?.effort;
        expect(got, isNotNull, reason: '$day');
        expect(got, inInclusiveRange(want * 0.75, want * 1.25), reason: '$day');
        day = day.add(const Duration(days: 19)); // walk all weekdays
      }
    });

    test('golden dailies: generator changes that alter past dailies fail '
        'here (bump DailyChallenge.version on purpose instead)', () {
      int hashOf(DateTime d) =>
          stableHash(jsonEncode(DailyChallenge.levelFor(d).toJson()));
      expect(hashOf(DateTime(2026, 10, 29)), 1026247464);
      expect(hashOf(DateTime(2027, 3, 14)), 2033023680);
    });

    test('keys', () {
      final d = DateTime(2026, 3, 7);
      expect(DailyChallenge.keyFor(d), '2026-03-07');
      expect(DailyChallenge.parseKey('2026-03-07'), d);
      expect(() => DailyChallenge.parseKey('x'), throwsFormatException);
      // Weekday Nov 2: 85 arrows; Sunday Nov 1: weekend bonus.
      expect(DailyChallenge.arrowsFor(DateTime(2026, 11, 2)), 85);
      expect(DailyChallenge.arrowsFor(DateTime(2026, 11, 1)), 91);
      // Every day takes a little longer than the day before (weekdays),
      // and far longer than campaign level 100.
      var day = DateTime(2026, 11, 2);
      for (var i = 0; i < 4; i++) {
        final next = day.add(const Duration(days: 1));
        expect(
          DailyChallenge.effortFor(next),
          greaterThan(DailyChallenge.effortFor(day)),
        );
        day = next;
      }
      expect(
        DailyChallenge.effortFor(DateTime(2026, 11, 2)),
        greaterThan(Campaign.effortTarget(100)),
      );
    });
  });

  test('no same-way queues or rows of parallel heads', () {
    for (final level in [
      Campaign.build(3),
      Campaign.build(11),
      Campaign.build(260),
      DailyChallenge.levelFor(DateTime(2026, 11, 3)),
    ]) {
      final at = <int, PieceDef>{
        for (final p in level.pieces)
          for (final c in p.cells) c: p,
      };
      int? next(int c, Dir d) {
        final x = level.xOf(c) + d.dx, y = level.yOf(c) + d.dy;
        return level.inBounds(x, y) ? level.indexOf(x, y) : null;
      }

      for (final p in level.pieces) {
        if (p.kind == PieceKind.ambulance) continue;
        // Nothing pointing the same way right in front of a head…
        final f = next(p.head, p.dir);
        expect(at[f]?.dir == p.dir, isFalse, reason: 'queue L${level.id}');
        // …and no same-way head right beside it.
        for (final side in [p.dir.clockwise, p.dir.counterClockwise]) {
          final s = next(p.head, side);
          final o = at[s];
          expect(
            o != null && o.head == s && o.dir == p.dir,
            isFalse,
            reason: 'row L${level.id}',
          );
        }
      }
    }
  });

  test('every arrow runs straight into its head (no turn at the head)', () {
    for (final n in [3, 11, 60, 250]) {
      final level = Campaign.build(n);
      for (final p in level.pieces) {
        if (p.cells.length < 2) continue;
        final behind = p.cells[1];
        final dx = level.xOf(p.head) - level.xOf(behind);
        final dy = level.yOf(p.head) - level.yOf(behind);
        expect((dx, dy), (p.dir.dx, p.dir.dy), reason: 'L$n');
      }
    }
  });
}

const _goldenRng = <int>[3898016280, 503430273, 2109199260];
