import 'package:flutter/material.dart';

import '../services/mobile_auth_service.dart';
import 'attendance_history_screen.dart';
import 'mobile_profile_screen.dart';
import 'qr_scanner_screen.dart';

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({
    super.key,
    required this.authService,
    required this.onLoggedOut,
  });

  final MobileAuthService authService;
  final VoidCallback onLoggedOut;

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _currentIndex = 0;
  final GlobalKey<AttendanceHistoryScreenState> _historyKey = GlobalKey();

  void _onAttendanceSuccess() {
    // Notify history screen to reload data
    _historyKey.currentState?.loadAttendances();
  }

  @override
  Widget build(BuildContext context) {
    const fptOrange = Color(0xFFF37021);
    const ink = Color(0xFF3A504E);

    final screens = [
      QrScannerScreen(
        authService: widget.authService,
        onAttendanceSuccess: _onAttendanceSuccess,
      ),
      AttendanceHistoryScreen(
        key: _historyKey,
        authService: widget.authService,
      ),
      MobileProfileScreen(
        authService: widget.authService,
        onLoggedOut: widget.onLoggedOut,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            _historyKey.currentState?.loadAttendances();
          }
        },
        backgroundColor: Colors.white,
        indicatorColor: fptOrange.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined, color: ink),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: fptOrange),
            label: 'Quét QR',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, color: ink),
            selectedIcon: Icon(Icons.history_rounded, color: fptOrange),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded, color: ink),
            selectedIcon: Icon(Icons.person_rounded, color: fptOrange),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
