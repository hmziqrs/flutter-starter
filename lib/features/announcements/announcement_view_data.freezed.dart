// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'announcement_view_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Announcement {

 String get id; AnnouncementSeverity get severity; String Function(Translations translations) get title; String Function(Translations translations) get message; String? get actionRoute; bool get dismissible; DateTime? get activeFrom; DateTime? get activeUntil; String? get minAppVersion; String? get maxAppVersion;
/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnnouncementCopyWith<Announcement> get copyWith => _$AnnouncementCopyWithImpl<Announcement>(this as Announcement, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Announcement&&(identical(other.id, id) || other.id == id)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.actionRoute, actionRoute) || other.actionRoute == actionRoute)&&(identical(other.dismissible, dismissible) || other.dismissible == dismissible)&&(identical(other.activeFrom, activeFrom) || other.activeFrom == activeFrom)&&(identical(other.activeUntil, activeUntil) || other.activeUntil == activeUntil)&&(identical(other.minAppVersion, minAppVersion) || other.minAppVersion == minAppVersion)&&(identical(other.maxAppVersion, maxAppVersion) || other.maxAppVersion == maxAppVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,severity,title,message,actionRoute,dismissible,activeFrom,activeUntil,minAppVersion,maxAppVersion);

@override
String toString() {
  return 'Announcement(id: $id, severity: $severity, title: $title, message: $message, actionRoute: $actionRoute, dismissible: $dismissible, activeFrom: $activeFrom, activeUntil: $activeUntil, minAppVersion: $minAppVersion, maxAppVersion: $maxAppVersion)';
}


}

/// @nodoc
abstract mixin class $AnnouncementCopyWith<$Res>  {
  factory $AnnouncementCopyWith(Announcement value, $Res Function(Announcement) _then) = _$AnnouncementCopyWithImpl;
@useResult
$Res call({
 String id, AnnouncementSeverity severity, String Function(Translations translations) title, String Function(Translations translations) message, String? actionRoute, bool dismissible, DateTime? activeFrom, DateTime? activeUntil, String? minAppVersion, String? maxAppVersion
});




}
/// @nodoc
class _$AnnouncementCopyWithImpl<$Res>
    implements $AnnouncementCopyWith<$Res> {
  _$AnnouncementCopyWithImpl(this._self, this._then);

  final Announcement _self;
  final $Res Function(Announcement) _then;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? severity = null,Object? title = null,Object? message = null,Object? actionRoute = freezed,Object? dismissible = null,Object? activeFrom = freezed,Object? activeUntil = freezed,Object? minAppVersion = freezed,Object? maxAppVersion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AnnouncementSeverity,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String Function(Translations translations),message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String Function(Translations translations),actionRoute: freezed == actionRoute ? _self.actionRoute : actionRoute // ignore: cast_nullable_to_non_nullable
as String?,dismissible: null == dismissible ? _self.dismissible : dismissible // ignore: cast_nullable_to_non_nullable
as bool,activeFrom: freezed == activeFrom ? _self.activeFrom : activeFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,activeUntil: freezed == activeUntil ? _self.activeUntil : activeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,minAppVersion: freezed == minAppVersion ? _self.minAppVersion : minAppVersion // ignore: cast_nullable_to_non_nullable
as String?,maxAppVersion: freezed == maxAppVersion ? _self.maxAppVersion : maxAppVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Announcement].
extension AnnouncementPatterns on Announcement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Announcement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Announcement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Announcement value)  $default,){
final _that = this;
switch (_that) {
case _Announcement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Announcement value)?  $default,){
final _that = this;
switch (_that) {
case _Announcement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AnnouncementSeverity severity,  String Function(Translations translations) title,  String Function(Translations translations) message,  String? actionRoute,  bool dismissible,  DateTime? activeFrom,  DateTime? activeUntil,  String? minAppVersion,  String? maxAppVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Announcement() when $default != null:
return $default(_that.id,_that.severity,_that.title,_that.message,_that.actionRoute,_that.dismissible,_that.activeFrom,_that.activeUntil,_that.minAppVersion,_that.maxAppVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AnnouncementSeverity severity,  String Function(Translations translations) title,  String Function(Translations translations) message,  String? actionRoute,  bool dismissible,  DateTime? activeFrom,  DateTime? activeUntil,  String? minAppVersion,  String? maxAppVersion)  $default,) {final _that = this;
switch (_that) {
case _Announcement():
return $default(_that.id,_that.severity,_that.title,_that.message,_that.actionRoute,_that.dismissible,_that.activeFrom,_that.activeUntil,_that.minAppVersion,_that.maxAppVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AnnouncementSeverity severity,  String Function(Translations translations) title,  String Function(Translations translations) message,  String? actionRoute,  bool dismissible,  DateTime? activeFrom,  DateTime? activeUntil,  String? minAppVersion,  String? maxAppVersion)?  $default,) {final _that = this;
switch (_that) {
case _Announcement() when $default != null:
return $default(_that.id,_that.severity,_that.title,_that.message,_that.actionRoute,_that.dismissible,_that.activeFrom,_that.activeUntil,_that.minAppVersion,_that.maxAppVersion);case _:
  return null;

}
}

}

/// @nodoc


class _Announcement extends Announcement {
  const _Announcement({required this.id, required this.severity, required this.title, required this.message, this.actionRoute, this.dismissible = true, this.activeFrom, this.activeUntil, this.minAppVersion, this.maxAppVersion}): super._();
  

@override final  String id;
@override final  AnnouncementSeverity severity;
@override final  String Function(Translations translations) title;
@override final  String Function(Translations translations) message;
@override final  String? actionRoute;
@override@JsonKey() final  bool dismissible;
@override final  DateTime? activeFrom;
@override final  DateTime? activeUntil;
@override final  String? minAppVersion;
@override final  String? maxAppVersion;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnnouncementCopyWith<_Announcement> get copyWith => __$AnnouncementCopyWithImpl<_Announcement>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Announcement&&(identical(other.id, id) || other.id == id)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.title, title) || other.title == title)&&(identical(other.message, message) || other.message == message)&&(identical(other.actionRoute, actionRoute) || other.actionRoute == actionRoute)&&(identical(other.dismissible, dismissible) || other.dismissible == dismissible)&&(identical(other.activeFrom, activeFrom) || other.activeFrom == activeFrom)&&(identical(other.activeUntil, activeUntil) || other.activeUntil == activeUntil)&&(identical(other.minAppVersion, minAppVersion) || other.minAppVersion == minAppVersion)&&(identical(other.maxAppVersion, maxAppVersion) || other.maxAppVersion == maxAppVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,severity,title,message,actionRoute,dismissible,activeFrom,activeUntil,minAppVersion,maxAppVersion);

