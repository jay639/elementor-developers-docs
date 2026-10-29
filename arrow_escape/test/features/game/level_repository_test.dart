import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/data/level_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts asset loads so caching can be checked.
class CountingBundle extends CachingAssetBundle {
  final loads = <String>[];

  @override
  Future<ByteData> load(String key) {
    loads.add(key);
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads shipped levels with matching ids', () async {
    final repo = AssetLevelRepository();
    expect(repo.count, 1500);
    for (final n in [1, 100, 101, 777, 1500]) {
      final level = await repo.load(n);
      expect(level.id, n);
      expect(level.meta.breather, Campaign.isBreather(n));
    }
  });

  test('shipped level 1 is the hand-made tutorial', () async {
    final level = await AssetLevelRepository().load(1);
    expect(level.pieces, Campaign.handmade[1]!.pieces);
  });

  test('every level in a shipped pack is solvable', () async {
    final repo = AssetLevelRepository();
    for (var n = 1401; n <= 1500; n++) {
      expect(Solver(await repo.load(n)).solve(), isNotNull, reason: 'L$n');
    }
  });

  test('packs are cached and evicted least-recently-used', () async {
    final bundle = CountingBundle();
    final repo = AssetLevelRepository(bundle: bundle, cachedPacks: 2);
    await repo.load(1);
    await repo.load(50); // same pack
    expect(bundle.loads, hasLength(1));
    await repo.load(150);
    await repo.load(250); // evicts pack 1
    await repo.load(1);
    expect(bundle.loads, hasLength(4));
  });

  test('rejects out-of-range numbers', () {
    final repo = AssetLevelRepository();
    expect(() => repo.load(0), throwsRangeError);
    expect(() => repo.load(1501), throwsRangeError);
  });

  test('daily generation off the UI thread matches the engine', () async {
    final level = await generateDailyLevel('2026-10-29');
    expect(
      level.toJson(),
      DailyChallenge.levelFor(DateTime(2026, 10, 29)).toJson(),
    );
  });
}
