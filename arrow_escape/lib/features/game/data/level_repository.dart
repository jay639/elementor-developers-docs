import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:isolate';

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/features/game/domain/level_ref.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of campaign levels, numbered from 1.
abstract interface class LevelRepository {
  int get count;
  Future<Level> load(int number);
}

/// Reads the generated, gzip-compressed packs in `assets/levels/`
/// (see `tool/bin/generate_levels.dart`). Packs are decoded on a background
/// isolate and the few most recent are kept in memory.
class AssetLevelRepository implements LevelRepository {
  AssetLevelRepository({AssetBundle? bundle, this.cachedPacks = 3})
    : _bundle = bundle ?? rootBundle;

  static const dir = 'assets/levels';

  final AssetBundle _bundle;
  final int cachedPacks;

  /// Decoded packs, most recently used last.
  final _loaded = <int, List<Level>>{};

  /// Decodes in flight, so concurrent loads of one pack share the work.
  final _pending = <int, Future<List<Level>>>{};

  @override
  int get count => Campaign.levelCount;

  @override
  Future<Level> load(int number) async {
    if (number < 1 || number > count) {
      throw RangeError.range(number, 1, count, 'level');
    }
    final pack = Campaign.packOf(number);
    final levels = _loaded.remove(pack) ?? await _fetch(pack);
    _loaded[pack] = levels;
    while (_loaded.length > cachedPacks) {
      _loaded.remove(_loaded.keys.first);
    }
    final level = levels[(number - 1) % Campaign.packSize];
    if (level.id != number) {
      throw StateError('Pack $pack is out of order: ${level.id} != $number');
    }
    return level;
  }

  Future<List<Level>> _fetch(int pack) =>
      _pending[pack] ??= _decode(pack).whenComplete(() {
        // Block body on purpose: returning the removed future (which is this
        // very future) would make whenComplete wait on itself forever.
        _pending.remove(pack);
      });

  Future<List<Level>> _decode(int pack) async {
    final data = await _bundle.load('$dir/${Campaign.packFile(pack)}');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    return decodeLevelPack(await _gunzipOnIsolate(bytes));
  }
}

/// Top-level so the isolate closure captures only [bytes], never the
/// repository.
Future<String> _gunzipOnIsolate(Uint8List bytes) =>
    Isolate.run(() => utf8.decode(gzip.decode(bytes)));

final levelRepositoryProvider = Provider<LevelRepository>(
  (ref) => AssetLevelRepository(),
);

/// Generates the daily challenge off the UI thread.
Future<Level> generateDailyLevel(String dateKey) async {
  final json = await Isolate.run(
    () => jsonEncode(
      DailyChallenge.levelFor(DailyChallenge.parseKey(dateKey)).toJson(),
    ),
  );
  return Level.fromJson((jsonDecode(json) as Map).cast<String, Object?>());
}

/// Overridable so tests can skip the isolate.
final dailyLevelGeneratorProvider =
    Provider<Future<Level> Function(String dateKey)>(
      (ref) => generateDailyLevel,
    );

final levelProvider = FutureProvider.autoDispose.family<Level, LevelRef>(
  (ref, levelRef) => switch (levelRef) {
    CampaignLevelRef(:final number) =>
      ref.watch(levelRepositoryProvider).load(number),
    DailyLevelRef(:final dateKey) => ref.watch(dailyLevelGeneratorProvider)(
      dateKey,
    ),
  },
);
