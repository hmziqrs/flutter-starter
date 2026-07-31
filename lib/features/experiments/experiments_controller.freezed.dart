// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'experiments_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExperimentsSnapshot {

 List<ExperimentAssignment> get assignments;
/// Create a copy of ExperimentsSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentsSnapshotCopyWith<ExperimentsSnapshot> get copyWith => _$ExperimentsSnapshotCopyWithImpl<ExperimentsSnapshot>(this as ExperimentsSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentsSnapshot&&const DeepCollectionEquality().equals(other.assignments, assignments));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(assignments));

@override
String toString() {
  return 'ExperimentsSnapshot(assignments: $assignments)';
}


}

/// @nodoc
abstract mixin class $ExperimentsSnapshotCopyWith<$Res>  {
  factory $ExperimentsSnapshotCopyWith(ExperimentsSnapshot value, $Res Function(ExperimentsSnapshot) _then) = _$ExperimentsSnapshotCopyWithImpl;
@useResult
$Res call({
 List<ExperimentAssignment> assignments
});




}
/// @nodoc
class _$ExperimentsSnapshotCopyWithImpl<$Res>
    implements $ExperimentsSnapshotCopyWith<$Res> {
  _$ExperimentsSnapshotCopyWithImpl(this._self, this._then);

  final ExperimentsSnapshot _self;
  final $Res Function(ExperimentsSnapshot) _then;

/// Create a copy of ExperimentsSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? assignments = null,}) {
  return _then(_self.copyWith(
assignments: null == assignments ? _self.assignments : assignments // ignore: cast_nullable_to_non_nullable
as List<ExperimentAssignment>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExperimentsSnapshot].
extension ExperimentsSnapshotPatterns on ExperimentsSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExperimentsSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExperimentsSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExperimentsSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _ExperimentsSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExperimentsSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _ExperimentsSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ExperimentAssignment> assignments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExperimentsSnapshot() when $default != null:
return $default(_that.assignments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ExperimentAssignment> assignments)  $default,) {final _that = this;
switch (_that) {
case _ExperimentsSnapshot():
return $default(_that.assignments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ExperimentAssignment> assignments)?  $default,) {final _that = this;
switch (_that) {
case _ExperimentsSnapshot() when $default != null:
return $default(_that.assignments);case _:
  return null;

}
}

}

/// @nodoc


class _ExperimentsSnapshot extends ExperimentsSnapshot {
  const _ExperimentsSnapshot({final  List<ExperimentAssignment> assignments = const <ExperimentAssignment>[]}): _assignments = assignments,super._();
  

 final  List<ExperimentAssignment> _assignments;
@override@JsonKey() List<ExperimentAssignment> get assignments {
  if (_assignments is EqualUnmodifiableListView) return _assignments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_assignments);
}


/// Create a copy of ExperimentsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExperimentsSnapshotCopyWith<_ExperimentsSnapshot> get copyWith => __$ExperimentsSnapshotCopyWithImpl<_ExperimentsSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExperimentsSnapshot&&const DeepCollectionEquality().equals(other._assignments, _assignments));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_assignments));

@override
String toString() {
  return 'ExperimentsSnapshot(assignments: $assignments)';
}


}

/// @nodoc
abstract mixin class _$ExperimentsSnapshotCopyWith<$Res> implements $ExperimentsSnapshotCopyWith<$Res> {
  factory _$ExperimentsSnapshotCopyWith(_ExperimentsSnapshot value, $Res Function(_ExperimentsSnapshot) _then) = __$ExperimentsSnapshotCopyWithImpl;
@override @useResult
$Res call({
 List<ExperimentAssignment> assignments
});




}
/// @nodoc
class __$ExperimentsSnapshotCopyWithImpl<$Res>
    implements _$ExperimentsSnapshotCopyWith<$Res> {
  __$ExperimentsSnapshotCopyWithImpl(this._self, this._then);

  final _ExperimentsSnapshot _self;
  final $Res Function(_ExperimentsSnapshot) _then;

/// Create a copy of ExperimentsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? assignments = null,}) {
  return _then(_ExperimentsSnapshot(
assignments: null == assignments ? _self._assignments : assignments // ignore: cast_nullable_to_non_nullable
as List<ExperimentAssignment>,
  ));
}


}

// dart format on
