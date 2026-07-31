// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'experiment_variant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExperimentVariant {

 Map<String, Object?> get payload;
/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentVariantCopyWith<ExperimentVariant> get copyWith => _$ExperimentVariantCopyWithImpl<ExperimentVariant>(this as ExperimentVariant, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentVariant&&const DeepCollectionEquality().equals(other.payload, payload));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(payload));

@override
String toString() {
  return 'ExperimentVariant(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ExperimentVariantCopyWith<$Res>  {
  factory $ExperimentVariantCopyWith(ExperimentVariant value, $Res Function(ExperimentVariant) _then) = _$ExperimentVariantCopyWithImpl;
@useResult
$Res call({
 Map<String, Object?> payload
});




}
/// @nodoc
class _$ExperimentVariantCopyWithImpl<$Res>
    implements $ExperimentVariantCopyWith<$Res> {
  _$ExperimentVariantCopyWithImpl(this._self, this._then);

  final ExperimentVariant _self;
  final $Res Function(ExperimentVariant) _then;

/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? payload = null,}) {
  return _then(_self.copyWith(
payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExperimentVariant].
extension ExperimentVariantPatterns on ExperimentVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExperimentVariantControl value)?  control,TResult Function( ExperimentVariantTreatmentA value)?  treatmentA,TResult Function( ExperimentVariantTreatmentB value)?  treatmentB,TResult Function( ExperimentVariantTreatmentC value)?  treatmentC,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExperimentVariantControl() when control != null:
return control(_that);case ExperimentVariantTreatmentA() when treatmentA != null:
return treatmentA(_that);case ExperimentVariantTreatmentB() when treatmentB != null:
return treatmentB(_that);case ExperimentVariantTreatmentC() when treatmentC != null:
return treatmentC(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExperimentVariantControl value)  control,required TResult Function( ExperimentVariantTreatmentA value)  treatmentA,required TResult Function( ExperimentVariantTreatmentB value)  treatmentB,required TResult Function( ExperimentVariantTreatmentC value)  treatmentC,}){
final _that = this;
switch (_that) {
case ExperimentVariantControl():
return control(_that);case ExperimentVariantTreatmentA():
return treatmentA(_that);case ExperimentVariantTreatmentB():
return treatmentB(_that);case ExperimentVariantTreatmentC():
return treatmentC(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExperimentVariantControl value)?  control,TResult? Function( ExperimentVariantTreatmentA value)?  treatmentA,TResult? Function( ExperimentVariantTreatmentB value)?  treatmentB,TResult? Function( ExperimentVariantTreatmentC value)?  treatmentC,}){
final _that = this;
switch (_that) {
case ExperimentVariantControl() when control != null:
return control(_that);case ExperimentVariantTreatmentA() when treatmentA != null:
return treatmentA(_that);case ExperimentVariantTreatmentB() when treatmentB != null:
return treatmentB(_that);case ExperimentVariantTreatmentC() when treatmentC != null:
return treatmentC(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Map<String, Object?> payload)?  control,TResult Function( Map<String, Object?> payload)?  treatmentA,TResult Function( Map<String, Object?> payload)?  treatmentB,TResult Function( Map<String, Object?> payload)?  treatmentC,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExperimentVariantControl() when control != null:
return control(_that.payload);case ExperimentVariantTreatmentA() when treatmentA != null:
return treatmentA(_that.payload);case ExperimentVariantTreatmentB() when treatmentB != null:
return treatmentB(_that.payload);case ExperimentVariantTreatmentC() when treatmentC != null:
return treatmentC(_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Map<String, Object?> payload)  control,required TResult Function( Map<String, Object?> payload)  treatmentA,required TResult Function( Map<String, Object?> payload)  treatmentB,required TResult Function( Map<String, Object?> payload)  treatmentC,}) {final _that = this;
switch (_that) {
case ExperimentVariantControl():
return control(_that.payload);case ExperimentVariantTreatmentA():
return treatmentA(_that.payload);case ExperimentVariantTreatmentB():
return treatmentB(_that.payload);case ExperimentVariantTreatmentC():
return treatmentC(_that.payload);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Map<String, Object?> payload)?  control,TResult? Function( Map<String, Object?> payload)?  treatmentA,TResult? Function( Map<String, Object?> payload)?  treatmentB,TResult? Function( Map<String, Object?> payload)?  treatmentC,}) {final _that = this;
switch (_that) {
case ExperimentVariantControl() when control != null:
return control(_that.payload);case ExperimentVariantTreatmentA() when treatmentA != null:
return treatmentA(_that.payload);case ExperimentVariantTreatmentB() when treatmentB != null:
return treatmentB(_that.payload);case ExperimentVariantTreatmentC() when treatmentC != null:
return treatmentC(_that.payload);case _:
  return null;

}
}

}

/// @nodoc


class ExperimentVariantControl extends ExperimentVariant {
  const ExperimentVariantControl({final  Map<String, Object?> payload = const <String, Object?>{}}): _payload = payload,super._();
  

 final  Map<String, Object?> _payload;
@override@JsonKey() Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentVariantControlCopyWith<ExperimentVariantControl> get copyWith => _$ExperimentVariantControlCopyWithImpl<ExperimentVariantControl>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentVariantControl&&const DeepCollectionEquality().equals(other._payload, _payload));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'ExperimentVariant.control(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ExperimentVariantControlCopyWith<$Res> implements $ExperimentVariantCopyWith<$Res> {
  factory $ExperimentVariantControlCopyWith(ExperimentVariantControl value, $Res Function(ExperimentVariantControl) _then) = _$ExperimentVariantControlCopyWithImpl;
