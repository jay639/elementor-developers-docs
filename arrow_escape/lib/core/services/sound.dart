import 'dart:async';

import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Sfx {
  swoosh('sounds/swoosh.wav', 4),

  /// Wrong move: a clear two-tone buzz (a heart is lost).
  error('sounds/error.wav', 2),
  tap('sounds/tap.wav', 2),
  win('sounds/win.wav', 1),
  lose('sounds/lose.wav', 1);

  const Sfx(this.asset, this.voices);

  final String asset;

  /// How many copies may overlap (quick successive exits).
  final int voices;
}

abstract interface class SoundService {
  void play(Sfx sfx);

  /// Loads the effects ahead of time so the first tap isn't late.
  void warmUp();

  Future<void> dispose();
}

class SilentSoundService implements SoundService {
  const SilentSoundService();

  @override
  void play(Sfx sfx) {}

  @override
  void warmUp() {}

  @override
  Future<void> dispose() async {}
}

/// Low-latency pooled players. Pools load lazily on first use so start-up
/// stays fast, and any audio failure is swallowed: sound is never worth a
/// crash.
class PooledSoundService implements SoundService {
  PooledSoundService(this._enabled);

  final bool Function() _enabled;
  final _pools = <Sfx, Future<AudioPool?>>{};

  Future<AudioPool?> _pool(Sfx sfx) => _pools.putIfAbsent(sfx, () async {
    try {
      return await AudioPool.createFromAsset(
        path: sfx.asset,
        maxPlayers: sfx.voices,
      );
    } catch (e) {
      debugPrint('Sound ${sfx.name} unavailable: $e');
      return null;
    }
  });

  @override
  void warmUp() {
    if (!_enabled()) return;
    for (final sfx in Sfx.values) {
      _pool(sfx).ignore();
    }
  }

  @override
  void play(Sfx sfx) {
    if (!_enabled()) return;
    unawaited(() async {
      try {
        await (await _pool(sfx))?.start(volume: 0.7);
      } catch (e) {
        debugPrint('Sound ${sfx.name} failed: $e');
      }
    }());
  }

  @override
  Future<void> dispose() async {
    for (final pool in _pools.values) {
      await (await pool)?.dispose();
    }
    _pools.clear();
  }
}

final soundProvider = Provider<SoundService>((ref) {
  final service = PooledSoundService(() => ref.read(settingsProvider).sound);
  ref.onDispose(service.dispose);
  return service;
});
