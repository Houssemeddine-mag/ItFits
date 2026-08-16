// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Point _$PointFromJson(Map<String, dynamic> json) {
  return _Point.fromJson(json);
}

/// @nodoc
mixin _$Point {
  double get x => throw _privateConstructorUsedError;
  double get y => throw _privateConstructorUsedError;

  /// Serializes this Point to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointCopyWith<Point> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointCopyWith<$Res> {
  factory $PointCopyWith(Point value, $Res Function(Point) then) =
      _$PointCopyWithImpl<$Res, Point>;
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class _$PointCopyWithImpl<$Res, $Val extends Point>
    implements $PointCopyWith<$Res> {
  _$PointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointImplCopyWith<$Res> implements $PointCopyWith<$Res> {
  factory _$$PointImplCopyWith(
          _$PointImpl value, $Res Function(_$PointImpl) then) =
      __$$PointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double x, double y});
}

/// @nodoc
class __$$PointImplCopyWithImpl<$Res>
    extends _$PointCopyWithImpl<$Res, _$PointImpl>
    implements _$$PointImplCopyWith<$Res> {
  __$$PointImplCopyWithImpl(
      _$PointImpl _value, $Res Function(_$PointImpl) _then)
      : super(_value, _then);

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
  }) {
    return _then(_$PointImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointImpl with DiagnosticableTreeMixin implements _Point {
  const _$PointImpl({required this.x, required this.y});

  factory _$PointImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointImplFromJson(json);

  @override
  final double x;
  @override
  final double y;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Point(x: $x, y: $y)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Point'))
      ..add(DiagnosticsProperty('x', x))
      ..add(DiagnosticsProperty('y', y));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y);

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointImplCopyWith<_$PointImpl> get copyWith =>
      __$$PointImplCopyWithImpl<_$PointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointImplToJson(
      this,
    );
  }
}

abstract class _Point implements Point {
  const factory _Point({required final double x, required final double y}) =
      _$PointImpl;

  factory _Point.fromJson(Map<String, dynamic> json) = _$PointImpl.fromJson;

  @override
  double get x;
  @override
  double get y;

  /// Create a copy of Point
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointImplCopyWith<_$PointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectModel _$ProjectModelFromJson(Map<String, dynamic> json) {
  return _ProjectModel.fromJson(json);
}

/// @nodoc
mixin _$ProjectModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get roomType => throw _privateConstructorUsedError;
  String get style => throw _privateConstructorUsedError;
  int get primaryColor => throw _privateConstructorUsedError;
  int get secondaryColor => throw _privateConstructorUsedError;
  int get accentColor => throw _privateConstructorUsedError;
  int get backgroundColor => throw _privateConstructorUsedError;
  int get surfaceColor => throw _privateConstructorUsedError;
  List<String>? get rawCaptureRefs => throw _privateConstructorUsedError;
  String? get panoramaUrl => throw _privateConstructorUsedError;
  FloorPlanModel? get floorPlan => throw _privateConstructorUsedError;
  List<GeneratedDesignModel>? get generatedDesigns =>
      throw _privateConstructorUsedError;
  ProjectStatus get status => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ProjectModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectModelCopyWith<ProjectModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectModelCopyWith<$Res> {
  factory $ProjectModelCopyWith(
          ProjectModel value, $Res Function(ProjectModel) then) =
      _$ProjectModelCopyWithImpl<$Res, ProjectModel>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String name,
      String roomType,
      String style,
      int primaryColor,
      int secondaryColor,
      int accentColor,
      int backgroundColor,
      int surfaceColor,
      List<String>? rawCaptureRefs,
      String? panoramaUrl,
      FloorPlanModel? floorPlan,
      List<GeneratedDesignModel>? generatedDesigns,
      ProjectStatus status,
      DateTime? createdAt,
      DateTime? updatedAt});

  $FloorPlanModelCopyWith<$Res>? get floorPlan;
}

