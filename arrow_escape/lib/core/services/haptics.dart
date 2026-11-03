import 'package:arrow_escape/features/settings/application/settings_controller.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
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
      // Wrong move and losing use the vibration motor directly: system
      // haptic feedback is silent when "touch feedback" is off, and these
      // must be felt. Double buzz for a wrong move, longer for a loss.
      HapticKind.bump => Vibration.vibrate(
        pattern: const [0, 70, 70, 110],
        intensities: const [0, 200, 0, 255],
      ),
      HapticKind.win => HapticFeedback.mediumImpact(),
      HapticKind.lose => Vibration.vibrate(duration: 350, amplitude: 255),
    };
    f.catchError((Object _) {}).ignore();
  }
}

final hapticsProvider = Provider<HapticsService>(
  (ref) => PlatformHaptics(() => ref.read(settingsProvider).haptics),
);
