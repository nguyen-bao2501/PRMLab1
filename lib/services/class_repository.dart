import 'dart:async';
import '../models/app_models.dart';
import 'api_service.dart';

abstract class ClassRepository {
  Future<List<ClassModel>> getClasses({String? semester, String? query});
  Future<ClassModel> getClassDetail(String classId);
  Future<List<SessionModel>> getTodaySessions();
  Future<List<SessionModel>> getUpcomingSessions();
  Future<List<SessionModel>> getScheduleByDate(String date);
  Future<SessionModel> createSchedule(SessionModel session);
  Future<List<String>> fetchSheetTabs(String sheetUrl);
  Future<int> importStudentsFromSheet(String classId, String sheetUrl, String tabName);
  Future<List<StudentAttendanceItem>> getLiveAttendance(String sessionId);
  Future<void> updateStudentStatus(String sessionId, String studentId, bool isPresent);
  Future<void> finalizeAttendanceSession(String sessionId);
  Future<List<AbsentSummaryItem>> getTopAbsentStudents(String classId);
}

class AppClassRepository implements ClassRepository {
  AppClassRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  // In-memory cache & mock fallback data matching Figma designs
  final List<ClassModel> _cachedClasses = [
    const ClassModel(
      id: 'c1',
      subjectCode: 'PRM393',
      className: 'SE1917',
      semester: 'FA2026',
      studentCount: 35,
      sessionCount: 8,
      sheetUrl: 'https://docs.google.com/spreadsheets/d/1BxiM/v',
      sheetTab: '12_PRM393_SE1917',
      isLinkedSheet: true,
    ),
    const ClassModel(
      id: 'c2',
      subjectCode: 'PRN232',
      className: 'SE1918',
      semester: 'FA2026',
      studentCount: 32,
      sessionCount: 6,
      sheetUrl: 'https://docs.google.com/spreadsheets/d/1BxiM/v',
      sheetTab: '10_PRN232_SE1918',
      isLinkedSheet: true,
    ),
    const ClassModel(
      id: 'c3',
      subjectCode: 'SWP391',
      className: 'SE1908',
      semester: 'FA2026',
      studentCount: 0,
      sessionCount: 0,
      sheetUrl: null,
      sheetTab: null,
      isLinkedSheet: false,
    ),
  ];

  final List<SessionModel> _sessions = [
    const SessionModel(
      id: 's1',
      classId: 'c1',
      subjectCode: 'PRM393',
      className: 'SE1917',
      room: 'A101',
      slot: 2,
      timeRange: 'Slot 2 · 09:30 – 11:45',
      date: '03/10/2026',
      dayOfWeek: 'T7',
      status: SessionStatus.active,
      qrToken: 'PRM393_TOKEN_ACTIVE_2026_001',
      attendedCount: 28,
      totalCount: 35,
    ),
    const SessionModel(
      id: 's2',
      classId: 'c2',
      subjectCode: 'PRN232',
      className: 'SE1918',
      room: 'A203',
      slot: 3,
      timeRange: 'Slot 3 · 12:30 – 14:45',
      date: '03/10/2026',
      dayOfWeek: 'T7',
      status: SessionStatus.upcoming,
      attendedCount: 0,
      totalCount: 32,
    ),
    const SessionModel(
      id: 's3',
      classId: 'c1',
      subjectCode: 'PRM393',
      className: 'SE1917',
      room: 'A101',
      slot: 1,
      timeRange: 'Slot 1 · 07:00 – 09:15',
      date: '04/10/2026',
      dayOfWeek: 'CN',
      status: SessionStatus.upcoming,
      attendedCount: 0,
      totalCount: 35,
    ),
    const SessionModel(
      id: 's4',
      classId: 'c1',
      subjectCode: 'PRM393',
      className: 'SE1917',
      room: 'A101',
      slot: 2,
      timeRange: 'Slot 2 · 09:30 – 11:45',
      date: '06/10/2026',
      dayOfWeek: 'T2',
      status: SessionStatus.upcoming,
      attendedCount: 0,
      totalCount: 35,
    ),
  ];

