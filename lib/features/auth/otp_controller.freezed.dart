// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OtpControllerState {

 OtpPresentationState get presentation; int get remainingSeconds; int get attemptsRemaining; bool get isExpired; AuthAuthenticated? get session;
/// Create a copy of OtpControllerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpControllerStateCopyWith<OtpControllerState> get copyWith => _$OtpControllerStateCopyWithImpl<OtpControllerState>(this as OtpControllerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpControllerState&&(identical(other.presentation, presentation) || other.presentation == presentation)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining)&&(identical(other.isExpired, isExpired) || other.isExpired == isExpired)&&const DeepCollectionEquality().equals(other.session, session));
}


@override
int get hashCode => Object.hash(runtimeType,presentation,remainingSeconds,attemptsRemaining,isExpired,const DeepCollectionEquality().hash(session));

@override
String toString() {
  return 'OtpControllerState(presentation: $presentation, remainingSeconds: $remainingSeconds, attemptsRemaining: $attemptsRemaining, isExpired: $isExpired, session: $session)';
}


}

/// @nodoc
abstract mixin class $OtpControllerStateCopyWith<$Res>  {
  factory $OtpControllerStateCopyWith(OtpControllerState value, $Res Function(OtpControllerState) _then) = _$OtpControllerStateCopyWithImpl;
@useResult
$Res call({
 OtpPresentationState presentation, int remainingSeconds, int attemptsRemaining, bool isExpired, AuthAuthenticated? session
});


$OtpPresentationStateCopyWith<$Res> get presentation;

}
/// @nodoc
class _$OtpControllerStateCopyWithImpl<$Res>
    implements $OtpControllerStateCopyWith<$Res> {
  _$OtpControllerStateCopyWithImpl(this._self, this._then);

  final OtpControllerState _self;
  final $Res Function(OtpControllerState) _then;

/// Create a copy of OtpControllerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? presentation = null,Object? remainingSeconds = null,Object? attemptsRemaining = null,Object? isExpired = null,Object? session = freezed,}) {
  return _then(_self.copyWith(
presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as OtpPresentationState,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,attemptsRemaining: null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,isExpired: null == isExpired ? _self.isExpired : isExpired // ignore: cast_nullable_to_non_nullable
as bool,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as AuthAuthenticated?,
  ));
}
/// Create a copy of OtpControllerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OtpPresentationStateCopyWith<$Res> get presentation {
  
  return $OtpPresentationStateCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}


/// Adds pattern-matching-related methods to [OtpControllerState].
extension OtpControllerStatePatterns on OtpControllerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OtpControllerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OtpControllerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OtpControllerState value)  $default,){
final _that = this;
switch (_that) {
case _OtpControllerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OtpControllerState value)?  $default,){
final _that = this;
switch (_that) {
case _OtpControllerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OtpPresentationState presentation,  int remainingSeconds,  int attemptsRemaining,  bool isExpired,  AuthAuthenticated? session)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OtpControllerState() when $default != null:
return $default(_that.presentation,_that.remainingSeconds,_that.attemptsRemaining,_that.isExpired,_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OtpPresentationState presentation,  int remainingSeconds,  int attemptsRemaining,  bool isExpired,  AuthAuthenticated? session)  $default,) {final _that = this;
switch (_that) {
case _OtpControllerState():
return $default(_that.presentation,_that.remainingSeconds,_that.attemptsRemaining,_that.isExpired,_that.session);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OtpPresentationState presentation,  int remainingSeconds,  int attemptsRemaining,  bool isExpired,  AuthAuthenticated? session)?  $default,) {final _that = this;
switch (_that) {
case _OtpControllerState() when $default != null:
return $default(_that.presentation,_that.remainingSeconds,_that.attemptsRemaining,_that.isExpired,_that.session);case _:
  return null;

}
}

}

/// @nodoc


class _OtpControllerState extends OtpControllerState {
  const _OtpControllerState({this.presentation = const OtpPresentationState(), this.remainingSeconds = 0, this.attemptsRemaining = 0, this.isExpired = false, this.session}): assert(remainingSeconds >= 0, 'remainingSeconds must not be negative.'),assert(attemptsRemaining >= 0, 'attemptsRemaining must not be negative.'),super._();
  

@override@JsonKey() final  OtpPresentationState presentation;
@override@JsonKey() final  int remainingSeconds;
@override@JsonKey() final  int attemptsRemaining;
@override@JsonKey() final  bool isExpired;
@override final  AuthAuthenticated? session;

/// Create a copy of OtpControllerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OtpControllerStateCopyWith<_OtpControllerState> get copyWith => __$OtpControllerStateCopyWithImpl<_OtpControllerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OtpControllerState&&(identical(other.presentation, presentation) || other.presentation == presentation)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds)&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining)&&(identical(other.isExpired, isExpired) || other.isExpired == isExpired)&&const DeepCollectionEquality().equals(other.session, session));
}


@override
int get hashCode => Object.hash(runtimeType,presentation,remainingSeconds,attemptsRemaining,isExpired,const DeepCollectionEquality().hash(session));

@override
String toString() {
  return 'OtpControllerState(presentation: $presentation, remainingSeconds: $remainingSeconds, attemptsRemaining: $attemptsRemaining, isExpired: $isExpired, session: $session)';
}


}

/// @nodoc
abstract mixin class _$OtpControllerStateCopyWith<$Res> implements $OtpControllerStateCopyWith<$Res> {
  factory _$OtpControllerStateCopyWith(_OtpControllerState value, $Res Function(_OtpControllerState) _then) = __$OtpControllerStateCopyWithImpl;
@override @useResult
$Res call({
 OtpPresentationState presentation, int remainingSeconds, int attemptsRemaining, bool isExpired, AuthAuthenticated? session
});


@override $OtpPresentationStateCopyWith<$Res> get presentation;

}
/// @nodoc
class __$OtpControllerStateCopyWithImpl<$Res>
    implements _$OtpControllerStateCopyWith<$Res> {
  __$OtpControllerStateCopyWithImpl(this._self, this._then);

  final _OtpControllerState _self;
  final $Res Function(_OtpControllerState) _then;

/// Create a copy of OtpControllerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? presentation = null,Object? remainingSeconds = null,Object? attemptsRemaining = null,Object? isExpired = null,Object? session = freezed,}) {
  return _then(_OtpControllerState(
presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as OtpPresentationState,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,attemptsRemaining: null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,isExpired: null == isExpired ? _self.isExpired : isExpired // ignore: cast_nullable_to_non_nullable
as bool,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as AuthAuthenticated?,
  ));
}

/// Create a copy of OtpControllerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OtpPresentationStateCopyWith<$Res> get presentation {
  
  return $OtpPresentationStateCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}

// dart format on
