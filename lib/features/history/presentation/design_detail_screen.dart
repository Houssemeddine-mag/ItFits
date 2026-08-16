import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/models/project_model.dart';

final designDetailProvider = FutureProvider.family<ProjectModel?, String>((ref, projectId) async {
  final authService = ref.read(authServiceProvider);
  final projectService = ref.read(projectServiceProvider);
  final user = authService.currentUser;
  if (user == null) return null;

  final projects = await projectService.getUserProjects(user.uid);
  for (final p in projects) {
    if (p.id == projectId) return p;
  }
  return null;
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
                  Icon(Icons.error_outline_rounded, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Project not found', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: () => context.pop(), child: const Text('Go Back')),
                ],
              ),
            );
          }

          final designs = project.generatedDesigns ?? [];
          final design = designs.isNotEmpty ? designs.last : null;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'design_$designId',
                    child: design != null && design.panoramaUrl.isNotEmpty
                        ? _buildDesignImage(design.panoramaUrl, colorScheme)
                        : Container(
                            color: colorScheme.primaryContainer,
                            child: Icon(Icons.home_rounded, color: colorScheme.primary, size: 80),
                          ),
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
                      const SizedBox(height: 24),
                      if (design != null) ...[
                        _PaletteSection(design: design),
                        const SizedBox(height: 24),
                        if (design.prompt != null) ...[
                          _PromptSection(prompt: design.prompt!),
                          const SizedBox(height: 24),
                        ],
                      ],
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
            title: const Text('Delete Project', style: TextStyle(color: Colors.red)),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (project.style.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roomTypeDisplay[0].toUpperCase() + roomTypeDisplay.substring(1),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              if (project.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Created ${_formatDate(project.createdAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
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

class _PaletteSection extends StatelessWidget {
  final GeneratedDesignModel design;

  const _PaletteSection({required this.design});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      ('Primary', Color(design.primaryColor)),
      ('Secondary', Color(design.secondaryColor)),
      ('Accent', Color(design.accentColor)),
      ('Background', Color(design.backgroundColor)),
      ('Surface', Color(design.surfaceColor)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Color Palette', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
        Text('AI Prompt', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
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

Widget _buildDesignImage(String imageUrl, ColorScheme colorScheme) {
  if (imageUrl.startsWith('data:image')) {
    try {
      final bytes = base64Decode(imageUrl.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.image_not_supported_rounded, size: 48)),
      );
    }
  }
  return Image.network(
    imageUrl,
    fit: BoxFit.cover,
    loadingBuilder: (context, child, progress) {
      if (progress == null) return child;
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator()),
      );
    },
    errorBuilder: (_, __, ___) => Container(
      color: colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_not_supported_rounded, size: 48)),
    ),
  );
}
