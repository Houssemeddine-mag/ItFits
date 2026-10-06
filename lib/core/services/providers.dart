import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../services/firestore_image_service.dart';
import '../services/ai_design_service.dart';
import '../services/ai_proxy_service.dart';
import '../services/openrouter_service.dart';
import '../router/app_router.dart';
import '../models/project_model.dart';
import '../models/floor_plan_data.dart';

bool firebaseReady = false;
String? firebaseInitError;

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  if (!firebaseReady) throw Exception('Firebase not initialized');
  return FirebaseAuth.instance;
});

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  if (!firebaseReady) throw Exception('Firebase not initialized');
  return FirebaseFirestore.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  if (!firebaseReady) return AuthService.dummy();
  final service = AuthService(
    ref.read(firebaseAuthProvider),
    ref.read(firebaseFirestoreProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Single source of truth for auth state.
///
/// All user-scoped providers MUST watch this (not `currentUser` snapshots)
/// so switching accounts instantly invalidates old-uid data.
/// This was the "logged into another account" bug: providers captured the
/// uid once via `ref.read` and never refreshed.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current uid, reactive. Null when signed out.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).asData?.value?.uid;
});

/// Firestore profile for the currently signed-in user.
/// Auto-switches when accounts change; null when signed out.
final userProfileLiveProvider =
    StreamProvider<Map<String, dynamic>?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  final db = ref.watch(firebaseFirestoreProvider);
  return db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? doc.data() : null)
      .handleError((_) => null);
});

final projectServiceProvider = Provider<ProjectService>((ref) {
  if (!firebaseReady) return ProjectService.dummy();
  return ProjectService(ref.read(firebaseFirestoreProvider));
});

final firestoreImageServiceProvider = Provider<FirestoreImageService>((ref) {
  if (!firebaseReady) return FirestoreImageService.dummy();
  return FirestoreImageService(ref.read(firebaseFirestoreProvider));
});

final aiProxyServiceProvider = Provider<AiProxyService>((ref) {
  return AiProxyService();
});

final aiDesignServiceProvider = Provider<AiDesignService>((ref) {
  return AiDesignService(
    ref.read(aiProxyServiceProvider),
    ref.read(openRouterServiceProvider),
  );
});

final currentProjectProvider = StateProvider<ProjectModel?>((ref) => null);
final capturedImagesProvider = StateProvider<List<String>>((ref) => []);
final capturedImageIdsProvider = StateProvider<List<String>>((ref) => []);
final selectedStyleNameProvider = StateProvider<String>((ref) => '');
final selectedPaletteProvider2 = StateProvider<List<int>>((ref) => []);
final generatedDesignsProvider =
    StateProvider<List<GeneratedDesignResult>>((ref) => []);
final generatedDesignUrlsProvider = StateProvider<List<String>>((ref) => []);
final aiPreferencesProvider = StateProvider<List<String>>((ref) => []);
final floorPlanDataProvider = StateProvider<FloorPlanData?>((ref) => null);
final selectedRoomTypeProvider = StateProvider<String>((ref) => 'Living Room');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  return createRouter(authService);
});
