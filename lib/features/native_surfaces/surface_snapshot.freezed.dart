// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'surface_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SurfaceAction {

 String get label; String get route;
/// Create a copy of SurfaceAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurfaceActionCopyWith<SurfaceAction> get copyWith => _$SurfaceActionCopyWithImpl<SurfaceAction>(this as SurfaceAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurfaceAction&&(identical(other.label, label) || other.label == label)&&(identical(other.route, route) || other.route == route));
}


@override
int get hashCode => Object.hash(runtimeType,label,route);

@override
String toString() {
  return 'SurfaceAction(label: $label, route: $route)';
}


}

/// @nodoc
abstract mixin class $SurfaceActionCopyWith<$Res>  {
  factory $SurfaceActionCopyWith(SurfaceAction value, $Res Function(SurfaceAction) _then) = _$SurfaceActionCopyWithImpl;
@useResult
$Res call({
 String label, String route
});




}
/// @nodoc
class _$SurfaceActionCopyWithImpl<$Res>
    implements $SurfaceActionCopyWith<$Res> {
  _$SurfaceActionCopyWithImpl(this._self, this._then);

  final SurfaceAction _self;
  final $Res Function(SurfaceAction) _then;

/// Create a copy of SurfaceAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? route = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SurfaceAction].
extension SurfaceActionPatterns on SurfaceAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SurfaceAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SurfaceAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SurfaceAction value)  $default,){
final _that = this;
switch (_that) {
case _SurfaceAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SurfaceAction value)?  $default,){
final _that = this;
switch (_that) {
case _SurfaceAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String route)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SurfaceAction() when $default != null:
return $default(_that.label,_that.route);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String route)  $default,) {final _that = this;
switch (_that) {
case _SurfaceAction():
return $default(_that.label,_that.route);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String route)?  $default,) {final _that = this;
switch (_that) {
case _SurfaceAction() when $default != null:
return $default(_that.label,_that.route);case _:
  return null;

}
}

}

/// @nodoc


class _SurfaceAction extends SurfaceAction {
  const _SurfaceAction({required this.label, required this.route}): super._();
  

@override final  String label;
@override final  String route;

/// Create a copy of SurfaceAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SurfaceActionCopyWith<_SurfaceAction> get copyWith => __$SurfaceActionCopyWithImpl<_SurfaceAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SurfaceAction&&(identical(other.label, label) || other.label == label)&&(identical(other.route, route) || other.route == route));
}


@override
int get hashCode => Object.hash(runtimeType,label,route);

@override
String toString() {
  return 'SurfaceAction(label: $label, route: $route)';
}


}

/// @nodoc
abstract mixin class _$SurfaceActionCopyWith<$Res> implements $SurfaceActionCopyWith<$Res> {
  factory _$SurfaceActionCopyWith(_SurfaceAction value, $Res Function(_SurfaceAction) _then) = __$SurfaceActionCopyWithImpl;
@override @useResult
$Res call({
 String label, String route
});




}
/// @nodoc
class __$SurfaceActionCopyWithImpl<$Res>
    implements _$SurfaceActionCopyWith<$Res> {
  __$SurfaceActionCopyWithImpl(this._self, this._then);

  final _SurfaceAction _self;
  final $Res Function(_SurfaceAction) _then;

/// Create a copy of SurfaceAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? route = null,}) {
  return _then(_SurfaceAction(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SurfaceSnapshot {

 String get title; String get subtitle; DateTime get updatedAt;/// The main figure, already formatted, such as "48,210" or "72%".
 String? get value;/// The value's caption, such as "Visitors".
 String? get valueLabel;/// Completion from 0 to 1. Null means nothing is in progress.
 double? get progress; SurfaceStatus get status;/// Where tapping the surface goes. Must pass `isOpenableSurfaceRoute`.
 String get route; List<SurfaceAction> get actions;
/// Create a copy of SurfaceSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SurfaceSnapshotCopyWith<SurfaceSnapshot> get copyWith => _$SurfaceSnapshotCopyWithImpl<SurfaceSnapshot>(this as SurfaceSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SurfaceSnapshot&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.value, value) || other.value == value)&&(identical(other.valueLabel, valueLabel) || other.valueLabel == valueLabel)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.status, status) || other.status == status)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other.actions, actions));
}


@override
int get hashCode => Object.hash(runtimeType,title,subtitle,updatedAt,value,valueLabel,progress,status,route,const DeepCollectionEquality().hash(actions));

@override
String toString() {
  return 'SurfaceSnapshot(title: $title, subtitle: $subtitle, updatedAt: $updatedAt, value: $value, valueLabel: $valueLabel, progress: $progress, status: $status, route: $route, actions: $actions)';
}


}

/// @nodoc
abstract mixin class $SurfaceSnapshotCopyWith<$Res>  {
  factory $SurfaceSnapshotCopyWith(SurfaceSnapshot value, $Res Function(SurfaceSnapshot) _then) = _$SurfaceSnapshotCopyWithImpl;
@useResult
$Res call({
 String title, String subtitle, DateTime updatedAt, String? value, String? valueLabel, double? progress, SurfaceStatus status, String route, List<SurfaceAction> actions
});




}
/// @nodoc
class _$SurfaceSnapshotCopyWithImpl<$Res>
    implements $SurfaceSnapshotCopyWith<$Res> {
  _$SurfaceSnapshotCopyWithImpl(this._self, this._then);

  final SurfaceSnapshot _self;
  final $Res Function(SurfaceSnapshot) _then;

/// Create a copy of SurfaceSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? subtitle = null,Object? updatedAt = null,Object? value = freezed,Object? valueLabel = freezed,Object? progress = freezed,Object? status = null,Object? route = null,Object? actions = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,valueLabel: freezed == valueLabel ? _self.valueLabel : valueLabel // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SurfaceStatus,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as List<SurfaceAction>,
  ));
}

}


