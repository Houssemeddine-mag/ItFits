import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'project_model.freezed.dart';
part 'project_model.g.dart';

/// Firestore stores dates as [Timestamp] when written with
/// `FieldValue.serverTimestamp()`, but new docs are written as ISO strings.
/// Accept String / Timestamp / DateTime / epoch millis so old + new +
/// offline docs all parse instead of throwing (which blanked History/Home).
DateTime? _dateTimeFromJson(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  if (value is Timestamp) return value.toDate();
  if (value is num) {
    final ms = value.toInt();
    // Heuristic: seconds (<1e11) vs millis.
    return DateTime.fromMillisecondsSinceEpoch(ms < 100000000000 ? ms * 1000 : ms);
  }
  try {
    final dynamic dyn = value;
    final DateTime? viaToDate = (dyn.toDate() as DateTime?);
    if (viaToDate != null) return viaToDate;
  } catch (_) {}
  return null;
}

String? _dateTimeToJson(DateTime? value) => value?.toIso8601String();

@freezed
class Point with _$Point {
  const factory Point({
    required double x,
    required double y,
  }) = _Point;

  factory Point.fromJson(Map<String, dynamic> json) => _$PointFromJson(json);
}

@freezed
class ProjectModel with _$ProjectModel {
  const factory ProjectModel({
    required String id,
    required String userId,
    required String name,
    required String roomType,
    required String style,
    required int primaryColor,
    required int secondaryColor,
    required int accentColor,
    required int backgroundColor,
    required int surfaceColor,
    List<String>? rawCaptureRefs,
    String? panoramaUrl,
    FloorPlanModel? floorPlan,
    List<GeneratedDesignModel>? generatedDesigns,
    @Default(ProjectStatus.scanning) ProjectStatus status,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? createdAt,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? updatedAt,
  }) = _ProjectModel;

  factory ProjectModel.fromJson(Map<String, dynamic> json) => _$ProjectModelFromJson(json);
}

@freezed
class FloorPlanModel with _$FloorPlanModel {
  const factory FloorPlanModel({
    @Default(<WallModel>[]) List<WallModel> walls,
    @Default(<DoorModel>[]) List<DoorModel> doors,
    @Default(<WindowModel>[]) List<WindowModel> windows,
    required DimensionsModel dimensions,
    @Default(MeasurementUnit.metric) MeasurementUnit unit,
    @Default(false) bool isUserEdited,
  }) = _FloorPlanModel;

  factory FloorPlanModel.fromJson(Map<String, dynamic> json) => _$FloorPlanModelFromJson(json);
}

@freezed
class WallModel with _$WallModel {
  const factory WallModel({
    required String id,
    required Point start,
    required Point end,
    required double thickness,
    @Default(false) bool isExternal,
  }) = _WallModel;

  factory WallModel.fromJson(Map<String, dynamic> json) => _$WallModelFromJson(json);
}

@freezed
class DoorModel with _$DoorModel {
  const factory DoorModel({
    required String id,
    required String wallId,
    required double position,
    required double width,
    @Default(DoorType.hinged) DoorType type,
  }) = _DoorModel;

  factory DoorModel.fromJson(Map<String, dynamic> json) => _$DoorModelFromJson(json);
}

@freezed
class WindowModel with _$WindowModel {
  const factory WindowModel({
    required String id,
    required String wallId,
    required double position,
    required double width,
    required double height,
    @Default(WindowType.casement) WindowType type,
  }) = _WindowModel;

  factory WindowModel.fromJson(Map<String, dynamic> json) => _$WindowModelFromJson(json);
}

@freezed
class DimensionsModel with _$DimensionsModel {
  const factory DimensionsModel({
    required double width,
    required double height,
    required double area,
  }) = _DimensionsModel;

  factory DimensionsModel.fromJson(Map<String, dynamic> json) => _$DimensionsModelFromJson(json);
}

@freezed
class GeneratedDesignModel with _$GeneratedDesignModel {
  const factory GeneratedDesignModel({
    required String id,
    required String panoramaUrl,
    required String style,
    required int primaryColor,
    required int secondaryColor,
    required int accentColor,
    required int backgroundColor,
    required int surfaceColor,
    String? prompt,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    DateTime? createdAt,
  }) = _GeneratedDesignModel;

  factory GeneratedDesignModel.fromJson(Map<String, dynamic> json) => _$GeneratedDesignModelFromJson(json);
}

enum RoomType {
  @JsonValue('living_room')
  livingRoom,
  @JsonValue('bedroom')
  bedroom,
  @JsonValue('kitchen')
  kitchen,
  @JsonValue('bathroom')
  bathroom,
  @JsonValue('dining_room')
  diningRoom,
  @JsonValue('home_office')
  homeOffice,
  @JsonValue('entryway')
  entryway,
}

enum ProjectStatus {
  @JsonValue('scanning')
  scanning,
  @JsonValue('processing')
  processing,
  @JsonValue('reviewing_plan')
  reviewingPlan,
  @JsonValue('styling')
  styling,
  @JsonValue('generating')
  generating,
  @JsonValue('complete')
  complete,
  @JsonValue('failed')
  failed,
}

enum DoorType {
  @JsonValue('hinged')
  hinged,
  @JsonValue('sliding')
  sliding,
  @JsonValue('pocket')
  pocket,
  @JsonValue('bifold')
  bifold,
}

enum WindowType {
  @JsonValue('casement')
  casement,
  @JsonValue('sliding')
  sliding,
  @JsonValue('double_hung')
  doubleHung,
  @JsonValue('fixed')
  fixed,
  @JsonValue('bay')
  bay,
}

enum MeasurementUnit {
  @JsonValue('metric')
  metric,
  @JsonValue('imperial')
  imperial,
}