// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {

 AppThemeMode get themeMode; AppAccent get accent; double get fontScale; AppTextPreset get textPreset; AppLocale? get localeOverride; bool get hasCompletedOnboarding; bool get biometricUnlockEnabled; bool get hapticsEnabled; bool get passcodeEnabled; int get autoLockDelaySeconds; bool get lockOnBackground;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.fontScale, fontScale) || other.fontScale == fontScale)&&(identical(other.textPreset, textPreset) || other.textPreset == textPreset)&&const DeepCollectionEquality().equals(other.localeOverride, localeOverride)&&(identical(other.hasCompletedOnboarding, hasCompletedOnboarding) || other.hasCompletedOnboarding == hasCompletedOnboarding)&&(identical(other.biometricUnlockEnabled, biometricUnlockEnabled) || other.biometricUnlockEnabled == biometricUnlockEnabled)&&(identical(other.hapticsEnabled, hapticsEnabled) || other.hapticsEnabled == hapticsEnabled)&&(identical(other.passcodeEnabled, passcodeEnabled) || other.passcodeEnabled == passcodeEnabled)&&(identical(other.autoLockDelaySeconds, autoLockDelaySeconds) || other.autoLockDelaySeconds == autoLockDelaySeconds)&&(identical(other.lockOnBackground, lockOnBackground) || other.lockOnBackground == lockOnBackground));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,accent,fontScale,textPreset,const DeepCollectionEquality().hash(localeOverride),hasCompletedOnboarding,biometricUnlockEnabled,hapticsEnabled,passcodeEnabled,autoLockDelaySeconds,lockOnBackground);

@override
String toString() {
  return 'SettingsState(themeMode: $themeMode, accent: $accent, fontScale: $fontScale, textPreset: $textPreset, localeOverride: $localeOverride, hasCompletedOnboarding: $hasCompletedOnboarding, biometricUnlockEnabled: $biometricUnlockEnabled, hapticsEnabled: $hapticsEnabled, passcodeEnabled: $passcodeEnabled, autoLockDelaySeconds: $autoLockDelaySeconds, lockOnBackground: $lockOnBackground)';
}


}




/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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
