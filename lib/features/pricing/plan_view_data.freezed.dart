// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_view_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlanViewData {

 String get id; String get name; String get description; num get monthlyPrice; num get annualPrice; String get currencyCode; List<String> get benefits; bool get isRecommended; bool get isCurrent; PricingAvailability get availability;
/// Create a copy of PlanViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanViewDataCopyWith<PlanViewData> get copyWith => _$PlanViewDataCopyWithImpl<PlanViewData>(this as PlanViewData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.monthlyPrice, monthlyPrice) || other.monthlyPrice == monthlyPrice)&&(identical(other.annualPrice, annualPrice) || other.annualPrice == annualPrice)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&const DeepCollectionEquality().equals(other.benefits, benefits)&&(identical(other.isRecommended, isRecommended) || other.isRecommended == isRecommended)&&(identical(other.isCurrent, isCurrent) || other.isCurrent == isCurrent)&&(identical(other.availability, availability) || other.availability == availability));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,monthlyPrice,annualPrice,currencyCode,const DeepCollectionEquality().hash(benefits),isRecommended,isCurrent,availability);

@override
String toString() {
  return 'PlanViewData(id: $id, name: $name, description: $description, monthlyPrice: $monthlyPrice, annualPrice: $annualPrice, currencyCode: $currencyCode, benefits: $benefits, isRecommended: $isRecommended, isCurrent: $isCurrent, availability: $availability)';
}


}

/// @nodoc
abstract mixin class $PlanViewDataCopyWith<$Res>  {
  factory $PlanViewDataCopyWith(PlanViewData value, $Res Function(PlanViewData) _then) = _$PlanViewDataCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, num monthlyPrice, num annualPrice, String currencyCode, List<String> benefits, bool isRecommended, bool isCurrent, PricingAvailability availability
});




}
/// @nodoc
class _$PlanViewDataCopyWithImpl<$Res>
    implements $PlanViewDataCopyWith<$Res> {
  _$PlanViewDataCopyWithImpl(this._self, this._then);

  final PlanViewData _self;
  final $Res Function(PlanViewData) _then;

/// Create a copy of PlanViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? monthlyPrice = null,Object? annualPrice = null,Object? currencyCode = null,Object? benefits = null,Object? isRecommended = null,Object? isCurrent = null,Object? availability = null,}) {
  return _then(PlanViewData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,monthlyPrice: null == monthlyPrice ? _self.monthlyPrice : monthlyPrice // ignore: cast_nullable_to_non_nullable
as num,annualPrice: null == annualPrice ? _self.annualPrice : annualPrice // ignore: cast_nullable_to_non_nullable
as num,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,benefits: null == benefits ? _self.benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<String>,isRecommended: null == isRecommended ? _self.isRecommended : isRecommended // ignore: cast_nullable_to_non_nullable
as bool,isCurrent: null == isCurrent ? _self.isCurrent : isCurrent // ignore: cast_nullable_to_non_nullable
as bool,availability: null == availability ? _self.availability : availability // ignore: cast_nullable_to_non_nullable
as PricingAvailability,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanViewData].
extension PlanViewDataPatterns on PlanViewData {
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
