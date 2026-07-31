// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_overlay_fixture.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SystemOverlayFixtureState {

 SystemOverlayFixtureKind get kind;
/// Create a copy of SystemOverlayFixtureState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemOverlayFixtureStateCopyWith<SystemOverlayFixtureState> get copyWith => _$SystemOverlayFixtureStateCopyWithImpl<SystemOverlayFixtureState>(this as SystemOverlayFixtureState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemOverlayFixtureState&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'SystemOverlayFixtureState(kind: $kind)';
}


}

/// @nodoc
abstract mixin class $SystemOverlayFixtureStateCopyWith<$Res>  {
  factory $SystemOverlayFixtureStateCopyWith(SystemOverlayFixtureState value, $Res Function(SystemOverlayFixtureState) _then) = _$SystemOverlayFixtureStateCopyWithImpl;
@useResult
$Res call({
 SystemOverlayFixtureKind kind
});




}
/// @nodoc
class _$SystemOverlayFixtureStateCopyWithImpl<$Res>
    implements $SystemOverlayFixtureStateCopyWith<$Res> {
  _$SystemOverlayFixtureStateCopyWithImpl(this._self, this._then);

  final SystemOverlayFixtureState _self;
  final $Res Function(SystemOverlayFixtureState) _then;

/// Create a copy of SystemOverlayFixtureState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SystemOverlayFixtureKind,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemOverlayFixtureState].
extension SystemOverlayFixtureStatePatterns on SystemOverlayFixtureState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SystemOverlayFixtureState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SystemOverlayFixtureState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SystemOverlayFixtureState value)  $default,){
final _that = this;
switch (_that) {
case _SystemOverlayFixtureState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SystemOverlayFixtureState value)?  $default,){
final _that = this;
switch (_that) {
case _SystemOverlayFixtureState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SystemOverlayFixtureKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SystemOverlayFixtureState() when $default != null:
return $default(_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SystemOverlayFixtureKind kind)  $default,) {final _that = this;
switch (_that) {
case _SystemOverlayFixtureState():
return $default(_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SystemOverlayFixtureKind kind)?  $default,) {final _that = this;
switch (_that) {
case _SystemOverlayFixtureState() when $default != null:
return $default(_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _SystemOverlayFixtureState implements SystemOverlayFixtureState {
  const _SystemOverlayFixtureState({required this.kind});
  

@override final  SystemOverlayFixtureKind kind;

/// Create a copy of SystemOverlayFixtureState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SystemOverlayFixtureStateCopyWith<_SystemOverlayFixtureState> get copyWith => __$SystemOverlayFixtureStateCopyWithImpl<_SystemOverlayFixtureState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SystemOverlayFixtureState&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,kind);

@override
String toString() {
  return 'SystemOverlayFixtureState(kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$SystemOverlayFixtureStateCopyWith<$Res> implements $SystemOverlayFixtureStateCopyWith<$Res> {
  factory _$SystemOverlayFixtureStateCopyWith(_SystemOverlayFixtureState value, $Res Function(_SystemOverlayFixtureState) _then) = __$SystemOverlayFixtureStateCopyWithImpl;
@override @useResult
$Res call({
 SystemOverlayFixtureKind kind
});




}
/// @nodoc
class __$SystemOverlayFixtureStateCopyWithImpl<$Res>
    implements _$SystemOverlayFixtureStateCopyWith<$Res> {
  __$SystemOverlayFixtureStateCopyWithImpl(this._self, this._then);

  final _SystemOverlayFixtureState _self;
  final $Res Function(_SystemOverlayFixtureState) _then;

/// Create a copy of SystemOverlayFixtureState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,}) {
  return _then(_SystemOverlayFixtureState(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SystemOverlayFixtureKind,
  ));
}


}

// dart format on