/// @nodoc
class _$ProjectModelCopyWithImpl<$Res, $Val extends ProjectModel>
    implements $ProjectModelCopyWith<$Res> {
  _$ProjectModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? roomType = null,
    Object? style = null,
    Object? primaryColor = null,
    Object? secondaryColor = null,
    Object? accentColor = null,
    Object? backgroundColor = null,
    Object? surfaceColor = null,
    Object? rawCaptureRefs = freezed,
    Object? panoramaUrl = freezed,
    Object? floorPlan = freezed,
    Object? generatedDesigns = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      roomType: null == roomType
          ? _value.roomType
          : roomType // ignore: cast_nullable_to_non_nullable
              as String,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String,
      primaryColor: null == primaryColor
          ? _value.primaryColor
          : primaryColor // ignore: cast_nullable_to_non_nullable
              as int,
      secondaryColor: null == secondaryColor
          ? _value.secondaryColor
          : secondaryColor // ignore: cast_nullable_to_non_nullable
              as int,
      accentColor: null == accentColor
          ? _value.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as int,
      backgroundColor: null == backgroundColor
          ? _value.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as int,
      surfaceColor: null == surfaceColor
          ? _value.surfaceColor
          : surfaceColor // ignore: cast_nullable_to_non_nullable
              as int,
      rawCaptureRefs: freezed == rawCaptureRefs
          ? _value.rawCaptureRefs
          : rawCaptureRefs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      panoramaUrl: freezed == panoramaUrl
          ? _value.panoramaUrl
          : panoramaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      floorPlan: freezed == floorPlan
          ? _value.floorPlan
          : floorPlan // ignore: cast_nullable_to_non_nullable
              as FloorPlanModel?,
      generatedDesigns: freezed == generatedDesigns
          ? _value.generatedDesigns
          : generatedDesigns // ignore: cast_nullable_to_non_nullable
              as List<GeneratedDesignModel>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ProjectStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FloorPlanModelCopyWith<$Res>? get floorPlan {
    if (_value.floorPlan == null) {
      return null;
    }

    return $FloorPlanModelCopyWith<$Res>(_value.floorPlan!, (value) {
      return _then(_value.copyWith(floorPlan: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectModelImplCopyWith<$Res>
    implements $ProjectModelCopyWith<$Res> {
  factory _$$ProjectModelImplCopyWith(
          _$ProjectModelImpl value, $Res Function(_$ProjectModelImpl) then) =
      __$$ProjectModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String name,
      String roomType,
      String style,
      int primaryColor,
      int secondaryColor,
      int accentColor,
      int backgroundColor,
      int surfaceColor,
      List<String>? rawCaptureRefs,
      String? panoramaUrl,
      FloorPlanModel? floorPlan,
      List<GeneratedDesignModel>? generatedDesigns,
      ProjectStatus status,
      DateTime? createdAt,
      DateTime? updatedAt});

  @override
  $FloorPlanModelCopyWith<$Res>? get floorPlan;
}

/// @nodoc
class __$$ProjectModelImplCopyWithImpl<$Res>
    extends _$ProjectModelCopyWithImpl<$Res, _$ProjectModelImpl>
    implements _$$ProjectModelImplCopyWith<$Res> {
  __$$ProjectModelImplCopyWithImpl(
      _$ProjectModelImpl _value, $Res Function(_$ProjectModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? name = null,
    Object? roomType = null,
    Object? style = null,
    Object? primaryColor = null,
    Object? secondaryColor = null,
    Object? accentColor = null,
    Object? backgroundColor = null,
    Object? surfaceColor = null,
    Object? rawCaptureRefs = freezed,
    Object? panoramaUrl = freezed,
    Object? floorPlan = freezed,
    Object? generatedDesigns = freezed,
    Object? status = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ProjectModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      roomType: null == roomType
          ? _value.roomType
          : roomType // ignore: cast_nullable_to_non_nullable
              as String,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String,
      primaryColor: null == primaryColor
          ? _value.primaryColor
          : primaryColor // ignore: cast_nullable_to_non_nullable
              as int,
      secondaryColor: null == secondaryColor
          ? _value.secondaryColor
          : secondaryColor // ignore: cast_nullable_to_non_nullable
              as int,
      accentColor: null == accentColor
          ? _value.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as int,
      backgroundColor: null == backgroundColor
          ? _value.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as int,
      surfaceColor: null == surfaceColor
          ? _value.surfaceColor
          : surfaceColor // ignore: cast_nullable_to_non_nullable
              as int,
      rawCaptureRefs: freezed == rawCaptureRefs
          ? _value._rawCaptureRefs
          : rawCaptureRefs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      panoramaUrl: freezed == panoramaUrl
          ? _value.panoramaUrl
          : panoramaUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      floorPlan: freezed == floorPlan
          ? _value.floorPlan
          : floorPlan // ignore: cast_nullable_to_non_nullable
              as FloorPlanModel?,
      generatedDesigns: freezed == generatedDesigns
          ? _value._generatedDesigns
          : generatedDesigns // ignore: cast_nullable_to_non_nullable
              as List<GeneratedDesignModel>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as ProjectStatus,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectModelImpl with DiagnosticableTreeMixin implements _ProjectModel {
  const _$ProjectModelImpl(
      {required this.id,
      required this.userId,
      required this.name,
      required this.roomType,
      required this.style,
      required this.primaryColor,
      required this.secondaryColor,
      required this.accentColor,
      required this.backgroundColor,
      required this.surfaceColor,
      final List<String>? rawCaptureRefs,
      this.panoramaUrl,
      this.floorPlan,
      final List<GeneratedDesignModel>? generatedDesigns,
      this.status = ProjectStatus.scanning,
      this.createdAt,
      this.updatedAt})
      : _rawCaptureRefs = rawCaptureRefs,
        _generatedDesigns = generatedDesigns;

  factory _$ProjectModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String name;
  @override
  final String roomType;
  @override
  final String style;
  @override
  final int primaryColor;
  @override
  final int secondaryColor;
  @override
  final int accentColor;
  @override
  final int backgroundColor;
  @override
  final int surfaceColor;
  final List<String>? _rawCaptureRefs;
  @override
  List<String>? get rawCaptureRefs {
    final value = _rawCaptureRefs;
    if (value == null) return null;
    if (_rawCaptureRefs is EqualUnmodifiableListView) return _rawCaptureRefs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? panoramaUrl;
  @override
  final FloorPlanModel? floorPlan;
  final List<GeneratedDesignModel>? _generatedDesigns;
  @override
  List<GeneratedDesignModel>? get generatedDesigns {
    final value = _generatedDesigns;
    if (value == null) return null;
    if (_generatedDesigns is EqualUnmodifiableListView)
      return _generatedDesigns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final ProjectStatus status;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ProjectModel(id: $id, userId: $userId, name: $name, roomType: $roomType, style: $style, primaryColor: $primaryColor, secondaryColor: $secondaryColor, accentColor: $accentColor, backgroundColor: $backgroundColor, surfaceColor: $surfaceColor, rawCaptureRefs: $rawCaptureRefs, panoramaUrl: $panoramaUrl, floorPlan: $floorPlan, generatedDesigns: $generatedDesigns, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ProjectModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('userId', userId))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('roomType', roomType))
      ..add(DiagnosticsProperty('style', style))
      ..add(DiagnosticsProperty('primaryColor', primaryColor))
      ..add(DiagnosticsProperty('secondaryColor', secondaryColor))
      ..add(DiagnosticsProperty('accentColor', accentColor))
      ..add(DiagnosticsProperty('backgroundColor', backgroundColor))
      ..add(DiagnosticsProperty('surfaceColor', surfaceColor))
      ..add(DiagnosticsProperty('rawCaptureRefs', rawCaptureRefs))
      ..add(DiagnosticsProperty('panoramaUrl', panoramaUrl))
      ..add(DiagnosticsProperty('floorPlan', floorPlan))
      ..add(DiagnosticsProperty('generatedDesigns', generatedDesigns))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.roomType, roomType) ||
                other.roomType == roomType) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.secondaryColor, secondaryColor) ||
                other.secondaryColor == secondaryColor) &&
            (identical(other.accentColor, accentColor) ||
                other.accentColor == accentColor) &&
            (identical(other.backgroundColor, backgroundColor) ||
                other.backgroundColor == backgroundColor) &&
            (identical(other.surfaceColor, surfaceColor) ||
                other.surfaceColor == surfaceColor) &&
            const DeepCollectionEquality()
                .equals(other._rawCaptureRefs, _rawCaptureRefs) &&
            (identical(other.panoramaUrl, panoramaUrl) ||
                other.panoramaUrl == panoramaUrl) &&
            (identical(other.floorPlan, floorPlan) ||
                other.floorPlan == floorPlan) &&
            const DeepCollectionEquality()
                .equals(other._generatedDesigns, _generatedDesigns) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      name,
      roomType,
      style,
      primaryColor,
      secondaryColor,
      accentColor,
      backgroundColor,
      surfaceColor,
      const DeepCollectionEquality().hash(_rawCaptureRefs),
      panoramaUrl,
      floorPlan,
      const DeepCollectionEquality().hash(_generatedDesigns),
      status,
      createdAt,
      updatedAt);

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectModelImplCopyWith<_$ProjectModelImpl> get copyWith =>
      __$$ProjectModelImplCopyWithImpl<_$ProjectModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectModelImplToJson(
      this,
    );
  }
}

abstract class _ProjectModel implements ProjectModel {
  const factory _ProjectModel(
      {required final String id,
      required final String userId,
      required final String name,
      required final String roomType,
      required final String style,
      required final int primaryColor,
      required final int secondaryColor,
      required final int accentColor,
      required final int backgroundColor,
      required final int surfaceColor,
      final List<String>? rawCaptureRefs,
      final String? panoramaUrl,
      final FloorPlanModel? floorPlan,
      final List<GeneratedDesignModel>? generatedDesigns,
      final ProjectStatus status,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$ProjectModelImpl;

  factory _ProjectModel.fromJson(Map<String, dynamic> json) =
      _$ProjectModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get name;
  @override
  String get roomType;
  @override
  String get style;
  @override
  int get primaryColor;
  @override
  int get secondaryColor;
  @override
  int get accentColor;
  @override
  int get backgroundColor;
  @override
  int get surfaceColor;
  @override
  List<String>? get rawCaptureRefs;
  @override
  String? get panoramaUrl;
  @override
  FloorPlanModel? get floorPlan;
  @override
  List<GeneratedDesignModel>? get generatedDesigns;
  @override
  ProjectStatus get status;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ProjectModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectModelImplCopyWith<_$ProjectModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FloorPlanModel _$FloorPlanModelFromJson(Map<String, dynamic> json) {
  return _FloorPlanModel.fromJson(json);
}

/// @nodoc
mixin _$FloorPlanModel {
  List<WallModel> get walls => throw _privateConstructorUsedError;
  List<DoorModel> get doors => throw _privateConstructorUsedError;
  List<WindowModel> get windows => throw _privateConstructorUsedError;
  DimensionsModel get dimensions => throw _privateConstructorUsedError;
  MeasurementUnit get unit => throw _privateConstructorUsedError;
  bool get isUserEdited => throw _privateConstructorUsedError;

  /// Serializes this FloorPlanModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FloorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FloorPlanModelCopyWith<FloorPlanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FloorPlanModelCopyWith<$Res> {
  factory $FloorPlanModelCopyWith(
          FloorPlanModel value, $Res Function(FloorPlanModel) then) =
      _$FloorPlanModelCopyWithImpl<$Res, FloorPlanModel>;
  @useResult
  $Res call(
      {List<WallModel> walls,
      List<DoorModel> doors,
      List<WindowModel> windows,
      DimensionsModel dimensions,
      MeasurementUnit unit,
      bool isUserEdited});

  $DimensionsModelCopyWith<$Res> get dimensions;
}

/// @nodoc
class _$FloorPlanModelCopyWithImpl<$Res, $Val extends FloorPlanModel>
    implements $FloorPlanModelCopyWith<$Res> {
  _$FloorPlanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FloorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walls = null,
    Object? doors = null,
    Object? windows = null,
    Object? dimensions = null,
    Object? unit = null,
    Object? isUserEdited = null,
  }) {
    return _then(_value.copyWith(
      walls: null == walls
          ? _value.walls
          : walls // ignore: cast_nullable_to_non_nullable
              as List<WallModel>,
      doors: null == doors
          ? _value.doors
          : doors // ignore: cast_nullable_to_non_nullable
              as List<DoorModel>,
      windows: null == windows
          ? _value.windows
          : windows // ignore: cast_nullable_to_non_nullable
              as List<WindowModel>,
      dimensions: null == dimensions
          ? _value.dimensions
          : dimensions // ignore: cast_nullable_to_non_nullable
              as DimensionsModel,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as MeasurementUnit,
      isUserEdited: null == isUserEdited
          ? _value.isUserEdited
          : isUserEdited // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of FloorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DimensionsModelCopyWith<$Res> get dimensions {
    return $DimensionsModelCopyWith<$Res>(_value.dimensions, (value) {
      return _then(_value.copyWith(dimensions: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FloorPlanModelImplCopyWith<$Res>
    implements $FloorPlanModelCopyWith<$Res> {
  factory _$$FloorPlanModelImplCopyWith(_$FloorPlanModelImpl value,
          $Res Function(_$FloorPlanModelImpl) then) =
      __$$FloorPlanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<WallModel> walls,
      List<DoorModel> doors,
      List<WindowModel> windows,
      DimensionsModel dimensions,
      MeasurementUnit unit,
      bool isUserEdited});

  @override
  $DimensionsModelCopyWith<$Res> get dimensions;
}

/// @nodoc
class __$$FloorPlanModelImplCopyWithImpl<$Res>
    extends _$FloorPlanModelCopyWithImpl<$Res, _$FloorPlanModelImpl>
    implements _$$FloorPlanModelImplCopyWith<$Res> {
  __$$FloorPlanModelImplCopyWithImpl(
      _$FloorPlanModelImpl _value, $Res Function(_$FloorPlanModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of FloorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? walls = null,
    Object? doors = null,
    Object? windows = null,
    Object? dimensions = null,
    Object? unit = null,
    Object? isUserEdited = null,
  }) {
    return _then(_$FloorPlanModelImpl(
      walls: null == walls
          ? _value._walls
          : walls // ignore: cast_nullable_to_non_nullable
              as List<WallModel>,
      doors: null == doors
          ? _value._doors
          : doors // ignore: cast_nullable_to_non_nullable
              as List<DoorModel>,
      windows: null == windows
          ? _value._windows
          : windows // ignore: cast_nullable_to_non_nullable
              as List<WindowModel>,
      dimensions: null == dimensions
          ? _value.dimensions
          : dimensions // ignore: cast_nullable_to_non_nullable
              as DimensionsModel,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as MeasurementUnit,
      isUserEdited: null == isUserEdited
          ? _value.isUserEdited
          : isUserEdited // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FloorPlanModelImpl
    with DiagnosticableTreeMixin
    implements _FloorPlanModel {
  const _$FloorPlanModelImpl(
      {final List<WallModel> walls = const <WallModel>[],
      final List<DoorModel> doors = const <DoorModel>[],
      final List<WindowModel> windows = const <WindowModel>[],
      required this.dimensions,
      this.unit = MeasurementUnit.metric,
      this.isUserEdited = false})
      : _walls = walls,
        _doors = doors,
        _windows = windows;

  factory _$FloorPlanModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FloorPlanModelImplFromJson(json);

  final List<WallModel> _walls;
  @override
  @JsonKey()
  List<WallModel> get walls {
    if (_walls is EqualUnmodifiableListView) return _walls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_walls);
  }

  final List<DoorModel> _doors;
  @override
  @JsonKey()
  List<DoorModel> get doors {
    if (_doors is EqualUnmodifiableListView) return _doors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_doors);
  }

  final List<WindowModel> _windows;
  @override
  @JsonKey()
  List<WindowModel> get windows {
    if (_windows is EqualUnmodifiableListView) return _windows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_windows);
  }

  @override
  final DimensionsModel dimensions;
  @override
  @JsonKey()
  final MeasurementUnit unit;
  @override
  @JsonKey()
  final bool isUserEdited;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FloorPlanModel(walls: $walls, doors: $doors, windows: $windows, dimensions: $dimensions, unit: $unit, isUserEdited: $isUserEdited)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'FloorPlanModel'))
      ..add(DiagnosticsProperty('walls', walls))
      ..add(DiagnosticsProperty('doors', doors))
      ..add(DiagnosticsProperty('windows', windows))
      ..add(DiagnosticsProperty('dimensions', dimensions))
      ..add(DiagnosticsProperty('unit', unit))
      ..add(DiagnosticsProperty('isUserEdited', isUserEdited));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FloorPlanModelImpl &&
            const DeepCollectionEquality().equals(other._walls, _walls) &&
            const DeepCollectionEquality().equals(other._doors, _doors) &&
            const DeepCollectionEquality().equals(other._windows, _windows) &&
            (identical(other.dimensions, dimensions) ||
                other.dimensions == dimensions) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.isUserEdited, isUserEdited) ||
                other.isUserEdited == isUserEdited));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_walls),
      const DeepCollectionEquality().hash(_doors),
      const DeepCollectionEquality().hash(_windows),
      dimensions,
      unit,
      isUserEdited);

  /// Create a copy of FloorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FloorPlanModelImplCopyWith<_$FloorPlanModelImpl> get copyWith =>
      __$$FloorPlanModelImplCopyWithImpl<_$FloorPlanModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FloorPlanModelImplToJson(
      this,
    );
  }
}

abstract class _FloorPlanModel implements FloorPlanModel {
  const factory _FloorPlanModel(
      {final List<WallModel> walls,
      final List<DoorModel> doors,
      final List<WindowModel> windows,
      required final DimensionsModel dimensions,
      final MeasurementUnit unit,
      final bool isUserEdited}) = _$FloorPlanModelImpl;

  factory _FloorPlanModel.fromJson(Map<String, dynamic> json) =
      _$FloorPlanModelImpl.fromJson;

  @override
  List<WallModel> get walls;
  @override
  List<DoorModel> get doors;
  @override
  List<WindowModel> get windows;
  @override
  DimensionsModel get dimensions;
  @override
  MeasurementUnit get unit;
  @override
  bool get isUserEdited;

  /// Create a copy of FloorPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FloorPlanModelImplCopyWith<_$FloorPlanModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WallModel _$WallModelFromJson(Map<String, dynamic> json) {
  return _WallModel.fromJson(json);
}

/// @nodoc
mixin _$WallModel {
  String get id => throw _privateConstructorUsedError;
  Point get start => throw _privateConstructorUsedError;
  Point get end => throw _privateConstructorUsedError;
  double get thickness => throw _privateConstructorUsedError;
  bool get isExternal => throw _privateConstructorUsedError;

  /// Serializes this WallModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WallModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WallModelCopyWith<WallModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WallModelCopyWith<$Res> {
  factory $WallModelCopyWith(WallModel value, $Res Function(WallModel) then) =
      _$WallModelCopyWithImpl<$Res, WallModel>;
  @useResult
  $Res call(
      {String id, Point start, Point end, double thickness, bool isExternal});

  $PointCopyWith<$Res> get start;
  $PointCopyWith<$Res> get end;
}

/// @nodoc
class _$WallModelCopyWithImpl<$Res, $Val extends WallModel>
    implements $WallModelCopyWith<$Res> {
  _$WallModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WallModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? start = null,
    Object? end = null,
    Object? thickness = null,
    Object? isExternal = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as Point,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as Point,
      thickness: null == thickness
          ? _value.thickness
          : thickness // ignore: cast_nullable_to_non_nullable
              as double,
      isExternal: null == isExternal
          ? _value.isExternal
          : isExternal // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of WallModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PointCopyWith<$Res> get start {
    return $PointCopyWith<$Res>(_value.start, (value) {
      return _then(_value.copyWith(start: value) as $Val);
    });
  }

  /// Create a copy of WallModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PointCopyWith<$Res> get end {
    return $PointCopyWith<$Res>(_value.end, (value) {
      return _then(_value.copyWith(end: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WallModelImplCopyWith<$Res>
    implements $WallModelCopyWith<$Res> {
  factory _$$WallModelImplCopyWith(
          _$WallModelImpl value, $Res Function(_$WallModelImpl) then) =
      __$$WallModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, Point start, Point end, double thickness, bool isExternal});

  @override
  $PointCopyWith<$Res> get start;
  @override
  $PointCopyWith<$Res> get end;
}

/// @nodoc
class __$$WallModelImplCopyWithImpl<$Res>
    extends _$WallModelCopyWithImpl<$Res, _$WallModelImpl>
    implements _$$WallModelImplCopyWith<$Res> {
  __$$WallModelImplCopyWithImpl(
      _$WallModelImpl _value, $Res Function(_$WallModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of WallModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? start = null,
    Object? end = null,
    Object? thickness = null,
    Object? isExternal = null,
  }) {
    return _then(_$WallModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as Point,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as Point,
      thickness: null == thickness
          ? _value.thickness
          : thickness // ignore: cast_nullable_to_non_nullable
              as double,
      isExternal: null == isExternal
          ? _value.isExternal
          : isExternal // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WallModelImpl with DiagnosticableTreeMixin implements _WallModel {
  const _$WallModelImpl(
      {required this.id,
      required this.start,
      required this.end,
      required this.thickness,
      this.isExternal = false});

  factory _$WallModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WallModelImplFromJson(json);

  @override
  final String id;
  @override
  final Point start;
  @override
  final Point end;
  @override
  final double thickness;
  @override
  @JsonKey()
  final bool isExternal;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'WallModel(id: $id, start: $start, end: $end, thickness: $thickness, isExternal: $isExternal)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'WallModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('start', start))
      ..add(DiagnosticsProperty('end', end))
      ..add(DiagnosticsProperty('thickness', thickness))
      ..add(DiagnosticsProperty('isExternal', isExternal));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WallModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.thickness, thickness) ||
                other.thickness == thickness) &&
            (identical(other.isExternal, isExternal) ||
                other.isExternal == isExternal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, start, end, thickness, isExternal);

  /// Create a copy of WallModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WallModelImplCopyWith<_$WallModelImpl> get copyWith =>
      __$$WallModelImplCopyWithImpl<_$WallModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WallModelImplToJson(
      this,
    );
  }
}

abstract class _WallModel implements WallModel {
  const factory _WallModel(
      {required final String id,
      required final Point start,
      required final Point end,
      required final double thickness,
      final bool isExternal}) = _$WallModelImpl;

  factory _WallModel.fromJson(Map<String, dynamic> json) =
      _$WallModelImpl.fromJson;

  @override
  String get id;
  @override
  Point get start;
  @override
  Point get end;
  @override
  double get thickness;
  @override
  bool get isExternal;

  /// Create a copy of WallModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WallModelImplCopyWith<_$WallModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DoorModel _$DoorModelFromJson(Map<String, dynamic> json) {
  return _DoorModel.fromJson(json);
}

/// @nodoc
mixin _$DoorModel {
  String get id => throw _privateConstructorUsedError;
  String get wallId => throw _privateConstructorUsedError;
  double get position => throw _privateConstructorUsedError;
  double get width => throw _privateConstructorUsedError;
  DoorType get type => throw _privateConstructorUsedError;

  /// Serializes this DoorModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DoorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DoorModelCopyWith<DoorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DoorModelCopyWith<$Res> {
  factory $DoorModelCopyWith(DoorModel value, $Res Function(DoorModel) then) =
      _$DoorModelCopyWithImpl<$Res, DoorModel>;
  @useResult
  $Res call(
      {String id, String wallId, double position, double width, DoorType type});
}

/// @nodoc
class _$DoorModelCopyWithImpl<$Res, $Val extends DoorModel>
    implements $DoorModelCopyWith<$Res> {
  _$DoorModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DoorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? wallId = null,
    Object? position = null,
    Object? width = null,
    Object? type = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      wallId: null == wallId
          ? _value.wallId
          : wallId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DoorType,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DoorModelImplCopyWith<$Res>
    implements $DoorModelCopyWith<$Res> {
  factory _$$DoorModelImplCopyWith(
          _$DoorModelImpl value, $Res Function(_$DoorModelImpl) then) =
      __$$DoorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id, String wallId, double position, double width, DoorType type});
}

/// @nodoc
class __$$DoorModelImplCopyWithImpl<$Res>
    extends _$DoorModelCopyWithImpl<$Res, _$DoorModelImpl>
    implements _$$DoorModelImplCopyWith<$Res> {
  __$$DoorModelImplCopyWithImpl(
      _$DoorModelImpl _value, $Res Function(_$DoorModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DoorModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? wallId = null,
    Object? position = null,
    Object? width = null,
    Object? type = null,
  }) {
    return _then(_$DoorModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      wallId: null == wallId
          ? _value.wallId
          : wallId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as DoorType,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DoorModelImpl with DiagnosticableTreeMixin implements _DoorModel {
  const _$DoorModelImpl(
      {required this.id,
      required this.wallId,
      required this.position,
      required this.width,
      this.type = DoorType.hinged});

  factory _$DoorModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DoorModelImplFromJson(json);

  @override
  final String id;
  @override
  final String wallId;
  @override
  final double position;
  @override
  final double width;
  @override
  @JsonKey()
  final DoorType type;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DoorModel(id: $id, wallId: $wallId, position: $position, width: $width, type: $type)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DoorModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('wallId', wallId))
      ..add(DiagnosticsProperty('position', position))
      ..add(DiagnosticsProperty('width', width))
      ..add(DiagnosticsProperty('type', type));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DoorModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.wallId, wallId) || other.wallId == wallId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, wallId, position, width, type);

  /// Create a copy of DoorModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DoorModelImplCopyWith<_$DoorModelImpl> get copyWith =>
      __$$DoorModelImplCopyWithImpl<_$DoorModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DoorModelImplToJson(
      this,
    );
  }
}

