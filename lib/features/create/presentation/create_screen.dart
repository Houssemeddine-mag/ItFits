import 'dart:convert';

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
import 'package:itfits/core/models/project_model.dart';
import 'package:itfits/core/services/ai_design_service.dart'
    show GeneratedDesignResult;
import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/services/project_stage.dart'
    show floorPlanDataFromModel, floorPlanModelFromData, stepIndexForStatus;

class CreateScreen extends ConsumerStatefulWidget {
  /// When set, resumes this existing project instead of starting a new one.
  final String? resumeProjectId;

  const CreateScreen({super.key, this.resumeProjectId});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isResuming = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final resumeId = widget.resumeProjectId;
      if (resumeId != null && resumeId.isNotEmpty) {
        _resumeProject(resumeId);
      } else {
        _resetWizardState();
      }
    });
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
    ref.read(generationProgressProvider.notifier).state = 0.0;
    ref.read(generationStageProvider.notifier).state = 'Preparing...';
    ref.read(isGeneratingProvider.notifier).state = false;
    ref.read(generationErrorProvider.notifier).state = null;
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
    try {
      final existing = ref.read(currentProjectProvider);
      if (existing != null) return;

      final authService = ref.read(authServiceProvider);
      final projectService = ref.read(projectServiceProvider);
      final user = authService.currentUser;
      // Never fall back to 'anonymous' — that leaked projects across accounts.
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in to create a project')),
          );
        }
        return;
      }
      final userId = user.uid;

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
    } catch (e) {
      debugPrint('Project creation failed, using local fallback: $e');
      if (ref.read(currentProjectProvider) == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working offline — project will be saved locally'),
          ),
        );
      }
    }
  }

  Future<void> _persistStage(ProjectStatus status) async {
    try {
      final project = ref.read(currentProjectProvider);
      final user = ref.read(authServiceProvider).currentUser;
      if (project == null || user == null) return;
      if (project.status == status) return;
      await ref
          .read(projectServiceProvider)
          .updateProjectStatus(user.uid, project.id, status);
      ref.read(currentProjectProvider.notifier).state =
          project.copyWith(status: status);
    } catch (e) {
      debugPrint('Stage persist failed: $e');
    }
  }

  /// Saves the edited floor plan to the project (marks it as reviewed).
  Future<void> _persistFloorPlan() async {
    try {
      final plan = ref.read(floorPlanDataProvider);
      final project = ref.read(currentProjectProvider);
      final user = ref.read(authServiceProvider).currentUser;
      if (plan == null || project == null || user == null) return;
      await ref
          .read(projectServiceProvider)
          .updateFloorPlan(user.uid, project.id, floorPlanModelFromData(plan));
      ref.read(currentProjectProvider.notifier).state =
          project.copyWith(status: ProjectStatus.reviewingPlan);
    } catch (e) {
      debugPrint('Floor plan persist failed: $e');
    }
  }

  /// Uploads scan images early so the 360 capture exists even for
  /// unfinished projects. Generation reuses these ids (no duplicates).
  Future<void> _saveScanImages() async {
    try {
      final project = ref.read(currentProjectProvider);
      final user = ref.read(authServiceProvider).currentUser;
      if (project == null || user == null) return;
      if (ref.read(capturedImageIdsProvider).isNotEmpty) return;
      final images = ref.read(capturedImagesProvider);
      if (images.isEmpty) return;
      final bytesList = images.map((b64) {
        final data = b64.contains(',') ? b64.split(',').last : b64;
        return base64Decode(data);
      }).toList();
      final saved = await ref
          .read(firestoreImageServiceProvider)
          .saveCapturedImages(
            userId: user.uid,
            projectId: project.id,
            imageBytesList: bytesList,
          );
      ref.read(capturedImageIdsProvider.notifier).state =
          saved.map((img) => img.id).toList();
    } catch (e) {
      debugPrint('Scan image save failed: $e');
    }
  }

  /// Restores wizard state for an unfinished project and jumps to its stage.
  ///
  /// Previously this left stale cross-project state behind (style id,
  /// palette index, chat, old designs) and never restored generated designs,
  /// so resuming could land on a step whose screen read inconsistent
  /// providers and red-screened. Now: reset first, restore everything the
  /// step screens read, and clamp the landing step so Continue never crashes.
  Future<void> _resumeProject(String projectId) async {
    setState(() => _isResuming = true);
    try {
      final authService = ref.read(authServiceProvider);
      final projectService = ref.read(projectServiceProvider);
      final imageService = ref.read(firestoreImageServiceProvider);
      final user = authService.currentUser;
      if (user == null) {
        _resetWizardState();
        return;
      }
      // Start clean — stale ids/urls from another project must not leak in.
      _resetWizardState();
      final projects = await projectService.getUserProjects(user.uid);
      ProjectModel? found;
      for (final p in projects) {
        if (p.id == projectId) found = p;
      }
      final project = found;
      if (project == null || !mounted) {
        if (mounted) _resetWizardState();
        return;
      }
      ref.read(currentProjectProvider.notifier).state = project;
      ref.read(selectedRoomTypeProvider.notifier).state =
          project.roomType.isNotEmpty ? project.roomType : 'Living Room';
      if (project.style.isNotEmpty) {
        ref.read(selectedStyleNameProvider.notifier).state = project.style;
        ref.read(selectedPaletteProvider2.notifier).state = [
          project.primaryColor,
          project.secondaryColor,
          project.accentColor,
        ];
        // Style screen works with ids/indices, not names — map them back so
        // the palette list and save path don't hit firstWhere on null.
        try {
          final match = designStyles.where(
            (s) => s.name.toLowerCase() == project.style.toLowerCase(),
          );
          if (match.isNotEmpty) {
            final style = match.first;
            ref.read(selectedStyleProvider.notifier).state = style.id;
            final palIdx = style.colorPalettes.indexWhere(
              (p) => p.colors.isNotEmpty && p.colors.first == project.primaryColor,
            );
            ref.read(selectedPaletteProvider.notifier).state =
                palIdx >= 0 ? palIdx : 0;
          }
        } catch (e) {
          debugPrint('Style restore failed: $e');
        }
      }
      if (project.floorPlan != null) {
        try {
          final restored = floorPlanDataFromModel(project.floorPlan!);
          // Guard against docs with openings but no walls (index crash in
          // painters): drop orphaned elements.
          if (restored.walls.isEmpty &&
              (restored.doors.isNotEmpty ||
                  restored.windows.isNotEmpty ||
                  restored.outlets.isNotEmpty)) {
            restored.doors.clear();
            restored.windows.clear();
            restored.outlets.clear();
          }
          ref.read(floorPlanDataProvider.notifier).state = restored;
        } catch (e) {
          debugPrint('Floor plan restore failed: $e');
        }
      }
      try {
        final saved = await imageService.getCapturedImages(
          userId: user.uid,
          projectId: project.id,
        );
        if (saved.isNotEmpty && mounted) {
          ref.read(capturedImagesProvider.notifier).state = saved
              .map((img) => 'data:image/jpeg;base64,${img.base64Data}')
              .toList();
          ref.read(capturedImageIdsProvider.notifier).state =
              saved.map((img) => img.id).toList();
        }
      } catch (e) {
        debugPrint('Captured image restore failed: $e');
      }
      // Result step reads in-memory urls — refill from the doc so a
      // finished project doesn't land on an empty result screen.
      try {
        final inlineUrls = (project.generatedDesigns ?? [])
            .map((d) => d.panoramaUrl)
            .where((u) => u.isNotEmpty)
            .toList();
        if (inlineUrls.isNotEmpty) {
          ref.read(generatedDesignUrlsProvider.notifier).state = inlineUrls;
          ref.read(generatedDesignsProvider.notifier).state = inlineUrls
              .map((u) => GeneratedDesignResult(
                    imageUrl: u,
                    style: project.style,
                    prompt: '',
                    createdAt: DateTime.now(),
                  ))
              .toList();
        } else if (project.panoramaUrl != null &&
            project.panoramaUrl!.isNotEmpty) {
          ref.read(generatedDesignUrlsProvider.notifier).state = [
            project.panoramaUrl!
          ];
        } else {
          final docs = await imageService.getGeneratedDesigns(
            userId: user.uid,
            projectId: project.id,
          );
          if (docs.isNotEmpty && mounted) {
            ref.read(generatedDesignUrlsProvider.notifier).state =
                docs.map((d) => d.imageUrl).toList();
          }
        }
      } catch (e) {
        debugPrint('Design restore failed: $e');
      }
      var step = stepIndexForStatus(project.status).clamp(0, _steps.length - 1);
      // Panorama step with no images red-screened the review screen's decode
      // path on some devices — send them to capture instead.
      if (step == 1 && ref.read(capturedImagesProvider).isEmpty) {
        step = 0;
      }
      if (mounted) {
        setState(() {
          _currentStep = step;
          _isResuming = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            try {
              _pageController.jumpToPage(step);
            } catch (e) {
              debugPrint('Resume jump failed: $e');
            }
          }
        });
        return;
      }
    } catch (e) {
      debugPrint('Resume failed, starting fresh capture: $e');
      if (mounted) {
        _resetWizardState();
        setState(() {
          _currentStep = 0;
          _isResuming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not resume — starting a fresh capture'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResuming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isResuming) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Resuming your project...'),
            ],
          ),
        ),
      );
    }

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
                    await _saveScanImages();
                    await _persistStage(ProjectStatus.scanning);
                    _goToStep(1);
                  },
                ),
                PanoramaViewerScreen(
                  onComplete: () async {
                    await _persistStage(ProjectStatus.processing);
                    _goToStep(2);
                  },
                  onBack: () => _goToStep(0),
                ),
                FloorPlanCombinedScreen(
                  onComplete: () async {
                    await _persistFloorPlan();
                    _goToStep(3);
                  },
                  onBack: () => _goToStep(1),
                ),
                StyleSelectionScreen(
                    onComplete: () async {
                      await _persistStage(ProjectStatus.styling);
                      _goToStep(4);
                    },
                    onBack: () => _goToStep(2)),
                AiChatScreen(onComplete: () async {
                  await _persistStage(ProjectStatus.generating);
                  _goToStep(5);
                }),
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
