import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';

class MobileAuthUser {
  const MobileAuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.studentCode,
    this.avatarUrl,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;
  final String? studentCode;
  final String? avatarUrl;

  factory MobileAuthUser.fromJson(Map<String, dynamic> json) {
    return MobileAuthUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      role: json['role']?.toString() ?? 'STUDENT',
      studentCode: json['studentCode']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role,
    'studentCode': studentCode,
    'avatarUrl': avatarUrl,
  };
}

class MobileAuthService extends ChangeNotifier {
  MobileAuthService({ApiService? apiService})
      : apiService = apiService ?? ApiService();

  final ApiService apiService;
  MobileAuthUser? _currentUser;
  String? _token;
  bool _isLoading = false;
  String _baseUrl = 'http://10.0.2.2:8080';

  MobileAuthUser? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String get baseUrl => _baseUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString('api_base_url') ??
          (kIsWeb
              ? 'http://localhost:8080'
              : (defaultTargetPlatform == TargetPlatform.android
                  ? 'http://10.0.2.2:8080'
                  : 'http://localhost:8080'));
      apiService.baseUrl = _baseUrl;

      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('auth_user');

      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        apiService.token = savedToken;
        _currentUser = MobileAuthUser.fromJson(
            jsonDecode(savedUserJson) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('MobileAuthService init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBaseUrl(String newUrl) async {
    String cleanUrl = newUrl.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _baseUrl = cleanUrl;
    apiService.baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', cleanUrl);
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const ApiException('Bạn đã hủy đăng nhập Google.');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const ApiException(
          'Không lấy được Google id_token từ thiết bị. '
          'Hãy đảm bảo đã cấu hình Web Client ID trên Google Cloud Console.',
        );
      }

      final res = await apiService.googleLogin(idToken);
      await _handleLoginResponse(res);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithDev(String email, {String role = 'STUDENT'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await apiService.devLogin(email, role);
      await _handleLoginResponse(res);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleLoginResponse(Map<String, dynamic> res) async {
    final token = res['accessToken'] as String? ?? res['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('Không nhận được token xác thực từ máy chủ.');
    }

    _token = token;
    apiService.token = token;

    final userMap = res['user'] as Map<String, dynamic>?;
    if (userMap != null) {
      _currentUser = MobileAuthUser.fromJson(userMap);
    } else {
      final meRes = await apiService.me();
      _currentUser = MobileAuthUser.fromJson(meRes);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (_currentUser != null) {
      await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      _token = null;
      _currentUser = null;
      apiService.token = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
