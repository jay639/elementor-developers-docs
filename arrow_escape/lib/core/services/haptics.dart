import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HapticKind { tap, exit, bump, win, lose }

abstract interface class HapticsService {
  void play(HapticKind kind);
}

/// Platform haptics, silenced when the player turns them off.
class PlatformHaptics implements HapticsService {
  PlatformHaptics(this._enabled);

  final bool Function() _enabled;

  @override
  void play(HapticKind kind) {
    if (!_enabled()) return;
    final Future<void> f = switch (kind) {
      HapticKind.tap => HapticFeedback.selectionClick(),
      HapticKind.exit => HapticFeedback.lightImpact(),
      HapticKind.bump => HapticFeedback.heavyImpact(),
      HapticKind.win => HapticFeedback.mediumImpact(),
      HapticKind.lose => HapticFeedback.vibrate(),
    };
    f.ignore();
  }
}

final hapticsProvider = Provider<HapticsService>(
  (ref) => PlatformHaptics(() => ref.read(settingsProvider).haptics),
);
