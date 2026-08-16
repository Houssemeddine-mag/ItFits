// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'style_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StyleModel _$StyleModelFromJson(Map<String, dynamic> json) {
  return _StyleModel.fromJson(json);
}

/// @nodoc
mixin _$StyleModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get thumbnailUrl => throw _privateConstructorUsedError;
  List<String> get keywords => throw _privateConstructorUsedError;
  @ColorPaletteConverter()
  ColorPalette get colorPalette => throw _privateConstructorUsedError;
  List<FurnitureCategory> get furnitureCategories =>
      throw _privateConstructorUsedError;
  bool get isPopular => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;

  /// Serializes this StyleModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StyleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StyleModelCopyWith<StyleModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StyleModelCopyWith<$Res> {
  factory $StyleModelCopyWith(
          StyleModel value, $Res Function(StyleModel) then) =
      _$StyleModelCopyWithImpl<$Res, StyleModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String thumbnailUrl,
      List<String> keywords,
      @ColorPaletteConverter() ColorPalette colorPalette,
      List<FurnitureCategory> furnitureCategories,
      bool isPopular,
      int order});

  $ColorPaletteCopyWith<$Res> get colorPalette;
}

/// @nodoc
class _$StyleModelCopyWithImpl<$Res, $Val extends StyleModel>
    implements $StyleModelCopyWith<$Res> {
  _$StyleModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StyleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? thumbnailUrl = null,
    Object? keywords = null,
    Object? colorPalette = null,
    Object? furnitureCategories = null,
    Object? isPopular = null,
    Object? order = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: null == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
      keywords: null == keywords
          ? _value.keywords
          : keywords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      colorPalette: null == colorPalette
          ? _value.colorPalette
          : colorPalette // ignore: cast_nullable_to_non_nullable
              as ColorPalette,
      furnitureCategories: null == furnitureCategories
          ? _value.furnitureCategories
          : furnitureCategories // ignore: cast_nullable_to_non_nullable
              as List<FurnitureCategory>,
      isPopular: null == isPopular
          ? _value.isPopular
          : isPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of StyleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ColorPaletteCopyWith<$Res> get colorPalette {
    return $ColorPaletteCopyWith<$Res>(_value.colorPalette, (value) {
      return _then(_value.copyWith(colorPalette: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StyleModelImplCopyWith<$Res>
    implements $StyleModelCopyWith<$Res> {
  factory _$$StyleModelImplCopyWith(
          _$StyleModelImpl value, $Res Function(_$StyleModelImpl) then) =
      __$$StyleModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      String thumbnailUrl,
      List<String> keywords,
      @ColorPaletteConverter() ColorPalette colorPalette,
      List<FurnitureCategory> furnitureCategories,
      bool isPopular,
      int order});

  @override
  $ColorPaletteCopyWith<$Res> get colorPalette;
}

/// @nodoc
class __$$StyleModelImplCopyWithImpl<$Res>
    extends _$StyleModelCopyWithImpl<$Res, _$StyleModelImpl>
    implements _$$StyleModelImplCopyWith<$Res> {
  __$$StyleModelImplCopyWithImpl(
      _$StyleModelImpl _value, $Res Function(_$StyleModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of StyleModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? thumbnailUrl = null,
    Object? keywords = null,
    Object? colorPalette = null,
    Object? furnitureCategories = null,
    Object? isPopular = null,
    Object? order = null,
  }) {
    return _then(_$StyleModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: null == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
      keywords: null == keywords
          ? _value._keywords
          : keywords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      colorPalette: null == colorPalette
          ? _value.colorPalette
          : colorPalette // ignore: cast_nullable_to_non_nullable
              as ColorPalette,
      furnitureCategories: null == furnitureCategories
          ? _value._furnitureCategories
          : furnitureCategories // ignore: cast_nullable_to_non_nullable
              as List<FurnitureCategory>,
      isPopular: null == isPopular
          ? _value.isPopular
          : isPopular // ignore: cast_nullable_to_non_nullable
              as bool,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StyleModelImpl implements _StyleModel {
  const _$StyleModelImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.thumbnailUrl,
      required final List<String> keywords,
      @ColorPaletteConverter() required this.colorPalette,
      required final List<FurnitureCategory> furnitureCategories,
      this.isPopular = true,
      this.order = 0})
      : _keywords = keywords,
        _furnitureCategories = furnitureCategories;

  factory _$StyleModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StyleModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final String thumbnailUrl;
  final List<String> _keywords;
  @override
  List<String> get keywords {
    if (_keywords is EqualUnmodifiableListView) return _keywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keywords);
  }

  @override
  @ColorPaletteConverter()
  final ColorPalette colorPalette;
  final List<FurnitureCategory> _furnitureCategories;
  @override
  List<FurnitureCategory> get furnitureCategories {
    if (_furnitureCategories is EqualUnmodifiableListView)
      return _furnitureCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_furnitureCategories);
  }

  @override
  @JsonKey()
  final bool isPopular;
  @override
  @JsonKey()
  final int order;

  @override
  String toString() {
    return 'StyleModel(id: $id, name: $name, description: $description, thumbnailUrl: $thumbnailUrl, keywords: $keywords, colorPalette: $colorPalette, furnitureCategories: $furnitureCategories, isPopular: $isPopular, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StyleModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            const DeepCollectionEquality().equals(other._keywords, _keywords) &&
            (identical(other.colorPalette, colorPalette) ||
                other.colorPalette == colorPalette) &&
            const DeepCollectionEquality()
                .equals(other._furnitureCategories, _furnitureCategories) &&
            (identical(other.isPopular, isPopular) ||
                other.isPopular == isPopular) &&
            (identical(other.order, order) || other.order == order));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      thumbnailUrl,
      const DeepCollectionEquality().hash(_keywords),
      colorPalette,
      const DeepCollectionEquality().hash(_furnitureCategories),
      isPopular,
      order);

  /// Create a copy of StyleModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StyleModelImplCopyWith<_$StyleModelImpl> get copyWith =>
      __$$StyleModelImplCopyWithImpl<_$StyleModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StyleModelImplToJson(
      this,
    );
  }
}

abstract class _StyleModel implements StyleModel {
  const factory _StyleModel(
      {required final String id,
      required final String name,
      required final String description,
      required final String thumbnailUrl,
      required final List<String> keywords,
      @ColorPaletteConverter() required final ColorPalette colorPalette,
      required final List<FurnitureCategory> furnitureCategories,
      final bool isPopular,
      final int order}) = _$StyleModelImpl;

  factory _StyleModel.fromJson(Map<String, dynamic> json) =
      _$StyleModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  String get thumbnailUrl;
  @override
  List<String> get keywords;
  @override
  @ColorPaletteConverter()
  ColorPalette get colorPalette;
  @override
  List<FurnitureCategory> get furnitureCategories;
  @override
  bool get isPopular;
  @override
  int get order;

  /// Create a copy of StyleModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StyleModelImplCopyWith<_$StyleModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FurnitureCategory _$FurnitureCategoryFromJson(Map<String, dynamic> json) {
  return _FurnitureCategory.fromJson(json);
}

/// @nodoc
mixin _$FurnitureCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get iconUrl => throw _privateConstructorUsedError;
  List<String> get keywords => throw _privateConstructorUsedError;

  /// Serializes this FurnitureCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FurnitureCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FurnitureCategoryCopyWith<FurnitureCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FurnitureCategoryCopyWith<$Res> {
  factory $FurnitureCategoryCopyWith(
          FurnitureCategory value, $Res Function(FurnitureCategory) then) =
      _$FurnitureCategoryCopyWithImpl<$Res, FurnitureCategory>;
  @useResult
  $Res call({String id, String name, String iconUrl, List<String> keywords});
}

