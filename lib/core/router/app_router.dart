import 'package:go_router/go_router.dart';
import 'package:itfits/features/home/presentation/home_screen.dart';
import 'package:itfits/features/create/presentation/create_screen.dart';
import 'package:itfits/features/history/presentation/history_screen.dart';
import 'package:itfits/features/profile/presentation/profile_screen.dart';
import 'package:itfits/features/history/presentation/design_detail_screen.dart';
import 'package:itfits/features/profile/presentation/settings_screen.dart';
import 'package:itfits/features/profile/presentation/edit_profile_screen.dart';
import 'package:itfits/features/auth/presentation/auth_screen.dart';
import 'package:itfits/features/auth/presentation/onboarding_screen.dart';
import 'package:itfits/features/auth/presentation/verify_email_screen.dart';
import 'package:itfits/core/services/auth_service.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: authService,
    redirect: (context, state) {
      // Always read fresh — never cache the user across redirects.
      final user = authService.currentUser;
      final isAuthenticated = user != null;
      final location = state.matchedLocation;

      final isOnboarding = location == '/onboarding';
      final isAuth = location == '/auth';
      final isVerify = location == '/verify-email';
      final isAuthRoute = isOnboarding || isAuth || isVerify;

      // Not signed in → only auth routes allowed.
      if (!isAuthenticated && !isAuthRoute) {
        return '/onboarding';
      }

      if (isAuthenticated) {
        // Signed in → never stay on login/onboarding.
        if (isOnboarding || isAuth) return '/';
        // Email/password users with unverified email get nudged once.
        // Google/Apple users are pre-verified; don't block them.
        final isPasswordUser = user.providerData
            .any((p) => p.providerId == 'password');
        if (isPasswordUser &&
            !user.emailVerified &&
            !isVerify &&
            location == '/') {
          // Soft gate: allow app use but route first login through verify.
          // Comment out next line to hard-block unverified users.
          // return '/verify-email';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeTabScreen(),
          ),
          GoRoute(
            path: '/create',
            builder: (context, state) => CreateScreen(
              resumeProjectId: state.uri.queryParameters['resume'],
            ),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/design/:id',
        builder: (context, state) =>
            DesignDetailScreen(designId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
    ],
  );
}