  final List<StudentAttendanceItem> _students = [
    const StudentAttendanceItem(
      studentId: 'SE190003',
      name: 'Lê Ngọc Chi',
      isPresent: true,
      checkInTime: '07:22:45',
    ),
    const StudentAttendanceItem(
      studentId: 'SE190012',
      name: 'Đặng Quốc Bảo',
      isPresent: true,
      checkInTime: '07:15:50',
    ),
    const StudentAttendanceItem(
      studentId: 'SE190008',
      name: 'Vũ Thị Mai',
      isPresent: true,
      checkInTime: '07:11:33',
    ),
    const StudentAttendanceItem(
      studentId: 'SE190005',
      name: 'Hoàng Đức Anh',
      isPresent: true,
      checkInTime: '07:08:19',
    ),
    const StudentAttendanceItem(
      studentId: 'SE190002',
      name: 'Trần Minh Bình',
      isPresent: true,
      checkInTime: '07:07:02',
    ),
    const StudentAttendanceItem(
      studentId: 'SE190001',
      name: 'Nguyễn Văn An',
      isPresent: true,
      checkInTime: '07:05:12',
    ),
    const StudentAttendanceItem(
      studentId: 'SE190006',
      name: 'Hoàng Minh Đức',
      isPresent: false,
      checkInTime: null,
    ),
  ];

  @override
  Future<List<ClassModel>> getClasses({String? semester, String? query}) async {
    try {
      final res = await _apiService.classes();
      if (res.isNotEmpty) {
        return res.map((e) => ClassModel.fromJson(e)).toList();
      }
    } catch (_) {
      // Fallback
    }

    var list = List<ClassModel>.from(_cachedClasses);
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((c) =>
        c.subjectCode.toLowerCase().contains(q) ||
        c.className.toLowerCase().contains(q) ||
        c.semester.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  @override
  Future<ClassModel> getClassDetail(String classId) async {
    return _cachedClasses.firstWhere(
      (c) => c.id == classId || c.subjectCode == classId,
      orElse: () => _cachedClasses.first,
    );
  }

  @override
  Future<List<SessionModel>> getTodaySessions() async {
    return _sessions.where((s) => s.date == '03/10/2026').toList();
  }

  @override
  Future<List<SessionModel>> getUpcomingSessions() async {
    return _sessions.where((s) => s.date != '03/10/2026').toList();
  }

  @override
  Future<List<SessionModel>> getScheduleByDate(String date) async {
    final list = _sessions.where((s) => s.date == date).toList();
    if (list.isEmpty) {
      return [
        SessionModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          classId: 'c1',
          subjectCode: 'PRM393',
          className: 'SE1917',
          room: 'A101',
          slot: 1,
          timeRange: 'Slot 1 · 07:00 – 09:15',
          date: date,
          dayOfWeek: 'T',
          status: SessionStatus.upcoming,
        ),
      ];
    }
    return list;
  }

  @override
  Future<SessionModel> createSchedule(SessionModel session) async {
    _sessions.add(session);
    return session;
  }

  @override
  Future<List<String>> fetchSheetTabs(String sheetUrl) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return ['12_PRM393_SE1917', '10_PRN232_SE1918', 'Danh_Sach_Tong_Hop'];
  }

  @override
  Future<int> importStudentsFromSheet(String classId, String sheetUrl, String tabName) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return 35; // 35 students imported
  }

  @override
  Future<List<StudentAttendanceItem>> getLiveAttendance(String sessionId) async {
    return List.from(_students);
  }

  @override
  Future<void> updateStudentStatus(String sessionId, String studentId, bool isPresent) async {
    final index = _students.indexWhere((s) => s.studentId == studentId);
    if (index != -1) {
      _students[index] = _students[index].copyWith(
        isPresent: isPresent,
        checkInTime: isPresent ? '07:25:00' : null,
      );
    }
  }

  @override
  Future<void> finalizeAttendanceSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Future<List<AbsentSummaryItem>> getTopAbsentStudents(String classId) async {
    return const [
      AbsentSummaryItem(
        studentId: 'SE190901',
        name: 'Nguyễn Văn An',
        absentCount: 5,
        totalSessions: 6,
        percent: 83.3,
      ),
      AbsentSummaryItem(
        studentId: 'SE190902',
        name: 'Trần Minh Bình',
        absentCount: 4,
        totalSessions: 6,
        percent: 66.7,
      ),
      AbsentSummaryItem(
        studentId: 'SE190903',
        name: 'Lê Ngọc Chi',
        absentCount: 1,
        totalSessions: 6,
        percent: 16.7,
      ),
      AbsentSummaryItem(
        studentId: 'SE190904',
        name: 'Phạm Gia Duy',
        absentCount: 1,
        totalSessions: 6,
        percent: 16.7,
      ),
    ];
  }
}
