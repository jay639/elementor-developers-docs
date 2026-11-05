// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

 ThemeMode get themeMode; bool get thickArrows; bool get highContrast; bool get colorblind; bool get haptics; bool get sound; bool get reduceMotion;/// "Share usage analytics": anonymous gameplay stats.
 bool get shareAnalytics;/// Reminder notifications (7:30 PM local) and pushes from Firebase.
 bool get reminders;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.themeMode, _this.themeMode) || other.themeMode == _this.themeMode)&&(identical(other.thickArrows, _this.thickArrows) || other.thickArrows == _this.thickArrows)&&(identical(other.highContrast, _this.highContrast) || other.highContrast == _this.highContrast)&&(identical(other.colorblind, _this.colorblind) || other.colorblind == _this.colorblind)&&(identical(other.haptics, _this.haptics) || other.haptics == _this.haptics)&&(identical(other.sound, _this.sound) || other.sound == _this.sound)&&(identical(other.reduceMotion, _this.reduceMotion) || other.reduceMotion == _this.reduceMotion)&&(identical(other.shareAnalytics, _this.shareAnalytics) || other.shareAnalytics == _this.shareAnalytics)&&(identical(other.reminders, _this.reminders) || other.reminders == _this.reminders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hash(runtimeType,_this.themeMode,_this.thickArrows,_this.highContrast,_this.colorblind,_this.haptics,_this.sound,_this.reduceMotion,_this.shareAnalytics,_this.reminders);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(themeMode: ${_this.themeMode}, thickArrows: ${_this.thickArrows}, highContrast: ${_this.highContrast}, colorblind: ${_this.colorblind}, haptics: ${_this.haptics}, sound: ${_this.sound}, reduceMotion: ${_this.reduceMotion}, shareAnalytics: ${_this.shareAnalytics}, reminders: ${_this.reminders})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 ThemeMode themeMode, bool thickArrows, bool highContrast, bool colorblind, bool haptics, bool sound, bool reduceMotion, bool shareAnalytics, bool reminders
});




}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeMode = null,Object? thickArrows = null,Object? highContrast = null,Object? colorblind = null,Object? haptics = null,Object? sound = null,Object? reduceMotion = null,Object? shareAnalytics = null,Object? reminders = null,}) {
  return _then(AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,thickArrows: null == thickArrows ? _self.thickArrows : thickArrows // ignore: cast_nullable_to_non_nullable
as bool,highContrast: null == highContrast ? _self.highContrast : highContrast // ignore: cast_nullable_to_non_nullable
as bool,colorblind: null == colorblind ? _self.colorblind : colorblind // ignore: cast_nullable_to_non_nullable
as bool,haptics: null == haptics ? _self.haptics : haptics // ignore: cast_nullable_to_non_nullable
as bool,sound: null == sound ? _self.sound : sound // ignore: cast_nullable_to_non_nullable
as bool,reduceMotion: null == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool,shareAnalytics: null == shareAnalytics ? _self.shareAnalytics : shareAnalytics // ignore: cast_nullable_to_non_nullable
as bool,reminders: null == reminders ? _self.reminders : reminders // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeMode themeMode,  bool thickArrows,  bool highContrast,  bool colorblind,  bool haptics,  bool sound,  bool reduceMotion,  bool shareAnalytics,  bool reminders)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.thickArrows,_that.highContrast,_that.colorblind,_that.haptics,_that.sound,_that.reduceMotion,_that.shareAnalytics,_that.reminders);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeMode themeMode,  bool thickArrows,  bool highContrast,  bool colorblind,  bool haptics,  bool sound,  bool reduceMotion,  bool shareAnalytics,  bool reminders)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.themeMode,_that.thickArrows,_that.highContrast,_that.colorblind,_that.haptics,_that.sound,_that.reduceMotion,_that.shareAnalytics,_that.reminders);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeMode themeMode,  bool thickArrows,  bool highContrast,  bool colorblind,  bool haptics,  bool sound,  bool reduceMotion,  bool shareAnalytics,  bool reminders)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.themeMode,_that.thickArrows,_that.highContrast,_that.colorblind,_that.haptics,_that.sound,_that.reduceMotion,_that.shareAnalytics,_that.reminders);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings implements AppSettings {
  const _AppSettings({this.themeMode = ThemeMode.system, this.thickArrows = false, this.highContrast = false, this.colorblind = false, this.haptics = true, this.sound = true, this.reduceMotion = false, this.shareAnalytics = true, this.reminders = true});
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

@override@JsonKey() final  ThemeMode themeMode;
@override@JsonKey() final  bool thickArrows;
@override@JsonKey() final  bool highContrast;
@override@JsonKey() final  bool colorblind;
@override@JsonKey() final  bool haptics;
@override@JsonKey() final  bool sound;
@override@JsonKey() final  bool reduceMotion;
/// "Share usage analytics": anonymous gameplay stats.
@override@JsonKey() final  bool shareAnalytics;
/// Reminder notifications (7:30 PM local) and pushes from Firebase.
@override@JsonKey() final  bool reminders;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.thickArrows, thickArrows) || other.thickArrows == thickArrows)&&(identical(other.highContrast, highContrast) || other.highContrast == highContrast)&&(identical(other.colorblind, colorblind) || other.colorblind == colorblind)&&(identical(other.haptics, haptics) || other.haptics == haptics)&&(identical(other.sound, sound) || other.sound == sound)&&(identical(other.reduceMotion, reduceMotion) || other.reduceMotion == reduceMotion)&&(identical(other.shareAnalytics, shareAnalytics) || other.shareAnalytics == shareAnalytics)&&(identical(other.reminders, reminders) || other.reminders == reminders));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,themeMode,thickArrows,highContrast,colorblind,haptics,sound,reduceMotion,shareAnalytics,reminders);
}

@override
String toString() {
    return 'AppSettings(themeMode: $themeMode, thickArrows: $thickArrows, highContrast: $highContrast, colorblind: $colorblind, haptics: $haptics, sound: $sound, reduceMotion: $reduceMotion, shareAnalytics: $shareAnalytics, reminders: $reminders)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 ThemeMode themeMode, bool thickArrows, bool highContrast, bool colorblind, bool haptics, bool sound, bool reduceMotion, bool shareAnalytics, bool reminders
});




}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? thickArrows = null,Object? highContrast = null,Object? colorblind = null,Object? haptics = null,Object? sound = null,Object? reduceMotion = null,Object? shareAnalytics = null,Object? reminders = null,}) {
  return _then(_AppSettings(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,thickArrows: null == thickArrows ? _self.thickArrows : thickArrows // ignore: cast_nullable_to_non_nullable
as bool,highContrast: null == highContrast ? _self.highContrast : highContrast // ignore: cast_nullable_to_non_nullable
as bool,colorblind: null == colorblind ? _self.colorblind : colorblind // ignore: cast_nullable_to_non_nullable
as bool,haptics: null == haptics ? _self.haptics : haptics // ignore: cast_nullable_to_non_nullable
as bool,sound: null == sound ? _self.sound : sound // ignore: cast_nullable_to_non_nullable
as bool,reduceMotion: null == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool,shareAnalytics: null == shareAnalytics ? _self.shareAnalytics : shareAnalytics // ignore: cast_nullable_to_non_nullable
as bool,reminders: null == reminders ? _self.reminders : reminders // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
