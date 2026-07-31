// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'permissions_gallery_cases.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PermissionGalleryState {

 AppPermission get permission; bool get permanentlyDenied; bool get showDeniedAlert;
/// Create a copy of PermissionGalleryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PermissionGalleryStateCopyWith<PermissionGalleryState> get copyWith => _$PermissionGalleryStateCopyWithImpl<PermissionGalleryState>(this as PermissionGalleryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PermissionGalleryState&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.permanentlyDenied, permanentlyDenied) || other.permanentlyDenied == permanentlyDenied)&&(identical(other.showDeniedAlert, showDeniedAlert) || other.showDeniedAlert == showDeniedAlert));
}


@override
int get hashCode => Object.hash(runtimeType,permission,permanentlyDenied,showDeniedAlert);

@override
String toString() {
  return 'PermissionGalleryState(permission: $permission, permanentlyDenied: $permanentlyDenied, showDeniedAlert: $showDeniedAlert)';
}


}

/// @nodoc
abstract mixin class $PermissionGalleryStateCopyWith<$Res>  {
  factory $PermissionGalleryStateCopyWith(PermissionGalleryState value, $Res Function(PermissionGalleryState) _then) = _$PermissionGalleryStateCopyWithImpl;
@useResult
$Res call({
 AppPermission permission, bool permanentlyDenied, bool showDeniedAlert
});




}
/// @nodoc
class _$PermissionGalleryStateCopyWithImpl<$Res>
    implements $PermissionGalleryStateCopyWith<$Res> {
  _$PermissionGalleryStateCopyWithImpl(this._self, this._then);

  final PermissionGalleryState _self;
  final $Res Function(PermissionGalleryState) _then;

/// Create a copy of PermissionGalleryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? permission = null,Object? permanentlyDenied = null,Object? showDeniedAlert = null,}) {
  return _then(_self.copyWith(
permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as AppPermission,permanentlyDenied: null == permanentlyDenied ? _self.permanentlyDenied : permanentlyDenied // ignore: cast_nullable_to_non_nullable
as bool,showDeniedAlert: null == showDeniedAlert ? _self.showDeniedAlert : showDeniedAlert // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PermissionGalleryState].
extension PermissionGalleryStatePatterns on PermissionGalleryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PermissionGalleryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PermissionGalleryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PermissionGalleryState value)  $default,){
final _that = this;
switch (_that) {
case _PermissionGalleryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PermissionGalleryState value)?  $default,){
final _that = this;
switch (_that) {
case _PermissionGalleryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppPermission permission,  bool permanentlyDenied,  bool showDeniedAlert)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PermissionGalleryState() when $default != null:
return $default(_that.permission,_that.permanentlyDenied,_that.showDeniedAlert);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppPermission permission,  bool permanentlyDenied,  bool showDeniedAlert)  $default,) {final _that = this;
switch (_that) {
case _PermissionGalleryState():
return $default(_that.permission,_that.permanentlyDenied,_that.showDeniedAlert);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppPermission permission,  bool permanentlyDenied,  bool showDeniedAlert)?  $default,) {final _that = this;
switch (_that) {
case _PermissionGalleryState() when $default != null:
return $default(_that.permission,_that.permanentlyDenied,_that.showDeniedAlert);case _:
  return null;

}
}

}

/// @nodoc


class _PermissionGalleryState implements PermissionGalleryState {
  const _PermissionGalleryState({required this.permission, required this.permanentlyDenied, required this.showDeniedAlert});
  

@override final  AppPermission permission;
@override final  bool permanentlyDenied;
@override final  bool showDeniedAlert;

/// Create a copy of PermissionGalleryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PermissionGalleryStateCopyWith<_PermissionGalleryState> get copyWith => __$PermissionGalleryStateCopyWithImpl<_PermissionGalleryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PermissionGalleryState&&(identical(other.permission, permission) || other.permission == permission)&&(identical(other.permanentlyDenied, permanentlyDenied) || other.permanentlyDenied == permanentlyDenied)&&(identical(other.showDeniedAlert, showDeniedAlert) || other.showDeniedAlert == showDeniedAlert));
}


@override
int get hashCode => Object.hash(runtimeType,permission,permanentlyDenied,showDeniedAlert);

@override
String toString() {
  return 'PermissionGalleryState(permission: $permission, permanentlyDenied: $permanentlyDenied, showDeniedAlert: $showDeniedAlert)';
}


}

/// @nodoc
abstract mixin class _$PermissionGalleryStateCopyWith<$Res> implements $PermissionGalleryStateCopyWith<$Res> {
  factory _$PermissionGalleryStateCopyWith(_PermissionGalleryState value, $Res Function(_PermissionGalleryState) _then) = __$PermissionGalleryStateCopyWithImpl;
@override @useResult
$Res call({
 AppPermission permission, bool permanentlyDenied, bool showDeniedAlert
});




}
/// @nodoc
class __$PermissionGalleryStateCopyWithImpl<$Res>
    implements _$PermissionGalleryStateCopyWith<$Res> {
  __$PermissionGalleryStateCopyWithImpl(this._self, this._then);

  final _PermissionGalleryState _self;
  final $Res Function(_PermissionGalleryState) _then;

/// Create a copy of PermissionGalleryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? permission = null,Object? permanentlyDenied = null,Object? showDeniedAlert = null,}) {
  return _then(_PermissionGalleryState(
permission: null == permission ? _self.permission : permission // ignore: cast_nullable_to_non_nullable
as AppPermission,permanentlyDenied: null == permanentlyDenied ? _self.permanentlyDenied : permanentlyDenied // ignore: cast_nullable_to_non_nullable
as bool,showDeniedAlert: null == showDeniedAlert ? _self.showDeniedAlert : showDeniedAlert // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