abstract class _DoorModel implements DoorModel {
  const factory _DoorModel(
      {required final String id,
      required final String wallId,
      required final double position,
      required final double width,
      final DoorType type}) = _$DoorModelImpl;

  factory _DoorModel.fromJson(Map<String, dynamic> json) =
      _$DoorModelImpl.fromJson;

  @override
  String get id;
  @override
  String get wallId;
  @override
  double get position;
  @override
  double get width;
  @override
  DoorType get type;

  /// Create a copy of DoorModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DoorModelImplCopyWith<_$DoorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WindowModel _$WindowModelFromJson(Map<String, dynamic> json) {
  return _WindowModel.fromJson(json);
}

/// @nodoc
mixin _$WindowModel {
  String get id => throw _privateConstructorUsedError;
  String get wallId => throw _privateConstructorUsedError;
  double get position => throw _privateConstructorUsedError;
  double get width => throw _privateConstructorUsedError;
  double get height => throw _privateConstructorUsedError;
  WindowType get type => throw _privateConstructorUsedError;

  /// Serializes this WindowModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WindowModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WindowModelCopyWith<WindowModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WindowModelCopyWith<$Res> {
  factory $WindowModelCopyWith(
          WindowModel value, $Res Function(WindowModel) then) =
      _$WindowModelCopyWithImpl<$Res, WindowModel>;
  @useResult
  $Res call(
      {String id,
      String wallId,
      double position,
      double width,
      double height,
      WindowType type});
}

