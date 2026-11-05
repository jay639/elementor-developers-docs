import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(false) bool thickArrows,
    @Default(false) bool highContrast,
    @Default(false) bool colorblind,
    @Default(true) bool haptics,
    @Default(true) bool sound,
    @Default(false) bool reduceMotion,

    /// "Share usage analytics": anonymous gameplay stats.
    @Default(true) bool shareAnalytics,

    /// Reminder notifications (7:30 PM local) and pushes from Firebase.
    @Default(true) bool reminders,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, Object?> json) =>
      _$AppSettingsFromJson(json);
}
