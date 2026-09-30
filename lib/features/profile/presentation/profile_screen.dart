import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/models/project_model.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.getUserProfile();
});

final userProjectsCountProvider = StreamProvider<List<ProjectModel>>((ref) {
  final projectService = ref.read(projectServiceProvider);
  final authService = ref.read(authServiceProvider);
  final user = authService.currentUser;
  if (user == null) return Stream.value(const <ProjectModel>[]);
  return projectService.watchUserProjects(user.uid);
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileAsync = ref.watch(userProfileProvider);
    final projectsAsync = ref.watch(userProjectsCountProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(profileAsync: profileAsync),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
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
                  _SectionTitle(title: 'My Projects', onTap: () => context.push('/history')),
                  const SizedBox(height: 12),
                  _ProjectStatsRow(projectsAsync: projectsAsync),
                  const SizedBox(height: 24),
                  _SectionTitle(title: 'Preferences', onTap: () => context.push('/settings')),
                  const SizedBox(height: 12),
                  _PreferencesCard(profile: profileAsync.value),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Account'),
                  const SizedBox(height: 12),
                  const _AccountCard(),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'Support'),
                  const SizedBox(height: 12),
                  const _SupportCard(),
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

class _ProfileHeader extends StatelessWidget {
  final AsyncValue<Map<String, dynamic>?> profileAsync;

  const _ProfileHeader({required this.profileAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profile = profileAsync.value;
    final name = profile?['displayName'] ?? 'User';
    final email = profile?['email'] ?? '';
    final photoUrl = profile?['photoURL'];
    final plan = profile?['plan'] ?? 'free';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                        ? (photoUrl.startsWith('data:')
                            ? MemoryImage(base64Decode(photoUrl.split(',').last))
                            : NetworkImage(photoUrl) as ImageProvider)
                        : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            plan == 'pro' ? 'Pro Plan' : 'Free Plan',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SectionTitle({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('View All'),
          ),
      ],
    );
  }
}

class _ProjectStatsRow extends StatelessWidget {
  final AsyncValue<List<ProjectModel>> projectsAsync;

  const _ProjectStatsRow({required this.projectsAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final projects = projectsAsync.value ?? [];
    final projectCount = projects.length;

    int designCount = 0;
    int styleCount = 0;
    for (final p in projects) {
      if (p.generatedDesigns != null) {
        designCount += p.generatedDesigns!.length;
      }
      if (p.style.isNotEmpty) styleCount++;
    }

    final stats = [
      ('Projects', '$projectCount', Icons.folder_rounded),
      ('Designs', '$designCount', Icons.auto_awesome_rounded),
      ('Styles', '$styleCount', Icons.palette_rounded),
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: _StatCard(
            label: stat.$1,
            value: stat.$2,
            icon: stat.$3,
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  final Map<String, dynamic>? profile;

  const _PreferencesCard({this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final prefs = profile?['preferences'] as Map<String, dynamic>? ?? {};
    final notifications = prefs['notifications'] ?? true;

    return Card(
      child: Column(
        children: [
          _PreferenceTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'System default',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings'),
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _PreferenceTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: notifications ? 'Push notifications enabled' : 'Push notifications disabled',
            trailing: Switch(
              value: notifications,
              onChanged: (v) {},
            ),
            onTap: () {},
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _PreferenceTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English (US)',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Column(
        children: [
          _AccountTile(
            icon: Icons.person_rounded,
            title: 'Edit Profile',
            subtitle: 'Update name, photo, preferences',
            onTap: () => context.push('/edit-profile'),
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _AccountTile(
            icon: Icons.lock_rounded,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () {},
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _AccountTile(
            icon: Icons.payment_rounded,
            title: 'Subscription',
            subtitle: 'Free Plan',
            onTap: () {},
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _AccountTile(
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            isDestructive: true,
            onTap: () => _showDeleteConfirmation(context, ref),
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _AccountTile(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            onTap: () => _showLogoutConfirmation(context, ref),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action cannot be undone. All your projects and designs will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final authService = ref.read(authServiceProvider);
              await authService.deleteAccount();
              if (context.mounted) context.go('/onboarding');
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              if (context.mounted) context.go('/onboarding');
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final VoidCallback onTap;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive ? colorScheme.errorContainer : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? colorScheme.error : colorScheme.primary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDestructive ? colorScheme.error : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Column(
        children: [
          _SupportTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            subtitle: 'FAQs, guides, and tutorials',
            onTap: () {},
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _SupportTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Contact Support',
            subtitle: 'Chat with our team',
            onTap: () {},
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _SupportTile(
            icon: Icons.star_outline_rounded,
            title: 'Rate the App',
            subtitle: 'Share your feedback',
            onTap: () {},
          ),
          Divider(height: 1, indent: 56, endIndent: 16, color: colorScheme.outlineVariant),
          _SupportTile(
            icon: Icons.info_outline_rounded,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
      trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
