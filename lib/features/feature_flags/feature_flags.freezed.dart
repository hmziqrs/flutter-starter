// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_flags.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeatureFlags {

 bool get onboardingRevamp; bool get homeRedesign; bool get checkoutV2; bool get profileSync; String get searchBackend; int get checkoutRolloutPercent;
/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureFlagsCopyWith<FeatureFlags> get copyWith => _$FeatureFlagsCopyWithImpl<FeatureFlags>(this as FeatureFlags, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureFlags&&(identical(other.onboardingRevamp, onboardingRevamp) || other.onboardingRevamp == onboardingRevamp)&&(identical(other.homeRedesign, homeRedesign) || other.homeRedesign == homeRedesign)&&(identical(other.checkoutV2, checkoutV2) || other.checkoutV2 == checkoutV2)&&(identical(other.profileSync, profileSync) || other.profileSync == profileSync)&&(identical(other.searchBackend, searchBackend) || other.searchBackend == searchBackend)&&(identical(other.checkoutRolloutPercent, checkoutRolloutPercent) || other.checkoutRolloutPercent == checkoutRolloutPercent));
}


@override
int get hashCode => Object.hash(runtimeType,onboardingRevamp,homeRedesign,checkoutV2,profileSync,searchBackend,checkoutRolloutPercent);

@override
String toString() {
  return 'FeatureFlags(onboardingRevamp: $onboardingRevamp, homeRedesign: $homeRedesign, checkoutV2: $checkoutV2, profileSync: $profileSync, searchBackend: $searchBackend, checkoutRolloutPercent: $checkoutRolloutPercent)';
}


}

/// @nodoc
abstract mixin class $FeatureFlagsCopyWith<$Res>  {
  factory $FeatureFlagsCopyWith(FeatureFlags value, $Res Function(FeatureFlags) _then) = _$FeatureFlagsCopyWithImpl;
@useResult
$Res call({
 bool onboardingRevamp, bool homeRedesign, bool checkoutV2, bool profileSync, String searchBackend, int checkoutRolloutPercent
});




}
/// @nodoc
class _$FeatureFlagsCopyWithImpl<$Res>
    implements $FeatureFlagsCopyWith<$Res> {
  _$FeatureFlagsCopyWithImpl(this._self, this._then);

  final FeatureFlags _self;
  final $Res Function(FeatureFlags) _then;

/// Create a copy of FeatureFlags
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? onboardingRevamp = null,Object? homeRedesign = null,Object? checkoutV2 = null,Object? profileSync = null,Object? searchBackend = null,Object? checkoutRolloutPercent = null,}) {
  return _then(FeatureFlags(
onboardingRevamp: null == onboardingRevamp ? _self.onboardingRevamp : onboardingRevamp // ignore: cast_nullable_to_non_nullable
as bool,homeRedesign: null == homeRedesign ? _self.homeRedesign : homeRedesign // ignore: cast_nullable_to_non_nullable
as bool,checkoutV2: null == checkoutV2 ? _self.checkoutV2 : checkoutV2 // ignore: cast_nullable_to_non_nullable
as bool,profileSync: null == profileSync ? _self.profileSync : profileSync // ignore: cast_nullable_to_non_nullable
as bool,searchBackend: null == searchBackend ? _self.searchBackend : searchBackend // ignore: cast_nullable_to_non_nullable
as String,checkoutRolloutPercent: null == checkoutRolloutPercent ? _self.checkoutRolloutPercent : checkoutRolloutPercent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureFlags].
extension FeatureFlagsPatterns on FeatureFlags {
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
