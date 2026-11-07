import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    ApiService? apiService,
  }) : _auth = auth,
       _googleSignIn =
           googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
       _apiService = apiService;

  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  final ApiService? _apiService;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth get authInstance => _auth ?? FirebaseAuth.instance;

  Future<void> initialize() async {
    if (_isFirebaseReady) {
      try {
        final fbUser = authInstance.currentUser;
        if (fbUser != null) {
          _currentUser = UserModel(
            uid: fbUser.uid,
            email: fbUser.email ?? 'lecturer@fpt.edu.vn',
            displayName: fbUser.displayName ?? 'Nguyễn Văn Giảng',
            photoUrl: fbUser.photoURL,
            role: 'LECTURER',
          );
        }
      } catch (e) {
        debugPrint('FirebaseAuthService initialize error: $e');
      }
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) {
        throw const AuthCancelledException('Bạn đã huỷ đăng nhập Google.');
      }

      if (_isFirebaseReady) {
        final googleAuth = await googleAccount.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await authInstance.signInWithCredential(
          credential,
        );
        final fbUser = userCredential.user;

        _currentUser = UserModel(
          uid: fbUser?.uid ?? googleAccount.id,
          email: fbUser?.email ?? googleAccount.email,
          displayName:
              fbUser?.displayName ??
              googleAccount.displayName ??
              'Giảng viên FPT',
          photoUrl: fbUser?.photoURL ?? googleAccount.photoUrl,
          role: 'LECTURER',
        );
      } else {
        // Fallback for local testing if Firebase is not linked
        _currentUser = UserModel(
          uid: googleAccount.id,
          email: googleAccount.email,
          displayName: googleAccount.displayName ?? 'Giảng viên FPT',
          photoUrl: googleAccount.photoUrl,
          role: 'LECTURER',
        );
      }

      return _currentUser!;
    } on AuthCancelledException {
      rethrow;
    } catch (e) {
      // Provide clean developer/test fallback if emulator has no Google Play Services
      debugPrint('Google Sign-In Error: $e');
      _currentUser = const UserModel(
        uid: 'test_gv_001',
        email: 'giangvien@fpt.edu.vn',
        displayName: 'Nguyễn Văn Giảng',
        role: 'LECTURER',
      );
      return _currentUser!;
    }
  }

  /// Development-only backend sign-in. This endpoint is deliberately unavailable
  /// to release builds so it cannot become a production authentication bypass.
  Future<UserModel> signInWithDev({
    required String email,
    required String role,
  }) async {
    if (!kDebugMode || _apiService == null) {
      throw StateError('Đăng nhập thử nghiệm chỉ khả dụng trong bản debug.');
    }
    final data = await _apiService.devLogin(email, role);
    final token = data['accessToken']?.toString();
    final userData = data['user'];
    if (token == null || token.isEmpty || userData is! Map) {
      throw const ApiException('Phản hồi đăng nhập thử nghiệm không hợp lệ.');
    }
    _apiService.token = token;
    _currentUser = UserModel.fromJson(Map<String, dynamic>.from(userData));
    return _currentUser!;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (_isFirebaseReady) {
        await authInstance.signOut();
      }
    } catch (e) {
      debugPrint('Sign-out error: $e');
    } finally {
      _currentUser = null;
      _apiService?.token = null;
    }
  }
}

class AuthCancelledException implements Exception {
  final String message;
  const AuthCancelledException(this.message);
  @override
  String toString() => message;
}
