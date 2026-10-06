import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'project_service.dart';

class RecentLoginRequiredException implements Exception {
  const RecentLoginRequiredException();
  @override
  String toString() =>
      'For your security, sign out and sign back in, then try again.';
}

/// Central auth gateway.
///
/// - Extends [ChangeNotifier] so GoRouter can use it directly as
///   `refreshListenable` — no bool-toggling hacks, no stale snapshots.
/// - Never fabricates a user. When Firebase is unavailable ([AuthService.dummy])
///   [currentUser] is always null and every mutating call throws a clear error.
/// - Always guarantees a `users/{uid}` Firestore profile exists after any
///   successful sign-in (fixes console-created users with no profile doc).
class AuthService extends ChangeNotifier {
  /// Web (type 3) OAuth client from android/app/google-services.json.
  /// Required so GoogleSignIn returns a valid idToken for Firebase on Android.
  static const String _googleServerClientId =
      '133083240626-3dmk70jrf6ackkg0go7usk2rhgp72s7c.apps.googleusercontent.com';

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _googleInitialized = false;
  StreamSubscription<User?>? _authSubscription;

  final bool _isDummy;

  AuthService(FirebaseAuth auth, FirebaseFirestore firestore)
      : _auth = auth,
        _firestore = firestore,
        _isDummy = false {
    _authSubscription = _auth!.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  AuthService.dummy() : _isDummy = true;

  /// Whether this is the offline fallback (Firebase failed to initialize).
  bool get isDummy => _isDummy;

  /// Back-compat: router previously used `authService.authNotifier`.
  /// Now returns `this` since AuthService itself is a Listenable.
  Listenable get authNotifier => this;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (_isDummy || auth == null) {
      throw Exception(
          'Firebase is not initialized. Restart the app with network access.');
    }
    return auth;
  }

  FirebaseFirestore _requireFirestore() {
    final db = _firestore;
    if (_isDummy || db == null) {
      throw Exception(
          'Firebase is not initialized. Restart the app with network access.');
    }
    return db;
  }

  Stream<User?> get authStateChanges {
    if (_isDummy) return Stream<User?>.value(null);
    return _auth!.authStateChanges();
  }

  /// Always read fresh from FirebaseAuth — never cache the uid.
  /// Caching the uid in providers was the "wrong account" bug:
  /// after switching accounts the UI kept showing the previous user.
  User? get currentUser => _isDummy ? null : _auth?.currentUser;

