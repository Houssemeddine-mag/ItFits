import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/models/project_model.dart';
import 'package:itfits/core/services/project_stage.dart'
    show isProjectComplete, stageLabelFor;

/// Normalizes room-type strings so 'Living Room', 'living_room' and
/// filter names like 'livingRoom' compare equal.
String _normalizeRoom(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[_\s]'), '');

final historyProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  final projectService = ref.read(projectServiceProvider);
  final authService = ref.read(authServiceProvider);
  final user = authService.currentUser;
  if (user == null) return Stream.value(const <ProjectModel>[]);
  return projectService.watchUserProjects(user.uid);
});

enum HistoryFilter { all, livingRoom, bedroom, kitchen, bathroom, office }

final historyFilterProvider = StateProvider<HistoryFilter>((ref) => HistoryFilter.all);

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projectsAsync = ref.watch(historyProjectsProvider);
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: _showFilterSheet,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  _SearchBar(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 16),
                  _FilterChips(
                    selectedFilter: filter,
                    onFilterChanged: (f) => ref.read(historyFilterProvider.notifier).state = f,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          projectsAsync.when(
            data: (projects) {
              final filteredProjects = projects.where((p) {
                final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.style.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.roomType.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesFilter = filter == HistoryFilter.all ||
                    _normalizeRoom(p.roomType).contains(_normalizeRoom(filter.name));
                return matchesSearch && matchesFilter;
              }).toList();

              if (filteredProjects.isEmpty) {
                return SliverFillRemaining(
                    child: _EmptyHistoryState(onCreate: () => context.go('/create')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final project = filteredProjects[index];
                      return _HistoryProjectCard(
                        project: filteredProjects[index],
                        onLongPress: () => _showProjectOptions(project),
                      ).animate()
                          .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                          .slideY(begin: 0.2);
                    },
                    childCount: filteredProjects.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Failed to load projects: $e')),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FilterBottomSheet(
        currentFilter: ref.read(historyFilterProvider),
        onFilterChanged: (f) {
          ref.read(historyFilterProvider.notifier).state = f;
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showProjectOptions(ProjectModel project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility_rounded),
            title: const Text('Open Project'),
            onTap: () {
              Navigator.pop(context);
              if (GoRouterState.of(context).uri.toString() ==
                  '/design/${project.id}') {
                return;
              }
              context.push('/design/${project.id}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final authService = ref.read(authServiceProvider);
              final projectService = ref.read(projectServiceProvider);
              final user = authService.currentUser;
              if (user != null) {
                await projectService.deleteProject(user.uid, project.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search projects...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final HistoryFilter selectedFilter;
  final ValueChanged<HistoryFilter> onFilterChanged;

  const _FilterChips({required this.selectedFilter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      HistoryFilter.all,
      HistoryFilter.livingRoom,
      HistoryFilter.bedroom,
      HistoryFilter.kitchen,
      HistoryFilter.bathroom,
      HistoryFilter.office,
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          return FilterChip(
            label: Text(_filterLabel(filter)),
            selected: isSelected,
            onSelected: (_) => onFilterChanged(filter),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  String _filterLabel(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.all:
        return 'All';
      case HistoryFilter.livingRoom:
        return 'Living Room';
      case HistoryFilter.bedroom:
        return 'Bedroom';
      case HistoryFilter.kitchen:
        return 'Kitchen';
      case HistoryFilter.bathroom:
        return 'Bathroom';
      case HistoryFilter.office:
        return 'Office';
    }
  }
}

class _FilterBottomSheet extends StatelessWidget {
  final HistoryFilter currentFilter;
  final ValueChanged<HistoryFilter> onFilterChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      HistoryFilter.all,
      HistoryFilter.livingRoom,
      HistoryFilter.bedroom,
      HistoryFilter.kitchen,
      HistoryFilter.bathroom,
      HistoryFilter.office,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Room Type',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...filters.map((filter) => ListTile(
                title: Text(_filterLabel(filter)),
                leading: Radio<HistoryFilter>(
                  value: filter,
                  groupValue: currentFilter,
                  onChanged: (value) => onFilterChanged(value!),
                ),
                onTap: () => onFilterChanged(filter),
              )),
        ],
      ),
    );
  }

  String _filterLabel(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.all:
        return 'All Projects';
      case HistoryFilter.livingRoom:
        return 'Living Room';
      case HistoryFilter.bedroom:
        return 'Bedroom';
      case HistoryFilter.kitchen:
        return 'Kitchen';
      case HistoryFilter.bathroom:
        return 'Bathroom';
      case HistoryFilter.office:
        return 'Home Office';
    }
  }
}

class _HistoryProjectCard extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onLongPress;

  const _HistoryProjectCard({
    required this.project,
    required this.onLongPress,
  });

  @override
  State<_HistoryProjectCard> createState() => _HistoryProjectCardState();
}

class _HistoryProjectCardState extends State<_HistoryProjectCard> {
  bool _navigating = false;

  Future<void> _openProject() async {
    // Guard against double-taps pushing the same route twice, which
    // crashes the Navigator with duplicate page keys (red screen).
    if (_navigating) return;
    final id = widget.project.id;
    if (GoRouterState.of(context).uri.toString() == '/design/$id') return;
    setState(() => _navigating = true);
    try {
      await context.push('/design/$id');
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasDesigns = project.generatedDesigns != null && project.generatedDesigns!.isNotEmpty;
    final thumbnailUrl = hasDesigns ? project.generatedDesigns!.last.panoramaUrl : null;
    final designCount = hasDesigns ? project.generatedDesigns!.length : 0;
    final roomTypeDisplay = project.roomType.replaceAll('_', ' ');
    final roomLabel = roomTypeDisplay.isNotEmpty
        ? roomTypeDisplay[0].toUpperCase() + roomTypeDisplay.substring(1)
        : 'Room';
    final complete = isProjectComplete(project);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openProject,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbnailUrl != null && thumbnailUrl.isNotEmpty
                      ? _buildProjectImage(thumbnailUrl, colorScheme)
                      : Container(
                          color: colorScheme.primaryContainer,
                          child: Icon(Icons.home_rounded, color: colorScheme.primary, size: 48),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                        onPressed: widget.onLongPress,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: complete
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            complete ? Icons.check_rounded : Icons.autorenew_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            complete ? 'Done' : stageLabelFor(project),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roomLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (project.style.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            project.style,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (project.updatedAt != null) ...[
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(project.updatedAt!),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                      ],
                      if (designCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$designCount design${designCount > 1 ? 's' : ''}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyHistoryState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.history_rounded,
                color: colorScheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Projects Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your saved designs will appear here.\nStart by scanning your first room!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Start First Scan'),
              onPressed: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildProjectImage(String imageUrl, ColorScheme colorScheme) {
  if (imageUrl.startsWith('data:image')) {
    try {
      final bytes = base64Decode(imageUrl.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported_rounded, size: 48),
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
      child: const Icon(Icons.image_not_supported_rounded, size: 48),
    ),
  );
}
