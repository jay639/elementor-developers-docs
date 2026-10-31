// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GameViewState {

 LevelRef get levelRef; PlaySession get session; bool get showPaths;/// Coins awarded for the win (0 until won).
 int get coinsEarned;/// Whether the win reward was already doubled by a rewarded ad.
 bool get coinsDoubled;/// Vehicle highlighted by a hint until the next move.
 int? get hintPiece;/// Level-1 tutorial progress (none outside the tutorial).
 TutorialStep get tutorial;/// No order of moves can clear the board any more (traffic lights or
/// the ambulance turned the last moves into a dead end).
 bool get stuck;/// Picture puzzles this win unlocked (ids), announced on the win card.
 List<String> get unlockedPuzzles;
/// Create a copy of GameViewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameViewStateCopyWith<GameViewState> get copyWith => _$GameViewStateCopyWithImpl<GameViewState>(this as GameViewState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameViewState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameViewState&&(identical(other.levelRef, _this.levelRef) || other.levelRef == _this.levelRef)&&(identical(other.session, _this.session) || other.session == _this.session)&&(identical(other.showPaths, _this.showPaths) || other.showPaths == _this.showPaths)&&(identical(other.coinsEarned, _this.coinsEarned) || other.coinsEarned == _this.coinsEarned)&&(identical(other.coinsDoubled, _this.coinsDoubled) || other.coinsDoubled == _this.coinsDoubled)&&(identical(other.hintPiece, _this.hintPiece) || other.hintPiece == _this.hintPiece)&&(identical(other.tutorial, _this.tutorial) || other.tutorial == _this.tutorial)&&(identical(other.stuck, _this.stuck) || other.stuck == _this.stuck)&&const DeepCollectionEquality().equals(other.unlockedPuzzles, _this.unlockedPuzzles));
}


@override
int get hashCode {
  final _this = this as GameViewState;
  return Object.hash(runtimeType,_this.levelRef,_this.session,_this.showPaths,_this.coinsEarned,_this.coinsDoubled,_this.hintPiece,_this.tutorial,_this.stuck,const DeepCollectionEquality().hash(_this.unlockedPuzzles));
}

@override
String toString() {
  final _this = this as GameViewState;
  return 'GameViewState(levelRef: ${_this.levelRef}, session: ${_this.session}, showPaths: ${_this.showPaths}, coinsEarned: ${_this.coinsEarned}, coinsDoubled: ${_this.coinsDoubled}, hintPiece: ${_this.hintPiece}, tutorial: ${_this.tutorial}, stuck: ${_this.stuck}, unlockedPuzzles: ${_this.unlockedPuzzles})';
}


}

