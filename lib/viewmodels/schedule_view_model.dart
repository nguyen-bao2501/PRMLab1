import 'package:flutter/material.dart';
import '../firebase/firebase_analytics_service.dart';
import '../models/app_models.dart';
import '../models/ui_state.dart';
import '../services/class_repository.dart';

class ScheduleViewModel extends ChangeNotifier {
  ScheduleViewModel({
    required ClassRepository repository,
    required FirebaseAnalyticsService analyticsService,
  })  : _repository = repository,
        _analyticsService = analyticsService;

  final ClassRepository _repository;
  final FirebaseAnalyticsService _analyticsService;

  UiState<List<SessionModel>> _scheduleState = const UiInitial();
  UiState<List<SessionModel>> get scheduleState => _scheduleState;

  DateTime _selectedDate = DateTime(2026, 10, 3); // 03/10/2026 matching Figma
  DateTime get selectedDate => _selectedDate;

  SessionModel? _selectedSession;
  SessionModel? get selectedSession => _selectedSession;

  final List<DateTime> weekDays = [
    DateTime(2026, 9, 28), // T2
    DateTime(2026, 9, 29), // T3
    DateTime(2026, 9, 30), // T4
    DateTime(2026, 10, 1), // T5
    DateTime(2026, 10, 2), // T6
    DateTime(2026, 10, 3), // T7 (default)
    DateTime(2026, 10, 4), // CN
  ];

  Future<void> loadSchedule([DateTime? date]) async {
    if (date != null) _selectedDate = date;
    _scheduleState = const UiLoading('Đang tải lịch giảng dạy...');
    notifyListeners();

    try {
      final dateFormatted = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
      final sessions = await _repository.getScheduleByDate(dateFormatted);

      if (sessions.isEmpty) {
        _scheduleState = const UiEmpty('Không có lịch dạy cho ngày này.');
      } else {
        _scheduleState = UiSuccess(sessions);
      }

      await _analyticsService.logViewSchedule(
        selectedDate: dateFormatted,
        sessionCount: sessions.length,
      );
      notifyListeners();
    } catch (e) {
      _scheduleState = UiError('Không thể tải lịch dạy', e);
      notifyListeners();
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    loadSchedule(date);
  }

  void selectSession(SessionModel session) {
    _selectedSession = session;
    notifyListeners();
  }

  Future<bool> createNewSessionSchedule({
    required ClassModel classItem,
    required DateTime date,
    required int slot,
    required String timeRange,
    required String room,
  }) async {
    try {
      final dateFormatted = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      final newSession = SessionModel(
        id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
        classId: classItem.id,
        subjectCode: classItem.subjectCode,
        className: classItem.className,
        room: room,
        slot: slot,
        timeRange: timeRange,
        date: dateFormatted,
        dayOfWeek: _dayOfWeekString(date.weekday),
        status: SessionStatus.upcoming,
        attendedCount: 0,
        totalCount: classItem.studentCount,
      );

      await _repository.createSchedule(newSession);
      await loadSchedule(_selectedDate);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _dayOfWeekString(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'T2';
      case DateTime.tuesday: return 'T3';
      case DateTime.wednesday: return 'T4';
      case DateTime.thursday: return 'T5';
      case DateTime.friday: return 'T6';
      case DateTime.saturday: return 'T7';
      default: return 'CN';
    }
  }
}