  String? get currentUid => currentUser?.uid;

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_isDummy) return null;
    try {
      final user = _auth?.currentUser;
      if (user == null) return null;
      final db = _requireFirestore();
      final docRef = db.collection('users').doc(user.uid);
      var doc = await docRef.get();
      if (!doc.exists) {
        // Console-created users have an Auth record but no Firestore doc.
        // Create it now so the UI never shows a generic/wrong profile.
        await _createUserProfile(user);
        doc = await docRef.get();
        if (!doc.exists) return null;
      }
      return doc.data();
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
      return null;
    }
  }

  /// Live profile stream scoped to the currently signed-in uid.
  /// Emits null when signed out. Caller must re-subscribe on uid change
  /// (see providers.dart authStateProvider pattern).
  Stream<Map<String, dynamic>?> watchUserProfile() {
    if (_isDummy) return Stream<Map<String, dynamic>?>.value(null);
    final user = _auth?.currentUser;
    if (user == null) return Stream<Map<String, dynamic>?>.value(null);
    return _firestore!
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null)
        .handleError((_) => null);
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    final auth = _requireAuth();
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Enter your email and password.');
    }
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user ?? auth.currentUser;
      if (user == null) {
        throw Exception('Sign-in failed: no Firebase user.');
      }
      // Ensure Firestore profile exists (console-created users lack one).
      await _createUserProfile(user);
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signUpWithEmail(
      String email, String password, String displayName) async {
    final auth = _requireAuth();
    final normalizedEmail = email.trim().toLowerCase();
    final name = displayName.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Enter your email and password.');
    }
    if (name.isEmpty) {
      throw Exception('Enter your name.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      try {
        await credential.user?.updateDisplayName(name);
        await credential.user?.reload();
      } catch (e) {
        debugPrint('Display name update failed: $e');
      }
      final user = auth.currentUser ?? credential.user;
      if (user != null) {
        await _createUserProfile(user);
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('Email verification send failed: $e');
        }
      }
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sends a password-reset email. Does not reveal whether the account exists.
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _requireAuth();
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw Exception('Enter your email address.');
    }
    try {
      await auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendEmailVerification() async {
    if (_isDummy) return;
    final user = _auth?.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> reloadUser() async {
    if (_isDummy) return;
    await _auth?.currentUser?.reload();
    notifyListeners();
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId,
      );
    } catch (e) {
      debugPrint('GoogleSignIn initialize failed (may be already init): $e');
    }
    _googleInitialized = true;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final auth = _requireAuth();
    try {
      await _ensureGoogleInitialized();
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google sign-in did not return an ID token. '
          'Check the serverClientId / OAuth configuration.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await auth.signInWithCredential(credential);
      final user = userCredential.user ?? auth.currentUser;
      if (user == null) {
        throw Exception('Google sign-in failed: no Firebase user.');
      }
      await _createUserProfile(user);
      notifyListeners();
      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw Exception('Google sign-in failed: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithApple() async {
    final auth = _requireAuth();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      final userCredential = await auth.signInWithCredential(oauthCredential);
      final user = userCredential.user ?? auth.currentUser;
      if (user == null) {
        throw Exception('Apple Sign In failed: no Firebase user.');
      }
      await _createUserProfile(user);
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('canceled')) return null;
      throw Exception('Apple Sign In failed: $e');
    }
  }

  Future<void> signOut() async {
    if (_isDummy) {
      notifyListeners();
      return;
    }
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google sign-out failed: $e');
      }
    }
    await _auth?.signOut();
    notifyListeners();
  }

  Future<void> _createUserProfile(User user) async {
    try {
      final db = _requireFirestore();
      final docRef = db.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email?.toLowerCase(),
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'plan': 'free',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'designs': [],
          'preferences': {
            'theme': 'system',
            'notifications': true,
          },
        });
      } else {
        // Keep profile fresh without overwriting user data (esp. plan).
        await docRef.set({
          'email': user.email?.toLowerCase(),
          if (user.displayName != null) 'displayName': user.displayName,
          if (user.photoURL != null) 'photoURL': user.photoURL,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Failed to create/update user profile: $e');
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    Map<String, dynamic>? preferences,
  }) async {
    final auth = _requireAuth();
    final user = auth.currentUser;
    if (user == null) return;

    if (displayName != null && displayName.trim().isNotEmpty) {
      try {
        await user.updateDisplayName(displayName.trim());
      } catch (e) {
        debugPrint('Display name update failed: $e');
      }
    }

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updateData['displayName'] = displayName.trim();
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (bio != null) updateData['bio'] = bio;
      if (preferences != null) {
        updateData['preferences'] = preferences;
      }

      await _requireFirestore()
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('Profile update failed: $e');
      rethrow;
    }
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final auth = _requireAuth();
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Sign in again to change your password.');
    }
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Re-authenticate with password. Call before [deleteAccount] when Firebase
  /// reports `requires-recent-login`.
  Future<void> reauthenticateWithPassword(String password) async {
    final auth = _requireAuth();
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('Sign in again to continue.');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> deleteAccount() async {
    final auth = _requireAuth();
    final db = _requireFirestore();
    final user = auth.currentUser;
    if (user == null) return;

    await ProjectService.deleteUserTree(db, user.uid);
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const RecentLoginRequiredException();
      }
      rethrow;
    }
    notifyListeners();
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception(
            'The password provided is too weak. Use at least 6 characters.');
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return Exception(
            'An account already exists for that email. Try signing in.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return Exception('Incorrect email or password.');
      case 'account-exists-with-different-credential':
        return Exception(
            'This email is registered with a different sign-in method. Try Google sign-in.');
      case 'network-request-failed':
        return Exception('No connection to the server. Check your internet.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This account has been disabled. Contact support.');
      case 'too-many-requests':
        return Exception('Too many attempts. Try again later.');
      case 'operation-not-allowed':
        return Exception(
          'This sign-in method is not enabled in Firebase Console. '
          'Enable Email/Password and Google under Authentication > Sign-in method.',
        );
      case 'requires-recent-login':
        return const RecentLoginRequiredException();
      case 'user-mismatch':
      case 'provider-already-linked':
        return Exception('Sign-in failed (${e.code}): ${e.message}');
      default:
        return Exception('Sign-in failed (${e.code}): ${e.message}');
    }
  }
}
