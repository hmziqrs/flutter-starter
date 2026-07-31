// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'login_presentation_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LoginPresentationState {

 LoginPresentationStatus get status; String? get successMessage; int get attemptsRemaining; int get lockedSeconds;
/// Create a copy of LoginPresentationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoginPresentationStateCopyWith<LoginPresentationState> get copyWith => _$LoginPresentationStateCopyWithImpl<LoginPresentationState>(this as LoginPresentationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LoginPresentationState&&(identical(other.status, status) || other.status == status)&&(identical(other.successMessage, successMessage) || other.successMessage == successMessage)&&(identical(other.attemptsRemaining, attemptsRemaining) || other.attemptsRemaining == attemptsRemaining)&&(identical(other.lockedSeconds, lockedSeconds) || other.lockedSeconds == lockedSeconds));
}


@override
int get hashCode => Object.hash(runtimeType,status,successMessage,attemptsRemaining,lockedSeconds);

@override
String toString() {
  return 'LoginPresentationState(status: $status, successMessage: $successMessage, attemptsRemaining: $attemptsRemaining, lockedSeconds: $lockedSeconds)';
}


}

/// @nodoc
abstract mixin class $LoginPresentationStateCopyWith<$Res>  {
  factory $LoginPresentationStateCopyWith(LoginPresentationState value, $Res Function(LoginPresentationState) _then) = _$LoginPresentationStateCopyWithImpl;
@useResult
$Res call({
 LoginPresentationStatus status, String? successMessage, int attemptsRemaining, int lockedSeconds
});




}
/// @nodoc
class _$LoginPresentationStateCopyWithImpl<$Res>
    implements $LoginPresentationStateCopyWith<$Res> {
  _$LoginPresentationStateCopyWithImpl(this._self, this._then);

  final LoginPresentationState _self;
  final $Res Function(LoginPresentationState) _then;

/// Create a copy of LoginPresentationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? successMessage = freezed,Object? attemptsRemaining = null,Object? lockedSeconds = null,}) {
  return _then(LoginPresentationState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LoginPresentationStatus,successMessage: freezed == successMessage ? _self.successMessage : successMessage // ignore: cast_nullable_to_non_nullable
as String?,attemptsRemaining: null == attemptsRemaining ? _self.attemptsRemaining : attemptsRemaining // ignore: cast_nullable_to_non_nullable
as int,lockedSeconds: null == lockedSeconds ? _self.lockedSeconds : lockedSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LoginPresentationState].
extension LoginPresentationStatePatterns on LoginPresentationState {
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