/// Adds pattern-matching-related methods to [SurfaceSnapshot].
extension SurfaceSnapshotPatterns on SurfaceSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SurfaceSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SurfaceSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SurfaceSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _SurfaceSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SurfaceSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _SurfaceSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String subtitle,  DateTime updatedAt,  String? value,  String? valueLabel,  double? progress,  SurfaceStatus status,  String route,  List<SurfaceAction> actions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SurfaceSnapshot() when $default != null:
return $default(_that.title,_that.subtitle,_that.updatedAt,_that.value,_that.valueLabel,_that.progress,_that.status,_that.route,_that.actions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String subtitle,  DateTime updatedAt,  String? value,  String? valueLabel,  double? progress,  SurfaceStatus status,  String route,  List<SurfaceAction> actions)  $default,) {final _that = this;
switch (_that) {
case _SurfaceSnapshot():
return $default(_that.title,_that.subtitle,_that.updatedAt,_that.value,_that.valueLabel,_that.progress,_that.status,_that.route,_that.actions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String subtitle,  DateTime updatedAt,  String? value,  String? valueLabel,  double? progress,  SurfaceStatus status,  String route,  List<SurfaceAction> actions)?  $default,) {final _that = this;
switch (_that) {
case _SurfaceSnapshot() when $default != null:
return $default(_that.title,_that.subtitle,_that.updatedAt,_that.value,_that.valueLabel,_that.progress,_that.status,_that.route,_that.actions);case _:
  return null;

}
}

}

/// @nodoc


class _SurfaceSnapshot extends SurfaceSnapshot {
  const _SurfaceSnapshot({required this.title, required this.subtitle, required this.updatedAt, this.value, this.valueLabel, this.progress, this.status = SurfaceStatus.idle, this.route = '/', final  List<SurfaceAction> actions = const <SurfaceAction>[]}): _actions = actions,super._();
  

@override final  String title;
@override final  String subtitle;
@override final  DateTime updatedAt;
/// The main figure, already formatted, such as "48,210" or "72%".
@override final  String? value;
/// The value's caption, such as "Visitors".
@override final  String? valueLabel;
/// Completion from 0 to 1. Null means nothing is in progress.
@override final  double? progress;
@override@JsonKey() final  SurfaceStatus status;
/// Where tapping the surface goes. Must pass `isOpenableSurfaceRoute`.
@override@JsonKey() final  String route;
 final  List<SurfaceAction> _actions;
@override@JsonKey() List<SurfaceAction> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}


/// Create a copy of SurfaceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SurfaceSnapshotCopyWith<_SurfaceSnapshot> get copyWith => __$SurfaceSnapshotCopyWithImpl<_SurfaceSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SurfaceSnapshot&&(identical(other.title, title) || other.title == title)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.value, value) || other.value == value)&&(identical(other.valueLabel, valueLabel) || other.valueLabel == valueLabel)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.status, status) || other.status == status)&&(identical(other.route, route) || other.route == route)&&const DeepCollectionEquality().equals(other._actions, _actions));
}


@override
int get hashCode => Object.hash(runtimeType,title,subtitle,updatedAt,value,valueLabel,progress,status,route,const DeepCollectionEquality().hash(_actions));

@override
String toString() {
  return 'SurfaceSnapshot(title: $title, subtitle: $subtitle, updatedAt: $updatedAt, value: $value, valueLabel: $valueLabel, progress: $progress, status: $status, route: $route, actions: $actions)';
}


}

/// @nodoc
abstract mixin class _$SurfaceSnapshotCopyWith<$Res> implements $SurfaceSnapshotCopyWith<$Res> {
  factory _$SurfaceSnapshotCopyWith(_SurfaceSnapshot value, $Res Function(_SurfaceSnapshot) _then) = __$SurfaceSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String title, String subtitle, DateTime updatedAt, String? value, String? valueLabel, double? progress, SurfaceStatus status, String route, List<SurfaceAction> actions
});




}
/// @nodoc
class __$SurfaceSnapshotCopyWithImpl<$Res>
    implements _$SurfaceSnapshotCopyWith<$Res> {
  __$SurfaceSnapshotCopyWithImpl(this._self, this._then);

  final _SurfaceSnapshot _self;
  final $Res Function(_SurfaceSnapshot) _then;

/// Create a copy of SurfaceSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? subtitle = null,Object? updatedAt = null,Object? value = freezed,Object? valueLabel = freezed,Object? progress = freezed,Object? status = null,Object? route = null,Object? actions = null,}) {
  return _then(_SurfaceSnapshot(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,valueLabel: freezed == valueLabel ? _self.valueLabel : valueLabel // ignore: cast_nullable_to_non_nullable
as String?,progress: freezed == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SurfaceStatus,route: null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<SurfaceAction>,
  ));
}


}

// dart format on
