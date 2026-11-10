import 'dart:async';
import 'package:flutter/material.dart';
import '../firebase/firebase_analytics_service.dart';
import '../firebase/firebase_crashlytics_service.dart';
import '../models/app_models.dart';
import '../services/class_repository.dart';

enum AttendanceFilter { all, attended, absent }

class LiveAttendanceViewModel extends ChangeNotifier {
  LiveAttendanceViewModel({
    required ClassRepository repository,
    required FirebaseAnalyticsService analyticsService,
    required FirebaseCrashlyticsService crashlyticsService,
  })  : _repository = repository,
        _analyticsService = analyticsService,
        _crashlyticsService = crashlyticsService;

  final ClassRepository _repository;
  final FirebaseAnalyticsService _analyticsService;
  final FirebaseCrashlyticsService _crashlyticsService;

  SessionModel? _currentSession;
  SessionModel? get currentSession => _currentSession;

  List<StudentAttendanceItem> _allStudents = [];
  List<StudentAttendanceItem> get students => _getFilteredStudents();

  int _countdownSeconds = 45;
  int get countdownSeconds => _countdownSeconds;

  String _qrToken = '';
  String get qrToken => _qrToken;

  AttendanceFilter _currentFilter = AttendanceFilter.all;
  AttendanceFilter get currentFilter => _currentFilter;

  String _searchKeyword = '';
  String get searchKeyword => _searchKeyword;

  Timer? _countdownTimer;

  int get totalCount => _currentSession?.totalCount ?? 35;
  int get attendedCount => _allStudents.where((s) => s.isPresent).length;
  int get absentCount => totalCount - attendedCount;
  double get attendanceRate => totalCount > 0 ? (attendedCount / totalCount) * 100 : 0.0;

  void initialize(SessionModel session) {
    _currentSession = session;
    _qrToken = session.qrToken ?? 'PRM393_${session.className}_${DateTime.now().millisecondsSinceEpoch}';
    _currentFilter = AttendanceFilter.all;
    _searchKeyword = '';
    _countdownSeconds = 45;

    _loadStudentList();
    _startTimer();

    _analyticsService.logStartAttendance(
      sessionId: session.id,
      slot: session.slot,
      room: session.room,
    );
  }

  Future<void> _loadStudentList() async {
    final session = _currentSession;
    if (session == null) return;
    try {
      final students = await _repository.getLiveAttendance(session.id);
      // A previous screen can finish loading after another session is opened.
      // Do not let that stale response replace the current session's roster.
      if (_currentSession?.id != session.id) return;
      _allStudents = students;
      notifyListeners();
    } catch (e, stack) {
      await _crashlyticsService.recordNonFatalError(e, stack, reason: 'Failed to load live attendance');
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        refreshQr();
      }
    });
  }

  void refreshQr() {
    _countdownSeconds = 45;
    _qrToken = 'PRM393_${_currentSession?.className ?? "SE1917"}_${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
  }

  void setFilter(AttendanceFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword.trim().toLowerCase();
    notifyListeners();
  }

  List<StudentAttendanceItem> _getFilteredStudents() {
    var list = _allStudents;

    if (_currentFilter == AttendanceFilter.attended) {
      list = list.where((s) => s.isPresent).toList();
    } else if (_currentFilter == AttendanceFilter.absent) {
      list = list.where((s) => !s.isPresent).toList();
    }

    if (_searchKeyword.isNotEmpty) {
      list = list.where((s) =>
        s.name.toLowerCase().contains(_searchKeyword) ||
        s.studentId.toLowerCase().contains(_searchKeyword)
      ).toList();
    }

    return list;
  }

  Future<void> updateStudentStatus(String studentId, bool isPresent) async {
    if (_currentSession == null) return;
    await _repository.updateStudentStatus(_currentSession!.id, studentId, isPresent);
    final index = _allStudents.indexWhere((s) => s.studentId == studentId);
    if (index != -1) {
      _allStudents[index] = _allStudents[index].copyWith(
        isPresent: isPresent,
        checkInTime: isPresent ? '07:25:00' : null,
      );
      notifyListeners();
    }
  }

  Future<void> finalizeAttendance() async {
    if (_currentSession == null) return;
    _countdownTimer?.cancel();
    await _repository.finalizeAttendanceSession(_currentSession!.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
