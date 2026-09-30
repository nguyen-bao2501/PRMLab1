import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'mobile/mobile_app.dart';
import 'screens/dashboard_screen.dart';
import 'services/attendance_store.dart';

void main() => runApp(const AttendanceApp());
const fptOrange = Color(0xFFF37021);
const ink = Color(0xFF3A504E);
const muted = Color(0xFF8B9D9B);

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key, this.store, this.googleSignIn});
  final Future<String> Function()? googleSignIn;
  final AttendanceStore? store;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FPT University • Điểm danh',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: const Color(0xFFE8F0ED),
      colorScheme: ColorScheme.fromSeed(
        seedColor: ink,
        primary: ink,
        secondary: const Color(0xFFD69E2E),
        surface: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFEF9),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 25,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFDCEAA5),
        side: const BorderSide(color: Color(0xFFDCE1D4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        labelStyle: const TextStyle(color: ink, fontSize: 12),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
      dividerColor: const Color(0xFFDCE1D4),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F8F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ink, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
          side: const BorderSide(color: Color(0xFFDFE5EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    ),
    home: AdaptiveAttendanceHome(
      store: store,
      googleSignIn: googleSignIn,
    ),
  );
}

class AdaptiveAttendanceHome extends StatefulWidget {
  const AdaptiveAttendanceHome({
    super.key,
    this.store,
    this.googleSignIn,
  });

  final AttendanceStore? store;
  final Future<String> Function()? googleSignIn;

  @override
  State<AdaptiveAttendanceHome> createState() => _AdaptiveAttendanceHomeState();
}

class _AdaptiveAttendanceHomeState extends State<AdaptiveAttendanceHome> {
  bool _forceMobileView = false;

  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    // If running natively on Android/iOS or forced mobile view:
    if (_isMobilePlatform || _forceMobileView) {
      return Scaffold(
        body: const MobileApp(),
        floatingActionButton: !_isMobilePlatform
            ? FloatingActionButton.extended(
                backgroundColor: ink,
                foregroundColor: Colors.white,
                onPressed: () => setState(() => _forceMobileView = false),
                icon: const Icon(Icons.desktop_windows_rounded),
                label: const Text('Về giao diện Desktop (GV)'),
              )
            : null,
      );
    }

    // Default Desktop Experience for Windows/Web/macOS
    return Scaffold(
      body: Stack(
        children: [
          DashboardScreen(
            store: widget.store,
            googleSignIn: widget.googleSignIn,
          ),
          Positioned(
            top: 14,
            right: 180,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _forceMobileView = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: fptOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: fptOrange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.smartphone_rounded, size: 16, color: fptOrange),
                      SizedBox(width: 6),
                      Text(
                        'Xem Mobile App',
                        style: TextStyle(
                          color: fptOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
