// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feedback_form_value.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeedbackAppMetadata {

 String get appVersion; String get platform; String get locale;
/// Create a copy of FeedbackAppMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackAppMetadataCopyWith<FeedbackAppMetadata> get copyWith => _$FeedbackAppMetadataCopyWithImpl<FeedbackAppMetadata>(this as FeedbackAppMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackAppMetadata&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.locale, locale) || other.locale == locale));
}


@override
int get hashCode => Object.hash(runtimeType,appVersion,platform,locale);

@override
String toString() {
  return 'FeedbackAppMetadata(appVersion: $appVersion, platform: $platform, locale: $locale)';
}


}

/// @nodoc
abstract mixin class $FeedbackAppMetadataCopyWith<$Res>  {
  factory $FeedbackAppMetadataCopyWith(FeedbackAppMetadata value, $Res Function(FeedbackAppMetadata) _then) = _$FeedbackAppMetadataCopyWithImpl;
@useResult
$Res call({
 String appVersion, String platform, String locale
});




}
/// @nodoc
class _$FeedbackAppMetadataCopyWithImpl<$Res>
    implements $FeedbackAppMetadataCopyWith<$Res> {
  _$FeedbackAppMetadataCopyWithImpl(this._self, this._then);

  final FeedbackAppMetadata _self;
  final $Res Function(FeedbackAppMetadata) _then;

/// Create a copy of FeedbackAppMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appVersion = null,Object? platform = null,Object? locale = null,}) {
  return _then(_self.copyWith(
appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FeedbackAppMetadata].
extension FeedbackAppMetadataPatterns on FeedbackAppMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackAppMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackAppMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackAppMetadata value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackAppMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackAppMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackAppMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appVersion,  String platform,  String locale)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackAppMetadata() when $default != null:
return $default(_that.appVersion,_that.platform,_that.locale);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appVersion,  String platform,  String locale)  $default,) {final _that = this;
switch (_that) {
case _FeedbackAppMetadata():
return $default(_that.appVersion,_that.platform,_that.locale);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appVersion,  String platform,  String locale)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackAppMetadata() when $default != null:
return $default(_that.appVersion,_that.platform,_that.locale);case _:
  return null;

}
}

}

/// @nodoc


class _FeedbackAppMetadata implements FeedbackAppMetadata {
  const _FeedbackAppMetadata({required this.appVersion, required this.platform, required this.locale});
  

@override final  String appVersion;
@override final  String platform;
@override final  String locale;

/// Create a copy of FeedbackAppMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackAppMetadataCopyWith<_FeedbackAppMetadata> get copyWith => __$FeedbackAppMetadataCopyWithImpl<_FeedbackAppMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackAppMetadata&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.locale, locale) || other.locale == locale));
}


@override
int get hashCode => Object.hash(runtimeType,appVersion,platform,locale);

@override
String toString() {
  return 'FeedbackAppMetadata(appVersion: $appVersion, platform: $platform, locale: $locale)';
}


}

