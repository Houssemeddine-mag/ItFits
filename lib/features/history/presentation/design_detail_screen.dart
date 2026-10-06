import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:itfits/core/services/firestore_image_service.dart';
import 'package:itfits/core/services/project_stage.dart';
import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/models/project_model.dart';
import 'package:itfits/core/router/safe_push.dart';
import 'package:itfits/core/widgets/project_thumbnail.dart';

/// Live project document.
final designDetailProvider =
    StreamProvider.family<ProjectModel?, String>((ref, projectId) {
  final authService = ref.read(authServiceProvider);
  final projectService = ref.read(projectServiceProvider);
  final user = authService.currentUser;
  if (user == null) return Stream.value(null);
  return projectService.watchProject(user.uid, projectId);
});

/// Raw 360 captures from the images subcollection.
final projectCapturedImagesProvider =
    FutureProvider.family<List<CapturedImageData>, String>(
        (ref, projectId) async {
  final authService = ref.read(authServiceProvider);
  final imageService = ref.read(firestoreImageServiceProvider);
  final user = authService.currentUser;
  if (user == null) return const <CapturedImageData>[];
  try {
    return await imageService.getCapturedImages(
      userId: user.uid,
      projectId: projectId,
    );
  } catch (_) {
    return const <CapturedImageData>[];
  }
});

/// Generated designs from the designs subcollection (fallback when the
/// inline list on the project is empty).
final projectDesignDocsProvider =
    FutureProvider.family<List<GeneratedDesignData>, String>(
        (ref, projectId) async {
  final authService = ref.read(authServiceProvider);
  final imageService = ref.read(firestoreImageServiceProvider);
  final user = authService.currentUser;
  if (user == null) return const <GeneratedDesignData>[];
  try {
    return await imageService.getGeneratedDesigns(
      userId: user.uid,
      projectId: projectId,
    );
  } catch (_) {
    return const <GeneratedDesignData>[];
  }
});

class DesignDetailScreen extends ConsumerWidget {
  final String designId;

  const DesignDetailScreen({super.key, required this.designId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectAsync = ref.watch(designDetailProvider(designId));

    return Scaffold(
      body: projectAsync.when(
        data: (project) {
          if (project == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Project not found',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back')),
                ],
              ),
            );
          }

          final designs = project.generatedDesigns ?? [];
          String? heroUrl =
              designs.isNotEmpty ? designs.last.panoramaUrl : null;
          if (heroUrl == null || heroUrl.isEmpty) {
            heroUrl = project.panoramaUrl;
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'design_$designId',
                    child: heroUrl != null && heroUrl.isNotEmpty
                        ? ProjectThumbnail(
                            imageUrl: heroUrl, placeholderIconSize: 80)
                        : _HeroSubcollectionFallback(projectId: project.id),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _showOptions(context, ref, project),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DesignHeader(project: project),
                      const SizedBox(height: 20),
                      _StageTracker(project: project),
                      const SizedBox(height: 24),
                      _CaptureSection(projectId: project.id),
                      const SizedBox(height: 24),
                      _FinalDesignsSection(project: project),
                      const SizedBox(height: 24),
                      _FloorPlanSection(project: project),
                      const SizedBox(height: 24),
                      _CustomDetailsSection(project: project),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, ProjectModel project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: const Text('Delete Project',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final authService = ref.read(authServiceProvider);
              final projectService = ref.read(projectServiceProvider);
              final user = authService.currentUser;
              if (user != null) {
                await projectService.deleteProject(user.uid, project.id);
              }
              if (context.mounted) context.pop();
            },
          ),
        ],
      ),
    );
  }
}

class _DesignHeader extends StatelessWidget {
  final ProjectModel project;

