import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:itfits/core/models/project_model.dart';
import 'package:itfits/core/services/providers.dart';

final selectedStyleProvider = StateProvider<String?>((ref) => null);
final selectedPaletteProvider = StateProvider<int?>((ref) => null);
final selectedPreferencesProvider = StateProvider<List<String>>((ref) => []);

final designStyles = [
  DesignStyle(
    id: 'modern',
    name: 'Modern',
    description: 'Clean lines, neutral palette, minimal ornamentation',
    icon: Icons.architecture_rounded,
    color: Color(0xFF8B6B5A),
    colorPalettes: [
      ColorPalette(
        id: 'modern_neutral',
        name: 'Neutral',
        colors: [0xFFFAF8F5, 0xFFE8E0D8, 0xFFB8A898, 0xFF7D6D5D],
      ),
      ColorPalette(
        id: 'modern_mono',
        name: 'Monochrome',
        colors: [0xFFFFFFFF, 0xFFF0F0F0, 0xFF9C8A78, 0xFF1E2A3A],
      ),
      ColorPalette(
        id: 'modern_warm',
        name: 'Warm',
        colors: [0xFFFFF8F0, 0xFFF5E8D8, 0xFFD4A574, 0xFF8B6B5A],
      ),
    ],
  ),
  DesignStyle(
    id: 'scandinavian',
    name: 'Scandinavian',
    description: 'Light woods, cozy textures, functional beauty',
    icon: Icons.forest_rounded,
    color: Color(0xFF6B8E8E),
    colorPalettes: [
      ColorPalette(
        id: 'scandi_light',
        name: 'Light & Airy',
        colors: [0xFFFFFFFF, 0xFFF5F0EB, 0xFFD4C8BB, 0xFF9C8A78],
      ),
      ColorPalette(
        id: 'scandi_nature',
        name: 'Nature',
        colors: [0xFFFAF8F5, 0xFFE8E0D8, 0xFF6B8E8E, 0xFF4A7C7C],
      ),
      ColorPalette(
        id: 'scandi_warm',
        name: 'Warm Hygge',
        colors: [0xFFFFF8F0, 0xFFF5E8D8, 0xFFD4A574, 0xFFB88A5A],
      ),
    ],
  ),
  DesignStyle(
    id: 'industrial',
    name: 'Industrial',
    description: 'Raw materials, exposed elements, urban edge',
    icon: Icons.factory_rounded,
    color: Color(0xFF5E5042),
    colorPalettes: [
      ColorPalette(
        id: 'ind_raw',
        name: 'Raw Concrete',
        colors: [0xFFE8E0D8, 0xFFB8A898, 0xFF7D6D5D, 0xFF3F362D],
      ),
      ColorPalette(
        id: 'ind_warm',
        name: 'Warm Metal',
        colors: [0xFFFAF8F5, 0xFFE8E0D8, 0xFFD4A574, 0xFF8B6B5A],
      ),
      ColorPalette(
        id: 'ind_dark',
        name: 'Dark Factory',
        colors: [0xFF26221E, 0xFF3F362D, 0xFF5E5042, 0xFF9C8A78],
      ),
    ],
  ),
  DesignStyle(
    id: 'midcentury',
    name: 'Mid-Century',
    description: 'Organic shapes, warm tones, timeless classics',
    icon: Icons.chair_rounded,
    color: Color(0xFFD4A574),
    colorPalettes: [
      ColorPalette(
        id: 'mc_classic',
        name: 'Classic',
        colors: [0xFFFFF8F0, 0xFFF5E8D8, 0xFFD4A574, 0xFF8B6B5A],
      ),
      ColorPalette(
        id: 'mc_teak',
        name: 'Teak & Mustard',
        colors: [0xFFFAF8F5, 0xFFE8E0D8, 0xFFF57F17, 0xFF7D6D5D],
      ),
      ColorPalette(
        id: 'mc_olive',
        name: 'Olive & Walnut',
        colors: [0xFFFAF8F5, 0xFFD4C8BB, 0xFF7D6D5D, 0xFF4A7C59],
      ),
    ],
  ),
  DesignStyle(
    id: 'bohemian',
    name: 'Bohemian',
    description: 'Eclectic patterns, vibrant colors, layered textures',
    icon: Icons.palette_rounded,
    color: Color(0xFFB88A5A),
    colorPalettes: [
      ColorPalette(
        id: 'boho_jewel',
        name: 'Jewel Tones',
        colors: [0xFFFAF8F5, 0xFFD4C8BB, 0xFF8B6B5A, 0xFF4A7C8A],
      ),
      ColorPalette(
        id: 'boho_earth',
        name: 'Earth Tones',
        colors: [0xFFFFF8F0, 0xFFF5E8D8, 0xFFD4A574, 0xFF7D6D5D],
      ),
      ColorPalette(
        id: 'boho_vibrant',
        name: 'Vibrant',
        colors: [0xFFFFFFFF, 0xFFF0E8E0, 0xFFE8C56D, 0xFFC62828],
      ),
    ],
  ),
  DesignStyle(
    id: 'coastal',
    name: 'Coastal',
    description: 'Breezy blues, natural fibers, relaxed elegance',
    icon: Icons.waves_rounded,
    color: Color(0xFF4A7C8A),
    colorPalettes: [
      ColorPalette(
        id: 'coastal_blue',
        name: 'Classic Blue',
        colors: [0xFFFFFFFF, 0xFFF0F5FA, 0xFF4A7C8A, 0xFF2D3A4A],
      ),
      ColorPalette(
        id: 'coastal_sand',
        name: 'Sand & Sea',
        colors: [0xFFFAF8F5, 0xFFF5E8D8, 0xFF6B8E8E, 0xFF4A7C7C],
      ),
      ColorPalette(
        id: 'coastal_drift',
        name: 'Driftwood',
        colors: [0xFFFFFFFF, 0xFFF0EDE8, 0xFFB8A898, 0xFF7D6D5D],
      ),
    ],
  ),
  DesignStyle(
    id: 'japandi',
    name: 'Japandi',
    description: 'Japanese minimalism meets Scandinavian warmth',
    icon: Icons.brightness_low_rounded,
    color: Color(0xFF9C8A78),
    colorPalettes: [
      ColorPalette(
        id: 'jap_zen',
        name: 'Zen',
        colors: [0xFFFAF8F5, 0xFFE8E0D8, 0xFF9C8A78, 0xFF5E5042],
      ),
      ColorPalette(
        id: 'jap_warm',
        name: 'Warm Minimalism',
        colors: [0xFFFFF8F0, 0xFFF5E8D8, 0xFFD4A574, 0xFF8B6B5A],
      ),
      ColorPalette(
        id: 'jap_contrast',
        name: 'High Contrast',
        colors: [0xFFFFFFFF, 0xFFE8E0D8, 0xFF3F362D, 0xFF1E2A3A],
      ),
    ],
  ),
  DesignStyle(
    id: 'classic',
    name: 'Classic',
    description: 'Timeless elegance, symmetrical layouts, refined details',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF7D6D5D),
    colorPalettes: [
      ColorPalette(
        id: 'class_cream',
        name: 'Cream & Gold',
        colors: [0xFFFFF8F0, 0xFFF5E8D8, 0xFFD4A574, 0xFF8B6B5A],
      ),
      ColorPalette(
        id: 'class_navy',
        name: 'Navy & White',
        colors: [0xFFFFFFFF, 0xFFF0F0F0, 0xFF2D3A4A, 0xFF1E2A3A],
      ),
      ColorPalette(
        id: 'class_sage',
        name: 'Sage & Ivory',
        colors: [0xFFFFFFFF, 0xFFF0F5F0, 0xFF7D6D5D, 0xFF4A7C59],
      ),
    ],
  ),
];

