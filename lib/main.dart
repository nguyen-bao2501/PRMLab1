import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'services/attendance_store.dart';

void main() => runApp(const AttendanceApp());
const fptOrange = Color(0xFFF37021);
const ink = Color(0xFF192B3D);
const muted = Color(0xFF768393);

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key, this.store});
  final AttendanceStore? store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FPT University • Điểm danh',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      colorScheme: ColorScheme.fromSeed(
        seedColor: fptOrange,
        primary: fptOrange,
        surface: Colors.white,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink),
        titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w700),
      ),
      dividerColor: const Color(0xFFE9EDF2),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
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
    home: DashboardScreen(store: store),
  );
}
