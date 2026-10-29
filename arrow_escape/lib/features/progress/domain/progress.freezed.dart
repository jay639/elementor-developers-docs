// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Progress {

/// Highest level the player may open (1-based).
 int get unlocked;/// Best star rating per completed level, keyed by level number.
 Map<int, int> get stars;/// Best stars per completed daily challenge, keyed by `yyyy-mm-dd`.
 Map<String, int> get dailyStars;
/// Create a copy of Progress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressCopyWith<Progress> get copyWith => _$ProgressCopyWithImpl<Progress>(this as Progress, _$identity);

  /// Serializes this Progress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Progress;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Progress&&(identical(other.unlocked, _this.unlocked) || other.unlocked == _this.unlocked)&&const DeepCollectionEquality().equals(other.stars, _this.stars)&&const DeepCollectionEquality().equals(other.dailyStars, _this.dailyStars));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Progress;
  return Object.hash(runtimeType,_this.unlocked,const DeepCollectionEquality().hash(_this.stars),const DeepCollectionEquality().hash(_this.dailyStars));
}

@override
String toString() {
  final _this = this as Progress;
  return 'Progress(unlocked: ${_this.unlocked}, stars: ${_this.stars}, dailyStars: ${_this.dailyStars})';
}


}

/// @nodoc
abstract mixin class $ProgressCopyWith<$Res>  {
  factory $ProgressCopyWith(Progress value, $Res Function(Progress) _then) = _$ProgressCopyWithImpl;
@useResult
$Res call({
 int unlocked, Map<int, int> stars, Map<String, int> dailyStars
});




}
/// @nodoc
class _$ProgressCopyWithImpl<$Res>
    implements $ProgressCopyWith<$Res> {
  _$ProgressCopyWithImpl(this._self, this._then);

  final Progress _self;
  final $Res Function(Progress) _then;

/// Create a copy of Progress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? unlocked = null,Object? stars = null,Object? dailyStars = null,}) {
  return _then(Progress(
unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as int,stars: null == stars ? _self.stars : stars // ignore: cast_nullable_to_non_nullable
as Map<int, int>,dailyStars: null == dailyStars ? _self.dailyStars : dailyStars // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [Progress].
extension ProgressPatterns on Progress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Progress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Progress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Progress value)  $default,){
final _that = this;
switch (_that) {
case _Progress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Progress value)?  $default,){
final _that = this;
switch (_that) {
case _Progress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int unlocked,  Map<int, int> stars,  Map<String, int> dailyStars)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Progress() when $default != null:
return $default(_that.unlocked,_that.stars,_that.dailyStars);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int unlocked,  Map<int, int> stars,  Map<String, int> dailyStars)  $default,) {final _that = this;
switch (_that) {
case _Progress():
return $default(_that.unlocked,_that.stars,_that.dailyStars);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int unlocked,  Map<int, int> stars,  Map<String, int> dailyStars)?  $default,) {final _that = this;
switch (_that) {
case _Progress() when $default != null:
return $default(_that.unlocked,_that.stars,_that.dailyStars);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Progress extends Progress {
  const _Progress({this.unlocked = 1,  Map<int, int> stars = const <int, int>{},  Map<String, int> dailyStars = const <String, int>{}}): _stars = stars,_dailyStars = dailyStars,super._();
  factory _Progress.fromJson(Map<String, dynamic> json) => _$ProgressFromJson(json);

/// Highest level the player may open (1-based).
@override@JsonKey() final  int unlocked;
/// Best star rating per completed level, keyed by level number.
 final  Map<int, int> _stars;
/// Best star rating per completed level, keyed by level number.
@override@JsonKey() Map<int, int> get stars {
  if (_stars is EqualUnmodifiableMapView) return _stars;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_stars);
}

/// Best stars per completed daily challenge, keyed by `yyyy-mm-dd`.
 final  Map<String, int> _dailyStars;
/// Best stars per completed daily challenge, keyed by `yyyy-mm-dd`.
@override@JsonKey() Map<String, int> get dailyStars {
  if (_dailyStars is EqualUnmodifiableMapView) return _dailyStars;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_dailyStars);
}


/// Create a copy of Progress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressCopyWith<_Progress> get copyWith => __$ProgressCopyWithImpl<_Progress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Progress&&(identical(other.unlocked, unlocked) || other.unlocked == unlocked)&&const DeepCollectionEquality().equals(other.stars, _stars)&&const DeepCollectionEquality().equals(other.dailyStars, _dailyStars));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,unlocked,const DeepCollectionEquality().hash(_stars),const DeepCollectionEquality().hash(_dailyStars));
}

@override
String toString() {
    return 'Progress(unlocked: $unlocked, stars: $stars, dailyStars: $dailyStars)';
}


}

/// @nodoc
abstract mixin class _$ProgressCopyWith<$Res> implements $ProgressCopyWith<$Res> {
  factory _$ProgressCopyWith(_Progress value, $Res Function(_Progress) _then) = __$ProgressCopyWithImpl;
@override @useResult
$Res call({
 int unlocked, Map<int, int> stars, Map<String, int> dailyStars
});




}
/// @nodoc
class __$ProgressCopyWithImpl<$Res>
    implements _$ProgressCopyWith<$Res> {
  __$ProgressCopyWithImpl(this._self, this._then);

  final _Progress _self;
  final $Res Function(_Progress) _then;

/// Create a copy of Progress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? unlocked = null,Object? stars = null,Object? dailyStars = null,}) {
  return _then(_Progress(
unlocked: null == unlocked ? _self.unlocked : unlocked // ignore: cast_nullable_to_non_nullable
as int,stars: null == stars ? _self._stars : stars // ignore: cast_nullable_to_non_nullable
as Map<int, int>,dailyStars: null == dailyStars ? _self._dailyStars : dailyStars // ignore: cast_nullable_to_non_nullable
as Map<String, int>,
  ));
}


}

// dart format on
