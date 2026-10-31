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
    test('breather every 5th level', () {
      expect(Campaign.isBreather(5), isTrue);
      expect(Campaign.isBreather(1500), isTrue);
      expect(Campaign.isBreather(7), isFalse);
    });

    test('target curve rises and breathers dip', () {
      // Warm-up at 2, hard from 3 on, still rising late.
      expect(Campaign.targetDifficulty(2), lessThan(50));
      expect(Campaign.targetDifficulty(3), greaterThan(50));
      expect(Campaign.targetDifficulty(1497), greaterThan(74));
      expect(
        Campaign.targetDifficulty(1001),
        greaterThan(Campaign.targetDifficulty(501)),
      );
      for (var n = 10; n <= 1500; n += 5) {
        expect(
          Campaign.targetDifficulty(n),
          lessThan(Campaign.targetDifficulty(n - 1)),
          reason: 'L$n',
        );
      }
      // Smooth: neighbours never jump much (ignoring breathers and tiers).
      bool special(int n) =>
          Campaign.isBreather(n) || Campaign.tierFor(n) != LevelTier.normal;
      // (The step from the warm-up level 2 to level 3 is deliberate.)
      for (var n = 4; n <= 1500; n++) {
        if (special(n) || special(n - 1)) continue;
        expect(
          (Campaign.targetDifficulty(n) - Campaign.targetDifficulty(n - 1))
              .abs(),
          lessThan(5.5),
        );
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
      expect(
        Campaign.targetDifficulty(29),
        greaterThan(Campaign.targetDifficulty(28)),
      );
      expect(
        Campaign.targetDifficulty(49),
        greaterThan(Campaign.targetDifficulty(39)),
      );
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

    test('build is deterministic and near target', () {
      for (final n in [7, 33, 250, 900]) {
        final a = Campaign.build(n);
        expect(a.toJson(), Campaign.build(n).toJson());
        expect(a.id, n);
        expect(
          (a.meta.difficulty - Campaign.targetDifficulty(n)).abs(),
          // Per-level spread is wide with long winding arrows; the shipped
          // campaign's averages are checked by tool/verify_levels.
          lessThan(35),
        );
      }
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

    test('a year of dailies is solvable and stays near its target', () {
      var day = DateTime(2027, 1, 1);
      for (var i = 0; i < 60; i++) {
        final level = DailyChallenge.levelFor(day);
        expect(Solver(level).solve(), isNotNull, reason: '$day');
        expect(
          (level.meta.difficulty - DailyChallenge.targetFor(day)).abs(),
          lessThan(35),
          reason: '$day',
        );
        day = day.add(const Duration(days: 6)); // walk all weekdays
      }
    });

    test('golden dailies: generator changes that alter past dailies fail '
        'here (bump DailyChallenge.version on purpose instead)', () {
      int hashOf(DateTime d) =>
          stableHash(jsonEncode(DailyChallenge.levelFor(d).toJson()));
      expect(hashOf(DateTime(2026, 10, 29)), 3609196452);
      expect(hashOf(DateTime(2027, 3, 14)), 1170252708);
    });

    test('keys', () {
      final d = DateTime(2026, 3, 7);
      expect(DailyChallenge.keyFor(d), '2026-03-07');
      expect(DailyChallenge.parseKey('2026-03-07'), d);
      expect(() => DailyChallenge.parseKey('x'), throwsFormatException);
      expect(DailyChallenge.targetFor(DateTime(2026, 11, 2)), closeTo(66.1, 1e-9));
      // Harder every day, and harder than campaign level 20.
      expect(
        DailyChallenge.targetFor(DateTime(2027, 2, 2)),
        greaterThan(DailyChallenge.targetFor(DateTime(2026, 11, 3))),
      );
      expect(
        DailyChallenge.targetFor(DateTime(2026, 11, 2)),
        greaterThan(Campaign.targetDifficulty(20)),
      );
    });
  });
}

const _goldenRng = <int>[3898016280, 503430273, 2109199260];
