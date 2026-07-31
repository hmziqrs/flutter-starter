// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_presentation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OtpPresentationState {

 OtpPresentationStatus get status; int get resendSeconds; int get attemptsRemaining; int get lockedSeconds; int get remainingSeconds;
/// Create a copy of OtpPresentationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OtpPresentationStateCopyWith<OtpPresentationState> get copyWith => _$OtpPresentationStateCopyWithImpl<OtpPresentationState>(this as OtpPresentationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OtpPresentationState&&(identical(other.status, status) || other.status == status)&&(identical(other.resendSeconds, resendSeconds) || other.resendSeconds == resendSeconds)&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining)&&(identical(other.lockedSeconds, lockedSeconds) || other.lockedSeconds == lockedSeconds)&&(identical(other.remainingSeconds, remainingSeconds) || other.remainingSeconds == remainingSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,status,resendSeconds,attemptsRemaining,lockedSeconds,remainingSeconds);

@override
String toString() {
  return 'OtpPresentationState(status: $status, resendSeconds: $resendSeconds, attemptsRemaining: $attemptsRemaining, lockedSeconds: $lockedSeconds, remainingSeconds: $remainingSeconds)';
}


}

/// @nodoc
abstract mixin class $OtpPresentationStateCopyWith<$Res>  {
  factory $OtpPresentationStateCopyWith(OtpPresentationState value, $Res Function(OtpPresentationState) _then) = _$OtpPresentationStateCopyWithImpl;
@useResult
$Res call({
 OtpPresentationStatus status, int resendSeconds, int attemptsRemaining, int lockedSeconds, int remainingSeconds
});




}
/// @nodoc
class _$OtpPresentationStateCopyWithImpl<$Res>
    implements $OtpPresentationStateCopyWith<$Res> {
  _$OtpPresentationStateCopyWithImpl(this._self, this._then);

  final OtpPresentationState _self;
  final $Res Function(OtpPresentationState) _then;

/// Create a copy of OtpPresentationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? resendSeconds = null,Object? attemptsRemaining = null,Object? lockedSeconds = null,Object? remainingSeconds = null,}) {
  return _then(OtpPresentationState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OtpPresentationStatus,resendSeconds: null == resendSeconds ? _self.resendSeconds : resendSeconds // ignore: cast_nullable_to_non_nullable
as int,attemptsRemaining: null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,lockedSeconds: null == lockedSeconds ? _self.lockedSeconds : lockedSeconds // ignore: cast_nullable_to_non_nullable
as int,remainingSeconds: null == remainingSeconds ? _self.remainingSeconds : remainingSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OtpPresentationState].
extension OtpPresentationStatePatterns on OtpPresentationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
