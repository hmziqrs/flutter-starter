// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedbackControllerState {

 FeedbackDraft get draft; FeedbackPresentationState get presentation;
/// Create a copy of FeedbackControllerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackControllerStateCopyWith<FeedbackControllerState> get copyWith => _$FeedbackControllerStateCopyWithImpl<FeedbackControllerState>(this as FeedbackControllerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackControllerState&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,draft,presentation);

@override
String toString() {
  return 'FeedbackControllerState(draft: $draft, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class $FeedbackControllerStateCopyWith<$Res>  {
  factory $FeedbackControllerStateCopyWith(FeedbackControllerState value, $Res Function(FeedbackControllerState) _then) = _$FeedbackControllerStateCopyWithImpl;
@useResult
$Res call({
 FeedbackDraft draft, FeedbackPresentationState presentation
});


$FeedbackPresentationStateCopyWith<$Res> get presentation;

}
/// @nodoc
class _$FeedbackControllerStateCopyWithImpl<$Res>
    implements $FeedbackControllerStateCopyWith<$Res> {
  _$FeedbackControllerStateCopyWithImpl(this._self, this._then);

  final FeedbackControllerState _self;
  final $Res Function(FeedbackControllerState) _then;

/// Create a copy of FeedbackControllerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? draft = null,Object? presentation = null,}) {
  return _then(_self.copyWith(
draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as FeedbackDraft,presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as FeedbackPresentationState,
  ));
}
/// Create a copy of FeedbackControllerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeedbackPresentationStateCopyWith<$Res> get presentation {
  
  return $FeedbackPresentationStateCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}


/// Adds pattern-matching-related methods to [FeedbackControllerState].
extension FeedbackControllerStatePatterns on FeedbackControllerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackControllerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackControllerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackControllerState value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackControllerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackControllerState value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackControllerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FeedbackDraft draft,  FeedbackPresentationState presentation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackControllerState() when $default != null:
return $default(_that.draft,_that.presentation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FeedbackDraft draft,  FeedbackPresentationState presentation)  $default,) {final _that = this;
switch (_that) {
case _FeedbackControllerState():
return $default(_that.draft,_that.presentation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FeedbackDraft draft,  FeedbackPresentationState presentation)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackControllerState() when $default != null:
return $default(_that.draft,_that.presentation);case _:
  return null;

}
}

}

/// @nodoc


class _FeedbackControllerState implements FeedbackControllerState {
  const _FeedbackControllerState({this.draft = const FeedbackDraft.empty(), this.presentation = const FeedbackPresentationState()});
  

@override@JsonKey() final  FeedbackDraft draft;
@override@JsonKey() final  FeedbackPresentationState presentation;

/// Create a copy of FeedbackControllerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackControllerStateCopyWith<_FeedbackControllerState> get copyWith => __$FeedbackControllerStateCopyWithImpl<_FeedbackControllerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackControllerState&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.presentation, presentation) || other.presentation == presentation));
}


@override
int get hashCode => Object.hash(runtimeType,draft,presentation);

@override
String toString() {
  return 'FeedbackControllerState(draft: $draft, presentation: $presentation)';
}


}

/// @nodoc
abstract mixin class _$FeedbackControllerStateCopyWith<$Res> implements $FeedbackControllerStateCopyWith<$Res> {
  factory _$FeedbackControllerStateCopyWith(_FeedbackControllerState value, $Res Function(_FeedbackControllerState) _then) = __$FeedbackControllerStateCopyWithImpl;
@override @useResult
$Res call({
 FeedbackDraft draft, FeedbackPresentationState presentation
});


@override $FeedbackPresentationStateCopyWith<$Res> get presentation;

}
/// @nodoc
class __$FeedbackControllerStateCopyWithImpl<$Res>
    implements _$FeedbackControllerStateCopyWith<$Res> {
  __$FeedbackControllerStateCopyWithImpl(this._self, this._then);

  final _FeedbackControllerState _self;
  final $Res Function(_FeedbackControllerState) _then;

/// Create a copy of FeedbackControllerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? draft = null,Object? presentation = null,}) {
  return _then(_FeedbackControllerState(
draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as FeedbackDraft,presentation: null == presentation ? _self.presentation : presentation // ignore: cast_nullable_to_non_nullable
as FeedbackPresentationState,
  ));
}

/// Create a copy of FeedbackControllerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeedbackPresentationStateCopyWith<$Res> get presentation {
  
  return $FeedbackPresentationStateCopyWith<$Res>(_self.presentation, (value) {
    return _then(_self.copyWith(presentation: value));
  });
}
}

// dart format on
