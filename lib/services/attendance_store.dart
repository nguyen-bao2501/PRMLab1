import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'desktop_session.dart';

class AttendanceStore extends ChangeNotifier {
  AttendanceStore(this.api, {bool autoPoll = true, this.session}) {
    if (autoPoll) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) => poll());
    }
  }
  final ApiService api;
  final DesktopSession? session;

  Future<void> restoreSession() async {
    await run(() async {
      final generation = _generation;
      final saved = await session?.read();
      if (saved == null || _disposed || generation != _generation) return;
      Json data;
      try {
        data = jsonDecode(saved) as Json;
        if (data['baseUrl'] != api.baseUrl) return;
        if (data['token'] is! String) throw const FormatException();
      } catch (_) {
        await session?.clear();
        return;
      }
      api.token = data['token'] as String;
      try {
        final profile = await api.me();
        if (_disposed || generation != _generation) return;
        if (profile['role'] != 'TEACHER') {
          await session?.clear();
          throw const ApiException(
            'Chỉ giảng viên mới được phép đăng nhập trên máy tính.',
          );
        }
        user = profile;
        await reload();
      } catch (_) {
        api.token = null;
        user = null;
        rethrow;
      }
    });
  }

  Timer? _timer;
  Json? user, selectedClass, selectedSession;
  List<Json> classes = [], sessions = [], attendances = [];
  bool busy = false, _polling = false, _disposed = false;
  String? error;
  DateTime? lastSync;
  int _generation = 0;
  bool get student => user?['role'] == 'STUDENT';
  bool get open => selectedSession?['status'] == 'OPEN';
  int get present => attendances
      .where((a) => a['status'] == 'PRESENT' || a['status'] == 'LATE')
      .length;
  int get total =>
      (selectedSession?['totalStudents'] as num?)?.toInt() ??
      (selectedClass?['studentCount'] as num?)?.toInt() ??
      0;
  int get remaining => (total - present).clamp(0, total);
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      handleError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void handleError(Object e) {
    if (e is ApiException && e.statusCode == 401) logout();
    error = e is ApiException
        ? e.message
        : 'Không thể hoàn tất thao tác. Vui lòng thử lại.';
    notifyListeners();
  }

  Future<void> authenticate(Future<Json> Function() login) async {
    final data = await login();
    api.token = data['accessToken'] as String;
    try {
      final profile = await api.me();
      if (profile['role'] != 'TEACHER') {
        throw const ApiException(
          'Chỉ giảng viên mới được phép đăng nhập trên máy tính.',
        );
      }
      user = profile;
    } catch (_) {
      api.token = null;
      rethrow;
    }
    try {
      await session?.write(
        jsonEncode({'baseUrl': api.baseUrl, 'token': api.token}),
      );
    } catch (_) {
      error = 'Đã đăng nhập nhưng không thể lưu phiên trên Windows.';
    }
    await reload();
  }

  Future<void> reload() async {
    final generation = _generation;
    if (student) {
      final data = await api.myAttendances();
      if (generation != _generation) return;
      attendances = data;
    } else {
      final data = await api.classes();
      if (generation != _generation) return;
      classes = data;
      if (selectedClass != null) {
        final matches = data.where((c) => c['id'] == selectedClass!['id']);
        if (matches.isEmpty) {
          selectedClass = null;
          selectedSession = null;
          sessions = [];
          attendances = [];
        } else {
          selectedClass = matches.first;
          sessions = await api.sessions(selectedClass!['id'] as int);
        }
      }
    }
    lastSync = DateTime.now();
    notifyListeners();
  }

  Future<void> selectClass(Json item) async {
    final generation = ++_generation;
    selectedClass = item;
    selectedSession = null;
    sessions = [];
    attendances = [];
    notifyListeners();
    final detail = await api.classDetail(item['id'] as int);
    final list = await api.sessions(item['id'] as int);
    if (generation != _generation) return;
    selectedClass = detail;
    sessions = list;
    notifyListeners();
  }

  Future<void> selectSession(Json item) async {
    final generation = ++_generation;
    selectedSession = null;
    attendances = [];
    notifyListeners();
    final detail = await api.session(item['id'] as int);
    final rows = await api.attendances(item['id'] as int);
    if (generation != _generation) return;
    selectedSession = {
      ...detail,
      if (item['qrToken'] != null && detail['status'] == 'OPEN')
        'qrToken': item['qrToken'],
      if (item['qrUrl'] != null && detail['status'] == 'OPEN')
        'qrUrl': item['qrUrl'],
    };
    attendances = rows;
    lastSync = DateTime.now();
    notifyListeners();
  }

  Future<void> refreshQr() async {
    final id = selectedSession!['id'] as int;
    final generation = ++_generation;
    final data = await api.refreshQr(id);
    if (generation != _generation) return;
    selectedSession = {
      ...selectedSession!,
      ...data,
      'totalStudents': selectedSession!['totalStudents'],
    };
    notifyListeners();
  }

  Future<void> closeSession() async {
    ++_generation;
    final id = selectedSession!['id'] as int;
    await api.closeSession(id);
    selectedSession = {
      ...selectedSession!,
      'status': 'CLOSED',
      'qrToken': null,
    };
    notifyListeners();
    await selectSession(selectedSession!);
    sessions = await api.sessions(selectedClass!['id'] as int);
  }

  Future<void> poll() async {
    if (_polling || busy || user == null || student || !open) return;
    _polling = true;
    final generation = _generation;
    final id = selectedSession!['id'] as int;
    try {
      final detail = await api.session(id);
      final rows = await api.attendances(id);
      if (generation != _generation || _disposed) return;
      final token = selectedSession?['qrToken'];
      final qrUrl = selectedSession?['qrUrl'];
      selectedSession = {
        ...detail,
        'qrToken': detail['status'] == 'OPEN' ? token : null,
        'qrUrl': detail['status'] == 'OPEN' ? qrUrl : null,
      };
      attendances = rows;
      lastSync = DateTime.now();
      error = null;
      notifyListeners();
    } catch (e) {
      if (generation == _generation && !_disposed) handleError(e);
    } finally {
      _polling = false;
    }
  }

  void logout() {
    unawaited(
      session?.clear().catchError((Object _) {
        error = 'Không thể xóa phiên đã lưu trên Windows. Vui lòng thử đăng xuất lại.';
        notifyListeners();
      }),
    );
    _generation++;
    api.token = null;
    user = null;
    selectedClass = null;
    selectedSession = null;
    classes = [];
    sessions = [];
    attendances = [];
    error = null;
    lastSync = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    api.dispose();
    super.dispose();
  }
}
