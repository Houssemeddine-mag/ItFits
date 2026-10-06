import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:itfits/core/services/providers.dart';

/// Shown after email sign-up. Lets the user resend the verification
/// email and continue (verification is soft-gated, not blocking).
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _sending = false;
  bool _checking = false;
  String? _message;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Poll every 3s — auto-continue once the user clicks the email link.
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _checkSilent());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _checkSilent() async {
    if (!mounted || _checking) return;
    try {
      await ref.read(authServiceProvider).reloadUser();
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null && user.emailVerified && mounted) {
        _poll?.cancel();
        context.go('/');
      }
    } catch (_) {}
  }

  Future<void> _checkNow() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).reloadUser();
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null && user.emailVerified) {
        if (mounted) context.go('/');
      } else {
        setState(() => _message = 'Still not verified. Check your inbox.');
      }
    } catch (e) {
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await ref.read(authServiceProvider).sendEmailVerification();
      setState(() => _message = 'Verification email sent.');
    } catch (e) {
      setState(() => _message = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authServiceProvider).currentUser;
    final email = user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Icon(Icons.mark_email_read_outlined,
                size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Check your inbox',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              email.isEmpty
                  ? 'We sent a verification link to your email.'
                  : 'We sent a verification link to $email.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _checking ? null : _checkNow,
              child: _checking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("I've verified — continue"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _sending ? null : _resend,
              child: Text(_sending ? 'Sending…' : 'Resend email'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
