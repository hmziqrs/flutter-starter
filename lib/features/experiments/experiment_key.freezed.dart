// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'experiment_key.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExperimentAllocation {

 ExperimentVariantKind get variant; int get weight;
/// Create a copy of ExperimentAllocation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentAllocationCopyWith<ExperimentAllocation> get copyWith => _$ExperimentAllocationCopyWithImpl<ExperimentAllocation>(this as ExperimentAllocation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentAllocation&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.weight, weight) || other.weight == weight));
}


@override
int get hashCode => Object.hash(runtimeType,variant,weight);

@override
String toString() {
  return 'ExperimentAllocation(variant: $variant, weight: $weight)';
}


}

/// @nodoc
abstract mixin class $ExperimentAllocationCopyWith<$Res>  {
  factory $ExperimentAllocationCopyWith(ExperimentAllocation value, $Res Function(ExperimentAllocation) _then) = _$ExperimentAllocationCopyWithImpl;
@useResult
$Res call({
 ExperimentVariantKind variant, int weight
});




}
/// @nodoc
class _$ExperimentAllocationCopyWithImpl<$Res>
    implements $ExperimentAllocationCopyWith<$Res> {
  _$ExperimentAllocationCopyWithImpl(this._self, this._then);

  final ExperimentAllocation _self;
  final $Res Function(ExperimentAllocation) _then;

/// Create a copy of ExperimentAllocation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? variant = null,Object? weight = null,}) {
  return _then(_self.copyWith(
variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as ExperimentVariantKind,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ExperimentAllocation].
extension ExperimentAllocationPatterns on ExperimentAllocation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExperimentAllocation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExperimentAllocation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExperimentAllocation value)  $default,){
final _that = this;
switch (_that) {
case _ExperimentAllocation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExperimentAllocation value)?  $default,){
final _that = this;
switch (_that) {
case _ExperimentAllocation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExperimentVariantKind variant,  int weight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExperimentAllocation() when $default != null:
return $default(_that.variant,_that.weight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExperimentVariantKind variant,  int weight)  $default,) {final _that = this;
switch (_that) {
case _ExperimentAllocation():
return $default(_that.variant,_that.weight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExperimentVariantKind variant,  int weight)?  $default,) {final _that = this;
switch (_that) {
case _ExperimentAllocation() when $default != null:
return $default(_that.variant,_that.weight);case _:
  return null;

}
}

}

/// @nodoc


class _ExperimentAllocation implements ExperimentAllocation {
  const _ExperimentAllocation(this.variant, this.weight): assert(weight >= 0, 'ExperimentAllocation weight must be non-negative.');
  

@override final  ExperimentVariantKind variant;
@override final  int weight;

/// Create a copy of ExperimentAllocation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExperimentAllocationCopyWith<_ExperimentAllocation> get copyWith => __$ExperimentAllocationCopyWithImpl<_ExperimentAllocation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExperimentAllocation&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.weight, weight) || other.weight == weight));
}


@override
int get hashCode => Object.hash(runtimeType,variant,weight);

@override
String toString() {
  return 'ExperimentAllocation(variant: $variant, weight: $weight)';
}


}

/// @nodoc
abstract mixin class _$ExperimentAllocationCopyWith<$Res> implements $ExperimentAllocationCopyWith<$Res> {
  factory _$ExperimentAllocationCopyWith(_ExperimentAllocation value, $Res Function(_ExperimentAllocation) _then) = __$ExperimentAllocationCopyWithImpl;
@override @useResult
$Res call({
 ExperimentVariantKind variant, int weight
});




}
/// @nodoc
class __$ExperimentAllocationCopyWithImpl<$Res>
    implements _$ExperimentAllocationCopyWith<$Res> {
  __$ExperimentAllocationCopyWithImpl(this._self, this._then);

  final _ExperimentAllocation _self;
  final $Res Function(_ExperimentAllocation) _then;

/// Create a copy of ExperimentAllocation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? variant = null,Object? weight = null,}) {
  return _then(_ExperimentAllocation(
null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as ExperimentVariantKind,null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
