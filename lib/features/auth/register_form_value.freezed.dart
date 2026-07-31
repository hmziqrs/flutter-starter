// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'register_form_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RegisterFormValue {

 String get displayName; String get email; String get password; String get confirmPassword; bool get acceptTerms;
/// Create a copy of RegisterFormValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterFormValueCopyWith<RegisterFormValue> get copyWith => _$RegisterFormValueCopyWithImpl<RegisterFormValue>(this as RegisterFormValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterFormValue&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword)&&(identical(other.acceptTerms, acceptTerms) || other.acceptTerms == acceptTerms));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,email,password,confirmPassword,acceptTerms);

@override
String toString() {
  return 'RegisterFormValue(displayName: $displayName, email: $email, password: $password, confirmPassword: $confirmPassword, acceptTerms: $acceptTerms)';
}


}

/// @nodoc
abstract mixin class $RegisterFormValueCopyWith<$Res>  {
  factory $RegisterFormValueCopyWith(RegisterFormValue value, $Res Function(RegisterFormValue) _then) = _$RegisterFormValueCopyWithImpl;
@useResult
$Res call({
 String displayName, String email, String password, String confirmPassword, bool acceptTerms
});




}
/// @nodoc
class _$RegisterFormValueCopyWithImpl<$Res>
    implements $RegisterFormValueCopyWith<$Res> {
  _$RegisterFormValueCopyWithImpl(this._self, this._then);

  final RegisterFormValue _self;
  final $Res Function(RegisterFormValue) _then;

/// Create a copy of RegisterFormValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? email = null,Object? password = null,Object? confirmPassword = null,Object? acceptTerms = null,}) {
  return _then(_self.copyWith(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,acceptTerms: null == acceptTerms ? _self.acceptTerms : acceptTerms // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RegisterFormValue].
extension RegisterFormValuePatterns on RegisterFormValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterFormValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterFormValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterFormValue value)  $default,){
final _that = this;
switch (_that) {
case _RegisterFormValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterFormValue value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterFormValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  String email,  String password,  String confirmPassword,  bool acceptTerms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterFormValue() when $default != null:
return $default(_that.displayName,_that.email,_that.password,_that.confirmPassword,_that.acceptTerms);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  String email,  String password,  String confirmPassword,  bool acceptTerms)  $default,) {final _that = this;
switch (_that) {
case _RegisterFormValue():
return $default(_that.displayName,_that.email,_that.password,_that.confirmPassword,_that.acceptTerms);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  String email,  String password,  String confirmPassword,  bool acceptTerms)?  $default,) {final _that = this;
switch (_that) {
case _RegisterFormValue() when $default != null:
return $default(_that.displayName,_that.email,_that.password,_that.confirmPassword,_that.acceptTerms);case _:
  return null;

}
}

}

/// @nodoc


class _RegisterFormValue implements RegisterFormValue {
  const _RegisterFormValue({required this.displayName, required this.email, required this.password, required this.confirmPassword, required this.acceptTerms});
  

@override final  String displayName;
@override final  String email;
@override final  String password;
@override final  String confirmPassword;
@override final  bool acceptTerms;

/// Create a copy of RegisterFormValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterFormValueCopyWith<_RegisterFormValue> get copyWith => __$RegisterFormValueCopyWithImpl<_RegisterFormValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterFormValue&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.email, email) || other.email == email)&&(identical(other.password, password) || other.password == password)&&(identical(other.confirmPassword, confirmPassword) || other.confirmPassword == confirmPassword)&&(identical(other.acceptTerms, acceptTerms) || other.acceptTerms == acceptTerms));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,email,password,confirmPassword,acceptTerms);

@override
String toString() {
  return 'RegisterFormValue(displayName: $displayName, email: $email, password: $password, confirmPassword: $confirmPassword, acceptTerms: $acceptTerms)';
}


}

/// @nodoc
abstract mixin class _$RegisterFormValueCopyWith<$Res> implements $RegisterFormValueCopyWith<$Res> {
  factory _$RegisterFormValueCopyWith(_RegisterFormValue value, $Res Function(_RegisterFormValue) _then) = __$RegisterFormValueCopyWithImpl;
@override @useResult
$Res call({
 String displayName, String email, String password, String confirmPassword, bool acceptTerms
});




}
/// @nodoc
class __$RegisterFormValueCopyWithImpl<$Res>
    implements _$RegisterFormValueCopyWith<$Res> {
  __$RegisterFormValueCopyWithImpl(this._self, this._then);

  final _RegisterFormValue _self;
  final $Res Function(_RegisterFormValue) _then;

/// Create a copy of RegisterFormValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? email = null,Object? password = null,Object? confirmPassword = null,Object? acceptTerms = null,}) {
  return _then(_RegisterFormValue(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,confirmPassword: null == confirmPassword ? _self.confirmPassword : confirmPassword // ignore: cast_nullable_to_non_nullable
as String,acceptTerms: null == acceptTerms ? _self.acceptTerms : acceptTerms // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
