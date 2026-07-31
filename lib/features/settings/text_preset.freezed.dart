// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'text_preset.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppTextPresetSettings {

 double get fontScale; String? get fontFamily;
/// Create a copy of AppTextPresetSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppTextPresetSettingsCopyWith<AppTextPresetSettings> get copyWith => _$AppTextPresetSettingsCopyWithImpl<AppTextPresetSettings>(this as AppTextPresetSettings, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppTextPresetSettings&&(identical(other.fontScale, fontScale) || other.fontScale == fontScale)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily));
}


@override
int get hashCode => Object.hash(runtimeType,fontScale,fontFamily);

@override
String toString() {
  return 'AppTextPresetSettings(fontScale: $fontScale, fontFamily: $fontFamily)';
}


}

/// @nodoc
abstract mixin class $AppTextPresetSettingsCopyWith<$Res>  {
  factory $AppTextPresetSettingsCopyWith(AppTextPresetSettings value, $Res Function(AppTextPresetSettings) _then) = _$AppTextPresetSettingsCopyWithImpl;
@useResult
$Res call({
 double fontScale, String? fontFamily
});




}
/// @nodoc
class _$AppTextPresetSettingsCopyWithImpl<$Res>
    implements $AppTextPresetSettingsCopyWith<$Res> {
  _$AppTextPresetSettingsCopyWithImpl(this._self, this._then);

  final AppTextPresetSettings _self;
  final $Res Function(AppTextPresetSettings) _then;

/// Create a copy of AppTextPresetSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fontScale = null,Object? fontFamily = freezed,}) {
  return _then(_self.copyWith(
fontScale: null == fontScale ? _self.fontScale : fontScale // ignore: cast_nullable_to_non_nullable
as double,fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppTextPresetSettings].
extension AppTextPresetSettingsPatterns on AppTextPresetSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppTextPresetSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppTextPresetSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppTextPresetSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppTextPresetSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppTextPresetSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppTextPresetSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double fontScale,  String? fontFamily)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppTextPresetSettings() when $default != null:
return $default(_that.fontScale,_that.fontFamily);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double fontScale,  String? fontFamily)  $default,) {final _that = this;
switch (_that) {
case _AppTextPresetSettings():
return $default(_that.fontScale,_that.fontFamily);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double fontScale,  String? fontFamily)?  $default,) {final _that = this;
switch (_that) {
case _AppTextPresetSettings() when $default != null:
return $default(_that.fontScale,_that.fontFamily);case _:
  return null;

}
}

}

/// @nodoc


class _AppTextPresetSettings implements AppTextPresetSettings {
  const _AppTextPresetSettings({required this.fontScale, this.fontFamily});
  

@override final  double fontScale;
@override final  String? fontFamily;

/// Create a copy of AppTextPresetSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppTextPresetSettingsCopyWith<_AppTextPresetSettings> get copyWith => __$AppTextPresetSettingsCopyWithImpl<_AppTextPresetSettings>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppTextPresetSettings&&(identical(other.fontScale, fontScale) || other.fontScale == fontScale)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily));
}


@override
int get hashCode => Object.hash(runtimeType,fontScale,fontFamily);

@override
String toString() {
  return 'AppTextPresetSettings(fontScale: $fontScale, fontFamily: $fontFamily)';
}


}

/// @nodoc
abstract mixin class _$AppTextPresetSettingsCopyWith<$Res> implements $AppTextPresetSettingsCopyWith<$Res> {
  factory _$AppTextPresetSettingsCopyWith(_AppTextPresetSettings value, $Res Function(_AppTextPresetSettings) _then) = __$AppTextPresetSettingsCopyWithImpl;
@override @useResult
$Res call({
 double fontScale, String? fontFamily
});




}
/// @nodoc
class __$AppTextPresetSettingsCopyWithImpl<$Res>
    implements _$AppTextPresetSettingsCopyWith<$Res> {
  __$AppTextPresetSettingsCopyWithImpl(this._self, this._then);

  final _AppTextPresetSettings _self;
  final $Res Function(_AppTextPresetSettings) _then;

/// Create a copy of AppTextPresetSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fontScale = null,Object? fontFamily = freezed,}) {
  return _then(_AppTextPresetSettings(
fontScale: null == fontScale ? _self.fontScale : fontScale // ignore: cast_nullable_to_non_nullable
as double,fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
