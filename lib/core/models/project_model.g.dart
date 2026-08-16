// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointImpl _$$PointImplFromJson(Map<String, dynamic> json) => _$PointImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );

Map<String, dynamic> _$$PointImplToJson(_$PointImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
    };

_$ProjectModelImpl _$$ProjectModelImplFromJson(Map<String, dynamic> json) =>
    _$ProjectModelImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      roomType: json['roomType'] as String,
      style: json['style'] as String,
      primaryColor: (json['primaryColor'] as num).toInt(),
      secondaryColor: (json['secondaryColor'] as num).toInt(),
      accentColor: (json['accentColor'] as num).toInt(),
      backgroundColor: (json['backgroundColor'] as num).toInt(),
      surfaceColor: (json['surfaceColor'] as num).toInt(),
      rawCaptureRefs: (json['rawCaptureRefs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      panoramaUrl: json['panoramaUrl'] as String?,
      floorPlan: json['floorPlan'] == null
          ? null
          : FloorPlanModel.fromJson(json['floorPlan'] as Map<String, dynamic>),
      generatedDesigns: (json['generatedDesigns'] as List<dynamic>?)
          ?.map((e) => GeneratedDesignModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: $enumDecodeNullable(_$ProjectStatusEnumMap, json['status']) ??
          ProjectStatus.scanning,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ProjectModelImplToJson(_$ProjectModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'roomType': instance.roomType,
      'style': instance.style,
      'primaryColor': instance.primaryColor,
      'secondaryColor': instance.secondaryColor,
      'accentColor': instance.accentColor,
      'backgroundColor': instance.backgroundColor,
      'surfaceColor': instance.surfaceColor,
      'rawCaptureRefs': instance.rawCaptureRefs,
      'panoramaUrl': instance.panoramaUrl,
      'floorPlan': instance.floorPlan,
      'generatedDesigns': instance.generatedDesigns,
      'status': _$ProjectStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$ProjectStatusEnumMap = {
  ProjectStatus.scanning: 'scanning',
  ProjectStatus.processing: 'processing',
  ProjectStatus.reviewingPlan: 'reviewing_plan',
  ProjectStatus.styling: 'styling',
  ProjectStatus.generating: 'generating',
  ProjectStatus.complete: 'complete',
  ProjectStatus.failed: 'failed',
};

_$FloorPlanModelImpl _$$FloorPlanModelImplFromJson(Map<String, dynamic> json) =>
    _$FloorPlanModelImpl(
      walls: (json['walls'] as List<dynamic>?)
              ?.map((e) => WallModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WallModel>[],
      doors: (json['doors'] as List<dynamic>?)
              ?.map((e) => DoorModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DoorModel>[],
      windows: (json['windows'] as List<dynamic>?)
              ?.map((e) => WindowModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <WindowModel>[],
      dimensions:
          DimensionsModel.fromJson(json['dimensions'] as Map<String, dynamic>),
      unit: $enumDecodeNullable(_$MeasurementUnitEnumMap, json['unit']) ??
          MeasurementUnit.metric,
      isUserEdited: json['isUserEdited'] as bool? ?? false,
    );

Map<String, dynamic> _$$FloorPlanModelImplToJson(
        _$FloorPlanModelImpl instance) =>
    <String, dynamic>{
      'walls': instance.walls,
      'doors': instance.doors,
      'windows': instance.windows,
      'dimensions': instance.dimensions,
      'unit': _$MeasurementUnitEnumMap[instance.unit]!,
      'isUserEdited': instance.isUserEdited,
    };

const _$MeasurementUnitEnumMap = {
  MeasurementUnit.metric: 'metric',
  MeasurementUnit.imperial: 'imperial',
};

_$WallModelImpl _$$WallModelImplFromJson(Map<String, dynamic> json) =>
    _$WallModelImpl(
      id: json['id'] as String,
      start: Point.fromJson(json['start'] as Map<String, dynamic>),
      end: Point.fromJson(json['end'] as Map<String, dynamic>),
      thickness: (json['thickness'] as num).toDouble(),
      isExternal: json['isExternal'] as bool? ?? false,
    );

Map<String, dynamic> _$$WallModelImplToJson(_$WallModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': instance.start,
      'end': instance.end,
      'thickness': instance.thickness,
      'isExternal': instance.isExternal,
    };

_$DoorModelImpl _$$DoorModelImplFromJson(Map<String, dynamic> json) =>
    _$DoorModelImpl(
      id: json['id'] as String,
      wallId: json['wallId'] as String,
      position: (json['position'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      type: $enumDecodeNullable(_$DoorTypeEnumMap, json['type']) ??
          DoorType.hinged,
    );

Map<String, dynamic> _$$DoorModelImplToJson(_$DoorModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'wallId': instance.wallId,
      'position': instance.position,
      'width': instance.width,
      'type': _$DoorTypeEnumMap[instance.type]!,
    };

const _$DoorTypeEnumMap = {
  DoorType.hinged: 'hinged',
  DoorType.sliding: 'sliding',
  DoorType.pocket: 'pocket',
  DoorType.bifold: 'bifold',
};

_$WindowModelImpl _$$WindowModelImplFromJson(Map<String, dynamic> json) =>
    _$WindowModelImpl(
      id: json['id'] as String,
      wallId: json['wallId'] as String,
      position: (json['position'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      type: $enumDecodeNullable(_$WindowTypeEnumMap, json['type']) ??
          WindowType.casement,
    );

Map<String, dynamic> _$$WindowModelImplToJson(_$WindowModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'wallId': instance.wallId,
      'position': instance.position,
      'width': instance.width,
      'height': instance.height,
      'type': _$WindowTypeEnumMap[instance.type]!,
    };

const _$WindowTypeEnumMap = {
  WindowType.casement: 'casement',
  WindowType.sliding: 'sliding',
  WindowType.doubleHung: 'double_hung',
  WindowType.fixed: 'fixed',
  WindowType.bay: 'bay',
};

_$DimensionsModelImpl _$$DimensionsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$DimensionsModelImpl(
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      area: (json['area'] as num).toDouble(),
    );

Map<String, dynamic> _$$DimensionsModelImplToJson(
        _$DimensionsModelImpl instance) =>
    <String, dynamic>{
      'width': instance.width,
      'height': instance.height,
      'area': instance.area,
    };

_$GeneratedDesignModelImpl _$$GeneratedDesignModelImplFromJson(
        Map<String, dynamic> json) =>
    _$GeneratedDesignModelImpl(
      id: json['id'] as String,
      panoramaUrl: json['panoramaUrl'] as String,
      style: json['style'] as String,
      primaryColor: (json['primaryColor'] as num).toInt(),
      secondaryColor: (json['secondaryColor'] as num).toInt(),
      accentColor: (json['accentColor'] as num).toInt(),
      backgroundColor: (json['backgroundColor'] as num).toInt(),
      surfaceColor: (json['surfaceColor'] as num).toInt(),
      prompt: json['prompt'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$GeneratedDesignModelImplToJson(
        _$GeneratedDesignModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'panoramaUrl': instance.panoramaUrl,
      'style': instance.style,
      'primaryColor': instance.primaryColor,
      'secondaryColor': instance.secondaryColor,
      'accentColor': instance.accentColor,
      'backgroundColor': instance.backgroundColor,
      'surfaceColor': instance.surfaceColor,
      'prompt': instance.prompt,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
