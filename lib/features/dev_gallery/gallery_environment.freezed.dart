// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gallery_environment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GalleryViewportPreset {

 String get id; Size get size; GalleryLabelBuilder get labelBuilder; double get devicePixelRatio;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryViewportPreset&&(identical(other.id, id) || other.id == id)&&(identical(other.size, size) || other.size == size)&&(identical(other.labelBuilder, labelBuilder) || other.labelBuilder == labelBuilder)&&(identical(other.devicePixelRatio, devicePixelRatio) || other.devicePixelRatio == devicePixelRatio));
}


@override
int get hashCode => Object.hash(runtimeType,id,size,labelBuilder,devicePixelRatio);

@override
String toString() {
  return 'GalleryViewportPreset(id: $id, size: $size, labelBuilder: $labelBuilder, devicePixelRatio: $devicePixelRatio)';
}


}




/// Adds pattern-matching-related methods to [GalleryViewportPreset].
extension GalleryViewportPresetPatterns on GalleryViewportPreset {
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

/// @nodoc
mixin _$GalleryEnvironment {

 GalleryViewportPreset get viewport; Brightness get brightness; AppAccent get accent; AppLocale get locale; double get appFontScale; GallerySystemTextScale get systemTextScale; AppInteractionPolicy get interactionPolicy; AppViewingEnvironment get viewingEnvironment; AppTvPlatform get tvPlatform; bool get animationsEnabled; bool get highContrast; bool get boldText; bool get safeAreaEnabled; bool get keyboardInsetsEnabled; GalleryDisplayFeature get displayFeature;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GalleryEnvironment&&(identical(other.viewport, viewport) || other.viewport == viewport)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.accent, accent) || other.accent == accent)&&const DeepCollectionEquality().equals(other.locale, locale)&&(identical(other.appFontScale, appFontScale) || other.appFontScale == appFontScale)&&(identical(other.systemTextScale, systemTextScale) || other.systemTextScale == systemTextScale)&&(identical(other.interactionPolicy, interactionPolicy) || other.interactionPolicy == interactionPolicy)&&(identical(other.viewingEnvironment, viewingEnvironment) || other.viewingEnvironment == viewingEnvironment)&&(identical(other.tvPlatform, tvPlatform) || other.tvPlatform == tvPlatform)&&(identical(other.animationsEnabled, animationsEnabled) || other.animationsEnabled == animationsEnabled)&&(identical(other.highContrast, highContrast) || other.highContrast == highContrast)&&(identical(other.boldText, boldText) || other.boldText == boldText)&&(identical(other.safeAreaEnabled, safeAreaEnabled) || other.safeAreaEnabled == safeAreaEnabled)&&(identical(other.keyboardInsetsEnabled, keyboardInsetsEnabled) || other.keyboardInsetsEnabled == keyboardInsetsEnabled)&&(identical(other.displayFeature, displayFeature) || other.displayFeature == displayFeature));
}


@override
int get hashCode => Object.hash(runtimeType,viewport,brightness,accent,const DeepCollectionEquality().hash(locale),appFontScale,systemTextScale,interactionPolicy,viewingEnvironment,tvPlatform,animationsEnabled,highContrast,boldText,safeAreaEnabled,keyboardInsetsEnabled,displayFeature);

@override
String toString() {
  return 'GalleryEnvironment(viewport: $viewport, brightness: $brightness, accent: $accent, locale: $locale, appFontScale: $appFontScale, systemTextScale: $systemTextScale, interactionPolicy: $interactionPolicy, viewingEnvironment: $viewingEnvironment, tvPlatform: $tvPlatform, animationsEnabled: $animationsEnabled, highContrast: $highContrast, boldText: $boldText, safeAreaEnabled: $safeAreaEnabled, keyboardInsetsEnabled: $keyboardInsetsEnabled, displayFeature: $displayFeature)';
}


}




/// Adds pattern-matching-related methods to [GalleryEnvironment].
extension GalleryEnvironmentPatterns on GalleryEnvironment {
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
