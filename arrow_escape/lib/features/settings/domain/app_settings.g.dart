// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  themeMode:
      $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
      ThemeMode.system,
  thickArrows: json['thickArrows'] as bool? ?? false,
  highContrast: json['highContrast'] as bool? ?? false,
  colorblind: json['colorblind'] as bool? ?? false,
  haptics: json['haptics'] as bool? ?? true,
  sound: json['sound'] as bool? ?? true,
  reduceMotion: json['reduceMotion'] as bool? ?? false,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'thickArrows': instance.thickArrows,
      'highContrast': instance.highContrast,
      'colorblind': instance.colorblind,
      'haptics': instance.haptics,
      'sound': instance.sound,
      'reduceMotion': instance.reduceMotion,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
