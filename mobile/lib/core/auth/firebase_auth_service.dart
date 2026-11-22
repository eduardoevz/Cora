import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class CoraAuthUser {
  const CoraAuthUser({
    required this.uid,
    this.email,
  });

  final String uid;
  final String? email;
}

class CoraAuthException implements Exception {
  const CoraAuthException({
    required this.code,
    required this.messageEs,
  });

  final String code;
  final String messageEs;

  @override
  String toString() => messageEs;
}

abstract class ICoraAuthService {
  bool get isFirebaseReady;
  CoraAuthUser? get currentUser;
  Stream<CoraAuthUser?> authStateChanges();
  Future<void> initialize();
  Future<CoraAuthUser> signInWithEmail({
    required String email,
    required String password,
  });
  Future<CoraAuthUser> registerWithEmail({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<String?> getIdToken({bool forceRefresh = false});
  Future<void> signOut();
  Future<void> deleteCurrentUser();
}

class FirebaseCoraAuthService implements ICoraAuthService {
  FirebaseCoraAuthService._();

  static final FirebaseCoraAuthService instance = FirebaseCoraAuthService._();

  bool _isFirebaseReady = false;
  FirebaseAuth? _auth;

  @override
  bool get isFirebaseReady => _isFirebaseReady;

  @override
  CoraAuthUser? get currentUser {
    final user = _auth?.currentUser;
    if (user == null) return null;
    return CoraAuthUser(uid: user.uid, email: user.email);
  }

  @override
  Future<void> initialize() async {
    if (_isFirebaseReady) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _auth = FirebaseAuth.instance;
      _isFirebaseReady = true;
    } catch (_) {
      // Allows graceful execution in headless widget tests without google-services.json
      _isFirebaseReady = false;
    }
  }

  @override
  Stream<CoraAuthUser?> authStateChanges() {
    final auth = _auth;
    if (!_isFirebaseReady || auth == null) {
      return Stream<CoraAuthUser?>.value(null);
    }
    return auth.authStateChanges().map(
          (user) => user == null
              ? null
              : CoraAuthUser(uid: user.uid, email: user.email),
        );
  }

  @override
  Future<CoraAuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _requireAuth();
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const CoraAuthException(
          code: 'null-user',
          messageEs: 'No fue posible iniciar sesión. Intenta nuevamente.',
        );
      }
      return CoraAuthUser(uid: user.uid, email: user.email);
    } on FirebaseAuthException catch (e) {
      throw CoraAuthException(
        code: e.code,
        messageEs: _mapFirebaseErrorToSpanish(e.code),
      );
    }
  }

  @override
  Future<CoraAuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _requireAuth();
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const CoraAuthException(
          code: 'null-user',
          messageEs: 'No fue posible crear tu cuenta. Intenta nuevamente.',
        );
      }
      return CoraAuthUser(uid: user.uid, email: user.email);
    } on FirebaseAuthException catch (e) {
      throw CoraAuthException(
        code: e.code,
        messageEs: _mapFirebaseErrorToSpanish(e.code),
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _requireAuth();
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw CoraAuthException(
        code: e.code,
        messageEs: _mapFirebaseErrorToSpanish(e.code),
      );
    }
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth?.currentUser;
    if (!_isFirebaseReady || user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    if (_isFirebaseReady && _auth != null) {
      await _auth!.signOut();
    }
  }

  @override
  Future<void> deleteCurrentUser() async {
    final user = _auth?.currentUser;
    if (_isFirebaseReady && user != null) {
      try {
        await user.delete();
      } catch (_) {
        // Requires recent login; still sign out locally
        await signOut();
      }
    }
  }

  FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (!_isFirebaseReady || auth == null) {
      throw const CoraAuthException(
        code: 'firebase-not-configured',
        messageEs:
            'Firebase Authentication no está configurado en este dispositivo.',
      );
    }
    return auth;
  }

  String _mapFirebaseErrorToSpanish(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta se encuentra deshabilitada.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos. Verifica tus datos.';
      case 'wrong-password':
        return 'La contraseña ingresada es incorrecta.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con este correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red e intenta de nuevo.';
      case 'too-many-requests':
        return 'Demasiados intentos seguidos. Espera un momento e intenta de nuevo.';
      default:
        return 'No pudimos completar la autenticación ($code).';
    }
  }
}
