import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itfits/core/theme/app_theme.dart';
import 'package:itfits/core/services/providers.dart';
import 'package:itfits/firebase_options.dart';

class ItFitsApp extends ConsumerWidget {
  const ItFitsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);

    return MaterialApp.router(
      title: 'ItFits - AI Interior Design',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Shared AI key for all users (bundled via `.env`, see `.env.example`).
  // Missing file is fine — the app falls back to BYOK / server backend.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    debugPrint('.env not found — using BYOK / server AI only');
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init failed (running in offline mode): $e');
    firebaseInitError = e.toString();
  }
  runApp(const ProviderScope(child: ItFitsApp()));
}