final preferenceOptions = [
  _PreferenceOption('full_redesign', 'Full Redesign', 'Replace all furniture', Icons.transform_rounded),
  _PreferenceOption('keep_furniture', 'Keep Furniture', 'Redesign around existing', Icons.chair_rounded),
  _PreferenceOption('budget', 'Budget Friendly', 'Affordable alternatives', Icons.savings_rounded),
  _PreferenceOption('luxury', 'Luxury Look', 'Premium materials', Icons.diamond_rounded),
  _PreferenceOption('natural_light', 'Maximize Light', 'Bright, airy space', Icons.wb_sunny_rounded),
  _PreferenceOption('cozy', 'Cozy & Intimate', 'Warm, rich textures', Icons.fireplace_rounded),
];

class DesignStyle {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<ColorPalette> colorPalettes;

  const DesignStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.colorPalettes,
  });
}

class ColorPalette {
  final String id;
  final String name;
  final List<int> colors;

  const ColorPalette({
    required this.id,
    required this.name,
    required this.colors,
  });

  List<Color> get colorList => colors.map((c) => Color(c)).toList();
}

class _PreferenceOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const _PreferenceOption(this.id, this.title, this.description, this.icon);
}

class StyleSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onBack;

  const StyleSelectionScreen({super.key, required this.onComplete, this.onBack});

  @override
  ConsumerState<StyleSelectionScreen> createState() =>
      _StyleSelectionScreenState();
}