/// @nodoc
class _$WindowModelCopyWithImpl<$Res, $Val extends WindowModel>
    implements $WindowModelCopyWith<$Res> {
  _$WindowModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WindowModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? wallId = null,
    Object? position = null,
    Object? width = null,
    Object? height = null,
    Object? type = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      wallId: null == wallId
          ? _value.wallId
          : wallId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as WindowType,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WindowModelImplCopyWith<$Res>
    implements $WindowModelCopyWith<$Res> {
  factory _$$WindowModelImplCopyWith(
          _$WindowModelImpl value, $Res Function(_$WindowModelImpl) then) =
      __$$WindowModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String wallId,
      double position,
      double width,
      double height,
      WindowType type});
}

/// @nodoc
class __$$WindowModelImplCopyWithImpl<$Res>
    extends _$WindowModelCopyWithImpl<$Res, _$WindowModelImpl>
    implements _$$WindowModelImplCopyWith<$Res> {
  __$$WindowModelImplCopyWithImpl(
      _$WindowModelImpl _value, $Res Function(_$WindowModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of WindowModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? wallId = null,
    Object? position = null,
    Object? width = null,
    Object? height = null,
    Object? type = null,
  }) {
    return _then(_$WindowModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      wallId: null == wallId
          ? _value.wallId
          : wallId // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as WindowType,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WindowModelImpl with DiagnosticableTreeMixin implements _WindowModel {
  const _$WindowModelImpl(
      {required this.id,
      required this.wallId,
      required this.position,
      required this.width,
      required this.height,
      this.type = WindowType.casement});

  factory _$WindowModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$WindowModelImplFromJson(json);

  @override
  final String id;
  @override
  final String wallId;
  @override
  final double position;
  @override
  final double width;
  @override
  final double height;
  @override
  @JsonKey()
  final WindowType type;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'WindowModel(id: $id, wallId: $wallId, position: $position, width: $width, height: $height, type: $type)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'WindowModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('wallId', wallId))
      ..add(DiagnosticsProperty('position', position))
      ..add(DiagnosticsProperty('width', width))
      ..add(DiagnosticsProperty('height', height))
      ..add(DiagnosticsProperty('type', type));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WindowModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.wallId, wallId) || other.wallId == wallId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, wallId, position, width, height, type);

  /// Create a copy of WindowModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WindowModelImplCopyWith<_$WindowModelImpl> get copyWith =>
      __$$WindowModelImplCopyWithImpl<_$WindowModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WindowModelImplToJson(
      this,
    );
  }
}

