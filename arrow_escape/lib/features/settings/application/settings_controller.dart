import 'package:arrow_escape/core/services/analytics.dart';
import 'package:arrow_escape/features/save/application/save_controller.dart';
import 'package:arrow_escape/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// Settings live in the save document so they sync with it.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(saveProvider.select((s) => s.settings));

  void _update(AppSettings next) {
    if (next == state) return;
    final changed = {
      ...next
          .toJson()
          .entries
          .where((e) => state.toJson()[e.key] != e.value)
          .map((e) => e.key),
    };
    for (final key in changed) {
      ref.read(analyticsProvider).log('settings_change', {
        'setting': key,
        'value': '${next.toJson()[key]}',
      });
    }
    ref.read(saveProvider.notifier).updateSettings(next);
  }

  void setThemeMode(ThemeMode mode) => _update(state.copyWith(themeMode: mode));
  void setThickArrows(bool v) => _update(state.copyWith(thickArrows: v));
  void setHighContrast(bool v) => _update(state.copyWith(highContrast: v));
  void setColorblind(bool v) => _update(state.copyWith(colorblind: v));
  void setHaptics(bool v) => _update(state.copyWith(haptics: v));
  void setSound(bool v) => _update(state.copyWith(sound: v));
  void setReduceMotion(bool v) => _update(state.copyWith(reduceMotion: v));
  void setShareAnalytics(bool v) => _update(state.copyWith(shareAnalytics: v));
  void setReminders(bool v) => _update(state.copyWith(reminders: v));
}