@override @useResult
$Res call({
 Map<String, Object?> payload
});




}
/// @nodoc
class _$ExperimentVariantControlCopyWithImpl<$Res>
    implements $ExperimentVariantControlCopyWith<$Res> {
  _$ExperimentVariantControlCopyWithImpl(this._self, this._then);

  final ExperimentVariantControl _self;
  final $Res Function(ExperimentVariantControl) _then;

/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ExperimentVariantControl(
payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

/// @nodoc


class ExperimentVariantTreatmentA extends ExperimentVariant {
  const ExperimentVariantTreatmentA({final  Map<String, Object?> payload = const <String, Object?>{}}): _payload = payload,super._();
  

 final  Map<String, Object?> _payload;
@override@JsonKey() Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentVariantTreatmentACopyWith<ExperimentVariantTreatmentA> get copyWith => _$ExperimentVariantTreatmentACopyWithImpl<ExperimentVariantTreatmentA>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentVariantTreatmentA&&const DeepCollectionEquality().equals(other._payload, _payload));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'ExperimentVariant.treatmentA(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ExperimentVariantTreatmentACopyWith<$Res> implements $ExperimentVariantCopyWith<$Res> {
  factory $ExperimentVariantTreatmentACopyWith(ExperimentVariantTreatmentA value, $Res Function(ExperimentVariantTreatmentA) _then) = _$ExperimentVariantTreatmentACopyWithImpl;
@override @useResult
$Res call({
 Map<String, Object?> payload
});




}
/// @nodoc
class _$ExperimentVariantTreatmentACopyWithImpl<$Res>
    implements $ExperimentVariantTreatmentACopyWith<$Res> {
  _$ExperimentVariantTreatmentACopyWithImpl(this._self, this._then);

  final ExperimentVariantTreatmentA _self;
  final $Res Function(ExperimentVariantTreatmentA) _then;

/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ExperimentVariantTreatmentA(
payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

/// @nodoc


class ExperimentVariantTreatmentB extends ExperimentVariant {
  const ExperimentVariantTreatmentB({final  Map<String, Object?> payload = const <String, Object?>{}}): _payload = payload,super._();
  

 final  Map<String, Object?> _payload;
@override@JsonKey() Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentVariantTreatmentBCopyWith<ExperimentVariantTreatmentB> get copyWith => _$ExperimentVariantTreatmentBCopyWithImpl<ExperimentVariantTreatmentB>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentVariantTreatmentB&&const DeepCollectionEquality().equals(other._payload, _payload));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'ExperimentVariant.treatmentB(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ExperimentVariantTreatmentBCopyWith<$Res> implements $ExperimentVariantCopyWith<$Res> {
  factory $ExperimentVariantTreatmentBCopyWith(ExperimentVariantTreatmentB value, $Res Function(ExperimentVariantTreatmentB) _then) = _$ExperimentVariantTreatmentBCopyWithImpl;
@override @useResult
$Res call({
 Map<String, Object?> payload
});




}
/// @nodoc
class _$ExperimentVariantTreatmentBCopyWithImpl<$Res>
    implements $ExperimentVariantTreatmentBCopyWith<$Res> {
  _$ExperimentVariantTreatmentBCopyWithImpl(this._self, this._then);

  final ExperimentVariantTreatmentB _self;
  final $Res Function(ExperimentVariantTreatmentB) _then;

/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ExperimentVariantTreatmentB(
payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

/// @nodoc


class ExperimentVariantTreatmentC extends ExperimentVariant {
  const ExperimentVariantTreatmentC({final  Map<String, Object?> payload = const <String, Object?>{}}): _payload = payload,super._();
  

 final  Map<String, Object?> _payload;
@override@JsonKey() Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExperimentVariantTreatmentCCopyWith<ExperimentVariantTreatmentC> get copyWith => _$ExperimentVariantTreatmentCCopyWithImpl<ExperimentVariantTreatmentC>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExperimentVariantTreatmentC&&const DeepCollectionEquality().equals(other._payload, _payload));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'ExperimentVariant.treatmentC(payload: $payload)';
}


}

/// @nodoc
abstract mixin class $ExperimentVariantTreatmentCCopyWith<$Res> implements $ExperimentVariantCopyWith<$Res> {
  factory $ExperimentVariantTreatmentCCopyWith(ExperimentVariantTreatmentC value, $Res Function(ExperimentVariantTreatmentC) _then) = _$ExperimentVariantTreatmentCCopyWithImpl;
@override @useResult
$Res call({
 Map<String, Object?> payload
});




}
/// @nodoc
class _$ExperimentVariantTreatmentCCopyWithImpl<$Res>
    implements $ExperimentVariantTreatmentCCopyWith<$Res> {
  _$ExperimentVariantTreatmentCCopyWithImpl(this._self, this._then);

  final ExperimentVariantTreatmentC _self;
  final $Res Function(ExperimentVariantTreatmentC) _then;

/// Create a copy of ExperimentVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payload = null,}) {
  return _then(ExperimentVariantTreatmentC(
payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}


}

// dart format on