abstract class _WindowModel implements WindowModel {
  const factory _WindowModel(
      {required final String id,
      required final String wallId,
      required final double position,
      required final double width,
      required final double height,
      final WindowType type}) = _$WindowModelImpl;

  factory _WindowModel.fromJson(Map<String, dynamic> json) =
      _$WindowModelImpl.fromJson;

  @override
  String get id;
  @override
  String get wallId;
  @override
  double get position;
  @override
  double get width;
  @override
  double get height;
  @override
  WindowType get type;

  /// Create a copy of WindowModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WindowModelImplCopyWith<_$WindowModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DimensionsModel _$DimensionsModelFromJson(Map<String, dynamic> json) {
  return _DimensionsModel.fromJson(json);
}

/// @nodoc
mixin _$DimensionsModel {
  double get width => throw _privateConstructorUsedError;
  double get height => throw _privateConstructorUsedError;
  double get area => throw _privateConstructorUsedError;

  /// Serializes this DimensionsModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DimensionsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DimensionsModelCopyWith<DimensionsModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DimensionsModelCopyWith<$Res> {
  factory $DimensionsModelCopyWith(
          DimensionsModel value, $Res Function(DimensionsModel) then) =
      _$DimensionsModelCopyWithImpl<$Res, DimensionsModel>;
  @useResult
  $Res call({double width, double height, double area});
}

