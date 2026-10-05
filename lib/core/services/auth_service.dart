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
      'For your security, sign out and sign back in, then delete your account.';
}

class _DummyUser implements User {
  @override
  final String uid = 'dummy-user-001';
  @override
  final String? email = 'demo@itfits.app';
  @override
  final String? displayName = 'Demo User';
  @override
  final String? photoURL;

  const _DummyUser({this.photoURL});

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class AuthService {
  /// Web (type 3) OAuth client from android/app/google-services.json.
  /// Required so GoogleSignIn returns a valid idToken for Firebase on Android.
  /// From google-services.json `oauth_client` with `client_type: 3`.
  static const String _googleServerClientId =
      '133083240626-3dmk70jrf6ackkg0go7usk2rhgp72s7c.apps.googleusercontent.com';

  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  bool _googleInitialized = false;
  StreamSubscription<User?>? _authSubscription;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleInitialized = true;
  }
  final bool _isDummy;
  User? _dummyUser;
  final ValueNotifier<bool> _authNotifier = ValueNotifier(false);

  AuthService(FirebaseAuth auth, FirebaseFirestore firestore)
      : _auth = auth,
        _firestore = firestore,
        _isDummy = false {
    _authSubscription = _auth.authStateChanges().listen((_) {
      _authNotifier.value = !_authNotifier.value;
    });
  }

  AuthService.dummy()
      : _isDummy = true,
        _dummyUser = null;

  /// Whether this is the offline fallback (Firebase failed to initialize).
  bool get isDummy => _isDummy;

  void dispose() {
    _authSubscription?.cancel();
    _authNotifier.dispose();
  }

  ValueNotifier<bool> get authNotifier => _authNotifier;

  Stream<User?> get authStateChanges {
    if (_isDummy) {
      return Stream.value(_dummyUser);
    }
    return _auth.authStateChanges();
  }

  User? get currentUser => _isDummy ? _dummyUser : _auth.currentUser;

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_isDummy) {
      final dummy = _dummyUser;
      if (dummy == null) return null;
      return {
        'uid': 'dummy-user-001',
        'email': 'demo@itfits.app',
        'displayName': dummy.displayName ?? 'Demo User',
        'photoURL': dummy.photoURL,
        'plan': 'free',
        'preferences': {
          'theme': 'system',
          'notifications': true,
        },
      };
    }
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      debugPrint('Failed to load user profile: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (_isDummy) {
      throw Exception('Firebase is not initialized. Restart the app with network access.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Enter your email and password.');
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password, String displayName) async {
    if (_isDummy) {
      throw Exception('Firebase is not initialized. Restart the app with network access.');
    }
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
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      try {
        await credential.user?.updateDisplayName(name);
        await credential.user?.reload();
      } catch (e) {
        debugPrint('Display name update failed: $e');
      }
      final user = _auth.currentUser ?? credential.user;
      if (user != null) {
        await _createUserProfile(user);
        try {
          await user.sendEmailVerification();
        } catch (e) {
          debugPrint('Email verification send failed: $e');
        }
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sends a password-reset email. Does not reveal whether the account exists.
  Future<void> sendPasswordResetEmail(String email) async {
    if (_isDummy) {
      throw Exception('Firebase is not initialized. Restart the app with network access.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw Exception('Enter your email address.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> sendEmailVerification() async {
    if (_isDummy) return;
    final user = _auth.currentUser;
    if (user == null || user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> reloadUser() async {
    if (_isDummy) return;
    await _auth.currentUser?.reload();
    // Force router refresh after reload (e.g. emailVerified changed).
    _authNotifier.value = !_authNotifier.value;
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (_isDummy) {
      throw Exception('Firebase is not initialized. Restart the app with network access.');
    }
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

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user ?? _auth.currentUser;
      if (user == null) {
        throw Exception('Google sign-in failed: no Firebase user.');
      }
      await _createUserProfile(user);
      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw Exception('Google sign-in failed: ${e.description ?? e.code.name}');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithApple() async {
    if (_isDummy) {
      throw Exception('Firebase is not initialized. Restart the app with network access.');
    }
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

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user ?? _auth.currentUser;
      if (user == null) {
        throw Exception('Apple Sign In failed: no Firebase user.');
      }
      await _createUserProfile(user);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Apple Sign In failed: $e');
    }
  }

  Future<void> signOut() async {
    if (_isDummy) {
      _dummyUser = null;
      _authNotifier.value = !_authNotifier.value;
      return;
    }
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Google sign-out failed: $e');
      }
    }
    await _auth.signOut();
    _authNotifier.value = !_authNotifier.value;
  }

  Future<void> _createUserProfile(User user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'designs': [],
          'preferences': {
            'theme': 'system',
            'notifications': true,
          },
        });
      } else {
        // Keep profile fresh without overwriting user data.
        await docRef.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
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
    if (_isDummy) {
      if (_dummyUser != null) {
        _dummyUser = _DummyUser(photoURL: photoURL ?? _dummyUser?.photoURL);
      }
      return;
    }
    final user = _auth.currentUser;
    if (user == null) return;

    if (displayName != null) {
      try {
        await user.updateDisplayName(displayName);
      } catch (e) {
        debugPrint('Display name update failed: $e');
      }
    }

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (bio != null) updateData['bio'] = bio;
      if (preferences != null) updateData['preferences'] = preferences;

      await _firestore.collection('users').doc(user.uid).update(updateData);
    } catch (e) {
      debugPrint('Profile update failed: $e');
    }
  }

  Future<void> deleteAccount() async {
    if (_isDummy) {
      _dummyUser = null;
      _authNotifier.value = !_authNotifier.value;
      return;
    }
    final user = _auth.currentUser;
    if (user == null) return;

    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn == null ||
        DateTime.now().difference(lastSignIn) > const Duration(minutes: 5)) {
      throw const RecentLoginRequiredException();
    }

    await ProjectService.deleteUserTree(_firestore, user.uid);
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw const RecentLoginRequiredException();
      }
      rethrow;
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return Exception('The password provided is too weak. Use at least 6 characters.');
      case 'email-already-in-use':
      case 'credential-already-in-use':
        return Exception('An account already exists for that email. Try signing in.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return Exception('Incorrect email or password.');
      case 'account-exists-with-different-credential':
        return Exception('This email is registered with a different sign-in method. Try Google sign-in.');
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
