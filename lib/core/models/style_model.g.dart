// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'style_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StyleModelImpl _$$StyleModelImplFromJson(Map<String, dynamic> json) =>
    _$StyleModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      keywords:
          (json['keywords'] as List<dynamic>).map((e) => e as String).toList(),
      colorPalette: const ColorPaletteConverter()
          .fromJson(json['colorPalette'] as Map<String, dynamic>),
      furnitureCategories: (json['furnitureCategories'] as List<dynamic>)
          .map((e) => FurnitureCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPopular: json['isPopular'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$StyleModelImplToJson(_$StyleModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'thumbnailUrl': instance.thumbnailUrl,
      'keywords': instance.keywords,
      'colorPalette':
          const ColorPaletteConverter().toJson(instance.colorPalette),
      'furnitureCategories': instance.furnitureCategories,
      'isPopular': instance.isPopular,
      'order': instance.order,
    };

_$FurnitureCategoryImpl _$$FurnitureCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$FurnitureCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String,
      keywords:
          (json['keywords'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$$FurnitureCategoryImplToJson(
        _$FurnitureCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'iconUrl': instance.iconUrl,
      'keywords': instance.keywords,
    };

_$ColorPaletteImpl _$$ColorPaletteImplFromJson(Map<String, dynamic> json) =>
    _$ColorPaletteImpl(
      primary: (json['primary'] as num).toInt(),
      secondary: (json['secondary'] as num).toInt(),
      accent: (json['accent'] as num).toInt(),
      background: (json['background'] as num).toInt(),
      surface: (json['surface'] as num).toInt(),
    );

Map<String, dynamic> _$$ColorPaletteImplToJson(_$ColorPaletteImpl instance) =>
    <String, dynamic>{
      'primary': instance.primary,
      'secondary': instance.secondary,
      'accent': instance.accent,
      'background': instance.background,
      'surface': instance.surface,
    };
