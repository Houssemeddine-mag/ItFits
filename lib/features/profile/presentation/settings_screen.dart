import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:itfits/core/services/providers.dart';
import 'package:itfits/features/profile/presentation/profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoSave = true;
  String _language = 'English (US)';
  String _units = 'Metric';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  void _loadSettings() {
    final profile = ref.read(userProfileProvider).value;
    if (profile != null && !_loaded) {
      final prefs = profile['preferences'] as Map<String, dynamic>? ?? {};
      setState(() {
        _darkMode = prefs['darkMode'] ?? false;
        _notifications = prefs['notifications'] ?? true;
        _autoSave = prefs['autoSave'] ?? true;
        _language = prefs['language'] ?? 'English (US)';
        _units = prefs['units'] ?? 'Metric';
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_loaded) {
      ref.watch(userProfileProvider).whenData((data) {
        if (data != null && !_loaded && mounted) {
          final prefs = data['preferences'] as Map<String, dynamic>? ?? {};
          _darkMode = prefs['darkMode'] ?? false;
          _notifications = prefs['notifications'] ?? true;
          _autoSave = prefs['autoSave'] ?? true;
          _language = prefs['language'] ?? 'English (US)';
          _units = prefs['units'] ?? 'Metric';
          _loaded = true;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Appearance',
            children: [
              _buildSwitchTile(
                icon: Icons.dark_mode_rounded,
                title: 'Dark Mode',
                subtitle: 'Use system theme',
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  _persistSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Preferences',
            children: [
              _buildListTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: _language,
                onTap: _showLanguagePicker,
              ),
              _buildListTile(
                icon: Icons.straighten_rounded,
                title: 'Measurement Units',
                subtitle: _units,
                onTap: _showUnitsPicker,
              ),
              _buildSwitchTile(
                icon: Icons.save_rounded,
                title: 'Auto-save Designs',
                subtitle: 'Automatically save generated designs',
                value: _autoSave,
                onChanged: (v) {
                  setState(() => _autoSave = v);
                  _persistSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Notifications',
            children: [
              _buildSwitchTile(
                icon: Icons.notifications_rounded,
                title: 'Push Notifications',
                subtitle: 'Receive updates about your designs',
                value: _notifications,
                onChanged: (v) {
                  setState(() => _notifications = v);
                  _persistSettings();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            title: 'About',
            children: [
              _buildListTile(
                icon: Icons.info_outline_rounded,
                title: 'Version',
                subtitle: '1.0.0 (Build 1)',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _persistSettings() async {
    final authService = ref.read(authServiceProvider);
    await authService.updateProfile(
      displayName: null,
      preferences: {
        'darkMode': _darkMode,
        'notifications': _notifications,
        'autoSave': _autoSave,
        'language': _language,
        'units': _units,
      },
    );
    ref.invalidate(userProfileProvider);
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SwitchListTile(
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...['English (US)', 'English (UK)', 'Spanish', 'French', 'German', 'Japanese'].map((lang) {
              return ListTile(
                title: Text(lang),
                trailing: _language == lang ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  setState(() => _language = lang);
                  _persistSettings();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showUnitsPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Measurement Units', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...['Metric', 'Imperial'].map((unit) {
              return ListTile(
                title: Text(unit),
                trailing: _units == unit ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                onTap: () {
                  setState(() => _units = unit);
                  _persistSettings();
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
