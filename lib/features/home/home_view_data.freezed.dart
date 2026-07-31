// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_view_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeStatusViewData {

 String get id; HomeStatusKind get kind;
/// Create a copy of HomeStatusViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeStatusViewDataCopyWith<HomeStatusViewData> get copyWith => _$HomeStatusViewDataCopyWithImpl<HomeStatusViewData>(this as HomeStatusViewData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeStatusViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind);

@override
String toString() {
  return 'HomeStatusViewData(id: $id, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $HomeStatusViewDataCopyWith<$Res>  {
  factory $HomeStatusViewDataCopyWith(HomeStatusViewData value, $Res Function(HomeStatusViewData) _then) = _$HomeStatusViewDataCopyWithImpl;
@useResult
$Res call({
 String id, HomeStatusKind kind
});




}
/// @nodoc
class _$HomeStatusViewDataCopyWithImpl<$Res>
    implements $HomeStatusViewDataCopyWith<$Res> {
  _$HomeStatusViewDataCopyWithImpl(this._self, this._then);

  final HomeStatusViewData _self;
  final $Res Function(HomeStatusViewData) _then;

/// Create a copy of HomeStatusViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as HomeStatusKind,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeStatusViewData].
extension HomeStatusViewDataPatterns on HomeStatusViewData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeStatusViewData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeStatusViewData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeStatusViewData value)  $default,){
final _that = this;
switch (_that) {
case _HomeStatusViewData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeStatusViewData value)?  $default,){
final _that = this;
switch (_that) {
case _HomeStatusViewData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  HomeStatusKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeStatusViewData() when $default != null:
return $default(_that.id,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  HomeStatusKind kind)  $default,) {final _that = this;
switch (_that) {
case _HomeStatusViewData():
return $default(_that.id,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  HomeStatusKind kind)?  $default,) {final _that = this;
switch (_that) {
case _HomeStatusViewData() when $default != null:
return $default(_that.id,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _HomeStatusViewData implements HomeStatusViewData {
  const _HomeStatusViewData({required this.id, required this.kind});
  

@override final  String id;
@override final  HomeStatusKind kind;

/// Create a copy of HomeStatusViewData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeStatusViewDataCopyWith<_HomeStatusViewData> get copyWith => __$HomeStatusViewDataCopyWithImpl<_HomeStatusViewData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeStatusViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind);

@override
String toString() {
  return 'HomeStatusViewData(id: $id, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$HomeStatusViewDataCopyWith<$Res> implements $HomeStatusViewDataCopyWith<$Res> {
  factory _$HomeStatusViewDataCopyWith(_HomeStatusViewData value, $Res Function(_HomeStatusViewData) _then) = __$HomeStatusViewDataCopyWithImpl;
@override @useResult
$Res call({
 String id, HomeStatusKind kind
});




}
/// @nodoc
class __$HomeStatusViewDataCopyWithImpl<$Res>
    implements _$HomeStatusViewDataCopyWith<$Res> {
  __$HomeStatusViewDataCopyWithImpl(this._self, this._then);

  final _HomeStatusViewData _self;
  final $Res Function(_HomeStatusViewData) _then;

/// Create a copy of HomeStatusViewData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,}) {
  return _then(_HomeStatusViewData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as HomeStatusKind,
  ));
}


}

/// @nodoc
mixin _$HomeActivityViewData {

 String get id; HomeStatusKind get kind;
/// Create a copy of HomeActivityViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeActivityViewDataCopyWith<HomeActivityViewData> get copyWith => _$HomeActivityViewDataCopyWithImpl<HomeActivityViewData>(this as HomeActivityViewData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeActivityViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind);

@override
String toString() {
  return 'HomeActivityViewData(id: $id, kind: $kind)';
}


}

/// @nodoc
abstract mixin class $HomeActivityViewDataCopyWith<$Res>  {
  factory $HomeActivityViewDataCopyWith(HomeActivityViewData value, $Res Function(HomeActivityViewData) _then) = _$HomeActivityViewDataCopyWithImpl;
@useResult
$Res call({
 String id, HomeStatusKind kind
});




}
/// @nodoc
class _$HomeActivityViewDataCopyWithImpl<$Res>
    implements $HomeActivityViewDataCopyWith<$Res> {
  _$HomeActivityViewDataCopyWithImpl(this._self, this._then);

  final HomeActivityViewData _self;
  final $Res Function(HomeActivityViewData) _then;

/// Create a copy of HomeActivityViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as HomeStatusKind,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeActivityViewData].
extension HomeActivityViewDataPatterns on HomeActivityViewData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeActivityViewData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeActivityViewData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeActivityViewData value)  $default,){
final _that = this;
switch (_that) {
case _HomeActivityViewData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeActivityViewData value)?  $default,){
final _that = this;
switch (_that) {
case _HomeActivityViewData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  HomeStatusKind kind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeActivityViewData() when $default != null:
return $default(_that.id,_that.kind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  HomeStatusKind kind)  $default,) {final _that = this;
switch (_that) {
case _HomeActivityViewData():
return $default(_that.id,_that.kind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  HomeStatusKind kind)?  $default,) {final _that = this;
switch (_that) {
case _HomeActivityViewData() when $default != null:
return $default(_that.id,_that.kind);case _:
  return null;

}
}

}

/// @nodoc


class _HomeActivityViewData implements HomeActivityViewData {
  const _HomeActivityViewData({required this.id, required this.kind});
  

@override final  String id;
@override final  HomeStatusKind kind;

/// Create a copy of HomeActivityViewData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeActivityViewDataCopyWith<_HomeActivityViewData> get copyWith => __$HomeActivityViewDataCopyWithImpl<_HomeActivityViewData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeActivityViewData&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind);

@override
String toString() {
  return 'HomeActivityViewData(id: $id, kind: $kind)';
}


}

/// @nodoc
abstract mixin class _$HomeActivityViewDataCopyWith<$Res> implements $HomeActivityViewDataCopyWith<$Res> {
  factory _$HomeActivityViewDataCopyWith(_HomeActivityViewData value, $Res Function(_HomeActivityViewData) _then) = __$HomeActivityViewDataCopyWithImpl;
@override @useResult
$Res call({
 String id, HomeStatusKind kind
});




}
/// @nodoc
class __$HomeActivityViewDataCopyWithImpl<$Res>
    implements _$HomeActivityViewDataCopyWith<$Res> {
  __$HomeActivityViewDataCopyWithImpl(this._self, this._then);

  final _HomeActivityViewData _self;
  final $Res Function(_HomeActivityViewData) _then;

/// Create a copy of HomeActivityViewData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,}) {
  return _then(_HomeActivityViewData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as HomeStatusKind,
  ));
}


}

/// @nodoc
mixin _$HomeViewData {

 String get greetingName; List<HomeStatusViewData> get statuses; List<HomeActivityViewData> get recentActivity;
/// Create a copy of HomeViewData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeViewDataCopyWith<HomeViewData> get copyWith => _$HomeViewDataCopyWithImpl<HomeViewData>(this as HomeViewData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeViewData&&(identical(other.greetingName, greetingName) || other.greetingName == greetingName)&&const DeepCollectionEquality().equals(other.statuses, statuses)&&const DeepCollectionEquality().equals(other.recentActivity, recentActivity));
}


@override
int get hashCode => Object.hash(runtimeType,greetingName,const DeepCollectionEquality().hash(statuses),const DeepCollectionEquality().hash(recentActivity));

@override
String toString() {
  return 'HomeViewData(greetingName: $greetingName, statuses: $statuses, recentActivity: $recentActivity)';
}


}

/// @nodoc
abstract mixin class $HomeViewDataCopyWith<$Res>  {
  factory $HomeViewDataCopyWith(HomeViewData value, $Res Function(HomeViewData) _then) = _$HomeViewDataCopyWithImpl;
@useResult
$Res call({
 String greetingName, List<HomeStatusViewData> statuses, List<HomeActivityViewData> recentActivity
});




}
/// @nodoc
class _$HomeViewDataCopyWithImpl<$Res>
    implements $HomeViewDataCopyWith<$Res> {
  _$HomeViewDataCopyWithImpl(this._self, this._then);

  final HomeViewData _self;
  final $Res Function(HomeViewData) _then;

/// Create a copy of HomeViewData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? greetingName = null,Object? statuses = null,Object? recentActivity = null,}) {
  return _then(_self.copyWith(
greetingName: null == greetingName ? _self.greetingName : greetingName // ignore: cast_nullable_to_non_nullable
as String,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<HomeStatusViewData>,recentActivity: null == recentActivity ? _self.recentActivity : recentActivity // ignore: cast_nullable_to_non_nullable
as List<HomeActivityViewData>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeViewData].
extension HomeViewDataPatterns on HomeViewData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeViewData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeViewData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeViewData value)  $default,){
final _that = this;
switch (_that) {
case _HomeViewData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeViewData value)?  $default,){
final _that = this;
switch (_that) {
case _HomeViewData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String greetingName,  List<HomeStatusViewData> statuses,  List<HomeActivityViewData> recentActivity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeViewData() when $default != null:
return $default(_that.greetingName,_that.statuses,_that.recentActivity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String greetingName,  List<HomeStatusViewData> statuses,  List<HomeActivityViewData> recentActivity)  $default,) {final _that = this;
switch (_that) {
case _HomeViewData():
return $default(_that.greetingName,_that.statuses,_that.recentActivity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String greetingName,  List<HomeStatusViewData> statuses,  List<HomeActivityViewData> recentActivity)?  $default,) {final _that = this;
switch (_that) {
case _HomeViewData() when $default != null:
return $default(_that.greetingName,_that.statuses,_that.recentActivity);case _:
  return null;

}
}

}

/// @nodoc


class _HomeViewData extends HomeViewData {
  const _HomeViewData({required this.greetingName, required final  List<HomeStatusViewData> statuses, required final  List<HomeActivityViewData> recentActivity}): _statuses = statuses,_recentActivity = recentActivity,super._();
  

@override final  String greetingName;
 final  List<HomeStatusViewData> _statuses;
@override List<HomeStatusViewData> get statuses {
  if (_statuses is EqualUnmodifiableListView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statuses);
}

 final  List<HomeActivityViewData> _recentActivity;
@override List<HomeActivityViewData> get recentActivity {
  if (_recentActivity is EqualUnmodifiableListView) return _recentActivity;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentActivity);
}


/// Create a copy of HomeViewData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeViewDataCopyWith<_HomeViewData> get copyWith => __$HomeViewDataCopyWithImpl<_HomeViewData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeViewData&&(identical(other.greetingName, greetingName) || other.greetingName == greetingName)&&const DeepCollectionEquality().equals(other._statuses, _statuses)&&const DeepCollectionEquality().equals(other._recentActivity, _recentActivity));
}


@override
int get hashCode => Object.hash(runtimeType,greetingName,const DeepCollectionEquality().hash(_statuses),const DeepCollectionEquality().hash(_recentActivity));

@override
String toString() {
  return 'HomeViewData(greetingName: $greetingName, statuses: $statuses, recentActivity: $recentActivity)';
}


}

/// @nodoc
abstract mixin class _$HomeViewDataCopyWith<$Res> implements $HomeViewDataCopyWith<$Res> {
  factory _$HomeViewDataCopyWith(_HomeViewData value, $Res Function(_HomeViewData) _then) = __$HomeViewDataCopyWithImpl;
@override @useResult
$Res call({
 String greetingName, List<HomeStatusViewData> statuses, List<HomeActivityViewData> recentActivity
});




}
/// @nodoc
class __$HomeViewDataCopyWithImpl<$Res>
    implements _$HomeViewDataCopyWith<$Res> {
  __$HomeViewDataCopyWithImpl(this._self, this._then);

  final _HomeViewData _self;
  final $Res Function(_HomeViewData) _then;

/// Create a copy of HomeViewData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? greetingName = null,Object? statuses = null,Object? recentActivity = null,}) {
  return _then(_HomeViewData(
greetingName: null == greetingName ? _self.greetingName : greetingName // ignore: cast_nullable_to_non_nullable
as String,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<HomeStatusViewData>,recentActivity: null == recentActivity ? _self._recentActivity : recentActivity // ignore: cast_nullable_to_non_nullable
as List<HomeActivityViewData>,
  ));
}


}

// dart format on