  const _DesignHeader({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final roomTypeDisplay = project.roomType.replaceAll('_', ' ');
    final roomLabel = roomTypeDisplay.isNotEmpty
        ? roomTypeDisplay[0].toUpperCase() + roomTypeDisplay.substring(1)
        : 'Room';
    final complete = isProjectComplete(project);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: complete
                    ? Colors.green.shade700
                    : colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    complete
                        ? Icons.check_circle_rounded
                        : Icons.autorenew_rounded,
                    size: 14,
                    color: complete
                        ? Colors.white
                        : colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stageLabelFor(project),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: complete
                          ? Colors.white
                          : colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (project.style.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  project.style,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                roomLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _dateLine(project),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _dateLine(ProjectModel project) {
    final created =
        project.createdAt != null ? _formatDate(project.createdAt!) : null;
    final updated =
        project.updatedAt != null ? _formatDate(project.updatedAt!) : null;
    if (created == null) return '';
    if (updated == null || updated == created) return 'Created $created';
    return 'Created $created · Updated $updated';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Visual creation progress: 7 dots + current stage + Continue button.
class _StageTracker extends StatefulWidget {
  final ProjectModel project;

  const _StageTracker({required this.project});

  @override
  State<_StageTracker> createState() => _StageTrackerState();
}

class _StageTrackerState extends State<_StageTracker> {
  bool _navigating = false;

  Future<void> _continue() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      // safePush dedupes identical pushes app-wide: pushing
      // '/create?resume=id' twice reserves the same page key twice and
      // red-screens the Navigator (!keyReservation.contains(key)).
      await safePush(context, '/create?resume=${widget.project.id}');
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final complete = isProjectComplete(project);
    final currentStep = complete
        ? creationStages.length
        : stepIndexForStatus(project.status).clamp(0, creationStages.length);

    final rowChildren = <Widget>[];
    for (var i = 0; i < creationStages.length; i++) {
      final done = i < currentStep;
      final current = !complete && i == currentStep;
      rowChildren.add(_StageDot(
        icon: creationStages[i].icon,
        done: done,
        current: current,
      ));
      if (i < creationStages.length - 1) {
        rowChildren.add(Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i < currentStep - 1 || (complete && i < currentStep)
                  ? Colors.green.shade600
                  : colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ));
      }
    }

    final statusText = complete
        ? 'Design complete — all 7 steps done'
        : 'Step ${currentStep + 1} of ${creationStages.length}: '
            '${creationStages[currentStep].title} — '
            '${creationStages[currentStep].subtitle}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Creation Progress',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: rowChildren),
          const SizedBox(height: 12),
          Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (!complete) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _navigating ? null : _continue,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                    'Continue — ${creationStages[currentStep].title}'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  final IconData icon;
  final bool done;
  final bool current;

  const _StageDot({
    required this.icon,
    required this.done,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = done
        ? Colors.green.shade600
        : current
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest;
    final foreground = done || current
        ? Colors.white
        : colorScheme.onSurfaceVariant;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: current
            ? Border.all(color: colorScheme.primary, width: 2)
            : Border.all(
                color: done
                    ? Colors.green.shade600
                    : colorScheme.outlineVariant,
              ),
        boxShadow: current
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                )
              ]
            : null,
      ),
      child: Icon(done ? Icons.check_rounded : icon,
          size: 16, color: foreground),
    );
  }
}

/// Raw 360 captures uploaded during the scan step.
class _CaptureSection extends ConsumerWidget {
  final String projectId;

