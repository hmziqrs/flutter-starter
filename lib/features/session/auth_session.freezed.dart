// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthSession {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSession);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthSession()';
}


}

/// @nodoc
class $AuthSessionCopyWith<$Res>  {
$AuthSessionCopyWith(AuthSession _, $Res Function(AuthSession) __);
}


/// Adds pattern-matching-related methods to [AuthSession].
extension AuthSessionPatterns on AuthSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthAnonymous value)?  anonymous,TResult Function( AuthAuthenticated value)?  authenticated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthAnonymous() when anonymous != null:
return anonymous(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthAnonymous value)  anonymous,required TResult Function( AuthAuthenticated value)  authenticated,}){
final _that = this;
switch (_that) {
case AuthAnonymous():
return anonymous(_that);case AuthAuthenticated():
return authenticated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthAnonymous value)?  anonymous,TResult? Function( AuthAuthenticated value)?  authenticated,}){
final _that = this;
switch (_that) {
case AuthAnonymous() when anonymous != null:
return anonymous(_that);case AuthAuthenticated() when authenticated != null:
return authenticated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  anonymous,TResult Function( String accessToken,  String refreshToken,  DateTime expiresAt,  String userId)?  authenticated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthAnonymous() when anonymous != null:
return anonymous();case AuthAuthenticated() when authenticated != null:
return authenticated(_that.accessToken,_that.refreshToken,_that.expiresAt,_that.userId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  anonymous,required TResult Function( String accessToken,  String refreshToken,  DateTime expiresAt,  String userId)  authenticated,}) {final _that = this;
switch (_that) {
case AuthAnonymous():
return anonymous();case AuthAuthenticated():
return authenticated(_that.accessToken,_that.refreshToken,_that.expiresAt,_that.userId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  anonymous,TResult? Function( String accessToken,  String refreshToken,  DateTime expiresAt,  String userId)?  authenticated,}) {final _that = this;
switch (_that) {
case AuthAnonymous() when anonymous != null:
return anonymous();case AuthAuthenticated() when authenticated != null:
return authenticated(_that.accessToken,_that.refreshToken,_that.expiresAt,_that.userId);case _:
  return null;

}
}

}

/// @nodoc


class AuthAnonymous extends AuthSession {
  const AuthAnonymous(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthAnonymous);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthSession.anonymous()';
}


}




/// @nodoc


class AuthAuthenticated extends AuthSession {
  const AuthAuthenticated({required this.accessToken, required this.refreshToken, required this.expiresAt, required this.userId}): super._();
  

 final  String accessToken;
 final  String refreshToken;
 final  DateTime expiresAt;
 final  String userId;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthAuthenticatedCopyWith<AuthAuthenticated> get copyWith => _$AuthAuthenticatedCopyWithImpl<AuthAuthenticated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthAuthenticated&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.userId, userId) || other.userId == userId));
}


@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresAt,userId);

@override
String toString() {
  return 'AuthSession.authenticated(accessToken: $accessToken, refreshToken: $refreshToken, expiresAt: $expiresAt, userId: $userId)';
}


}

/// @nodoc
abstract mixin class $AuthAuthenticatedCopyWith<$Res> implements $AuthSessionCopyWith<$Res> {
  factory $AuthAuthenticatedCopyWith(AuthAuthenticated value, $Res Function(AuthAuthenticated) _then) = _$AuthAuthenticatedCopyWithImpl;
@useResult
$Res call({
 String accessToken, String refreshToken, DateTime expiresAt, String userId
});




}
/// @nodoc
class _$AuthAuthenticatedCopyWithImpl<$Res>
    implements $AuthAuthenticatedCopyWith<$Res> {
  _$AuthAuthenticatedCopyWithImpl(this._self, this._then);

  final AuthAuthenticated _self;
  final $Res Function(AuthAuthenticated) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = null,Object? expiresAt = null,Object? userId = null,}) {
  return _then(AuthAuthenticated(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
