import 'package:arrow_engine/arrow_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of campaign levels, numbered from 1.
abstract interface class LevelRepository {
  int get count;
  Future<Level> load(int number);
}

/// The hand-made starter levels. Phase 2 replaces this with the generated,
/// gzip-compressed asset packs.
class SampleLevelRepository implements LevelRepository {
  const SampleLevelRepository();

  @override
  int get count => sampleLevels.length;

  @override
  Future<Level> load(int number) async {
    if (number < 1 || number > count) {
      throw RangeError.range(number, 1, count, 'level');
    }
    return sampleLevels[number - 1];
  }
}

final levelRepositoryProvider = Provider<LevelRepository>(
  (ref) => const SampleLevelRepository(),
);

final levelProvider = FutureProvider.autoDispose.family<Level, int>(
  (ref, number) => ref.watch(levelRepositoryProvider).load(number),
);
