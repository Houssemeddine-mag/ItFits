import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

part 'style_model.freezed.dart';
part 'style_model.g.dart';

class ColorPaletteConverter implements JsonConverter<ColorPalette, Map<String, dynamic>> {
  const ColorPaletteConverter();

  @override
  ColorPalette fromJson(Map<String, dynamic> json) => ColorPalette(
        primary: json['primary'] as int,
        secondary: json['secondary'] as int,
        accent: json['accent'] as int,
        background: json['background'] as int,
        surface: json['surface'] as int,
      );

  @override
  Map<String, dynamic> toJson(ColorPalette object) => {
        'primary': object.primary,
        'secondary': object.secondary,
        'accent': object.accent,
        'background': object.background,
        'surface': object.surface,
      };
}

@freezed
class StyleModel with _$StyleModel {
  const factory StyleModel({
    required String id,
    required String name,
    required String description,
    required String thumbnailUrl,
    required List<String> keywords,
    @ColorPaletteConverter() required ColorPalette colorPalette,
    required List<FurnitureCategory> furnitureCategories,
    @Default(true) bool isPopular,
    @Default(0) int order,
  }) = _StyleModel;

  factory StyleModel.fromJson(Map<String, dynamic> json) => _$StyleModelFromJson(json);
}

@freezed
class FurnitureCategory with _$FurnitureCategory {
  const factory FurnitureCategory({
    required String id,
    required String name,
    required String iconUrl,
    required List<String> keywords,
  }) = _FurnitureCategory;

  factory FurnitureCategory.fromJson(Map<String, dynamic> json) => _$FurnitureCategoryFromJson(json);
}

@freezed
class ColorPalette with _$ColorPalette {
  const factory ColorPalette({
    required int primary,
    required int secondary,
    required int accent,
    required int background,
    required int surface,
  }) = _ColorPalette;

  const ColorPalette._();

  factory ColorPalette.fromJson(Map<String, dynamic> json) => _$ColorPaletteFromJson(json);

  Color get primaryColor => Color(primary);
  Color get secondaryColor => Color(secondary);
  Color get accentColor => Color(accent);
  Color get backgroundColor => Color(background);
  Color get surfaceColor => Color(surface);
}

enum FurnitureCategoryType {
  @JsonValue('seating')
  seating,
  @JsonValue('tables')
  tables,
  @JsonValue('storage')
  storage,
  @JsonValue('lighting')
  lighting,
  @JsonValue('decor')
  decor,
  @JsonValue('rugs')
  rugs,
  @JsonValue('window_treatments')
  windowTreatments,
  @JsonValue('plants')
  plants,
}