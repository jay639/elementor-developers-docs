// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SaveData {

 Progress get progress; int get coins; List<String> get ownedSkins; String get selectedSkin;/// Consecutive days with at least one win.
 int get streak;/// `yyyy-mm-dd` of the last day with a win.
 String? get lastWinDay;/// Consecutive days the daily reward was claimed (drives the amount).
 int get rewardStreak;/// `yyyy-mm-dd` of the last daily-reward claim.
 String? get lastRewardDay; AppSettings get settings;/// Non-consumable bundles whose one-time perks (coins, skin) were
/// granted, so restores on a new device don't grant them twice.
 List<String> get claimedBundles;/// Set once this install's save has been merged with the cloud copy.
 bool get cloudSynced;/// Bumped on every change; used when merging with the cloud copy.
 int get revision;/// Milliseconds since epoch of the last change.
 int get updatedAt;
/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveDataCopyWith<SaveData> get copyWith => _$SaveDataCopyWithImpl<SaveData>(this as SaveData, _$identity);

  /// Serializes this SaveData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SaveData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveData&&(identical(other.progress, _this.progress) || other.progress == _this.progress)&&(identical(other.coins, _this.coins) || other.coins == _this.coins)&&const DeepCollectionEquality().equals(other.ownedSkins, _this.ownedSkins)&&(identical(other.selectedSkin, _this.selectedSkin) || other.selectedSkin == _this.selectedSkin)&&(identical(other.streak, _this.streak) || other.streak == _this.streak)&&(identical(other.lastWinDay, _this.lastWinDay) || other.lastWinDay == _this.lastWinDay)&&(identical(other.rewardStreak, _this.rewardStreak) || other.rewardStreak == _this.rewardStreak)&&(identical(other.lastRewardDay, _this.lastRewardDay) || other.lastRewardDay == _this.lastRewardDay)&&(identical(other.settings, _this.settings) || other.settings == _this.settings)&&const DeepCollectionEquality().equals(other.claimedBundles, _this.claimedBundles)&&(identical(other.cloudSynced, _this.cloudSynced) || other.cloudSynced == _this.cloudSynced)&&(identical(other.revision, _this.revision) || other.revision == _this.revision)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SaveData;
  return Object.hash(runtimeType,_this.progress,_this.coins,const DeepCollectionEquality().hash(_this.ownedSkins),_this.selectedSkin,_this.streak,_this.lastWinDay,_this.rewardStreak,_this.lastRewardDay,_this.settings,const DeepCollectionEquality().hash(_this.claimedBundles),_this.cloudSynced,_this.revision,_this.updatedAt);
}

