import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// A level the player left part-way: which arrows already left (in order)
/// and the hearts left. Only the most recent unfinished level is kept.
@immutable
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.exits,
    required this.hearts,
    required this.mistakes,
  });

  /// Level label, e.g. `7`, `daily_2026-11-01`, `puzzle_leaf_2`.
  final String level;
  final List<int> exits;
  final int hearts;
  final int mistakes;

  Map<String, Object> toJson() => {
    'level': level,
    'exits': exits,
    'hearts': hearts,
    'mistakes': mistakes,
  };

  static LevelProgress? fromJson(Object? json) {
    if (json is! Map) return null;
    final level = json['level'];
    final exits = json['exits'];
    final hearts = json['hearts'];
    final mistakes = json['mistakes'];
    if (level is! String ||
        exits is! List ||
        hearts is! int ||
        mistakes is! int) {
      return null;
    }
    return LevelProgress(
      level: level,
      exits: [
        for (final e in exits)
          if (e is int) e,
      ],
      hearts: hearts,
      mistakes: mistakes,
    );
  }
}

/// Where an unfinished level is kept between app sessions. Local only:
/// it changes on every move, so it stays out of the cloud-synced save.
abstract interface class ResumeStore {
  LevelProgress? read(String level);
  void write(LevelProgress progress);
  void clear();
}

class InMemoryResumeStore implements ResumeStore {
  LevelProgress? _current;

  @override
  LevelProgress? read(String level) =>
      _current?.level == level ? _current : null;

  @override
  void write(LevelProgress progress) => _current = progress;

  @override
  void clear() => _current = null;
}

class HiveResumeStore implements ResumeStore {
  HiveResumeStore._(this._box);

  static const _boxName = 'arrow_resume';
  static const _key = 'current';

  final Box<String> _box;

  /// Call after `Hive.initFlutter()` (done by the save repository).
  static Future<HiveResumeStore> open() async {
    Box<String> box;
    try {
      box = await Hive.openBox<String>(_boxName);
    } catch (e) {
      debugPrint('Resume box unreadable, starting fresh: $e');
      await Hive.deleteBoxFromDisk(_boxName);
      box = await Hive.openBox<String>(_boxName);
    }
    return HiveResumeStore._(box);
  }

  @override
  LevelProgress? read(String level) {
    final raw = _box.get(_key);
    if (raw == null) return null;
    try {
      final p = LevelProgress.fromJson(jsonDecode(raw));
      return p?.level == level ? p : null;
    } on FormatException {
      return null;
    }
  }

  @override
  void write(LevelProgress progress) =>
      _box.put(_key, jsonEncode(progress.toJson())).ignore();

  @override
  void clear() => _box.delete(_key).ignore();
}

/// Overridden in bootstrap with the Hive store.
final resumeStoreProvider = Provider<ResumeStore>(
  (ref) => InMemoryResumeStore(),
);