/// @nodoc
class _$DimensionsModelCopyWithImpl<$Res, $Val extends DimensionsModel>
    implements $DimensionsModelCopyWith<$Res> {
  _$DimensionsModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DimensionsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? width = null,
    Object? height = null,
    Object? area = null,
  }) {
    return _then(_value.copyWith(
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DimensionsModelImplCopyWith<$Res>
    implements $DimensionsModelCopyWith<$Res> {
  factory _$$DimensionsModelImplCopyWith(_$DimensionsModelImpl value,
          $Res Function(_$DimensionsModelImpl) then) =
      __$$DimensionsModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double width, double height, double area});
}

/// @nodoc
class __$$DimensionsModelImplCopyWithImpl<$Res>
    extends _$DimensionsModelCopyWithImpl<$Res, _$DimensionsModelImpl>
    implements _$$DimensionsModelImplCopyWith<$Res> {
  __$$DimensionsModelImplCopyWithImpl(
      _$DimensionsModelImpl _value, $Res Function(_$DimensionsModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of DimensionsModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? width = null,
    Object? height = null,
    Object? area = null,
  }) {
    return _then(_$DimensionsModelImpl(
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      area: null == area
          ? _value.area
          : area // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DimensionsModelImpl
    with DiagnosticableTreeMixin
    implements _DimensionsModel {
  const _$DimensionsModelImpl(
      {required this.width, required this.height, required this.area});

  factory _$DimensionsModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$DimensionsModelImplFromJson(json);

  @override
  final double width;
  @override
  final double height;
  @override
  final double area;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'DimensionsModel(width: $width, height: $height, area: $area)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'DimensionsModel'))
      ..add(DiagnosticsProperty('width', width))
      ..add(DiagnosticsProperty('height', height))
      ..add(DiagnosticsProperty('area', area));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DimensionsModelImpl &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.area, area) || other.area == area));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, width, height, area);

  /// Create a copy of DimensionsModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DimensionsModelImplCopyWith<_$DimensionsModelImpl> get copyWith =>
      __$$DimensionsModelImplCopyWithImpl<_$DimensionsModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DimensionsModelImplToJson(
      this,
    );
  }
}

