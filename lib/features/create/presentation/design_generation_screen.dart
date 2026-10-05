import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/services/ai_design_service.dart';

final generationProgressProvider = StateProvider<double>((ref) => 0.0);
final generationStageProvider = StateProvider<String>((ref) => 'Preparing...');
final isGeneratingProvider = StateProvider<bool>((ref) => false);
final generationErrorProvider = StateProvider<String?>((ref) => null);

class DesignGenerationScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const DesignGenerationScreen({super.key, required this.onComplete});

  @override
  ConsumerState<DesignGenerationScreen> createState() =>
      _DesignGenerationScreenState();
}

class _DesignGenerationScreenState extends ConsumerState<DesignGenerationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startGeneration();
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _startGeneration() async {
    ref.read(isGeneratingProvider.notifier).state = true;
    ref.read(generationErrorProvider.notifier).state = null;

    try {
      final capturedImages = ref.read(capturedImagesProvider);
      final project = ref.read(currentProjectProvider);
      final authService = ref.read(authServiceProvider);
      final imageService = ref.read(firestoreImageServiceProvider);
      final user = authService.currentUser;

      if (project != null && user != null) {
        ref.read(generationStageProvider.notifier).state = 'Uploading images...';
        ref.read(generationProgressProvider.notifier).state = 0.1;

        try {
          final imageBytesList = capturedImages.map((b64) {
            final data = b64.contains(',') ? b64.split(',').last : b64;
            return base64Decode(data);
          }).toList();

          final savedImages = await imageService.saveCapturedImages(
            userId: user.uid,
            projectId: project.id,
            imageBytesList: imageBytesList,
          );

          ref.read(capturedImageIdsProvider.notifier).state =
              savedImages.map((img) => img.id).toList();
        } catch (_) {
        }
      }

      ref.read(generationStageProvider.notifier).state = 'Analyzing room...';
      ref.read(generationProgressProvider.notifier).state = 0.3;

      final imageUrls = capturedImages;

      ref.read(generationStageProvider.notifier).state = 'Generating designs...';
      ref.read(generationProgressProvider.notifier).state = 0.5;

      final aiService = ref.read(aiDesignServiceProvider);
      final styleName = ref.read(selectedStyleNameProvider);
      final palette = ref.read(selectedPaletteProvider2);
      final preferences = ref.read(aiPreferencesProvider);
      final floorPlan = ref.read(floorPlanDataProvider);

      final results = await aiService.generateDesign(
        imageUrls: imageUrls,
        style: styleName,
        roomType: project?.roomType ?? 'Room',
        palette: palette,
        preferences: preferences,
        floorPlan: floorPlan,
      );

      ref.read(generationStageProvider.notifier).state = 'Saving results...';
      ref.read(generationProgressProvider.notifier).state = 0.8;

      final designUrls = <String>[];
      final designResults = <GeneratedDesignResult>[];

      if (project != null && user != null) {
        try {
          await imageService.saveGeneratedDesign(
            userId: user.uid,
            projectId: project.id,
            imageUrl: results.imageUrl,
            style: results.style,
            prompt: results.prompt,
          );
        } catch (_) {}
      }

      designUrls.add(results.imageUrl);
      designResults.add(results);

      ref.read(generatedDesignUrlsProvider.notifier).state = designUrls;
      ref.read(generatedDesignsProvider.notifier).state = designResults;

      ref.read(generationStageProvider.notifier).state = 'Complete!';
      ref.read(generationProgressProvider.notifier).state = 1.0;

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) widget.onComplete();
    } catch (e) {
      ref.read(generationErrorProvider.notifier).state = e.toString();
      ref.read(generationStageProvider.notifier).state = 'Error occurred';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    } finally {
      ref.read(isGeneratingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = ref.watch(generationProgressProvider);
    final stage = ref.watch(generationStageProvider);
    final styleName = ref.watch(selectedStyleNameProvider);
    final error = ref.watch(generationErrorProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _buildGenerationOrb(progress, colorScheme, theme),
              const SizedBox(height: 32),
              _buildStageText(stage, theme),
              const SizedBox(height: 12),
              if (styleName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    styleName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 28),
              if (error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    error,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => _showCancelDialog(context),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenerationOrb(
    double progress,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildStageText(String stage, ThemeData theme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Text(
        stage,
        key: ValueKey(stage),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Generation?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(capturedImagesProvider.notifier).state = [];
              ref.read(currentProjectProvider.notifier).state = null;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
