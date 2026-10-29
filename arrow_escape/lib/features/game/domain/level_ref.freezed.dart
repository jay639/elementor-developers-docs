// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'level_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LevelRef {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LevelRef);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'LevelRef()';
}


}

/// @nodoc
class $LevelRefCopyWith<$Res>  {
$LevelRefCopyWith(LevelRef _, $Res Function(LevelRef) __);
}


/// Adds pattern-matching-related methods to [LevelRef].
extension LevelRefPatterns on LevelRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CampaignLevelRef value)?  campaign,TResult Function( DailyLevelRef value)?  daily,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CampaignLevelRef() when campaign != null:
return campaign(_that);case DailyLevelRef() when daily != null:
return daily(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CampaignLevelRef value)  campaign,required TResult Function( DailyLevelRef value)  daily,}){
final _that = this;
switch (_that) {
case CampaignLevelRef():
return campaign(_that);case DailyLevelRef():
return daily(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CampaignLevelRef value)?  campaign,TResult? Function( DailyLevelRef value)?  daily,}){
final _that = this;
switch (_that) {
case CampaignLevelRef() when campaign != null:
return campaign(_that);case DailyLevelRef() when daily != null:
return daily(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int number)?  campaign,TResult Function( String dateKey)?  daily,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CampaignLevelRef() when campaign != null:
return campaign(_that.number);case DailyLevelRef() when daily != null:
return daily(_that.dateKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int number)  campaign,required TResult Function( String dateKey)  daily,}) {final _that = this;
switch (_that) {
case CampaignLevelRef():
return campaign(_that.number);case DailyLevelRef():
return daily(_that.dateKey);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int number)?  campaign,TResult? Function( String dateKey)?  daily,}) {final _that = this;
switch (_that) {
case CampaignLevelRef() when campaign != null:
return campaign(_that.number);case DailyLevelRef() when daily != null:
return daily(_that.dateKey);case _:
  return null;

}
}

}

/// @nodoc


class CampaignLevelRef extends LevelRef {
  const CampaignLevelRef(this.number): super._();
  

 final  int number;

/// Create a copy of LevelRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CampaignLevelRefCopyWith<CampaignLevelRef> get copyWith => _$CampaignLevelRefCopyWithImpl<CampaignLevelRef>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CampaignLevelRef&&(identical(other.number, number) || other.number == number));
}


@override
int get hashCode {
    return Object.hash(runtimeType,number);
}

@override
String toString() {
    return 'LevelRef.campaign(number: $number)';
}


}

/// @nodoc
abstract mixin class $CampaignLevelRefCopyWith<$Res> implements $LevelRefCopyWith<$Res> {
  factory $CampaignLevelRefCopyWith(CampaignLevelRef value, $Res Function(CampaignLevelRef) _then) = _$CampaignLevelRefCopyWithImpl;
@useResult
$Res call({
 int number
});




}
/// @nodoc
class _$CampaignLevelRefCopyWithImpl<$Res>
    implements $CampaignLevelRefCopyWith<$Res> {
  _$CampaignLevelRefCopyWithImpl(this._self, this._then);

  final CampaignLevelRef _self;
  final $Res Function(CampaignLevelRef) _then;

/// Create a copy of LevelRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? number = null,}) {
  return _then(CampaignLevelRef(
null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class DailyLevelRef extends LevelRef {
  const DailyLevelRef(this.dateKey): super._();
  

 final  String dateKey;

/// Create a copy of LevelRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyLevelRefCopyWith<DailyLevelRef> get copyWith => _$DailyLevelRefCopyWithImpl<DailyLevelRef>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyLevelRef&&(identical(other.dateKey, dateKey) || other.dateKey == dateKey));
}


@override
int get hashCode {
    return Object.hash(runtimeType,dateKey);
}

@override
String toString() {
    return 'LevelRef.daily(dateKey: $dateKey)';
}


}

/// @nodoc
abstract mixin class $DailyLevelRefCopyWith<$Res> implements $LevelRefCopyWith<$Res> {
  factory $DailyLevelRefCopyWith(DailyLevelRef value, $Res Function(DailyLevelRef) _then) = _$DailyLevelRefCopyWithImpl;
@useResult
$Res call({
 String dateKey
});




}
/// @nodoc
class _$DailyLevelRefCopyWithImpl<$Res>
    implements $DailyLevelRefCopyWith<$Res> {
  _$DailyLevelRefCopyWithImpl(this._self, this._then);

  final DailyLevelRef _self;
  final $Res Function(DailyLevelRef) _then;

/// Create a copy of LevelRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? dateKey = null,}) {
  return _then(DailyLevelRef(
null == dateKey ? _self.dateKey : dateKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
