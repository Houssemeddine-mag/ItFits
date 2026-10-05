import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/models/project_model.dart';
import 'package:itfits/core/services/project_stage.dart'
    show isProjectComplete, stageLabelFor;

final homeProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  final projectService = ref.read(projectServiceProvider);
  final authService = ref.read(authServiceProvider);
  final user = authService.currentUser;
  if (user == null) return Stream.value(const <ProjectModel>[]);
  return projectService.watchUserProjects(user.uid);
});

class HomeScreen extends ConsumerWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

class _BottomNavBar extends ConsumerWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    if (location.startsWith('/create')) currentIndex = 1;
    else if (location.startsWith('/history')) currentIndex = 2;
    else if (location.startsWith('/profile')) currentIndex = 3;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/create');
            break;
          case 2:
            context.go('/history');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle),
          label: 'Create',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ).animate().slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}

class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final projectsAsync = ref.watch(homeProjectsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Image.asset(
              'assets/images/logo.png',
              height: 36,
              errorBuilder: (_, __, ___) => const Text('ItFits'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Design your dream space',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Capture your room, pick a style, and watch AI transform it',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.2),
                  const SizedBox(height: 24),
                  const _CreateProjectCard(),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Recent Projects',
                    actionLabel: 'View all',
                    onAction: () => context.push('/history'),
                  ),
                  const SizedBox(height: 12),
                  _RecentProjectsList(projectsAsync: projectsAsync),
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Design Styles',
                    actionLabel: 'Explore all',
                    onAction: () => context.push('/create'),
                  ),
                  const SizedBox(height: 12),
                  const _StyleCarousel(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateProjectCard extends StatelessWidget {
  const _CreateProjectCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: InkWell(
          onTap: () => context.push('/create'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: colorScheme.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start New Design',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan your room and let AI redesign it',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _RecentProjectsList extends StatelessWidget {
  final AsyncValue<List<ProjectModel>> projectsAsync;

  const _RecentProjectsList({required this.projectsAsync});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return projectsAsync.when(
      data: (projects) {
        if (projects.isEmpty) {
          return SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open_rounded, size: 48, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'No projects yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start by scanning your first room!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final displayProjects = projects.take(5).toList();
        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayProjects.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == displayProjects.length) {
                return const _NewProjectCard();
              }
              return _ProjectCard(project: displayProjects[index]);
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => SizedBox(
        height: 180,
        child: Center(
          child: Text('Failed to load projects', style: TextStyle(color: colorScheme.error)),
        ),
      ),
    );
  }
}

class _ProjectCard extends StatefulWidget {
  final ProjectModel project;

  const _ProjectCard({required this.project});

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
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
    final complete = isProjectComplete(project);

    return SizedBox(
      width: 200,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openProject,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    thumbnailUrl != null && thumbnailUrl.isNotEmpty
                        ? _displayImage(thumbnailUrl, colorScheme)
                        : Container(
                            color: colorScheme.primaryContainer,
                            child: Icon(Icons.home_rounded, color: colorScheme.primary, size: 40),
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
                    Text(
                      '${project.roomType.replaceAll('_', ' ')} ${project.style.isNotEmpty ? "· ${project.style}" : ""}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}

class _NewProjectCard extends StatelessWidget {
  const _NewProjectCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 200,
      child: Card(
        child: InkWell(
        onTap: () => context.push('/create'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New Project',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start designing your space',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StyleCarousel extends StatelessWidget {
  const _StyleCarousel();

  @override
  Widget build(BuildContext context) {
    final styles = [
      ('Modern Minimalist', 'Clean lines, neutral palette', Icons.architecture_rounded, Color(0xFF8B6B5A)),
      ('Scandinavian', 'Light woods, cozy textures', Icons.forest_rounded, Color(0xFF6B8E8E)),
      ('Industrial', 'Raw materials, exposed elements', Icons.factory_rounded, Color(0xFF5E5042)),
      ('Mid-Century', 'Organic shapes, warm tones', Icons.chair_rounded, Color(0xFFD4A574)),
      ('Bohemian', 'Eclectic patterns, vibrant colors', Icons.palette_rounded, Color(0xFFB88A5A)),
      ('Coastal', 'Breezy blues, natural fibers', Icons.waves_rounded, Color(0xFF4A7C8A)),
    ];

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final (name, desc, icon, color) = styles[index];
          return _StyleCard(
            name: name,
            description: desc,
            icon: icon,
            color: color,
          );
        },
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const _StyleCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/create'),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _displayImage(String imageUrl, ColorScheme colorScheme) {
  if (imageUrl.startsWith('data:image')) {
    try {
      final bytes = base64Decode(imageUrl.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (_) {
      return Container(
        color: colorScheme.primaryContainer,
        child: Icon(Icons.broken_image_rounded, color: colorScheme.primary, size: 40),
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
      color: colorScheme.primaryContainer,
      child: Icon(Icons.broken_image_rounded, color: colorScheme.primary, size: 40),
    ),
  );
}
