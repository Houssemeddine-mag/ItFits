import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:itfits/core/services/providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _clearError();

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      if (_isLogin) {
        final cred = await authService.signInWithEmail(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
        );
        debugPrint('Signed in as ${cred.user?.uid} ${cred.user?.email}');
      } else {
        await authService.signUpWithEmail(
          _emailController.text.trim().toLowerCase(),
          _passwordController.text,
          _nameController.text.trim(),
        );
        if (mounted) {
          // New accounts verify email first.
          context.go('/verify-email');
          return;
        }
      }
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Enter your email above first.');
      return;
    }
    _clearError();
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    _clearError();
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.signInWithGoogle();
      if (!mounted) return;
      if (result != null || authService.currentUser != null) {
        context.go('/');
      } else {
        // null result with no user + no exception = user cancelled.
        setState(() => _errorMessage = 'Google sign-in was cancelled');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    _clearError();
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithApple();
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 72,
                    height: 72,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.auto_awesome_rounded,
                      size: 72,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Sign in to continue designing'
                      : 'Start your interior design journey',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2),
                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colorScheme.error, size: 18),
                          onPressed: _clearError,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms),
                if (!_isLogin) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearError(),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_rounded),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearError(),
                ).animate().fadeIn(delay: _isLogin ? 200.ms : 300.ms).slideX(begin: 0.2),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (!_isLogin && v.length < 6) return 'Minimum 6 characters';
                    if (_isLogin && v.isEmpty) return 'Enter your password';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  onChanged: (_) => _clearError(),
                ).animate().fadeIn(delay: _isLogin ? 300.ms : 400.ms).slideX(begin: 0.2),
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isLogin ? 'Sign In' : 'Create Account',
                          style: theme.textTheme.labelLarge?.copyWith(fontSize: 16),
                        ),
                ).animate().fadeIn(delay: _isLogin ? 400.ms : 500.ms).slideY(begin: 0.2),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or continue with', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ).animate().fadeIn(delay: _isLogin ? 450.ms : 550.ms),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    // iOS auth skipped: only show Apple on Apple platforms.
                    final showApple = !kIsWeb &&
                        (Platform.isIOS || Platform.isMacOS);
                    if (!showApple) {
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                          label: const Text('Continue with Google'),
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ).animate().fadeIn(delay: _isLogin ? 500.ms : 600.ms).slideY(begin: 0.2);
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                            label: const Text('Google'),
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.apple_rounded, size: 22),
                            label: const Text('Apple'),
                            onPressed: _isLoading ? null : _signInWithApple,
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: _isLogin ? 500.ms : 600.ms).slideY(begin: 0.2);
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin ? "Don't have an account? " : 'Already have an account? ',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearError();
                        setState(() => _isLogin = !_isLogin);
                      },
                      child: Text(_isLogin ? 'Sign Up' : 'Sign In'),
                    ),
                  ],
                ).animate().fadeIn(delay: _isLogin ? 550.ms : 650.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
