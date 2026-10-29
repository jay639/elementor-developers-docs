import 'package:arrow_escape/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Storage for settings. Phase 3 swaps the in-memory default for the
/// encrypted Hive store.
abstract interface class SettingsStore {
  AppSettings load();
  Future<void> save(AppSettings settings);
}

class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([this._value = const AppSettings()]);

  AppSettings _value;

  @override
  AppSettings load() => _value;

  @override
  Future<void> save(AppSettings settings) async => _value = settings;
}

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => InMemorySettingsStore(),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(settingsStoreProvider).load();

  void _update(AppSettings next) {
    if (next == state) return;
    state = next;
    ref.read(settingsStoreProvider).save(next).ignore();
  }

  void setThemeMode(ThemeMode mode) => _update(state.copyWith(themeMode: mode));
  void setThickArrows(bool v) => _update(state.copyWith(thickArrows: v));
  void setHighContrast(bool v) => _update(state.copyWith(highContrast: v));
  void setColorblind(bool v) => _update(state.copyWith(colorblind: v));
  void setHaptics(bool v) => _update(state.copyWith(haptics: v));
  void setSound(bool v) => _update(state.copyWith(sound: v));
  void setReduceMotion(bool v) => _update(state.copyWith(reduceMotion: v));
}
