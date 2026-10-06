// File generated for itfits-ai (Android configured from google-services.json).
// Run `flutterfire configure` to regenerate for iOS/Web/macOS/Windows.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run `flutterfire configure` to add web config.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'run `flutterfire configure` to add iOS config.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'run `flutterfire configure` to add macOS config.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'run `flutterfire configure` to add Windows config.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run `flutterfire configure` to add Linux config.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBEnO7QBjaDze2KARo7P0I4gdDLOeOr1Aw',
    appId: '1:133083240626:android:767a45628abfcdf8f511ab',
    messagingSenderId: '133083240626',
    projectId: 'itfits-ai',
    storageBucket: 'itfits-ai.firebasestorage.app',
  );
}
