import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class FirebaseRemoteConfigService {
  FirebaseRemoteConfigService({FirebaseRemoteConfig? remoteConfig}) : _remoteConfig = remoteConfig;

  final FirebaseRemoteConfig? _remoteConfig;

  bool _isOcrFeatureEnabled = true;
  int _syncIntervalSeconds = 30;
  String _announcementBannerText = 'Chào mừng học kỳ mới FA2026 - Điểm danh đúng giờ!';
  int _maxRecentClasses = 5;

  bool get isOcrFeatureEnabled => _isOcrFeatureEnabled;
  int get syncIntervalSeconds => _syncIntervalSeconds;
  String get announcementBannerText => _announcementBannerText;
  int get maxRecentClasses => _maxRecentClasses;

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseRemoteConfig get remoteConfigInstance => _remoteConfig ?? FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    final defaults = <String, dynamic>{
      'feature_ocr_schedule_enabled': true,
      'sync_interval_seconds': 30,
      'announcement_banner_text': 'Chào mừng học kỳ mới FA2026 - Điểm danh đúng giờ!',
      'max_recent_classes_display': 5,
    };

    if (_isFirebaseReady) {
      try {
        await remoteConfigInstance.setConfigSettings(
          RemoteConfigSettings(
            fetchTimeout: const Duration(seconds: 10),
            minimumFetchInterval: const Duration(seconds: 0), // Allow fast refresh for demo/testing
          ),
        );
        await remoteConfigInstance.setDefaults(defaults);
        await fetchAndActivate();
      } catch (e) {
        debugPrint('RemoteConfig setup error: $e');
        _applyDefaults(defaults);
      }
    } else {
      _applyDefaults(defaults);
    }
  }

  void _applyDefaults(Map<String, dynamic> defaults) {
    _isOcrFeatureEnabled = defaults['feature_ocr_schedule_enabled'] as bool? ?? true;
    _syncIntervalSeconds = defaults['sync_interval_seconds'] as int? ?? 30;
    _announcementBannerText = defaults['announcement_banner_text'] as String? ?? '';
    _maxRecentClasses = defaults['max_recent_classes_display'] as int? ?? 5;
  }

  Future<bool> fetchAndActivate() async {
    if (_isFirebaseReady) {
      try {
        final updated = await remoteConfigInstance.fetchAndActivate();
        _isOcrFeatureEnabled = remoteConfigInstance.getBool('feature_ocr_schedule_enabled');
        _syncIntervalSeconds = remoteConfigInstance.getInt('sync_interval_seconds');
        _announcementBannerText = remoteConfigInstance.getString('announcement_banner_text');
        _maxRecentClasses = remoteConfigInstance.getInt('max_recent_classes_display');
        debugPrint('[RemoteConfig] Fetched! OCR: $_isOcrFeatureEnabled, SyncInterval: $_syncIntervalSeconds s');
        return updated;
      } catch (e) {
        debugPrint('RemoteConfig fetch error: $e');
      }
    }
    return false;
  }

  // Helper method for demo live testing
  void setMockValues({bool? ocrEnabled, int? syncInterval, String? banner}) {
    if (ocrEnabled != null) _isOcrFeatureEnabled = ocrEnabled;
    if (syncInterval != null) _syncIntervalSeconds = syncInterval;
    if (banner != null) _announcementBannerText = banner;
  }
}