/// @nodoc
abstract mixin class $GameViewStateCopyWith<$Res>  {
  factory $GameViewStateCopyWith(GameViewState value, $Res Function(GameViewState) _then) = _$GameViewStateCopyWithImpl;
@useResult
$Res call({
 LevelRef levelRef, PlaySession session, bool showPaths, int coinsEarned, bool coinsDoubled, int? hintPiece, TutorialStep tutorial, bool stuck, List<String> unlockedPuzzles
});


$LevelRefCopyWith<$Res> get levelRef;

}
/// @nodoc
class _$GameViewStateCopyWithImpl<$Res>
    implements $GameViewStateCopyWith<$Res> {
  _$GameViewStateCopyWithImpl(this._self, this._then);

  final GameViewState _self;
  final $Res Function(GameViewState) _then;

/// Create a copy of GameViewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? levelRef = null,Object? session = null,Object? showPaths = null,Object? coinsEarned = null,Object? coinsDoubled = null,Object? hintPiece = freezed,Object? tutorial = null,Object? stuck = null,Object? unlockedPuzzles = null,}) {
  return _then(GameViewState(
levelRef: null == levelRef ? _self.levelRef : levelRef // ignore: cast_nullable_to_non_nullable
as LevelRef,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as PlaySession,showPaths: null == showPaths ? _self.showPaths : showPaths // ignore: cast_nullable_to_non_nullable
as bool,coinsEarned: null == coinsEarned ? _self.coinsEarned : coinsEarned // ignore: cast_nullable_to_non_nullable
as int,coinsDoubled: null == coinsDoubled ? _self.coinsDoubled : coinsDoubled // ignore: cast_nullable_to_non_nullable
as bool,hintPiece: freezed == hintPiece ? _self.hintPiece : hintPiece // ignore: cast_nullable_to_non_nullable
as int?,tutorial: null == tutorial ? _self.tutorial : tutorial // ignore: cast_nullable_to_non_nullable
as TutorialStep,stuck: null == stuck ? _self.stuck : stuck // ignore: cast_nullable_to_non_nullable
as bool,unlockedPuzzles: null == unlockedPuzzles ? _self.unlockedPuzzles : unlockedPuzzles // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of GameViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LevelRefCopyWith<$Res> get levelRef {
  
  return $LevelRefCopyWith<$Res>(_self.levelRef, (value) {
    return _then(_self.copyWith(levelRef: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameViewState].
extension GameViewStatePatterns on GameViewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameViewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameViewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameViewState value)  $default,){
final _that = this;
switch (_that) {
case _GameViewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameViewState value)?  $default,){
final _that = this;
switch (_that) {
case _GameViewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LevelRef levelRef,  PlaySession session,  bool showPaths,  int coinsEarned,  bool coinsDoubled,  int? hintPiece,  TutorialStep tutorial,  bool stuck,  List<String> unlockedPuzzles)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameViewState() when $default != null:
return $default(_that.levelRef,_that.session,_that.showPaths,_that.coinsEarned,_that.coinsDoubled,_that.hintPiece,_that.tutorial,_that.stuck,_that.unlockedPuzzles);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LevelRef levelRef,  PlaySession session,  bool showPaths,  int coinsEarned,  bool coinsDoubled,  int? hintPiece,  TutorialStep tutorial,  bool stuck,  List<String> unlockedPuzzles)  $default,) {final _that = this;
switch (_that) {
case _GameViewState():
return $default(_that.levelRef,_that.session,_that.showPaths,_that.coinsEarned,_that.coinsDoubled,_that.hintPiece,_that.tutorial,_that.stuck,_that.unlockedPuzzles);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LevelRef levelRef,  PlaySession session,  bool showPaths,  int coinsEarned,  bool coinsDoubled,  int? hintPiece,  TutorialStep tutorial,  bool stuck,  List<String> unlockedPuzzles)?  $default,) {final _that = this;
switch (_that) {
case _GameViewState() when $default != null:
return $default(_that.levelRef,_that.session,_that.showPaths,_that.coinsEarned,_that.coinsDoubled,_that.hintPiece,_that.tutorial,_that.stuck,_that.unlockedPuzzles);case _:
  return null;

}
}

}

/// @nodoc


class _GameViewState extends GameViewState {
  const _GameViewState({required this.levelRef, required this.session, this.showPaths = false, this.coinsEarned = 0, this.coinsDoubled = false, this.hintPiece, this.tutorial = TutorialStep.none, this.stuck = false,  List<String> unlockedPuzzles = const <String>[]}): _unlockedPuzzles = unlockedPuzzles,super._();
  

@override final  LevelRef levelRef;
@override final  PlaySession session;
@override@JsonKey() final  bool showPaths;
/// Coins awarded for the win (0 until won).
@override@JsonKey() final  int coinsEarned;
/// Whether the win reward was already doubled by a rewarded ad.
@override@JsonKey() final  bool coinsDoubled;
/// Vehicle highlighted by a hint until the next move.
@override final  int? hintPiece;
/// Level-1 tutorial progress (none outside the tutorial).
@override@JsonKey() final  TutorialStep tutorial;
/// No order of moves can clear the board any more (traffic lights or
/// the ambulance turned the last moves into a dead end).
@override@JsonKey() final  bool stuck;
/// Picture puzzles this win unlocked (ids), announced on the win card.
 final  List<String> _unlockedPuzzles;
/// Picture puzzles this win unlocked (ids), announced on the win card.
@override@JsonKey() List<String> get unlockedPuzzles {
  if (_unlockedPuzzles is EqualUnmodifiableListView) return _unlockedPuzzles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unlockedPuzzles);
}


/// Create a copy of GameViewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameViewStateCopyWith<_GameViewState> get copyWith => __$GameViewStateCopyWithImpl<_GameViewState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameViewState&&(identical(other.levelRef, levelRef) || other.levelRef == levelRef)&&(identical(other.session, session) || other.session == session)&&(identical(other.showPaths, showPaths) || other.showPaths == showPaths)&&(identical(other.coinsEarned, coinsEarned) || other.coinsEarned == coinsEarned)&&(identical(other.coinsDoubled, coinsDoubled) || other.coinsDoubled == coinsDoubled)&&(identical(other.hintPiece, hintPiece) || other.hintPiece == hintPiece)&&(identical(other.tutorial, tutorial) || other.tutorial == tutorial)&&(identical(other.stuck, stuck) || other.stuck == stuck)&&const DeepCollectionEquality().equals(other.unlockedPuzzles, _unlockedPuzzles));
}


@override
int get hashCode {
    return Object.hash(runtimeType,levelRef,session,showPaths,coinsEarned,coinsDoubled,hintPiece,tutorial,stuck,const DeepCollectionEquality().hash(_unlockedPuzzles));
}

@override
String toString() {
    return 'GameViewState(levelRef: $levelRef, session: $session, showPaths: $showPaths, coinsEarned: $coinsEarned, coinsDoubled: $coinsDoubled, hintPiece: $hintPiece, tutorial: $tutorial, stuck: $stuck, unlockedPuzzles: $unlockedPuzzles)';
}


}

