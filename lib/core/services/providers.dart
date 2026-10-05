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
import '../router/app_router.dart';
import '../models/project_model.dart';
import '../models/floor_plan_data.dart';

bool firebaseReady = false;

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
  return AuthService(
    ref.read(firebaseAuthProvider),
    ref.read(firebaseFirestoreProvider),
  );
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
  return AiDesignService(ref.read(aiProxyServiceProvider));
});

final currentProjectProvider = StateProvider<ProjectModel?>((ref) => null);
final capturedImagesProvider = StateProvider<List<String>>((ref) => []);
final capturedImageIdsProvider = StateProvider<List<String>>((ref) => []);
final selectedStyleNameProvider = StateProvider<String>((ref) => '');
final selectedPaletteProvider2 = StateProvider<List<int>>((ref) => []);
final generatedDesignsProvider = StateProvider<List<GeneratedDesignResult>>((ref) => []);
final generatedDesignUrlsProvider = StateProvider<List<String>>((ref) => []);
final aiPreferencesProvider = StateProvider<List<String>>((ref) => []);
final floorPlanDataProvider = StateProvider<FloorPlanData?>((ref) => null);
final selectedRoomTypeProvider = StateProvider<String>((ref) => 'Living Room');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  return createRouter(authService);
});
