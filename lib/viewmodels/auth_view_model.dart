import 'package:flutter/material.dart';
import '../firebase/firebase_analytics_service.dart';
import '../firebase/firebase_auth_service.dart';
import '../models/app_models.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required FirebaseAuthService authService,
    required FirebaseAnalyticsService analyticsService,
  }) : _authService = authService,
       _analyticsService = analyticsService;

  final FirebaseAuthService _authService;
  final FirebaseAnalyticsService _analyticsService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;

  Future<void> init() async {
    await _authService.initialize();
    if (currentUser != null) {
      await _analyticsService.setUserId(currentUser!.uid);
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      await _analyticsService.setUserId(user.uid);
      await _analyticsService.logLogin(method: 'google');
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthCancelledException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đăng nhập không thành công: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithDev({
    required String email,
    required String role,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await _authService.signInWithDev(email: email, role: role);
      await _analyticsService.setUserId(user.uid);
      await _analyticsService.logLogin(method: 'debug_dev');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Đăng nhập thử nghiệm không thành công: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _analyticsService.logLogout();
    await _authService.signOut();
    await _analyticsService.setUserId(null);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
