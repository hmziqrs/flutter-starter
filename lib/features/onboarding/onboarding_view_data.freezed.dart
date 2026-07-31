// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_view_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingSlideViewData {

 String get id; String get title; String get body; OnboardingVisual get visual;
/// Create a copy of OnboardingSlideViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingSlideViewDataCopyWith<OnboardingSlideViewData> get copyWith => _$OnboardingSlideViewDataCopyWithImpl<OnboardingSlideViewData>(this as OnboardingSlideViewData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingSlideViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.visual, visual) || other.visual == visual));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,body,visual);

@override
String toString() {
  return 'OnboardingSlideViewData(id: $id, title: $title, body: $body, visual: $visual)';
}


}

/// @nodoc
abstract mixin class $OnboardingSlideViewDataCopyWith<$Res>  {
  factory $OnboardingSlideViewDataCopyWith(OnboardingSlideViewData value, $Res Function(OnboardingSlideViewData) _then) = _$OnboardingSlideViewDataCopyWithImpl;
@useResult
$Res call({
 String id, String title, String body, OnboardingVisual visual
});




}
/// @nodoc
class _$OnboardingSlideViewDataCopyWithImpl<$Res>
    implements $OnboardingSlideViewDataCopyWith<$Res> {
  _$OnboardingSlideViewDataCopyWithImpl(this._self, this._then);

  final OnboardingSlideViewData _self;
  final $Res Function(OnboardingSlideViewData) _then;

/// Create a copy of OnboardingSlideViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? body = null,Object? visual = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,visual: null == visual ? _self.visual : visual // ignore: cast_nullable_to_non_nullable
as OnboardingVisual,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingSlideViewData].
extension OnboardingSlideViewDataPatterns on OnboardingSlideViewData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingSlideViewData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingSlideViewData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingSlideViewData value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingSlideViewData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingSlideViewData value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingSlideViewData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String body,  OnboardingVisual visual)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingSlideViewData() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.visual);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String body,  OnboardingVisual visual)  $default,) {final _that = this;
switch (_that) {
case _OnboardingSlideViewData():
return $default(_that.id,_that.title,_that.body,_that.visual);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String body,  OnboardingVisual visual)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingSlideViewData() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.visual);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingSlideViewData implements OnboardingSlideViewData {
  const _OnboardingSlideViewData({required this.id, required this.title, required this.body, required this.visual});
  

@override final  String id;
@override final  String title;
@override final  String body;
@override final  OnboardingVisual visual;

/// Create a copy of OnboardingSlideViewData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingSlideViewDataCopyWith<_OnboardingSlideViewData> get copyWith => __$OnboardingSlideViewDataCopyWithImpl<_OnboardingSlideViewData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingSlideViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.visual, visual) || other.visual == visual));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,body,visual);

@override
String toString() {
  return 'OnboardingSlideViewData(id: $id, title: $title, body: $body, visual: $visual)';
}


}

/// @nodoc
abstract mixin class _$OnboardingSlideViewDataCopyWith<$Res> implements $OnboardingSlideViewDataCopyWith<$Res> {
  factory _$OnboardingSlideViewDataCopyWith(_OnboardingSlideViewData value, $Res Function(_OnboardingSlideViewData) _then) = __$OnboardingSlideViewDataCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String body, OnboardingVisual visual
});




}
/// @nodoc
class __$OnboardingSlideViewDataCopyWithImpl<$Res>
    implements _$OnboardingSlideViewDataCopyWith<$Res> {
  __$OnboardingSlideViewDataCopyWithImpl(this._self, this._then);

  final _OnboardingSlideViewData _self;
  final $Res Function(_OnboardingSlideViewData) _then;

/// Create a copy of OnboardingSlideViewData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? body = null,Object? visual = null,}) {
  return _then(_OnboardingSlideViewData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,visual: null == visual ? _self.visual : visual // ignore: cast_nullable_to_non_nullable
as OnboardingVisual,
  ));
}


}

// dart format on