@override
String toString() {
  return 'Announcement(id: $id, severity: $severity, title: $title, message: $message, actionRoute: $actionRoute, dismissible: $dismissible, activeFrom: $activeFrom, activeUntil: $activeUntil, minAppVersion: $minAppVersion, maxAppVersion: $maxAppVersion)';
}


}

/// @nodoc
abstract mixin class _$AnnouncementCopyWith<$Res> implements $AnnouncementCopyWith<$Res> {
  factory _$AnnouncementCopyWith(_Announcement value, $Res Function(_Announcement) _then) = __$AnnouncementCopyWithImpl;
@override @useResult
$Res call({
 String id, AnnouncementSeverity severity, String Function(Translations translations) title, String Function(Translations translations) message, String? actionRoute, bool dismissible, DateTime? activeFrom, DateTime? activeUntil, String? minAppVersion, String? maxAppVersion
});




}
/// @nodoc
class __$AnnouncementCopyWithImpl<$Res>
    implements _$AnnouncementCopyWith<$Res> {
  __$AnnouncementCopyWithImpl(this._self, this._then);

  final _Announcement _self;
  final $Res Function(_Announcement) _then;

/// Create a copy of Announcement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? severity = null,Object? title = null,Object? message = null,Object? actionRoute = freezed,Object? dismissible = null,Object? activeFrom = freezed,Object? activeUntil = freezed,Object? minAppVersion = freezed,Object? maxAppVersion = freezed,}) {
  return _then(_Announcement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as AnnouncementSeverity,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String Function(Translations translations),message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String Function(Translations translations),actionRoute: freezed == actionRoute ? _self.actionRoute : actionRoute // ignore: cast_nullable_to_non_nullable
as String?,dismissible: null == dismissible ? _self.dismissible : dismissible // ignore: cast_nullable_to_non_nullable
as bool,activeFrom: freezed == activeFrom ? _self.activeFrom : activeFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,activeUntil: freezed == activeUntil ? _self.activeUntil : activeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,minAppVersion: freezed == minAppVersion ? _self.minAppVersion : minAppVersion // ignore: cast_nullable_to_non_nullable
as String?,maxAppVersion: freezed == maxAppVersion ? _self.maxAppVersion : maxAppVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AnnouncementsState {

 Announcement? get active; Set<String> get dismissedIds; AnnouncementsStatus get status;
/// Create a copy of AnnouncementsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnnouncementsStateCopyWith<AnnouncementsState> get copyWith => _$AnnouncementsStateCopyWithImpl<AnnouncementsState>(this as AnnouncementsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnnouncementsState&&(identical(other.active, active) || other.active == active)&&const DeepCollectionEquality().equals(other.dismissedIds, dismissedIds)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,active,const DeepCollectionEquality().hash(dismissedIds),status);

@override
String toString() {
  return 'AnnouncementsState(active: $active, dismissedIds: $dismissedIds, status: $status)';
}


}

/// @nodoc
abstract mixin class $AnnouncementsStateCopyWith<$Res>  {
  factory $AnnouncementsStateCopyWith(AnnouncementsState value, $Res Function(AnnouncementsState) _then) = _$AnnouncementsStateCopyWithImpl;
@useResult
$Res call({
 Announcement? active, Set<String> dismissedIds, AnnouncementsStatus status
});


$AnnouncementCopyWith<$Res>? get active;

}
/// @nodoc
class _$AnnouncementsStateCopyWithImpl<$Res>
    implements $AnnouncementsStateCopyWith<$Res> {
  _$AnnouncementsStateCopyWithImpl(this._self, this._then);

  final AnnouncementsState _self;
  final $Res Function(AnnouncementsState) _then;

/// Create a copy of AnnouncementsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? active = freezed,Object? dismissedIds = null,Object? status = null,}) {
  return _then(_self.copyWith(
active: freezed == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as Announcement?,dismissedIds: null == dismissedIds ? _self.dismissedIds : dismissedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AnnouncementsStatus,
  ));
}
/// Create a copy of AnnouncementsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnnouncementCopyWith<$Res>? get active {
    if (_self.active == null) {
    return null;
  }

  return $AnnouncementCopyWith<$Res>(_self.active!, (value) {
    return _then(_self.copyWith(active: value));
  });
}
}