/// @nodoc
class _$FurnitureCategoryCopyWithImpl<$Res, $Val extends FurnitureCategory>
    implements $FurnitureCategoryCopyWith<$Res> {
  _$FurnitureCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FurnitureCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconUrl = null,
    Object? keywords = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: null == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String,
      keywords: null == keywords
          ? _value.keywords
          : keywords // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FurnitureCategoryImplCopyWith<$Res>
    implements $FurnitureCategoryCopyWith<$Res> {
  factory _$$FurnitureCategoryImplCopyWith(_$FurnitureCategoryImpl value,
          $Res Function(_$FurnitureCategoryImpl) then) =
      __$$FurnitureCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String iconUrl, List<String> keywords});
}

/// @nodoc
class __$$FurnitureCategoryImplCopyWithImpl<$Res>
    extends _$FurnitureCategoryCopyWithImpl<$Res, _$FurnitureCategoryImpl>
    implements _$$FurnitureCategoryImplCopyWith<$Res> {
  __$$FurnitureCategoryImplCopyWithImpl(_$FurnitureCategoryImpl _value,
      $Res Function(_$FurnitureCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of FurnitureCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconUrl = null,
    Object? keywords = null,
  }) {
    return _then(_$FurnitureCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: null == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String,
      keywords: null == keywords
          ? _value._keywords
          : keywords // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FurnitureCategoryImpl implements _FurnitureCategory {
  const _$FurnitureCategoryImpl(
      {required this.id,
      required this.name,
      required this.iconUrl,
      required final List<String> keywords})
      : _keywords = keywords;

  factory _$FurnitureCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$FurnitureCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String iconUrl;
  final List<String> _keywords;
  @override
  List<String> get keywords {
    if (_keywords is EqualUnmodifiableListView) return _keywords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_keywords);
  }

  @override
  String toString() {
    return 'FurnitureCategory(id: $id, name: $name, iconUrl: $iconUrl, keywords: $keywords)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FurnitureCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            const DeepCollectionEquality().equals(other._keywords, _keywords));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, iconUrl,
      const DeepCollectionEquality().hash(_keywords));

  /// Create a copy of FurnitureCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FurnitureCategoryImplCopyWith<_$FurnitureCategoryImpl> get copyWith =>
      __$$FurnitureCategoryImplCopyWithImpl<_$FurnitureCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FurnitureCategoryImplToJson(
      this,
    );
  }
}