@override
String toString() {
  final _this = this as SaveData;
  return 'SaveData(progress: ${_this.progress}, coins: ${_this.coins}, ownedSkins: ${_this.ownedSkins}, selectedSkin: ${_this.selectedSkin}, streak: ${_this.streak}, lastWinDay: ${_this.lastWinDay}, rewardStreak: ${_this.rewardStreak}, lastRewardDay: ${_this.lastRewardDay}, settings: ${_this.settings}, claimedBundles: ${_this.claimedBundles}, cloudSynced: ${_this.cloudSynced}, revision: ${_this.revision}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $SaveDataCopyWith<$Res>  {
  factory $SaveDataCopyWith(SaveData value, $Res Function(SaveData) _then) = _$SaveDataCopyWithImpl;
@useResult
$Res call({
 Progress progress, int coins, List<String> ownedSkins, String selectedSkin, int streak, String? lastWinDay, int rewardStreak, String? lastRewardDay, AppSettings settings, List<String> claimedBundles, bool cloudSynced, int revision, int updatedAt
});


$ProgressCopyWith<$Res> get progress;$AppSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$SaveDataCopyWithImpl<$Res>
    implements $SaveDataCopyWith<$Res> {
  _$SaveDataCopyWithImpl(this._self, this._then);

  final SaveData _self;
  final $Res Function(SaveData) _then;

/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? progress = null,Object? coins = null,Object? ownedSkins = null,Object? selectedSkin = null,Object? streak = null,Object? lastWinDay = freezed,Object? rewardStreak = null,Object? lastRewardDay = freezed,Object? settings = null,Object? claimedBundles = null,Object? cloudSynced = null,Object? revision = null,Object? updatedAt = null,}) {
  return _then(SaveData(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as Progress,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,ownedSkins: null == ownedSkins ? _self.ownedSkins : ownedSkins // ignore: cast_nullable_to_non_nullable
as List<String>,selectedSkin: null == selectedSkin ? _self.selectedSkin : selectedSkin // ignore: cast_nullable_to_non_nullable
as String,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,lastWinDay: freezed == lastWinDay ? _self.lastWinDay : lastWinDay // ignore: cast_nullable_to_non_nullable
as String?,rewardStreak: null == rewardStreak ? _self.rewardStreak : rewardStreak // ignore: cast_nullable_to_non_nullable
as int,lastRewardDay: freezed == lastRewardDay ? _self.lastRewardDay : lastRewardDay // ignore: cast_nullable_to_non_nullable
as String?,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as AppSettings,claimedBundles: null == claimedBundles ? _self.claimedBundles : claimedBundles // ignore: cast_nullable_to_non_nullable
as List<String>,cloudSynced: null == cloudSynced ? _self.cloudSynced : cloudSynced // ignore: cast_nullable_to_non_nullable
as bool,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressCopyWith<$Res> get progress {
  
  return $ProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<$Res> get settings {
  
  return $AppSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}


/// Adds pattern-matching-related methods to [SaveData].
extension SaveDataPatterns on SaveData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaveData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaveData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaveData value)  $default,){
final _that = this;
switch (_that) {
case _SaveData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaveData value)?  $default,){
final _that = this;
switch (_that) {
case _SaveData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Progress progress,  int coins,  List<String> ownedSkins,  String selectedSkin,  int streak,  String? lastWinDay,  int rewardStreak,  String? lastRewardDay,  AppSettings settings,  List<String> claimedBundles,  bool cloudSynced,  int revision,  int updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaveData() when $default != null:
return $default(_that.progress,_that.coins,_that.ownedSkins,_that.selectedSkin,_that.streak,_that.lastWinDay,_that.rewardStreak,_that.lastRewardDay,_that.settings,_that.claimedBundles,_that.cloudSynced,_that.revision,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Progress progress,  int coins,  List<String> ownedSkins,  String selectedSkin,  int streak,  String? lastWinDay,  int rewardStreak,  String? lastRewardDay,  AppSettings settings,  List<String> claimedBundles,  bool cloudSynced,  int revision,  int updatedAt)  $default,) {final _that = this;
switch (_that) {
case _SaveData():
return $default(_that.progress,_that.coins,_that.ownedSkins,_that.selectedSkin,_that.streak,_that.lastWinDay,_that.rewardStreak,_that.lastRewardDay,_that.settings,_that.claimedBundles,_that.cloudSynced,_that.revision,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Progress progress,  int coins,  List<String> ownedSkins,  String selectedSkin,  int streak,  String? lastWinDay,  int rewardStreak,  String? lastRewardDay,  AppSettings settings,  List<String> claimedBundles,  bool cloudSynced,  int revision,  int updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _SaveData() when $default != null:
return $default(_that.progress,_that.coins,_that.ownedSkins,_that.selectedSkin,_that.streak,_that.lastWinDay,_that.rewardStreak,_that.lastRewardDay,_that.settings,_that.claimedBundles,_that.cloudSynced,_that.revision,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SaveData extends SaveData {
  const _SaveData({this.progress = const Progress(), this.coins = 0,  List<String> ownedSkins = const <String>['classic'], this.selectedSkin = 'classic', this.streak = 0, this.lastWinDay, this.rewardStreak = 0, this.lastRewardDay, this.settings = const AppSettings(),  List<String> claimedBundles = const <String>[], this.cloudSynced = false, this.revision = 0, this.updatedAt = 0}): _ownedSkins = ownedSkins,_claimedBundles = claimedBundles,super._();
  factory _SaveData.fromJson(Map<String, dynamic> json) => _$SaveDataFromJson(json);

@override@JsonKey() final  Progress progress;
@override@JsonKey() final  int coins;
 final  List<String> _ownedSkins;
@override@JsonKey() List<String> get ownedSkins {
  if (_ownedSkins is EqualUnmodifiableListView) return _ownedSkins;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ownedSkins);
}

@override@JsonKey() final  String selectedSkin;
/// Consecutive days with at least one win.
@override@JsonKey() final  int streak;
/// `yyyy-mm-dd` of the last day with a win.
@override final  String? lastWinDay;
/// Consecutive days the daily reward was claimed (drives the amount).
@override@JsonKey() final  int rewardStreak;
/// `yyyy-mm-dd` of the last daily-reward claim.
@override final  String? lastRewardDay;
@override@JsonKey() final  AppSettings settings;
/// Non-consumable bundles whose one-time perks (coins, skin) were
/// granted, so restores on a new device don't grant them twice.
 final  List<String> _claimedBundles;
/// Non-consumable bundles whose one-time perks (coins, skin) were
/// granted, so restores on a new device don't grant them twice.
@override@JsonKey() List<String> get claimedBundles {
  if (_claimedBundles is EqualUnmodifiableListView) return _claimedBundles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_claimedBundles);
}

/// Set once this install's save has been merged with the cloud copy.
@override@JsonKey() final  bool cloudSynced;
/// Bumped on every change; used when merging with the cloud copy.
@override@JsonKey() final  int revision;
/// Milliseconds since epoch of the last change.
@override@JsonKey() final  int updatedAt;

/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveDataCopyWith<_SaveData> get copyWith => __$SaveDataCopyWithImpl<_SaveData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SaveDataToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveData&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.coins, coins) || other.coins == coins)&&const DeepCollectionEquality().equals(other.ownedSkins, _ownedSkins)&&(identical(other.selectedSkin, selectedSkin) || other.selectedSkin == selectedSkin)&&(identical(other.streak, streak) || other.streak == streak)&&(identical(other.lastWinDay, lastWinDay) || other.lastWinDay == lastWinDay)&&(identical(other.rewardStreak, rewardStreak) || other.rewardStreak == rewardStreak)&&(identical(other.lastRewardDay, lastRewardDay) || other.lastRewardDay == lastRewardDay)&&(identical(other.settings, settings) || other.settings == settings)&&const DeepCollectionEquality().equals(other.claimedBundles, _claimedBundles)&&(identical(other.cloudSynced, cloudSynced) || other.cloudSynced == cloudSynced)&&(identical(other.revision, revision) || other.revision == revision)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,progress,coins,const DeepCollectionEquality().hash(_ownedSkins),selectedSkin,streak,lastWinDay,rewardStreak,lastRewardDay,settings,const DeepCollectionEquality().hash(_claimedBundles),cloudSynced,revision,updatedAt);
}

@override
String toString() {
    return 'SaveData(progress: $progress, coins: $coins, ownedSkins: $ownedSkins, selectedSkin: $selectedSkin, streak: $streak, lastWinDay: $lastWinDay, rewardStreak: $rewardStreak, lastRewardDay: $lastRewardDay, settings: $settings, claimedBundles: $claimedBundles, cloudSynced: $cloudSynced, revision: $revision, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$SaveDataCopyWith<$Res> implements $SaveDataCopyWith<$Res> {
  factory _$SaveDataCopyWith(_SaveData value, $Res Function(_SaveData) _then) = __$SaveDataCopyWithImpl;
@override @useResult
$Res call({
 Progress progress, int coins, List<String> ownedSkins, String selectedSkin, int streak, String? lastWinDay, int rewardStreak, String? lastRewardDay, AppSettings settings, List<String> claimedBundles, bool cloudSynced, int revision, int updatedAt
});


@override $ProgressCopyWith<$Res> get progress;@override $AppSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class __$SaveDataCopyWithImpl<$Res>
    implements _$SaveDataCopyWith<$Res> {
  __$SaveDataCopyWithImpl(this._self, this._then);

  final _SaveData _self;
  final $Res Function(_SaveData) _then;

/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? progress = null,Object? coins = null,Object? ownedSkins = null,Object? selectedSkin = null,Object? streak = null,Object? lastWinDay = freezed,Object? rewardStreak = null,Object? lastRewardDay = freezed,Object? settings = null,Object? claimedBundles = null,Object? cloudSynced = null,Object? revision = null,Object? updatedAt = null,}) {
  return _then(_SaveData(
progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as Progress,coins: null == coins ? _self.coins : coins // ignore: cast_nullable_to_non_nullable
as int,ownedSkins: null == ownedSkins ? _self._ownedSkins : ownedSkins // ignore: cast_nullable_to_non_nullable
as List<String>,selectedSkin: null == selectedSkin ? _self.selectedSkin : selectedSkin // ignore: cast_nullable_to_non_nullable
as String,streak: null == streak ? _self.streak : streak // ignore: cast_nullable_to_non_nullable
as int,lastWinDay: freezed == lastWinDay ? _self.lastWinDay : lastWinDay // ignore: cast_nullable_to_non_nullable
as String?,rewardStreak: null == rewardStreak ? _self.rewardStreak : rewardStreak // ignore: cast_nullable_to_non_nullable
as int,lastRewardDay: freezed == lastRewardDay ? _self.lastRewardDay : lastRewardDay // ignore: cast_nullable_to_non_nullable
as String?,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as AppSettings,claimedBundles: null == claimedBundles ? _self._claimedBundles : claimedBundles // ignore: cast_nullable_to_non_nullable
as List<String>,cloudSynced: null == cloudSynced ? _self.cloudSynced : cloudSynced // ignore: cast_nullable_to_non_nullable
as bool,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgressCopyWith<$Res> get progress {
  
  return $ProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}/// Create a copy of SaveData
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<$Res> get settings {
  
  return $AppSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

// dart format on