abstract class _DimensionsModel implements DimensionsModel {
  const factory _DimensionsModel(
      {required final double width,
      required final double height,
      required final double area}) = _$DimensionsModelImpl;

  factory _DimensionsModel.fromJson(Map<String, dynamic> json) =
      _$DimensionsModelImpl.fromJson;

  @override
  double get width;
  @override
  double get height;
  @override
  double get area;

  /// Create a copy of DimensionsModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DimensionsModelImplCopyWith<_$DimensionsModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GeneratedDesignModel _$GeneratedDesignModelFromJson(Map<String, dynamic> json) {
  return _GeneratedDesignModel.fromJson(json);
}

/// @nodoc
mixin _$GeneratedDesignModel {
  String get id => throw _privateConstructorUsedError;
  String get panoramaUrl => throw _privateConstructorUsedError;
  String get style => throw _privateConstructorUsedError;
  int get primaryColor => throw _privateConstructorUsedError;
  int get secondaryColor => throw _privateConstructorUsedError;
  int get accentColor => throw _privateConstructorUsedError;
  int get backgroundColor => throw _privateConstructorUsedError;
  int get surfaceColor => throw _privateConstructorUsedError;
  String? get prompt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this GeneratedDesignModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GeneratedDesignModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GeneratedDesignModelCopyWith<GeneratedDesignModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GeneratedDesignModelCopyWith<$Res> {
  factory $GeneratedDesignModelCopyWith(GeneratedDesignModel value,
          $Res Function(GeneratedDesignModel) then) =
      _$GeneratedDesignModelCopyWithImpl<$Res, GeneratedDesignModel>;
  @useResult
  $Res call(
      {String id,
      String panoramaUrl,
      String style,
      int primaryColor,
      int secondaryColor,
      int accentColor,
      int backgroundColor,
      int surfaceColor,
      String? prompt,
      DateTime? createdAt});
}

/// @nodoc
class _$GeneratedDesignModelCopyWithImpl<$Res,
        $Val extends GeneratedDesignModel>
    implements $GeneratedDesignModelCopyWith<$Res> {
  _$GeneratedDesignModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GeneratedDesignModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? panoramaUrl = null,
    Object? style = null,
    Object? primaryColor = null,
    Object? secondaryColor = null,
    Object? accentColor = null,
    Object? backgroundColor = null,
    Object? surfaceColor = null,
    Object? prompt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      panoramaUrl: null == panoramaUrl
          ? _value.panoramaUrl
          : panoramaUrl // ignore: cast_nullable_to_non_nullable
              as String,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String,
      primaryColor: null == primaryColor
          ? _value.primaryColor
          : primaryColor // ignore: cast_nullable_to_non_nullable
              as int,
      secondaryColor: null == secondaryColor
          ? _value.secondaryColor
          : secondaryColor // ignore: cast_nullable_to_non_nullable
              as int,
      accentColor: null == accentColor
          ? _value.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as int,
      backgroundColor: null == backgroundColor
          ? _value.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as int,
      surfaceColor: null == surfaceColor
          ? _value.surfaceColor
          : surfaceColor // ignore: cast_nullable_to_non_nullable
              as int,
      prompt: freezed == prompt
          ? _value.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GeneratedDesignModelImplCopyWith<$Res>
    implements $GeneratedDesignModelCopyWith<$Res> {
  factory _$$GeneratedDesignModelImplCopyWith(_$GeneratedDesignModelImpl value,
          $Res Function(_$GeneratedDesignModelImpl) then) =
      __$$GeneratedDesignModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String panoramaUrl,
      String style,
      int primaryColor,
      int secondaryColor,
      int accentColor,
      int backgroundColor,
      int surfaceColor,
      String? prompt,
      DateTime? createdAt});
}