/// Adds pattern-matching-related methods to [AnnouncementsState].
extension AnnouncementsStatePatterns on AnnouncementsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnnouncementsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnnouncementsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnnouncementsState value)  $default,){
final _that = this;
switch (_that) {
case _AnnouncementsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnnouncementsState value)?  $default,){
final _that = this;
switch (_that) {
case _AnnouncementsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Announcement? active,  Set<String> dismissedIds,  AnnouncementsStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnnouncementsState() when $default != null:
return $default(_that.active,_that.dismissedIds,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Announcement? active,  Set<String> dismissedIds,  AnnouncementsStatus status)  $default,) {final _that = this;
switch (_that) {
case _AnnouncementsState():
return $default(_that.active,_that.dismissedIds,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Announcement? active,  Set<String> dismissedIds,  AnnouncementsStatus status)?  $default,) {final _that = this;
switch (_that) {
case _AnnouncementsState() when $default != null:
return $default(_that.active,_that.dismissedIds,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _AnnouncementsState implements AnnouncementsState {
  const _AnnouncementsState({required this.active, required final  Set<String> dismissedIds, this.status = AnnouncementsStatus.idle}): _dismissedIds = dismissedIds;
  

@override final  Announcement? active;
 final  Set<String> _dismissedIds;
@override Set<String> get dismissedIds {
  if (_dismissedIds is EqualUnmodifiableSetView) return _dismissedIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_dismissedIds);
}

@override@JsonKey() final  AnnouncementsStatus status;

/// Create a copy of AnnouncementsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnnouncementsStateCopyWith<_AnnouncementsState> get copyWith => __$AnnouncementsStateCopyWithImpl<_AnnouncementsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnnouncementsState&&(identical(other.active, active) || other.active == active)&&const DeepCollectionEquality().equals(other._dismissedIds, _dismissedIds)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,active,const DeepCollectionEquality().hash(_dismissedIds),status);

@override
String toString() {
  return 'AnnouncementsState(active: $active, dismissedIds: $dismissedIds, status: $status)';
}


}

/// @nodoc
abstract mixin class _$AnnouncementsStateCopyWith<$Res> implements $AnnouncementsStateCopyWith<$Res> {
  factory _$AnnouncementsStateCopyWith(_AnnouncementsState value, $Res Function(_AnnouncementsState) _then) = __$AnnouncementsStateCopyWithImpl;
@override @useResult
$Res call({
 Announcement? active, Set<String> dismissedIds, AnnouncementsStatus status
});


@override $AnnouncementCopyWith<$Res>? get active;

}
/// @nodoc
class __$AnnouncementsStateCopyWithImpl<$Res>
    implements _$AnnouncementsStateCopyWith<$Res> {
  __$AnnouncementsStateCopyWithImpl(this._self, this._then);

  final _AnnouncementsState _self;
  final $Res Function(_AnnouncementsState) _then;

/// Create a copy of AnnouncementsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? active = freezed,Object? dismissedIds = null,Object? status = null,}) {
  return _then(_AnnouncementsState(
active: freezed == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as Announcement?,dismissedIds: null == dismissedIds ? _self._dismissedIds : dismissedIds // ignore: cast_nullable_to_non_nullable
as Set<String>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AnnouncementsStatus,
  ));
}

/// Create a copy of AnnouncementsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AnnouncementCopyWith<$Res>? get active {
    if (_self.active == null) {
    return null;
  }

  return $AnnouncementCopyWith<$Res>(_self.active!, (value) {
    return _then(_self.copyWith(active: value));
  });
}
}

// dart format on