/// @nodoc
abstract mixin class _$GameViewStateCopyWith<$Res> implements $GameViewStateCopyWith<$Res> {
  factory _$GameViewStateCopyWith(_GameViewState value, $Res Function(_GameViewState) _then) = __$GameViewStateCopyWithImpl;
@override @useResult
$Res call({
 LevelRef levelRef, PlaySession session, bool showPaths, int coinsEarned, bool coinsDoubled, int? hintPiece, TutorialStep tutorial, bool stuck, List<String> unlockedPuzzles
});


@override $LevelRefCopyWith<$Res> get levelRef;

}
/// @nodoc
class __$GameViewStateCopyWithImpl<$Res>
    implements _$GameViewStateCopyWith<$Res> {
  __$GameViewStateCopyWithImpl(this._self, this._then);

  final _GameViewState _self;
  final $Res Function(_GameViewState) _then;

/// Create a copy of GameViewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? levelRef = null,Object? session = null,Object? showPaths = null,Object? coinsEarned = null,Object? coinsDoubled = null,Object? hintPiece = freezed,Object? tutorial = null,Object? stuck = null,Object? unlockedPuzzles = null,}) {
  return _then(_GameViewState(
levelRef: null == levelRef ? _self.levelRef : levelRef // ignore: cast_nullable_to_non_nullable
as LevelRef,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as PlaySession,showPaths: null == showPaths ? _self.showPaths : showPaths // ignore: cast_nullable_to_non_nullable
as bool,coinsEarned: null == coinsEarned ? _self.coinsEarned : coinsEarned // ignore: cast_nullable_to_non_nullable
as int,coinsDoubled: null == coinsDoubled ? _self.coinsDoubled : coinsDoubled // ignore: cast_nullable_to_non_nullable
as bool,hintPiece: freezed == hintPiece ? _self.hintPiece : hintPiece // ignore: cast_nullable_to_non_nullable
as int?,tutorial: null == tutorial ? _self.tutorial : tutorial // ignore: cast_nullable_to_non_nullable
as TutorialStep,stuck: null == stuck ? _self.stuck : stuck // ignore: cast_nullable_to_non_nullable
as bool,unlockedPuzzles: null == unlockedPuzzles ? _self._unlockedPuzzles : unlockedPuzzles // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of GameViewState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LevelRefCopyWith<$Res> get levelRef {
  
  return $LevelRefCopyWith<$Res>(_self.levelRef, (value) {
    return _then(_self.copyWith(levelRef: value));
  });
}
}

// dart format on