  const _CaptureSection({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imagesAsync = ref.watch(projectCapturedImagesProvider(projectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('360 Capture',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 12),
        imagesAsync.when(
          data: (images) {
            if (images.isEmpty) {
              return _EmptyNote(
                icon: Icons.view_in_ar_outlined,
                text: 'No captures saved yet — continue the design to scan.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${images.length} capture${images.length > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 150,
                          child: ProjectThumbnail(
                            imageUrl:
                                'data:image/jpeg;base64,${images[index].base64Data}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _EmptyNote(
            icon: Icons.image_not_supported_rounded,
            text: 'Could not load captures.',
          ),
        ),
      ],
    );
  }

}

/// All finished AI designs (inline list, falling back to subcollection docs).
class _FinalDesignsSection extends ConsumerWidget {
  final ProjectModel project;

  const _FinalDesignsSection({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inline = project.generatedDesigns ?? [];

    if (inline.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Design${inline.length > 1 ? 's' : ''} · ${inline.length}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...inline.asMap().entries.map((entry) {
            final i = entry.key;
            final design = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < inline.length - 1 ? 12 : 0),
              child: _DesignCard(
                imageUrl: design.panoramaUrl,
                title: design.style.isNotEmpty
                    ? design.style
                    : 'Design ${i + 1}',
                subtitle: design.createdAt != null
                    ? _formatDate(design.createdAt!)
                    : null,
              ),
            );
          }),
        ],
      );
    }

    final docsAsync = ref.watch(projectDesignDocsProvider(project.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Final Designs',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 12),
        docsAsync.when(
          data: (docs) {
            if (docs.isEmpty) {
              return const _EmptyNote(
                icon: Icons.auto_awesome_outlined,
                text: 'No designs generated yet — finish the flow to create one.',
              );
            }
            return Column(
              children: docs.asMap().entries.map((entry) {
                final i = entry.key;
                final doc = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i < docs.length - 1 ? 12 : 0),
                  child: _DesignCard(
                    imageUrl: doc.imageUrl,
                    title: doc.style.isNotEmpty
                        ? doc.style
                        : 'Design ${i + 1}',
                    subtitle: _formatDate(doc.createdAt),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _EmptyNote(
            icon: Icons.image_not_supported_rounded,
            text: 'Could not load designs.',
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _DesignCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String? subtitle;

  const _DesignCard({
    required this.imageUrl,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ProjectThumbnail(imageUrl: imageUrl.isNotEmpty ? imageUrl : null),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                ),
                if (subtitle != null)
                  Text(subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Persisted floor-plan summary (dimensions, counts, edited flag).
class _FloorPlanSection extends StatelessWidget {
  final ProjectModel project;

  const _FloorPlanSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final plan = project.floorPlan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Floor Plan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 12),
        if (plan == null)
          const _EmptyNote(
            icon: Icons.architecture_outlined,
            text: 'No floor plan drawn yet.',
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _PlanFact(
                        icon: Icons.straighten_rounded,
                        label: 'Size',
                        value:
                            '${plan.dimensions.width.toStringAsFixed(1)} × ${plan.dimensions.height.toStringAsFixed(1)} m',
                      ),
                    ),
                    Expanded(
                      child: _PlanFact(
                        icon: Icons.square_foot_rounded,
                        label: 'Area',
                        value:
                            '${plan.dimensions.area.toStringAsFixed(1)} m²',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PlanFact(
                        icon: Icons.border_style_rounded,
                        label: 'Walls',
                        value: '${plan.walls.length}',
                      ),
                    ),
                    Expanded(
                      child: _PlanFact(
                        icon: Icons.door_sliding_outlined,
                        label: 'Doors',
                        value: '${plan.doors.length}',
                      ),
                    ),
                    Expanded(
                      child: _PlanFact(
                        icon: Icons.curtains_outlined,
                        label: 'Windows',
                        value: '${plan.windows.length}',
                      ),
                    ),
                  ],
                ),
                if (plan.isUserEdited) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Customized by you',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _PlanFact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PlanFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
              Text(value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

/// Style, palette, prompt and other customized details.
class _CustomDetailsSection extends StatelessWidget {
  final ProjectModel project;

  const _CustomDetailsSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final designs = project.generatedDesigns ?? [];
    final prompt = designs.isNotEmpty ? designs.last.prompt : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Custom Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 12),
        _PaletteSection(project: project),
        if (prompt != null && prompt.isNotEmpty) ...[
          const SizedBox(height: 16),
          _PromptSection(prompt: prompt),
        ],
      ],
    );
  }
}

class _PaletteSection extends StatelessWidget {
  final ProjectModel project;

  const _PaletteSection({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      ('Primary', Color(project.primaryColor)),
      ('Secondary', Color(project.secondaryColor)),
      ('Accent', Color(project.accentColor)),
      ('Background', Color(project.backgroundColor)),
      ('Surface', Color(project.surfaceColor)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color Palette',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((entry) {
            final (label, color) = entry;
            return _PaletteChip(label: label, color: color);
          }).toList(),
        ),
      ],
    );
  }
}

class _PaletteChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PaletteChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              Text(
                '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptSection extends StatelessWidget {
  final String prompt;

  const _PromptSection({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Prompt',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '"$prompt"',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                )),
          ),
        ],
      ),
    );
  }
}

/// Old projects have no inline thumbnail — hero falls back to the latest
/// full image from the `designs` subcollection.
class _HeroSubcollectionFallback extends ConsumerWidget {
  final String projectId;
  const _HeroSubcollectionFallback({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(projectDesignDocsProvider(projectId));
    return docsAsync.when(
      data: (docs) => ProjectThumbnail(
          imageUrl: docs.isEmpty ? null : docs.first.imageUrl,
          placeholderIconSize: 80),
      loading: () => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) =>
          const ProjectThumbnail(imageUrl: null, placeholderIconSize: 80),
    );
  }
}