abstract class _FurnitureCategory implements FurnitureCategory {
  const factory _FurnitureCategory(
      {required final String id,
      required final String name,
      required final String iconUrl,
      required final List<String> keywords}) = _$FurnitureCategoryImpl;

  factory _FurnitureCategory.fromJson(Map<String, dynamic> json) =
      _$FurnitureCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get iconUrl;
  @override
  List<String> get keywords;

  /// Create a copy of FurnitureCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FurnitureCategoryImplCopyWith<_$FurnitureCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ColorPalette _$ColorPaletteFromJson(Map<String, dynamic> json) {
  return _ColorPalette.fromJson(json);
}

/// @nodoc
mixin _$ColorPalette {
  int get primary => throw _privateConstructorUsedError;
  int get secondary => throw _privateConstructorUsedError;
  int get accent => throw _privateConstructorUsedError;
  int get background => throw _privateConstructorUsedError;
  int get surface => throw _privateConstructorUsedError;

  /// Serializes this ColorPalette to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ColorPalette
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ColorPaletteCopyWith<ColorPalette> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ColorPaletteCopyWith<$Res> {
  factory $ColorPaletteCopyWith(
          ColorPalette value, $Res Function(ColorPalette) then) =
      _$ColorPaletteCopyWithImpl<$Res, ColorPalette>;
  @useResult
  $Res call(
      {int primary, int secondary, int accent, int background, int surface});
}

/// @nodoc
class _$ColorPaletteCopyWithImpl<$Res, $Val extends ColorPalette>
    implements $ColorPaletteCopyWith<$Res> {
  _$ColorPaletteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ColorPalette
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? primary = null,
    Object? secondary = null,
    Object? accent = null,
    Object? background = null,
    Object? surface = null,
  }) {
    return _then(_value.copyWith(
      primary: null == primary
          ? _value.primary
          : primary // ignore: cast_nullable_to_non_nullable
              as int,
      secondary: null == secondary
          ? _value.secondary
          : secondary // ignore: cast_nullable_to_non_nullable
              as int,
      accent: null == accent
          ? _value.accent
          : accent // ignore: cast_nullable_to_non_nullable
              as int,
      background: null == background
          ? _value.background
          : background // ignore: cast_nullable_to_non_nullable
              as int,
      surface: null == surface
          ? _value.surface
          : surface // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ColorPaletteImplCopyWith<$Res>
    implements $ColorPaletteCopyWith<$Res> {
  factory _$$ColorPaletteImplCopyWith(
          _$ColorPaletteImpl value, $Res Function(_$ColorPaletteImpl) then) =
      __$$ColorPaletteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int primary, int secondary, int accent, int background, int surface});
}

/// @nodoc
class __$$ColorPaletteImplCopyWithImpl<$Res>
    extends _$ColorPaletteCopyWithImpl<$Res, _$ColorPaletteImpl>
    implements _$$ColorPaletteImplCopyWith<$Res> {
  __$$ColorPaletteImplCopyWithImpl(
      _$ColorPaletteImpl _value, $Res Function(_$ColorPaletteImpl) _then)
      : super(_value, _then);

  /// Create a copy of ColorPalette
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? primary = null,
    Object? secondary = null,
    Object? accent = null,
    Object? background = null,
    Object? surface = null,
  }) {
    return _then(_$ColorPaletteImpl(
      primary: null == primary
          ? _value.primary
          : primary // ignore: cast_nullable_to_non_nullable
              as int,
      secondary: null == secondary
          ? _value.secondary
          : secondary // ignore: cast_nullable_to_non_nullable
              as int,
      accent: null == accent
          ? _value.accent
          : accent // ignore: cast_nullable_to_non_nullable
              as int,
      background: null == background
          ? _value.background
          : background // ignore: cast_nullable_to_non_nullable
              as int,
      surface: null == surface
          ? _value.surface
          : surface // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ColorPaletteImpl extends _ColorPalette {
  const _$ColorPaletteImpl(
      {required this.primary,
      required this.secondary,
      required this.accent,
      required this.background,
      required this.surface})
      : super._();

  factory _$ColorPaletteImpl.fromJson(Map<String, dynamic> json) =>
      _$$ColorPaletteImplFromJson(json);

  @override
  final int primary;
  @override
  final int secondary;
  @override
  final int accent;
  @override
  final int background;
  @override
  final int surface;

  @override
  String toString() {
    return 'ColorPalette(primary: $primary, secondary: $secondary, accent: $accent, background: $background, surface: $surface)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ColorPaletteImpl &&
            (identical(other.primary, primary) || other.primary == primary) &&
            (identical(other.secondary, secondary) ||
                other.secondary == secondary) &&
            (identical(other.accent, accent) || other.accent == accent) &&
            (identical(other.background, background) ||
                other.background == background) &&
            (identical(other.surface, surface) || other.surface == surface));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, primary, secondary, accent, background, surface);

  /// Create a copy of ColorPalette
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ColorPaletteImplCopyWith<_$ColorPaletteImpl> get copyWith =>
      __$$ColorPaletteImplCopyWithImpl<_$ColorPaletteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ColorPaletteImplToJson(
      this,
    );
  }
}

abstract class _ColorPalette extends ColorPalette {
  const factory _ColorPalette(
      {required final int primary,
      required final int secondary,
      required final int accent,
      required final int background,
      required final int surface}) = _$ColorPaletteImpl;
  const _ColorPalette._() : super._();

  factory _ColorPalette.fromJson(Map<String, dynamic> json) =
      _$ColorPaletteImpl.fromJson;

  @override
  int get primary;
  @override
  int get secondary;
  @override
  int get accent;
  @override
  int get background;
  @override
  int get surface;

  /// Create a copy of ColorPalette
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ColorPaletteImplCopyWith<_$ColorPaletteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
