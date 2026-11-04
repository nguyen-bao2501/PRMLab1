import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase/firebase_analytics_service.dart';
import 'firebase/firebase_auth_service.dart';
import 'firebase/firebase_crashlytics_service.dart';
import 'firebase/firebase_notification_service.dart';
import 'firebase/firebase_remote_config_service.dart';
import 'firebase/firebase_storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/class_repository.dart';
import 'theme/app_theme.dart';
import 'viewmodels/auth_view_model.dart';
import 'viewmodels/class_view_model.dart';
import 'viewmodels/dashboard_view_model.dart';
import 'viewmodels/firebase_demo_view_model.dart';
import 'viewmodels/live_attendance_view_model.dart';
import 'viewmodels/report_view_model.dart';
import 'viewmodels/schedule_view_model.dart';

const fptOrange = Color(0xFFF37021);
const ink = Color(0xFF3A504E);
const muted = Color(0xFF8B9D9B);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely with try-catch so it won't crash if google-services.json is pending)
  try {
    await Firebase.initializeApp();
    if (Firebase.apps.isNotEmpty) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Firebase.initializeApp() note: $e');
  }

  // Initialize Core Services
  final apiService = ApiService();
  final classRepository = AppClassRepository(apiService: apiService);

  final authService = FirebaseAuthService();
  final storageService = FirebaseStorageService();
  final notificationService = FirebaseNotificationService();
  final analyticsService = FirebaseAnalyticsService();
  final crashlyticsService = FirebaseCrashlyticsService();
  final remoteConfigService = FirebaseRemoteConfigService();

  // Pre-initialize Firebase background/config services
  await authService.initialize();
  await remoteConfigService.initialize();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        // Services Injection
        Provider<ApiService>.value(value: apiService),
        Provider<ClassRepository>.value(value: classRepository),
        Provider<FirebaseAuthService>.value(value: authService),
        Provider<FirebaseStorageService>.value(value: storageService),
        Provider<FirebaseNotificationService>.value(value: notificationService),
        Provider<FirebaseAnalyticsService>.value(value: analyticsService),
        Provider<FirebaseCrashlyticsService>.value(value: crashlyticsService),
        Provider<FirebaseRemoteConfigService>.value(value: remoteConfigService),

        // ViewModels Injection
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authService: authService,
            analyticsService: analyticsService,
          )..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            repository: classRepository,
            remoteConfigService: remoteConfigService,
            analyticsService: analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ClassViewModel(
            repository: classRepository,
            analyticsService: analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleViewModel(
            repository: classRepository,
            analyticsService: analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => LiveAttendanceViewModel(
            repository: classRepository,
            analyticsService: analyticsService,
            crashlyticsService: crashlyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportViewModel(
            repository: classRepository,
            storageService: storageService,
            authService: authService,
            analyticsService: analyticsService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => FirebaseDemoViewModel(
            authService: authService,
            storageService: storageService,
            notificationService: notificationService,
            analyticsService: analyticsService,
            crashlyticsService: crashlyticsService,
            remoteConfigService: remoteConfigService,
          ),
        ),
      ],
      child: const PRMApp(),
    ),
  );
}

class PRMApp extends StatelessWidget {
  const PRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return MaterialApp(
      title: 'FPT University • Điểm danh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authVm.isAuthenticated ? const DashboardScreen() : const LoginScreen(),
    );
  }
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key, this.store, this.googleSignIn});
  final dynamic store;
  final dynamic googleSignIn;

  @override
  Widget build(BuildContext context) => const PRMApp();
}
