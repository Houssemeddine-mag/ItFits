import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:itfits/features/create/presentation/room_scan_screen.dart';
import 'package:itfits/features/create/presentation/panorama_viewer_screen.dart';
import 'package:itfits/features/create/presentation/floor_plan_combined_screen.dart';
import 'package:itfits/features/create/presentation/style_selection_screen.dart';
import 'package:itfits/features/create/presentation/ai_chat_screen.dart';
import 'package:itfits/features/create/presentation/design_generation_screen.dart';
import 'package:itfits/features/create/presentation/design_result_screen.dart';
import 'package:itfits/core/services/providers.dart';

class CreateScreen extends ConsumerStatefulWidget {
  const CreateScreen({super.key});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<_CreateStep> _steps = [
    _CreateStep(
      number: 1,
      title: 'Capture',
      subtitle: 'Scan your space',
      icon: Icons.camera_alt_outlined,
    ),
    _CreateStep(
      number: 2,
      title: '360 View',
      subtitle: 'Review panorama',
      icon: Icons.view_in_ar_outlined,
    ),
    _CreateStep(
      number: 3,
      title: 'Floor Plan',
      subtitle: 'Draw walls, doors & layout',
      icon: Icons.architecture_outlined,
    ),
    _CreateStep(
      number: 4,
      title: 'Style',
      subtitle: 'Choose aesthetic & colors',
      icon: Icons.palette_outlined,
    ),
    _CreateStep(
      number: 5,
      title: 'AI Designer',
      subtitle: 'Chat with your personal designer',
      icon: Icons.auto_awesome_outlined,
    ),
    _CreateStep(
      number: 6,
      title: 'Generate',
      subtitle: 'Create your redesigned room',
      icon: Icons.auto_awesome_outlined,
    ),
    _CreateStep(
      number: 7,
      title: 'Result',
      subtitle: 'Your redesigned room',
      icon: Icons.check_circle_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _resetWizardState();
  }

  void _resetWizardState() {
    ref.read(selectedStyleProvider.notifier).state = null;
    ref.read(selectedPaletteProvider.notifier).state = null;
    ref.read(selectedPreferencesProvider.notifier).state = [];
    ref.read(selectedStyleNameProvider.notifier).state = '';
    ref.read(selectedPaletteProvider2.notifier).state = [];
    ref.read(selectedRoomTypeProvider.notifier).state = 'Living Room';
    ref.read(aiPreferencesProvider.notifier).state = [];
    ref.read(capturedImagesProvider.notifier).state = [];
    ref.read(capturedImageIdsProvider.notifier).state = [];
    ref.read(currentProjectProvider.notifier).state = null;
    ref.read(floorPlanDataProvider.notifier).state = null;
    ref.read(generatedDesignsProvider.notifier).state = [];
    ref.read(generatedDesignUrlsProvider.notifier).state = [];
    // Also reset generation state from design_generation_screen.dart
    ref.read(generationProgressProvider.notifier).state = 0.0;
    ref.read(generationStageProvider.notifier).state = 'Preparing...';
    ref.read(isGeneratingProvider.notifier).state = false;
    ref.read(generationErrorProvider.notifier).state = null;
    // Reset chat messages
    ref.read(chatMessagesProvider.notifier).state = [];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    if (step >= 0 && step < _steps.length) {
      setState(() => _currentStep = step);
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _ensureProjectCreated() async {
    final existing = ref.read(currentProjectProvider);
    if (existing != null) return;

    final authService = ref.read(authServiceProvider);
    final projectService = ref.read(projectServiceProvider);
    final user = authService.currentUser;
    final userId = user?.uid ?? 'anonymous';

    final roomType = ref.read(selectedRoomTypeProvider);
    final styleName = ref.read(selectedStyleNameProvider);

    final project = await projectService.createProject(
      userId: userId,
      name: 'Design ${DateTime.now().millisecondsSinceEpoch}',
      roomType: roomType,
    );

    ref.read(currentProjectProvider.notifier).state = project.copyWith(
      style: styleName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          if (_currentStep > 0)
            _ProgressHeader(
              steps: _steps,
              currentStep: _currentStep,
              onStepTap: _goToStep,
            ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                RoomScanScreen(
                  onComplete: (images) async {
                    ref.read(capturedImagesProvider.notifier).state = images;
                    await _ensureProjectCreated();
                    _goToStep(1);
                  },
                ),
                PanoramaViewerScreen(
                  onComplete: () => _goToStep(2),
                  onBack: () => _goToStep(0),
                ),
                FloorPlanCombinedScreen(
                  onComplete: () => _goToStep(3),
                  onBack: () => _goToStep(1),
                ),
                StyleSelectionScreen(onComplete: () => _goToStep(4), onBack: () => _goToStep(2)),
                AiChatScreen(onComplete: () => _goToStep(5)),
                DesignGenerationScreen(onComplete: () => _goToStep(6)),
                const DesignResultScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final List<_CreateStep> steps;
  final int currentStep;
  final Function(int) onStepTap;

  const _ProgressHeader({
    required this.steps,
    required this.currentStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => context.go('/'),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Create Design',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${currentStep + 1}/${steps.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (currentStep + 1) / steps.length,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateStep {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;

  const _CreateStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
