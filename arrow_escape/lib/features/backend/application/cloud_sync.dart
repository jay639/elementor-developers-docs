import 'dart:async';

import 'package:arrow_escape/features/backend/data/backend.dart';
import 'package:arrow_escape/features/backend/domain/save_merge.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/save/domain/save_data.dart';

/// Keeps the local save and the cloud copy in step: merge once at start,
/// then push changes (debounced) as they happen.
class CloudSync {
  CloudSync({
    required this.uid,
    required this.cloud,
    required this.controller,
    this.debounce = const Duration(seconds: 5),
  });

  final String uid;
  final CloudSaveService cloud;
  final SaveController controller;
  final Duration debounce;

  StreamSubscription<SaveData>? _sub;
  Timer? _timer;
  SaveData? _lastPushed;

  Future<void> start() async {
    final remote = await cloud.fetch(uid);
    final local = controller.current;
    final merged = remote == null ? local : mergeSaves(local, remote);
    if (merged != local) controller.replace(merged);
    if (merged != remote) await _push(merged);
    _sub = controller.changes.listen((save) {
      _timer?.cancel();
      _timer = Timer(debounce, () => _push(save));
    });
  }

  Future<void> _push(SaveData save) async {
    if (save == _lastPushed) return;
    _lastPushed = save;
    await cloud.push(uid, save);
  }

  /// Pushes anything pending right away (app going to background).
  /// Compares against what was last pushed rather than a pending timer:
  /// change events arrive asynchronously, so a change made just before
  /// pausing may not have started its timer yet.
  Future<void> flush() async {
    _timer?.cancel();
    await _push(controller.current);
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _sub?.cancel();
  }
}
