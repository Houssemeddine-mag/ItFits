import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';
import 'package:itfits/core/services/auth_service.dart';
import 'package:itfits/core/services/openrouter_service.dart';
import 'package:itfits/core/services/providers.dart';
import 'package:itfits/core/models/project_model.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Reactive: re-fetches whenever the signed-in uid changes.
  // Previously used ref.read(currentUser) once → stuck on old account.
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return null;
  if (!firebaseReady) {
    // Offline fallback: surface Auth metadata so UI never shows another user.
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? 'User',
      'photoURL': user.photoURL,
      'plan': 'free',
    };
  }
  try {
    final db = ref.watch(firebaseFirestoreProvider);
    final docRef = db.collection('users').doc(user.uid);
    var doc = await docRef.get();
    if (!doc.exists) {
      // Console-created users lack a profile doc — create then retry.
      await ref.read(authServiceProvider).getUserProfile();
      doc = await docRef.get();
      if (!doc.exists) {
        return {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName ?? 'User',
          'photoURL': user.photoURL,
          'plan': 'free',
        };
      }
    }
    final data = doc.data();
    // Always overlay live Auth values so email/name can never be stale.
    if (data != null) {
      data['uid'] = user.uid;
      data['email'] = user.email ?? data['email'];
      data['displayName'] = (data['displayName'] as String?)?.isNotEmpty == true
          ? data['displayName']
          : (user.displayName ?? 'User');
      data['photoURL'] = data['photoURL'] ?? user.photoURL;
    }
    return data;
  } catch (_) {
    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? 'User',
      'photoURL': user.photoURL,
      'plan': 'free',
    };
  }
});

final userProjectsCountProvider = StreamProvider<List<ProjectModel>>((ref) {
  final uid = ref.watch(authStateProvider).asData?.value?.uid;
  if (uid == null) return Stream.value(const <ProjectModel>[]);
  final projectService = ref.watch(projectServiceProvider);
  return projectService.watchUserProjects(uid);
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
                  const _SectionTitle(title: 'AI Setup'),
                  const SizedBox(height: 12),
                  const _AiSetupCard(),
                  const SizedBox(height: 24),
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

  void _clearUserScopedState(WidgetRef ref) {
    ref.invalidate(userProfileProvider);
    ref.invalidate(userProjectsCountProvider);
    ref.read(currentProjectProvider.notifier).state = null;
    ref.read(capturedImagesProvider.notifier).state = [];
    ref.read(capturedImageIdsProvider.notifier).state = [];
    ref.read(generatedDesignsProvider.notifier).state = [];
    ref.read(generatedDesignUrlsProvider.notifier).state = [];
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
              try {
                await authService.deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(e is RecentLoginRequiredException
                        ? e.toString()
                        : 'Could not delete your account. Please try again.'),
                  ));
                }
                return;
              }
              _clearUserScopedState(ref);
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
              _clearUserScopedState(ref);
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

/// BYOK OpenRouter setup: API key + chat/image model choice.
///
/// The whole creation flow (room analysis, AI designer chat, design
/// generation) prefers this key. Chat models have a free tier; image
/// models are always paid (need OpenRouter credits). Not every model can
/// generate images — that is why chat and image models are picked
/// separately. The key is stored on-device in secure storage.
class _AiSetupCard extends ConsumerStatefulWidget {
  const _AiSetupCard();

  @override
  ConsumerState<_AiSetupCard> createState() => _AiSetupCardState();
}

class _AiSetupCardState extends ConsumerState<_AiSetupCard> {
  final _keyCtrl = TextEditingController();
  final _chatCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _testing = false;
  String? _status;
  bool _statusOk = false;
  bool _loaded = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    _chatCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _syncFromProviders() {
    if (_loaded) return;
    _loaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(openRouterServiceProvider).loadPersisted();
      if (!mounted) return;
      setState(() {
        _keyCtrl.text = ref.read(openRouterApiKeyProvider);
        _chatCtrl.text = ref.read(openRouterChatModelProvider);
        _imageCtrl.text = ref.read(openRouterImageModelProvider);
      });
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _status = null;
    });
    try {
      final svc = ref.read(openRouterServiceProvider);
      await svc.saveApiKey(_keyCtrl.text);
      await svc.saveModels(chat: _chatCtrl.text, image: _imageCtrl.text);
      if (!mounted) return;
      setState(() {
        _statusOk = true;
        _status = _keyCtrl.text.trim().isEmpty
            ? 'Override removed. AI creation uses the shared .env key.'
            : 'Saved. AI creation will now prefer your key over the shared one.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _status = null;
    });
    try {
      await ref.read(openRouterServiceProvider).testConnection(_keyCtrl.text);
      if (!mounted) return;
      setState(() {
        _statusOk = true;
        _status = 'Key works. Chat + models reachable.';
      });
    } on OpenRouterException catch (e) {
      if (!mounted) return;
      setState(() {
        _statusOk = false;
        _status = e.message;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _remove() async {
    await ref.read(openRouterServiceProvider).clearAll();
    if (!mounted) return;
    setState(() {
      _keyCtrl.clear();
      _chatCtrl.text = OpenRouterService.defaultChatModel;
      _imageCtrl.text = OpenRouterService.defaultImageModel;
      _statusOk = true;
      _status = 'Key removed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncFromProviders();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ready = ref.watch(openRouterReadyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.key_rounded, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OpenRouter AI key (optional override)',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        ready
                            ? 'Connected — creation uses shared key or yours'
                            : 'Paste OPENROUTER_API_KEY into .env',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ready ? Colors.green.shade700 : cs.onSurfaceVariant,
                          fontWeight: ready ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ready ? Colors.green.shade700 : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    ready ? 'Ready' : 'Missing',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ready ? Colors.white : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'ItFits ships with one shared OpenRouter key (.env → OPENROUTER_API_KEY) used by all users for space detection, AI chat, and 360 redesigns. Only fill this in to override the shared key with your own. Chat models have a free tier; image models always need credits (top up past \$1).',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText('openrouter.ai/keys',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.primary, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Copy URL',
                  onPressed: () {
                    Clipboard.setData(
                        const ClipboardData(text: 'https://openrouter.ai/keys'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Copied: openrouter.ai/keys')));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keyCtrl,
              obscureText: _obscure,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'OpenRouter API key (sk-or-...)',
                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _chatCtrl,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Chat model (free tier OK)',
                prefixIcon: const Icon(Icons.chat_outlined, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: OpenRouterService.chatModels.map((m) {
                final selected = _chatCtrl.text.trim() == m.id;
                return ChoiceChip(
                  label: Text(m.label,
                      style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _chatCtrl.text = m.id),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _imageCtrl,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Image model (paid credits)',
                prefixIcon:
                    const Icon(Icons.image_outlined, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: OpenRouterService.imageModels.map((m) {
                final selected = _imageCtrl.text.trim() == m.id;
                return ChoiceChip(
                  label: Text(m.label,
                      style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _imageCtrl.text = m.id),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            if (_status != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _statusOk
                      ? Colors.green.withValues(alpha: 0.12)
                      : cs.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_status!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _statusOk
                          ? Colors.green.shade800
                          : cs.onErrorContainer,
                    )),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _test,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: const Text('Test'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _remove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Stored on-device only (secure storage), never uploaded.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
