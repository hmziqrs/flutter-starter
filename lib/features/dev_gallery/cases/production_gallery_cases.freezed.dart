// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'production_gallery_cases.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingGalleryState {

 int get initialPage;
/// Create a copy of OnboardingGalleryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingGalleryStateCopyWith<OnboardingGalleryState> get copyWith => _$OnboardingGalleryStateCopyWithImpl<OnboardingGalleryState>(this as OnboardingGalleryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingGalleryState&&(identical(other.initialPage, initialPage) || other.initialPage == initialPage));
}


@override
int get hashCode => Object.hash(runtimeType,initialPage);

@override
String toString() {
  return 'OnboardingGalleryState(initialPage: $initialPage)';
}


}

/// @nodoc
abstract mixin class $OnboardingGalleryStateCopyWith<$Res>  {
  factory $OnboardingGalleryStateCopyWith(OnboardingGalleryState value, $Res Function(OnboardingGalleryState) _then) = _$OnboardingGalleryStateCopyWithImpl;
@useResult
$Res call({
 int initialPage
});




}
/// @nodoc
class _$OnboardingGalleryStateCopyWithImpl<$Res>
    implements $OnboardingGalleryStateCopyWith<$Res> {
  _$OnboardingGalleryStateCopyWithImpl(this._self, this._then);

  final OnboardingGalleryState _self;
  final $Res Function(OnboardingGalleryState) _then;

/// Create a copy of OnboardingGalleryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? initialPage = null,}) {
  return _then(_self.copyWith(
initialPage: null == initialPage ? _self.initialPage : initialPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingGalleryState].
extension OnboardingGalleryStatePatterns on OnboardingGalleryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingGalleryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingGalleryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingGalleryState value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingGalleryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingGalleryState value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingGalleryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int initialPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingGalleryState() when $default != null:
return $default(_that.initialPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int initialPage)  $default,) {final _that = this;
switch (_that) {
case _OnboardingGalleryState():
return $default(_that.initialPage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int initialPage)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingGalleryState() when $default != null:
return $default(_that.initialPage);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingGalleryState implements OnboardingGalleryState {
  const _OnboardingGalleryState({required this.initialPage});
  

@override final  int initialPage;

/// Create a copy of OnboardingGalleryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingGalleryStateCopyWith<_OnboardingGalleryState> get copyWith => __$OnboardingGalleryStateCopyWithImpl<_OnboardingGalleryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingGalleryState&&(identical(other.initialPage, initialPage) || other.initialPage == initialPage));
}


@override
int get hashCode => Object.hash(runtimeType,initialPage);

@override
String toString() {
  return 'OnboardingGalleryState(initialPage: $initialPage)';
}


}

/// @nodoc
abstract mixin class _$OnboardingGalleryStateCopyWith<$Res> implements $OnboardingGalleryStateCopyWith<$Res> {
  factory _$OnboardingGalleryStateCopyWith(_OnboardingGalleryState value, $Res Function(_OnboardingGalleryState) _then) = __$OnboardingGalleryStateCopyWithImpl;
@override @useResult
$Res call({
 int initialPage
});




}
/// @nodoc
class __$OnboardingGalleryStateCopyWithImpl<$Res>
    implements _$OnboardingGalleryStateCopyWith<$Res> {
  __$OnboardingGalleryStateCopyWithImpl(this._self, this._then);

  final _OnboardingGalleryState _self;
  final $Res Function(_OnboardingGalleryState) _then;

/// Create a copy of OnboardingGalleryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? initialPage = null,}) {
  return _then(_OnboardingGalleryState(
initialPage: null == initialPage ? _self.initialPage : initialPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PricingGalleryState {

 List<PlanViewData> get plans; BillingPeriod get billingPeriod; String get initialPlanId; PricingAvailability get availability;
/// Create a copy of PricingGalleryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PricingGalleryStateCopyWith<PricingGalleryState> get copyWith => _$PricingGalleryStateCopyWithImpl<PricingGalleryState>(this as PricingGalleryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PricingGalleryState&&const DeepCollectionEquality().equals(other.plans, plans)&&(identical(other.billingPeriod, billingPeriod) || other.billingPeriod == billingPeriod)&&(identical(other.initialPlanId, initialPlanId) || other.initialPlanId == initialPlanId)&&(identical(other.availability, availability) || other.availability == availability));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(plans),billingPeriod,initialPlanId,availability);

@override
String toString() {
  return 'PricingGalleryState(plans: $plans, billingPeriod: $billingPeriod, initialPlanId: $initialPlanId, availability: $availability)';
}


}

/// @nodoc
abstract mixin class $PricingGalleryStateCopyWith<$Res>  {
  factory $PricingGalleryStateCopyWith(PricingGalleryState value, $Res Function(PricingGalleryState) _then) = _$PricingGalleryStateCopyWithImpl;
@useResult
$Res call({
 Iterable<PlanViewData> plans, BillingPeriod billingPeriod, String initialPlanId, PricingAvailability availability
});




}
/// @nodoc
class _$PricingGalleryStateCopyWithImpl<$Res>
    implements $PricingGalleryStateCopyWith<$Res> {
  _$PricingGalleryStateCopyWithImpl(this._self, this._then);

  final PricingGalleryState _self;
  final $Res Function(PricingGalleryState) _then;

/// Create a copy of PricingGalleryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plans = null,Object? billingPeriod = null,Object? initialPlanId = null,Object? availability = null,}) {
  return _then(PricingGalleryState(
plans: null == plans ? _self.plans! : plans // ignore: cast_nullable_to_non_nullable
as Iterable<PlanViewData>,billingPeriod: null == billingPeriod ? _self.billingPeriod : billingPeriod // ignore: cast_nullable_to_non_nullable
as BillingPeriod,initialPlanId: null == initialPlanId ? _self.initialPlanId : initialPlanId // ignore: cast_nullable_to_non_nullable
as String,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as PricingAvailability,
  ));
}

}


/// Adds pattern-matching-related methods to [PricingGalleryState].
extension PricingGalleryStatePatterns on PricingGalleryState {
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