/// @nodoc
class __$$GeneratedDesignModelImplCopyWithImpl<$Res>
    extends _$GeneratedDesignModelCopyWithImpl<$Res, _$GeneratedDesignModelImpl>
    implements _$$GeneratedDesignModelImplCopyWith<$Res> {
  __$$GeneratedDesignModelImplCopyWithImpl(_$GeneratedDesignModelImpl _value,
      $Res Function(_$GeneratedDesignModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of GeneratedDesignModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? panoramaUrl = null,
    Object? style = null,
    Object? primaryColor = null,
    Object? secondaryColor = null,
    Object? accentColor = null,
    Object? backgroundColor = null,
    Object? surfaceColor = null,
    Object? prompt = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$GeneratedDesignModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      panoramaUrl: null == panoramaUrl
          ? _value.panoramaUrl
          : panoramaUrl // ignore: cast_nullable_to_non_nullable
              as String,
      style: null == style
          ? _value.style
          : style // ignore: cast_nullable_to_non_nullable
              as String,
      primaryColor: null == primaryColor
          ? _value.primaryColor
          : primaryColor // ignore: cast_nullable_to_non_nullable
              as int,
      secondaryColor: null == secondaryColor
          ? _value.secondaryColor
          : secondaryColor // ignore: cast_nullable_to_non_nullable
              as int,
      accentColor: null == accentColor
          ? _value.accentColor
          : accentColor // ignore: cast_nullable_to_non_nullable
              as int,
      backgroundColor: null == backgroundColor
          ? _value.backgroundColor
          : backgroundColor // ignore: cast_nullable_to_non_nullable
              as int,
      surfaceColor: null == surfaceColor
          ? _value.surfaceColor
          : surfaceColor // ignore: cast_nullable_to_non_nullable
              as int,
      prompt: freezed == prompt
          ? _value.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GeneratedDesignModelImpl
    with DiagnosticableTreeMixin
    implements _GeneratedDesignModel {
  const _$GeneratedDesignModelImpl(
      {required this.id,
      required this.panoramaUrl,
      required this.style,
      required this.primaryColor,
      required this.secondaryColor,
      required this.accentColor,
      required this.backgroundColor,
      required this.surfaceColor,
      this.prompt,
      this.createdAt});

  factory _$GeneratedDesignModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GeneratedDesignModelImplFromJson(json);

  @override
  final String id;
  @override
  final String panoramaUrl;
  @override
  final String style;
  @override
  final int primaryColor;
  @override
  final int secondaryColor;
  @override
  final int accentColor;
  @override
  final int backgroundColor;
  @override
  final int surfaceColor;
  @override
  final String? prompt;
  @override
  final DateTime? createdAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'GeneratedDesignModel(id: $id, panoramaUrl: $panoramaUrl, style: $style, primaryColor: $primaryColor, secondaryColor: $secondaryColor, accentColor: $accentColor, backgroundColor: $backgroundColor, surfaceColor: $surfaceColor, prompt: $prompt, createdAt: $createdAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'GeneratedDesignModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('panoramaUrl', panoramaUrl))
      ..add(DiagnosticsProperty('style', style))
      ..add(DiagnosticsProperty('primaryColor', primaryColor))
      ..add(DiagnosticsProperty('secondaryColor', secondaryColor))
      ..add(DiagnosticsProperty('accentColor', accentColor))
      ..add(DiagnosticsProperty('backgroundColor', backgroundColor))
      ..add(DiagnosticsProperty('surfaceColor', surfaceColor))
      ..add(DiagnosticsProperty('prompt', prompt))
      ..add(DiagnosticsProperty('createdAt', createdAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GeneratedDesignModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.panoramaUrl, panoramaUrl) ||
                other.panoramaUrl == panoramaUrl) &&
            (identical(other.style, style) || other.style == style) &&
            (identical(other.primaryColor, primaryColor) ||
                other.primaryColor == primaryColor) &&
            (identical(other.secondaryColor, secondaryColor) ||
                other.secondaryColor == secondaryColor) &&
            (identical(other.accentColor, accentColor) ||
                other.accentColor == accentColor) &&
            (identical(other.backgroundColor, backgroundColor) ||
                other.backgroundColor == backgroundColor) &&
            (identical(other.surfaceColor, surfaceColor) ||
                other.surfaceColor == surfaceColor) &&
            (identical(other.prompt, prompt) || other.prompt == prompt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      panoramaUrl,
      style,
      primaryColor,
      secondaryColor,
      accentColor,
      backgroundColor,
      surfaceColor,
      prompt,
      createdAt);

  /// Create a copy of GeneratedDesignModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GeneratedDesignModelImplCopyWith<_$GeneratedDesignModelImpl>
      get copyWith =>
          __$$GeneratedDesignModelImplCopyWithImpl<_$GeneratedDesignModelImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GeneratedDesignModelImplToJson(
      this,
    );
  }
}

abstract class _GeneratedDesignModel implements GeneratedDesignModel {
  const factory _GeneratedDesignModel(
      {required final String id,
      required final String panoramaUrl,
      required final String style,
      required final int primaryColor,
      required final int secondaryColor,
      required final int accentColor,
      required final int backgroundColor,
      required final int surfaceColor,
      final String? prompt,
      final DateTime? createdAt}) = _$GeneratedDesignModelImpl;

  factory _GeneratedDesignModel.fromJson(Map<String, dynamic> json) =
      _$GeneratedDesignModelImpl.fromJson;

  @override
  String get id;
  @override
  String get panoramaUrl;
  @override
  String get style;
  @override
  int get primaryColor;
  @override
  int get secondaryColor;
  @override
  int get accentColor;
  @override
  int get backgroundColor;
  @override
  int get surfaceColor;
  @override
  String? get prompt;
  @override
  DateTime? get createdAt;

  /// Create a copy of GeneratedDesignModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GeneratedDesignModelImplCopyWith<_$GeneratedDesignModelImpl>
      get copyWith => throw _privateConstructorUsedError;
}
