// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reset_password_form_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ResetPasswordFormValue {

 String get newPassword; String get confirmPassword;
/// Create a copy of ResetPasswordFormValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResetPasswordFormValueCopyWith<ResetPasswordFormValue> get copyWith => _$ResetPasswordFormValueCopyWithImpl<ResetPasswordFormValue>(this as ResetPasswordFormValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResetPasswordFormValue&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword));
}


@override
int get hashCode => Object.hash(runtimeType,newPassword,confirmPassword);

@override
String toString() {
  return 'ResetPasswordFormValue(newPassword: $newPassword, confirmPassword: $confirmPassword)';
}


}

/// @nodoc
abstract mixin class $ResetPasswordFormValueCopyWith<$Res>  {
  factory $ResetPasswordFormValueCopyWith(ResetPasswordFormValue value, $Res Function(ResetPasswordFormValue) _then) = _$ResetPasswordFormValueCopyWithImpl;
@useResult
$Res call({
 String newPassword, String confirmPassword
});




}
/// @nodoc
class _$ResetPasswordFormValueCopyWithImpl<$Res>
    implements $ResetPasswordFormValueCopyWith<$Res> {
  _$ResetPasswordFormValueCopyWithImpl(this._self, this._then);

  final ResetPasswordFormValue _self;
  final $Res Function(ResetPasswordFormValue) _then;

/// Create a copy of ResetPasswordFormValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? newPassword = null,Object? confirmPassword = null,}) {
  return _then(_self.copyWith(
newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ResetPasswordFormValue].
extension ResetPasswordFormValuePatterns on ResetPasswordFormValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResetPasswordFormValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResetPasswordFormValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResetPasswordFormValue value)  $default,){
final _that = this;
switch (_that) {
case _ResetPasswordFormValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResetPasswordFormValue value)?  $default,){
final _that = this;
switch (_that) {
case _ResetPasswordFormValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String newPassword,  String confirmPassword)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResetPasswordFormValue() when $default != null:
return $default(_that.newPassword,_that.confirmPassword);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String newPassword,  String confirmPassword)  $default,) {final _that = this;
switch (_that) {
case _ResetPasswordFormValue():
return $default(_that.newPassword,_that.confirmPassword);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String newPassword,  String confirmPassword)?  $default,) {final _that = this;
switch (_that) {
case _ResetPasswordFormValue() when $default != null:
return $default(_that.newPassword,_that.confirmPassword);case _:
  return null;

}
}

}

/// @nodoc


class _ResetPasswordFormValue implements ResetPasswordFormValue {
  const _ResetPasswordFormValue({required this.newPassword, required this.confirmPassword});
  

@override final  String newPassword;
@override final  String confirmPassword;

/// Create a copy of ResetPasswordFormValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResetPasswordFormValueCopyWith<_ResetPasswordFormValue> get copyWith => __$ResetPasswordFormValueCopyWithImpl<_ResetPasswordFormValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResetPasswordFormValue&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword));
}


@override
int get hashCode => Object.hash(runtimeType,newPassword,confirmPassword);

@override
String toString() {
  return 'ResetPasswordFormValue(newPassword: $newPassword, confirmPassword: $confirmPassword)';
}


}

/// @nodoc
abstract mixin class _$ResetPasswordFormValueCopyWith<$Res> implements $ResetPasswordFormValueCopyWith<$Res> {
  factory _$ResetPasswordFormValueCopyWith(_ResetPasswordFormValue value, $Res Function(_ResetPasswordFormValue) _then) = __$ResetPasswordFormValueCopyWithImpl;
@override @useResult
$Res call({
 String newPassword, String confirmPassword
});




}
/// @nodoc
class __$ResetPasswordFormValueCopyWithImpl<$Res>
    implements _$ResetPasswordFormValueCopyWith<$Res> {
  __$ResetPasswordFormValueCopyWithImpl(this._self, this._then);

  final _ResetPasswordFormValue _self;
  final $Res Function(_ResetPasswordFormValue) _then;

/// Create a copy of ResetPasswordFormValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? newPassword = null,Object? confirmPassword = null,}) {
  return _then(_ResetPasswordFormValue(
newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
