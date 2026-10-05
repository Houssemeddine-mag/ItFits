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
import 'package:itfits/core/services/auth_service.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: authService.authNotifier,
    redirect: (context, state) {
      final isAuthenticated = authService.currentUser != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/onboarding';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isAuthRoute && !isOnboarding) {
        return '/onboarding';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      if (isAuthenticated && isOnboarding) {
        return '/';
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
        builder: (context, state) => DesignDetailScreen(designId: state.pathParameters['id']!),
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