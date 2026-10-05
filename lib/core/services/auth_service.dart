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
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }
  final bool _isDummy;
  User? _dummyUser;
  final ValueNotifier<bool> _authNotifier = ValueNotifier(false);

  AuthService(FirebaseAuth auth, FirebaseFirestore firestore)
      : _auth = auth,
        _firestore = firestore,
        _isDummy = false {
    _auth.authStateChanges().listen((_) {
      _authNotifier.value = !_authNotifier.value;
    });
  }

  AuthService.dummy()
      : _isDummy = true,
        _dummyUser = const _DummyUser();

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
      return {
        'uid': 'dummy-user-001',
        'email': 'demo@itfits.app',
        'displayName': _dummyUser?.displayName ?? 'Demo User',
        'photoURL': _dummyUser?.photoURL,
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
    } catch (_) {
      return null;
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    if (_isDummy) {
      _dummyUser = _DummyUser();
      _authNotifier.value = !_authNotifier.value;
      return null;
    }
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password, String displayName) async {
    if (_isDummy) {
      _dummyUser = _DummyUser();
      _authNotifier.value = !_authNotifier.value;
      return null;
    }
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      try {
        await credential.user?.updateDisplayName(displayName);
        await credential.user?.reload();
      } catch (e) {
        debugPrint('Display name update failed: $e');
      }
      await _createUserProfile(_auth.currentUser ?? credential.user!);
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (_isDummy) {
      _dummyUser = _DummyUser();
      _authNotifier.value = !_authNotifier.value;
      return null;
    }
    try {
      await _ensureGoogleInitialized();
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _createUserProfile(userCredential.user!);
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
      _dummyUser = _DummyUser();
      _authNotifier.value = !_authNotifier.value;
      return null;
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
      await _createUserProfile(userCredential.user!);
      return userCredential;
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
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
    }
    await _auth.signOut();
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
      }
    } catch (_) {}
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
      } catch (_) {}
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
    } catch (_) {}
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
        return Exception('The password provided is too weak.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return Exception('Incorrect email or password.');
      case 'network-request-failed':
        return Exception('No connection to the server. Check your internet.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This user has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Try again later.');
      case 'operation-not-allowed':
        return Exception('This sign-in method is not enabled.');
      default:
        return Exception('Sign-in failed (${e.code}): ${e.message}');
    }
  }
}