class _StyleSelectionScreenState extends ConsumerState<StyleSelectionScreen> {
  late String _selectedRoomType;

  static const _roomTypes = [
    'Living Room',
    'Bedroom',
    'Kitchen',
    'Bathroom',
    'Dining Room',
    'Home Office',
    'Entryway',
  ];

  @override
  void initState() {
    super.initState();
    _selectedRoomType = ref.read(selectedRoomTypeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedStyle = ref.watch(selectedStyleProvider);
    final selectedPalette = ref.watch(selectedPaletteProvider);

    final canProceed =
        selectedStyle != null && selectedPalette != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Style & Colors',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Room Type'),
                    const SizedBox(height: 4),
                    Text(
                      'What kind of room is this?',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRoomTypeSelector(colorScheme, theme),
                    const SizedBox(height: 28),

                    _SectionTitle('Design Style'),
                    const SizedBox(height: 4),
                    Text(
                      'This sets the overall aesthetic for your redesign',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStyleGrid(colorScheme, theme),
                    const SizedBox(height: 28),

                    if (selectedStyle != null) ...[
                      _SectionTitle('Color Palette'),
                      const SizedBox(height: 4),
                      Text(
                        'Pick colors that match your vision',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPaletteList(colorScheme, theme),
                      const SizedBox(height: 28),
                    ],

                    _SectionTitle('Design Preferences'),
                    const SizedBox(height: 4),
                    Text(
                      'Optional — helps the AI tailor suggestions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPreferencesGrid(colorScheme, theme),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: canProceed
                      ? () {
                          _saveSelections();
                          widget.onComplete();
                        }
                      : null,
                  child: const Text(
                    'Continue to AI Consult',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTypeSelector(ColorScheme colorScheme, ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roomTypes.map((type) {
        final isSelected = _selectedRoomType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedRoomType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.surface,
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStyleGrid(ColorScheme colorScheme, ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: designStyles.length,
      itemBuilder: (context, index) {
        final style = designStyles[index];
        final isSelected = ref.read(selectedStyleProvider) == style.id;
        return GestureDetector(
          onTap: () {
            ref.read(selectedStyleProvider.notifier).state = style.id;
            ref.read(selectedPaletteProvider.notifier).state = null;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                width: isSelected ? 2.5 : 1,
              ),
              color: isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.surface,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : style.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    style.icon,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : style.color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  style.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    style.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaletteList(ColorScheme colorScheme, ThemeData theme) {
    final styleId = ref.read(selectedStyleProvider);
    final style = designStyles.firstWhere((s) => s.id == styleId);

    return Column(
      children: List.generate(style.colorPalettes.length, (index) {
        final palette = style.colorPalettes[index];
        final isSelected = ref.read(selectedPaletteProvider) == index;
        return GestureDetector(
          onTap: () {
            ref.read(selectedPaletteProvider.notifier).state = index;
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              color: colorScheme.surface,
            ),
            child: Row(
              children: [
                Row(
                  children: palette.colorList.map((color) {
                    return Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    palette.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: colorScheme.outlineVariant,
                    size: 24,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPreferencesGrid(ColorScheme colorScheme, ThemeData theme) {
    final selectedPrefs = ref.watch(selectedPreferencesProvider);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: preferenceOptions.map((pref) {
        final isSelected = selectedPrefs.contains(pref.id);
        return GestureDetector(
          onTap: () {
            final current = ref.read(selectedPreferencesProvider);
            if (isSelected) {
              ref.read(selectedPreferencesProvider.notifier).state =
                  current.where((id) => id != pref.id).toList();
            } else {
              ref.read(selectedPreferencesProvider.notifier).state = [
                ...current,
                pref.id,
              ];
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 42) / 2,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected
                  ? colorScheme.primaryContainer.withOpacity(0.3)
                  : colorScheme.surface,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    pref.icon,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pref.title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        pref.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _saveSelections() {
    final styleId = ref.read(selectedStyleProvider);
    final paletteIndex = ref.read(selectedPaletteProvider);
    final selectedPrefs = ref.read(selectedPreferencesProvider);

    if (styleId != null) {
      final style = designStyles.firstWhere((s) => s.id == styleId);
      ref.read(selectedStyleNameProvider.notifier).state = style.name;
      if (paletteIndex != null && paletteIndex < style.colorPalettes.length) {
        ref.read(selectedPaletteProvider2.notifier).state =
            style.colorPalettes[paletteIndex].colors;
      }
    }

    final prefDescriptions = <String>[];
    for (final prefId in selectedPrefs) {
      final match = preferenceOptions.where((p) => p.id == prefId);
      if (match.isNotEmpty) {
        prefDescriptions.add('${match.first.title}: ${match.first.description}');
      }
    }
    ref.read(aiPreferencesProvider.notifier).state = prefDescriptions;

    ref.read(selectedRoomTypeProvider.notifier).state = _selectedRoomType;

    final project = ref.read(currentProjectProvider);
    if (project != null) {
      final styleName = ref.read(selectedStyleNameProvider);
      final palette = ref.read(selectedPaletteProvider2);
      ref.read(currentProjectProvider.notifier).state = project.copyWith(
        roomType: _selectedRoomType,
        style: styleName,
        primaryColor: palette.isNotEmpty ? palette[0] : project.primaryColor,
        secondaryColor: palette.length > 1 ? palette[1] : project.secondaryColor,
        accentColor: palette.length > 2 ? palette[2] : project.accentColor,
      );
      // Persist so an unfinished project keeps its style + stage.
      unawaited(_persistStyleToCloud(
        styleName: styleName,
        palette: List<int>.from(palette),
        project: project,
      ));
    }
  }

  Future<void> _persistStyleToCloud({
    required String styleName,
    required List<int> palette,
    required ProjectModel project,
  }) async {
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;
      await ref.read(projectServiceProvider).updateStyle(
            user.uid,
            project.id,
            styleName,
            primaryColor: palette.isNotEmpty ? palette[0] : project.primaryColor,
            secondaryColor:
                palette.length > 1 ? palette[1] : project.secondaryColor,
            accentColor: palette.length > 2 ? palette[2] : project.accentColor,
            backgroundColor: project.backgroundColor,
            surfaceColor: project.surfaceColor,
          );
    } catch (e) {
      debugPrint('Style persist failed: $e');
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
