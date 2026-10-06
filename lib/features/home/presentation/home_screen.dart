import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/models/project_model.dart';
import 'package:itfits/core/services/openrouter_service.dart';
import 'package:itfits/core/services/project_stage.dart'
    show isProjectComplete, stageLabelFor;
import 'package:itfits/core/widgets/project_thumbnail.dart';
import 'package:itfits/core/router/safe_push.dart';
import 'package:itfits/features/history/presentation/design_detail_screen.dart'
    show projectDesignDocsProvider;
import 'package:itfits/features/create/presentation/style_selection_screen.dart'
    show designStyles, DesignStyle;

final homeProjectsProvider = StreamProvider<List<ProjectModel>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const <ProjectModel>[]);
  final projectService = ref.watch(projectServiceProvider);
  return projectService.watchUserProjects(uid);
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
    // Triggers one-time load of the persisted OpenRouter key/models.
    ref.watch(openRouterBootstrapProvider);
    final aiReady = ref.watch(openRouterReadyProvider);

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
                  const SizedBox(height: 12),
                  if (!aiReady) const _AiKeyBanner(),
                  if (!aiReady) const SizedBox(height: 8),
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

/// Prompt to paste the OpenRouter key before creating with AI.
/// Creation is 100% AI-driven, so without a key the user is routed to
/// Profile → AI Setup instead of starting a half-working flow.
class _AiKeyBanner extends ConsumerWidget {
  const _AiKeyBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final chatModel = ref.watch(openRouterChatModelProvider);

    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.key_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add your AI key to start creating',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Paste your free OpenRouter key in Profile → AI Setup (chat: $chatModel). Image models need credits.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.push('/profile'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              child: const Text('Add key'),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.15);
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
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      await safePush(context, '/design/${widget.project.id}');
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
    String? thumbnailUrl =
        hasDesigns ? project.generatedDesigns!.last.panoramaUrl : null;
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
      thumbnailUrl = project.panoramaUrl;
    }
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
                    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                      ProjectThumbnail(
                          imageUrl: thumbnailUrl, placeholderIconSize: 40)
                    else
                      _HomeSubcollectionThumbnail(projectId: project.id),
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
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: designStyles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final style = designStyles[index];
          return _StyleCard(style: style);
        },
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final DesignStyle style;

  const _StyleCard({required this.style});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 160,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Info only — never starts a design directly.
          onTap: () => _showStyleInfo(context, style),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  style.color.withValues(alpha: 0.15),
                  style.color.withValues(alpha: 0.05),
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
                    color: style.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(style.icon, color: style.color, size: 22),
                ),
                const Spacer(),
                Text(
                  style.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  style.description,
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

void _showStyleInfo(BuildContext context, DesignStyle style) {
  final info = _styleIntel[style.id] ?? _StyleIntel.fallback(style.description);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final cs = theme.colorScheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(style.icon, color: style.color, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(style.name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(style.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('What it is',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(info.about,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 14),
              Text('Key characteristics',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...info.traits.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 16, color: style.color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(t,
                            style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  )),
              const SizedBox(height: 14),
              Text('Materials & palette',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(info.materials,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: style.colorPalettes.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...p.colorList.map((c) => Container(
                              width: 18,
                              height: 18,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: cs.outlineVariant, width: 0.5),
                              ),
                            )),
                        const SizedBox(width: 4),
                        Text(p.name,
                            style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text('How it is presented in ItFits',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(info.presentation,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Text('Best for: ${info.bestFor}',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final ready = ProviderScope.containerOf(context)
                            .read(openRouterReadyProvider);
                        Navigator.of(ctx).pop();
                        if (!ready) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Add your OpenRouter key in Profile → AI Setup first'),
                            ),
                          );
                          context.push('/profile');
                          return;
                        }
                        context.push('/create');
                      },
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Use this style'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _StyleIntel {
  final String about;
  final List<String> traits;
  final String materials;
  final String bestFor;
  final String presentation;

  const _StyleIntel({
    required this.about,
    required this.traits,
    required this.materials,
    required this.bestFor,
    required this.presentation,
  });

  factory _StyleIntel.fallback(String description) => _StyleIntel(
        about: description,
        traits: const ['Curated palette', 'Matched furniture', 'Balanced lighting'],
        materials: 'See palettes below.',
        bestFor: 'Any room',
        presentation:
            'Applied as wall/floor tints in 3D preview and as guidance for the AI redesign.',
      );
}

const _styleIntel = <String, _StyleIntel>{
  'modern': _StyleIntel(
    about:
        'Modern is about clarity: open space, straight lines and a calm neutral base with almost no ornament.',
    traits: [
      'Low-profile furniture with clean geometric lines',
      'Neutral base (white, beige, grey) + one restrained accent',
      'Uncluttered surfaces, hidden storage, simple lighting',
    ],
    materials: 'Polished concrete, glass, matte metal, light oak, boucle or leather accents.',
    bestFor: 'Living rooms, home offices, small apartments that need visual calm.',
    presentation:
        'In ItFits the Modern palettes tint the 3D floor/walls and steer the AI toward minimal furniture and monochrome or warm-neutral schemes.',
  ),
  'scandinavian': _StyleIntel(
    about:
        'Scandinavian blends minimalism with coziness (hygge): bright, functional rooms in pale woods and soft textiles.',
    traits: [
      'White walls, pale wood floors, light textiles',
      'Functional furniture, rounded soft shapes',
      'Layered lighting: daylight + warm lamps and candles',
    ],
    materials: 'Birch and ash wood, wool, linen, sheepskin, muted greens and warm beiges.',
    bestFor: 'Bedrooms, living rooms and dark rooms that need more light.',
    presentation:
        'Scandi palettes keep the 3D preview light and airy; the AI prioritizes light woods, cozy textures and uncluttered layouts.',
  ),
  'industrial': _StyleIntel(
    about:
        'Industrial borrows from old factories: raw structure, dark metals and honest, unfinished surfaces.',
    traits: [
      'Exposed brick, concrete and visible pipes or beams',
      'Black steel frames, leather, reclaimed wood',
      'High contrast, moody lighting with metal shades',
    ],
    materials: 'Raw concrete, black metal, distressed leather, dark walnut, Edison bulbs.',
    bestFor: 'Lofts, kitchens, dining areas with character.',
    presentation:
        'Industrial palettes darken the 3D walls/floor slightly; the AI leans into raw textures, dark frames and urban edge furniture.',
  ),
  'midcentury': _StyleIntel(
    about:
        'Mid-Century (1950s–60s) mixes organic curves with tapered legs and warm, optimistic color.',
    traits: [
      'Iconic shapes: lounge chairs, tapered wooden legs',
      'Warm tones: mustard, olive, teak, walnut',
      'Mix of straight lines and gentle organic curves',
    ],
    materials: 'Teak and walnut, tweed and velvet upholstery, brass details.',
    bestFor: 'Living rooms and dining rooms with a timeless retro feel.',
    presentation:
        'Mid-Century palettes warm up the 3D preview; the AI suggests classic silhouettes in teak, mustard and olive combinations.',
  ),
  'bohemian': _StyleIntel(
    about:
        'Bohemian is relaxed and eclectic: layered patterns, global accents and rich color collected over time.',
    traits: [
      'Layered rugs, cushions and throws in mixed patterns',
      'Plants, rattan, handmade and vintage pieces',
      'Jewel or earth tones, no strict symmetry',
    ],
    materials: 'Rattan, jute, velvet, kilim patterns, brass and lots of greenery.',
    bestFor: 'Bedrooms, creative studios, rentals that want personality.',
    presentation:
        'Boho palettes add saturated accents to the 3D preview; the AI layers patterns, textures and vibrant or earthy combinations.',
  ),
  'coastal': _StyleIntel(
    about:
        'Coastal is breezy and relaxed: light blues, sand tones and natural fibers that feel like the seaside.',
    traits: [
      'White + soft blue palette with sandy neutrals',
      'Linen slipcovers, light woods, woven textures',
      'Lots of natural light, sheer curtains, open feel',
    ],
    materials: 'Washed oak, linen, jute and rattan, sea-glass blues.',
    bestFor: 'Living rooms, bathrooms and bedrooms that should feel fresh.',
    presentation:
        'Coastal palettes cool the 3D preview with blues and sand; the AI keeps furniture light, natural and relaxed-elegant.',
  ),
  'japandi': _StyleIntel(
    about:
        'Japandi fuses Japanese minimalism with Scandinavian warmth: calm, low furniture and natural balance.',
    traits: [
      'Low, simple furniture with clean joinery',
      'Warm neutrals with soft black contrast',
      'Negative space, natural light, quiet textures',
    ],
    materials: 'Light oak and bamboo, paper lamps, stone, oatmeal linen, matte black accents.',
    bestFor: 'Bedrooms, living rooms and calm work-from-home spaces.',
    presentation:
        'Japandi palettes mute the 3D preview to zen neutrals; the AI favors low minimal furniture with warm-wood balance.',
  ),
  'classic': _StyleIntel(
    about:
        'Classic is timeless and symmetrical: refined proportions, elegant details and enduring color.',
    traits: [
      'Symmetrical layouts around a focal point',
      'Panelled walls or mouldings, tailored upholstery',
      'Cream, navy or sage with gold or wood accents',
    ],
    materials: 'Polished wood, marble, brass, velvet and crisp cotton.',
    bestFor: 'Dining rooms, formal living rooms, entryways.',
    presentation:
        'Classic palettes give the 3D preview a refined cream/navy/sage base; the AI composes symmetrical, elegant furniture arrangements.',
  ),
};

/// Old projects (generated before thumbnails were published to the project
/// doc) only have full images in the `designs` subcollection.
class _HomeSubcollectionThumbnail extends ConsumerWidget {
  final String projectId;
  const _HomeSubcollectionThumbnail({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(projectDesignDocsProvider(projectId));
    return docsAsync.when(
      data: (docs) => ProjectThumbnail(
          imageUrl: docs.isEmpty ? null : docs.first.imageUrl,
          placeholderIconSize: 40),
      loading: () => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) =>
          const ProjectThumbnail(imageUrl: null, placeholderIconSize: 40),
    );
  }
}
