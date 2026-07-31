// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'forgot_password_form_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ForgotPasswordFormValue {

 String get email;
/// Create a copy of ForgotPasswordFormValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ForgotPasswordFormValueCopyWith<ForgotPasswordFormValue> get copyWith => _$ForgotPasswordFormValueCopyWithImpl<ForgotPasswordFormValue>(this as ForgotPasswordFormValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ForgotPasswordFormValue&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'ForgotPasswordFormValue(email: $email)';
}


}

/// @nodoc
abstract mixin class $ForgotPasswordFormValueCopyWith<$Res>  {
  factory $ForgotPasswordFormValueCopyWith(ForgotPasswordFormValue value, $Res Function(ForgotPasswordFormValue) _then) = _$ForgotPasswordFormValueCopyWithImpl;
@useResult
$Res call({
 String email
});




}
/// @nodoc
class _$ForgotPasswordFormValueCopyWithImpl<$Res>
    implements $ForgotPasswordFormValueCopyWith<$Res> {
  _$ForgotPasswordFormValueCopyWithImpl(this._self, this._then);

  final ForgotPasswordFormValue _self;
  final $Res Function(ForgotPasswordFormValue) _then;

/// Create a copy of ForgotPasswordFormValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? email = null,}) {
  return _then(_self.copyWith(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ForgotPasswordFormValue].
extension ForgotPasswordFormValuePatterns on ForgotPasswordFormValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ForgotPasswordFormValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ForgotPasswordFormValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ForgotPasswordFormValue value)  $default,){
final _that = this;
switch (_that) {
case _ForgotPasswordFormValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ForgotPasswordFormValue value)?  $default,){
final _that = this;
switch (_that) {
case _ForgotPasswordFormValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ForgotPasswordFormValue() when $default != null:
return $default(_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String email)  $default,) {final _that = this;
switch (_that) {
case _ForgotPasswordFormValue():
return $default(_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String email)?  $default,) {final _that = this;
switch (_that) {
case _ForgotPasswordFormValue() when $default != null:
return $default(_that.email);case _:
  return null;

}
}

}

/// @nodoc


class _ForgotPasswordFormValue implements ForgotPasswordFormValue {
  const _ForgotPasswordFormValue({required this.email});
  

@override final  String email;

/// Create a copy of ForgotPasswordFormValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ForgotPasswordFormValueCopyWith<_ForgotPasswordFormValue> get copyWith => __$ForgotPasswordFormValueCopyWithImpl<_ForgotPasswordFormValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ForgotPasswordFormValue&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,email);

@override
String toString() {
  return 'ForgotPasswordFormValue(email: $email)';
}


}

/// @nodoc
abstract mixin class _$ForgotPasswordFormValueCopyWith<$Res> implements $ForgotPasswordFormValueCopyWith<$Res> {
  factory _$ForgotPasswordFormValueCopyWith(_ForgotPasswordFormValue value, $Res Function(_ForgotPasswordFormValue) _then) = __$ForgotPasswordFormValueCopyWithImpl;
@override @useResult
$Res call({
 String email
});




}
/// @nodoc
class __$ForgotPasswordFormValueCopyWithImpl<$Res>
    implements _$ForgotPasswordFormValueCopyWith<$Res> {
  __$ForgotPasswordFormValueCopyWithImpl(this._self, this._then);

  final _ForgotPasswordFormValue _self;
  final $Res Function(_ForgotPasswordFormValue) _then;

/// Create a copy of ForgotPasswordFormValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? email = null,}) {
  return _then(_ForgotPasswordFormValue(
email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
