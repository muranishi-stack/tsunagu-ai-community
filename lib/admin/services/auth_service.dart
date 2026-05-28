// Firebase Auth wrapper for TSUNAGU admin and user authentication.
//
// Behavior:
// - Provides login(email, password) and signUp(email, password)
// - On login, attempts Firebase Auth first; if that fails AND the
//   credentials match the legacy mock admin (admin@tsunagu.jp / admin1234)
//   we still allow login so the app remains usable before the admin
//   account is created in Firebase. This lets developers bootstrap.
// - Exposes currentUser as a stream and as a getter.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final FirebaseAuth _auth = FirebaseAuth.instance;

  // Legacy bootstrap credentials (kept for first-run admin access).
  static const _bootstrapEmail = 'admin@tsunagu.jp';
  static const _bootstrapPassword = 'admin1234';

  /// Whether the current session is the legacy bootstrap admin
  /// (not a real Firebase user). Used to decide whether to write to
  /// Firestore as that user or fall back to direct admin SDK access.
  bool _isBootstrapSession = false;
  bool get isBootstrapSession => _isBootstrapSession;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get userStream => _auth.authStateChanges();

  bool get isSignedIn => currentUser != null || _isBootstrapSession;

  /// Login with email + password. Returns null on success, error message
  /// on failure.
  Future<String?> login(String email, String password) async {
    // 1. Try Firebase Auth first
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isBootstrapSession = false;
      if (kDebugMode) {
        debugPrint('AuthService: Firebase login successful for $email');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      // Fall through to bootstrap check
      if (kDebugMode) {
        debugPrint('AuthService: Firebase login failed (${e.code}): ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Login error: $e');
      }
    }

    // 2. Legacy bootstrap fallback so the admin console remains usable
    //    before the admin account is created in Firebase Auth.
    if (email == _bootstrapEmail && password == _bootstrapPassword) {
      _isBootstrapSession = true;
      if (kDebugMode) {
        debugPrint('AuthService: Bootstrap admin login (no Firebase user)');
      }
      return null;
    }

    return 'メールアドレスまたはパスワードが間違っています';
  }

  /// Sign up a new user. Returns null on success, error message on failure.
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _isBootstrapSession = false;
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'パスワードは6文字以上で入力してください';
        case 'email-already-in-use':
          return 'このメールアドレスは既に使用されています';
        case 'invalid-email':
          return 'メールアドレスの形式が正しくありません';
        default:
          return e.message ?? '登録に失敗しました';
      }
    } catch (e) {
      return '登録に失敗しました: $e';
    }
  }

  Future<void> signOut() async {
    _isBootstrapSession = false;
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService.signOut error: $e');
      }
    }
  }
}
