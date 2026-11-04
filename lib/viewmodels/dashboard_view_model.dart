import 'dart:async';
import 'package:flutter/material.dart';
import '../firebase/firebase_analytics_service.dart';
import '../firebase/firebase_remote_config_service.dart';
import '../models/app_models.dart';
import '../models/ui_state.dart';
import '../services/class_repository.dart';

class DashboardData {
  const DashboardData({
    required this.todaySessions,
    required this.upcomingSessions,
    required this.activeSessionsCount,
    required this.lastUpdated,
  });

  final List<SessionModel> todaySessions;
  final List<SessionModel> upcomingSessions;
  final int activeSessionsCount;
  final String lastUpdated;
}

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required ClassRepository repository,
    required FirebaseRemoteConfigService remoteConfigService,
    required FirebaseAnalyticsService analyticsService,
  })  : _repository = repository,
        _remoteConfigService = remoteConfigService,
        _analyticsService = analyticsService;

  final ClassRepository _repository;
  final FirebaseRemoteConfigService _remoteConfigService;
  final FirebaseAnalyticsService _analyticsService;

  UiState<DashboardData> _state = const UiInitial();
  UiState<DashboardData> get state => _state;

  bool _autoSyncEnabled = true;
  bool get autoSyncEnabled => _autoSyncEnabled;

  Timer? _syncTimer;

  bool get isOcrEnabled => _remoteConfigService.isOcrFeatureEnabled;
  int get syncIntervalSeconds => _remoteConfigService.syncIntervalSeconds;
  String get bannerText => _remoteConfigService.announcementBannerText;

  Future<void> loadDashboard() async {
    _state = const UiLoading('Đang tải dữ liệu giảng dạy...');
    notifyListeners();

    try {
      final today = await _repository.getTodaySessions();
      final upcoming = await _repository.getUpcomingSessions();
      final activeCount = today.where((s) => s.status == SessionStatus.active).length;

      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      _state = UiSuccess(
        DashboardData(
          todaySessions: today,
          upcomingSessions: upcoming,
          activeSessionsCount: activeCount,
          lastUpdated: timeStr,
        ),
      );
      _setupAutoSync();
      await _analyticsService.logViewSchedule(selectedDate: 'Hôm nay', sessionCount: today.length);
      notifyListeners();
    } catch (e) {
      _state = UiError('Không thể tải tổng quan giảng dạy', e);
      notifyListeners();
    }
  }

  void toggleAutoSync(bool value) {
    _autoSyncEnabled = value;
    if (_autoSyncEnabled) {
      _setupAutoSync();
    } else {
      _syncTimer?.cancel();
    }
    notifyListeners();
  }

  void _setupAutoSync() {
    _syncTimer?.cancel();
    if (!_autoSyncEnabled) return;

    _syncTimer = Timer.periodic(Duration(seconds: syncIntervalSeconds), (_) {
      syncNow();
    });
  }

  Future<void> syncNow() async {
    try {
      final today = await _repository.getTodaySessions();
      final upcoming = await _repository.getUpcomingSessions();
      final activeCount = today.where((s) => s.status == SessionStatus.active).length;
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      _state = UiSuccess(
        DashboardData(
          todaySessions: today,
          upcomingSessions: upcoming,
          activeSessionsCount: activeCount,
          lastUpdated: timeStr,
        ),
      );
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}
