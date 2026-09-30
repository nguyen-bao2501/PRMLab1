import 'package:flutter/material.dart';

import 'screens/mobile_login_screen.dart';
import 'screens/mobile_main_screen.dart';
import 'services/mobile_auth_service.dart';

class MobileApp extends StatefulWidget {
  const MobileApp({super.key, this.authService});

  final MobileAuthService? authService;

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  late final MobileAuthService _authService;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? MobileAuthService();
    _initAuth();
  }

  Future<void> _initAuth() async {
    await _authService.initialize();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF3A504E);
    const fptOrange = Color(0xFFF37021);

    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F6),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: fptOrange),
              SizedBox(height: 16),
              Text(
                'FPT University Điểm danh',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _authService,
      builder: (context, _) {
        if (_authService.isAuthenticated) {
          return MobileMainScreen(
            authService: _authService,
            onLoggedOut: () => setState(() {}),
          );
        }

        return MobileLoginScreen(
          authService: _authService,
          onLoginSuccess: () => setState(() {}),
        );
      },
    );
  }
}
