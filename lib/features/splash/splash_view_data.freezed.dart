// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'splash_view_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SplashViewData {

 SplashPhase get phase; String? get buildLabel; String? get errorDiagnosticId;
/// Create a copy of SplashViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplashViewDataCopyWith<SplashViewData> get copyWith => _$SplashViewDataCopyWithImpl<SplashViewData>(this as SplashViewData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashViewData&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.buildLabel, buildLabel) || other.buildLabel == buildLabel)&&(identical(other.errorDiagnosticId, errorDiagnosticId) || other.errorDiagnosticId == errorDiagnosticId));
}


@override
int get hashCode => Object.hash(runtimeType,phase,buildLabel,errorDiagnosticId);

@override
String toString() {
  return 'SplashViewData(phase: $phase, buildLabel: $buildLabel, errorDiagnosticId: $errorDiagnosticId)';
}


}

/// @nodoc
abstract mixin class $SplashViewDataCopyWith<$Res>  {
  factory $SplashViewDataCopyWith(SplashViewData value, $Res Function(SplashViewData) _then) = _$SplashViewDataCopyWithImpl;
@useResult
$Res call({
 SplashPhase phase, String? buildLabel, String? errorDiagnosticId
});




}
/// @nodoc
class _$SplashViewDataCopyWithImpl<$Res>
    implements $SplashViewDataCopyWith<$Res> {
  _$SplashViewDataCopyWithImpl(this._self, this._then);

  final SplashViewData _self;
  final $Res Function(SplashViewData) _then;

/// Create a copy of SplashViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? buildLabel = freezed,Object? errorDiagnosticId = freezed,}) {
  return _then(SplashViewData(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as SplashPhase,buildLabel: freezed == buildLabel ? _self.buildLabel : buildLabel // ignore: cast_nullable_to_non_nullable
as String?,errorDiagnosticId: freezed == errorDiagnosticId ? _self.errorDiagnosticId : errorDiagnosticId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SplashViewData].
extension SplashViewDataPatterns on SplashViewData {
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