/// @nodoc
abstract mixin class _$FeedbackAppMetadataCopyWith<$Res> implements $FeedbackAppMetadataCopyWith<$Res> {
  factory _$FeedbackAppMetadataCopyWith(_FeedbackAppMetadata value, $Res Function(_FeedbackAppMetadata) _then) = __$FeedbackAppMetadataCopyWithImpl;
@override @useResult
$Res call({
 String appVersion, String platform, String locale
});




}
/// @nodoc
class __$FeedbackAppMetadataCopyWithImpl<$Res>
    implements _$FeedbackAppMetadataCopyWith<$Res> {
  __$FeedbackAppMetadataCopyWithImpl(this._self, this._then);

  final _FeedbackAppMetadata _self;
  final $Res Function(_FeedbackAppMetadata) _then;

/// Create a copy of FeedbackAppMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appVersion = null,Object? platform = null,Object? locale = null,}) {
  return _then(_FeedbackAppMetadata(
appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,locale: null == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$FeedbackDraft {

 String get message; String? get email; bool get includeScreenshot;



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackDraft&&(identical(other.message, message) || other.message == message)&&(identical(other.email, email) || other.email == email)&&(identical(other.includeScreenshot, includeScreenshot) || other.includeScreenshot == includeScreenshot));
}


@override
int get hashCode => Object.hash(runtimeType,message,email,includeScreenshot);

@override
String toString() {
  return 'FeedbackDraft(message: $message, email: $email, includeScreenshot: $includeScreenshot)';
}


}




/// Adds pattern-matching-related methods to [FeedbackDraft].
extension FeedbackDraftPatterns on FeedbackDraft {
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
mixin _$FeedbackFormValue {

 String get message; bool get includeScreenshot; FeedbackAppMetadata get appMetadata; String? get email;
/// Create a copy of FeedbackFormValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeedbackFormValueCopyWith<FeedbackFormValue> get copyWith => _$FeedbackFormValueCopyWithImpl<FeedbackFormValue>(this as FeedbackFormValue, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeedbackFormValue&&(identical(other.message, message) || other.message == message)&&(identical(other.includeScreenshot, includeScreenshot) || other.includeScreenshot == includeScreenshot)&&(identical(other.appMetadata, appMetadata) || other.appMetadata == appMetadata)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,message,includeScreenshot,appMetadata,email);

@override
String toString() {
  return 'FeedbackFormValue(message: $message, includeScreenshot: $includeScreenshot, appMetadata: $appMetadata, email: $email)';
}


}

/// @nodoc
abstract mixin class $FeedbackFormValueCopyWith<$Res>  {
  factory $FeedbackFormValueCopyWith(FeedbackFormValue value, $Res Function(FeedbackFormValue) _then) = _$FeedbackFormValueCopyWithImpl;
@useResult
$Res call({
 String message, bool includeScreenshot, FeedbackAppMetadata appMetadata, String? email
});


$FeedbackAppMetadataCopyWith<$Res> get appMetadata;

}
/// @nodoc
class _$FeedbackFormValueCopyWithImpl<$Res>
    implements $FeedbackFormValueCopyWith<$Res> {
  _$FeedbackFormValueCopyWithImpl(this._self, this._then);

  final FeedbackFormValue _self;
  final $Res Function(FeedbackFormValue) _then;

/// Create a copy of FeedbackFormValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? includeScreenshot = null,Object? appMetadata = null,Object? email = freezed,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,includeScreenshot: null == includeScreenshot ? _self.includeScreenshot : includeScreenshot // ignore: cast_nullable_to_non_nullable
as bool,appMetadata: null == appMetadata ? _self.appMetadata : appMetadata // ignore: cast_nullable_to_non_nullable
as FeedbackAppMetadata,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of FeedbackFormValue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeedbackAppMetadataCopyWith<$Res> get appMetadata {
  
  return $FeedbackAppMetadataCopyWith<$Res>(_self.appMetadata, (value) {
    return _then(_self.copyWith(appMetadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [FeedbackFormValue].
extension FeedbackFormValuePatterns on FeedbackFormValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeedbackFormValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeedbackFormValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeedbackFormValue value)  $default,){
final _that = this;
switch (_that) {
case _FeedbackFormValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeedbackFormValue value)?  $default,){
final _that = this;
switch (_that) {
case _FeedbackFormValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  bool includeScreenshot,  FeedbackAppMetadata appMetadata,  String? email)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeedbackFormValue() when $default != null:
return $default(_that.message,_that.includeScreenshot,_that.appMetadata,_that.email);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  bool includeScreenshot,  FeedbackAppMetadata appMetadata,  String? email)  $default,) {final _that = this;
switch (_that) {
case _FeedbackFormValue():
return $default(_that.message,_that.includeScreenshot,_that.appMetadata,_that.email);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  bool includeScreenshot,  FeedbackAppMetadata appMetadata,  String? email)?  $default,) {final _that = this;
switch (_that) {
case _FeedbackFormValue() when $default != null:
return $default(_that.message,_that.includeScreenshot,_that.appMetadata,_that.email);case _:
  return null;

}
}

}

/// @nodoc


class _FeedbackFormValue implements FeedbackFormValue {
  const _FeedbackFormValue({required this.message, required this.includeScreenshot, required this.appMetadata, this.email});
  

@override final  String message;
@override final  bool includeScreenshot;
@override final  FeedbackAppMetadata appMetadata;
@override final  String? email;

/// Create a copy of FeedbackFormValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeedbackFormValueCopyWith<_FeedbackFormValue> get copyWith => __$FeedbackFormValueCopyWithImpl<_FeedbackFormValue>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeedbackFormValue&&(identical(other.message, message) || other.message == message)&&(identical(other.includeScreenshot, includeScreenshot) || other.includeScreenshot == includeScreenshot)&&(identical(other.appMetadata, appMetadata) || other.appMetadata == appMetadata)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,message,includeScreenshot,appMetadata,email);

@override
String toString() {
  return 'FeedbackFormValue(message: $message, includeScreenshot: $includeScreenshot, appMetadata: $appMetadata, email: $email)';
}


}

/// @nodoc
abstract mixin class _$FeedbackFormValueCopyWith<$Res> implements $FeedbackFormValueCopyWith<$Res> {
  factory _$FeedbackFormValueCopyWith(_FeedbackFormValue value, $Res Function(_FeedbackFormValue) _then) = __$FeedbackFormValueCopyWithImpl;
@override @useResult
$Res call({
 String message, bool includeScreenshot, FeedbackAppMetadata appMetadata, String? email
});


@override $FeedbackAppMetadataCopyWith<$Res> get appMetadata;

}
/// @nodoc
class __$FeedbackFormValueCopyWithImpl<$Res>
    implements _$FeedbackFormValueCopyWith<$Res> {
  __$FeedbackFormValueCopyWithImpl(this._self, this._then);

  final _FeedbackFormValue _self;
  final $Res Function(_FeedbackFormValue) _then;

/// Create a copy of FeedbackFormValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? includeScreenshot = null,Object? appMetadata = null,Object? email = freezed,}) {
  return _then(_FeedbackFormValue(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,includeScreenshot: null == includeScreenshot ? _self.includeScreenshot : includeScreenshot // ignore: cast_nullable_to_non_nullable
as bool,appMetadata: null == appMetadata ? _self.appMetadata : appMetadata // ignore: cast_nullable_to_non_nullable
as FeedbackAppMetadata,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FeedbackFormValue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FeedbackAppMetadataCopyWith<$Res> get appMetadata {
  
  return $FeedbackAppMetadataCopyWith<$Res>(_self.appMetadata, (value) {
    return _then(_self.copyWith(appMetadata: value));
  });
}
}

// dart format on
