// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_requirement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateRequirement {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateRequirement);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateRequirement()';
}


}

/// @nodoc
class $UpdateRequirementCopyWith<$Res>  {
$UpdateRequirementCopyWith(UpdateRequirement _, $Res Function(UpdateRequirement) __);
}


/// Adds pattern-matching-related methods to [UpdateRequirement].
extension UpdateRequirementPatterns on UpdateRequirement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UpdateRequirementNone value)?  none,TResult Function( UpdateRequirementSoft value)?  soft,TResult Function( UpdateRequirementHard value)?  hard,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UpdateRequirementNone() when none != null:
return none(_that);case UpdateRequirementSoft() when soft != null:
return soft(_that);case UpdateRequirementHard() when hard != null:
return hard(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UpdateRequirementNone value)  none,required TResult Function( UpdateRequirementSoft value)  soft,required TResult Function( UpdateRequirementHard value)  hard,}){
final _that = this;
switch (_that) {
case UpdateRequirementNone():
return none(_that);case UpdateRequirementSoft():
return soft(_that);case UpdateRequirementHard():
return hard(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UpdateRequirementNone value)?  none,TResult? Function( UpdateRequirementSoft value)?  soft,TResult? Function( UpdateRequirementHard value)?  hard,}){
final _that = this;
switch (_that) {
case UpdateRequirementNone() when none != null:
return none(_that);case UpdateRequirementSoft() when soft != null:
return soft(_that);case UpdateRequirementHard() when hard != null:
return hard(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  none,TResult Function( String minVersion,  String latestVersion,  String storeUrl,  String? message)?  soft,TResult Function( String minVersion,  String latestVersion,  String storeUrl,  String? message)?  hard,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UpdateRequirementNone() when none != null:
return none();case UpdateRequirementSoft() when soft != null:
return soft(_that.minVersion,_that.latestVersion,_that.storeUrl,_that.message);case UpdateRequirementHard() when hard != null:
return hard(_that.minVersion,_that.latestVersion,_that.storeUrl,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  none,required TResult Function( String minVersion,  String latestVersion,  String storeUrl,  String? message)  soft,required TResult Function( String minVersion,  String latestVersion,  String storeUrl,  String? message)  hard,}) {final _that = this;
switch (_that) {
case UpdateRequirementNone():
return none();case UpdateRequirementSoft():
return soft(_that.minVersion,_that.latestVersion,_that.storeUrl,_that.message);case UpdateRequirementHard():
return hard(_that.minVersion,_that.latestVersion,_that.storeUrl,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  none,TResult? Function( String minVersion,  String latestVersion,  String storeUrl,  String? message)?  soft,TResult? Function( String minVersion,  String latestVersion,  String storeUrl,  String? message)?  hard,}) {final _that = this;
switch (_that) {
case UpdateRequirementNone() when none != null:
return none();case UpdateRequirementSoft() when soft != null:
return soft(_that.minVersion,_that.latestVersion,_that.storeUrl,_that.message);case UpdateRequirementHard() when hard != null:
return hard(_that.minVersion,_that.latestVersion,_that.storeUrl,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class UpdateRequirementNone implements UpdateRequirement {
  const UpdateRequirementNone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateRequirementNone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateRequirement.none()';
}


}




/// @nodoc


class UpdateRequirementSoft implements UpdateRequirement {
  const UpdateRequirementSoft({required this.minVersion, required this.latestVersion, required this.storeUrl, this.message});
  

 final  String minVersion;
 final  String latestVersion;
 final  String storeUrl;
 final  String? message;

/// Create a copy of UpdateRequirement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateRequirementSoftCopyWith<UpdateRequirementSoft> get copyWith => _$UpdateRequirementSoftCopyWithImpl<UpdateRequirementSoft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateRequirementSoft&&(identical(other.minVersion, minVersion) || other.minVersion == minVersion)&&(identical(other.latestVersion, latestVersion) || other.latestVersion == latestVersion)&&(identical(other.storeUrl, storeUrl) || other.storeUrl == storeUrl)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,minVersion,latestVersion,storeUrl,message);

@override
String toString() {
  return 'UpdateRequirement.soft(minVersion: $minVersion, latestVersion: $latestVersion, storeUrl: $storeUrl, message: $message)';
}


}

/// @nodoc
abstract mixin class $UpdateRequirementSoftCopyWith<$Res> implements $UpdateRequirementCopyWith<$Res> {
  factory $UpdateRequirementSoftCopyWith(UpdateRequirementSoft value, $Res Function(UpdateRequirementSoft) _then) = _$UpdateRequirementSoftCopyWithImpl;
@useResult
$Res call({
 String minVersion, String latestVersion, String storeUrl, String? message
});




}
/// @nodoc
class _$UpdateRequirementSoftCopyWithImpl<$Res>
    implements $UpdateRequirementSoftCopyWith<$Res> {
  _$UpdateRequirementSoftCopyWithImpl(this._self, this._then);

  final UpdateRequirementSoft _self;
  final $Res Function(UpdateRequirementSoft) _then;

/// Create a copy of UpdateRequirement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minVersion = null,Object? latestVersion = null,Object? storeUrl = null,Object? message = freezed,}) {
  return _then(UpdateRequirementSoft(
minVersion: null == minVersion ? _self.minVersion : minVersion // ignore: cast_nullable_to_non_nullable
as String,latestVersion: null == latestVersion ? _self.latestVersion : latestVersion // ignore: cast_nullable_to_non_nullable
as String,storeUrl: null == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class UpdateRequirementHard implements UpdateRequirement {
  const UpdateRequirementHard({required this.minVersion, required this.latestVersion, required this.storeUrl, this.message});
  

 final  String minVersion;
 final  String latestVersion;
 final  String storeUrl;
 final  String? message;

/// Create a copy of UpdateRequirement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateRequirementHardCopyWith<UpdateRequirementHard> get copyWith => _$UpdateRequirementHardCopyWithImpl<UpdateRequirementHard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateRequirementHard&&(identical(other.minVersion, minVersion) || other.minVersion == minVersion)&&(identical(other.latestVersion, latestVersion) || other.latestVersion == latestVersion)&&(identical(other.storeUrl, storeUrl) || other.storeUrl == storeUrl)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,minVersion,latestVersion,storeUrl,message);

@override
String toString() {
  return 'UpdateRequirement.hard(minVersion: $minVersion, latestVersion: $latestVersion, storeUrl: $storeUrl, message: $message)';
}


}

/// @nodoc
abstract mixin class $UpdateRequirementHardCopyWith<$Res> implements $UpdateRequirementCopyWith<$Res> {
  factory $UpdateRequirementHardCopyWith(UpdateRequirementHard value, $Res Function(UpdateRequirementHard) _then) = _$UpdateRequirementHardCopyWithImpl;
@useResult
$Res call({
 String minVersion, String latestVersion, String storeUrl, String? message
});




}
/// @nodoc
class _$UpdateRequirementHardCopyWithImpl<$Res>
    implements $UpdateRequirementHardCopyWith<$Res> {
  _$UpdateRequirementHardCopyWithImpl(this._self, this._then);

  final UpdateRequirementHard _self;
  final $Res Function(UpdateRequirementHard) _then;

/// Create a copy of UpdateRequirement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minVersion = null,Object? latestVersion = null,Object? storeUrl = null,Object? message = freezed,}) {
  return _then(UpdateRequirementHard(
minVersion: null == minVersion ? _self.minVersion : minVersion // ignore: cast_nullable_to_non_nullable
as String,latestVersion: null == latestVersion ? _self.latestVersion : latestVersion // ignore: cast_nullable_to_non_nullable
as String,storeUrl: null == storeUrl ? _self.storeUrl : storeUrl // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
