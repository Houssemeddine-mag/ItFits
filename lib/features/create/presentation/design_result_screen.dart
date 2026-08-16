import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/models/project_model.dart';

class DesignResultScreen extends ConsumerStatefulWidget {
  const DesignResultScreen({super.key});

  @override
  ConsumerState<DesignResultScreen> createState() =>
      _DesignResultScreenState();
}

class _DesignResultScreenState extends ConsumerState<DesignResultScreen> {
  bool _isSaving = false;
  int _selectedDesignIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final styleName = ref.watch(selectedStyleNameProvider);
    final palette = ref.watch(selectedPaletteProvider2);
    final generatedDesignUrls = ref.watch(generatedDesignUrlsProvider);

    final primaryColor =
        palette.isNotEmpty ? Color(palette[0]) : const Color(0xFF8B6B5A);
    final secondaryColor =
        palette.length > 1 ? Color(palette[1]) : const Color(0xFF6B8E8E);
    final accentColor =
        palette.length > 2 ? Color(palette[2]) : const Color(0xFFD4A574);

    final allDesigns = generatedDesignUrls;
    final currentDesign =
        allDesigns.isNotEmpty ? allDesigns[_selectedDesignIndex.clamp(0, allDesigns.length - 1)] : '';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(theme, colorScheme),
            Expanded(
              child: allDesigns.isNotEmpty
                  ? _buildDesignView(
                      currentDesign,
                      allDesigns,
                      colorScheme,
                      theme,
                      primaryColor,
                      secondaryColor,
                      accentColor,
                    )
                  : _buildEmptyState(colorScheme, theme),
            ),
            _buildBottomBar(
              theme,
              colorScheme,
              styleName,
              primaryColor,
              secondaryColor,
              accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              ref.read(capturedImagesProvider.notifier).state = [];
              ref.read(currentProjectProvider.notifier).state = null;
              context.go('/');
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your Designs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${ref.read(generatedDesignUrlsProvider).length} variations',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignView(
    String currentDesign,
    List<String> allDesigns,
    ColorScheme colorScheme,
    ThemeData theme,
    Color primaryColor,
    Color secondaryColor,
    Color accentColor,
  ) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _displayImage(currentDesign, colorScheme),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'AI Generated',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedDesignIndex + 1} of ${allDesigns.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (allDesigns.length > 1)
          Container(
            height: 80,
            margin: const EdgeInsets.only(top: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allDesigns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedDesignIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDesignIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: _displayImageSmall(allDesigns[index], colorScheme),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        _PalettePreview(
          primary: primaryColor,
          secondary: secondaryColor,
          accent: accentColor,
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Design Generated!',
            style: theme.textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    ThemeData theme,
    ColorScheme colorScheme,
    String styleName,
    Color primary,
    Color secondary,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  styleName.isNotEmpty ? styleName : 'Custom Design',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              _PaletteChips(primary: primary, secondary: secondary, accent: accent),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Regenerate'),
                  onPressed: () => context.go('/create'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(_isSaving ? 'Saving...' : 'Save Design'),
                  onPressed: _isSaving ? null : _saveDesign,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.home_rounded, size: 18),
              label: const Text('Go Home'),
              onPressed: () {
                ref.read(capturedImagesProvider.notifier).state = [];
                ref.read(currentProjectProvider.notifier).state = null;
                context.go('/');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _displayImage(String imageUrl, ColorScheme colorScheme) {
    if (imageUrl.isEmpty) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.auto_awesome_rounded,
            color: colorScheme.primary,
            size: 48,
          ),
        ),
      );
    }
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.broken_image_rounded, size: 48),
        );
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_rounded, size: 48),
      ),
    );
  }

  Widget _displayImageSmall(String imageUrl, ColorScheme colorScheme) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.image, color: colorScheme.onSurfaceVariant, size: 20),
        );
      }
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.image, color: colorScheme.onSurfaceVariant, size: 20),
      ),
    );
  }

  Future<void> _saveDesign() async {
    setState(() => _isSaving = true);
    try {
      final project = ref.read(currentProjectProvider);
      final styleName = ref.read(selectedStyleNameProvider);
      final palette = ref.read(selectedPaletteProvider2);
      final authService = ref.read(authServiceProvider);
      final projectService = ref.read(projectServiceProvider);
      final user = authService.currentUser;

      if (project == null || user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No project to save')),
          );
        }
        return;
      }

      final designUrls = ref.read(generatedDesignUrlsProvider);
      final panoramaUrl = designUrls.isNotEmpty ? designUrls.first : '';

      final design = GeneratedDesignModel(
        id: const Uuid().v4(),
        panoramaUrl: panoramaUrl,
        style: styleName,
        primaryColor: palette.isNotEmpty ? palette[0] : 0xFF8B6B5A,
        secondaryColor: palette.length > 1 ? palette[1] : 0xFF6B8E8E,
        accentColor: palette.length > 2 ? palette[2] : 0xFFD4A574,
        backgroundColor: palette.length > 3 ? palette[3] : 0xFFFAF8F5,
        surfaceColor: palette.length > 4 ? palette[4] : 0xFFFFFFFF,
        prompt: '$styleName interior design',
        createdAt: DateTime.now(),
      );

      await projectService.addGeneratedDesign(
        user.uid,
        project.id,
        design,
      );

      ref.read(capturedImagesProvider.notifier).state = [];
      ref.read(currentProjectProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Design saved!'),
            action: SnackBarAction(
              label: 'View',
              onPressed: () => context.go('/history'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _PaletteChips extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color accent;

  const _PaletteChips({
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [primary, secondary, accent];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: colors.map((color) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color accent;

  const _PalettePreview({
    required this.primary,
    required this.secondary,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      ('Primary', primary),
      ('Secondary', secondary),
      ('Accent', accent),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: colors.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: entry.$2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.$1,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
