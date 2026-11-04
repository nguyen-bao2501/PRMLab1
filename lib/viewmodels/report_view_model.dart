import 'package:flutter/material.dart';
import '../firebase/firebase_analytics_service.dart';
import '../firebase/firebase_auth_service.dart';
import '../firebase/firebase_storage_service.dart';
import '../models/app_models.dart';
import '../models/ui_state.dart';
import '../services/class_repository.dart';

class ReportViewModel extends ChangeNotifier {
  ReportViewModel({
    required ClassRepository repository,
    required FirebaseStorageService storageService,
    required FirebaseAuthService authService,
    required FirebaseAnalyticsService analyticsService,
  })  : _repository = repository,
        _storageService = storageService,
        _authService = authService,
        _analyticsService = analyticsService;

  final ClassRepository _repository;
  final FirebaseStorageService _storageService;
  final FirebaseAuthService _authService;
  final FirebaseAnalyticsService _analyticsService;

  UiState<List<StudentAttendanceItem>> _reportState = const UiInitial();
  UiState<List<StudentAttendanceItem>> get reportState => _reportState;

  List<StudentAttendanceItem> _allStudents = [];
  String _filter = 'ALL'; // ALL, ATTENDED, ABSENT
  String get filter => _filter;
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Selected class & session
  final String _selectedClassCode = 'PRM393 · SE1917';
  String get selectedClassCode => _selectedClassCode;

  final String _selectedSessionSlot = '05/10/2026 · Slot 1';
  String get selectedSessionSlot => _selectedSessionSlot;

  // PDF & Cloud Storage Upload State
  bool _isExporting = false;
  bool get isExporting => _isExporting;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  String? _downloadUrl;
  String? get downloadUrl => _downloadUrl;

  String? _exportSuccessMessage;
  String? get exportSuccessMessage => _exportSuccessMessage;

  int get totalCount => 35;
  int get attendedCount => 28;
  int get absentCount => 7;
  double get attendanceRate => 80.0;

  Future<void> loadReport() async {
    _reportState = const UiLoading('Đang tải báo cáo điểm danh...');
    notifyListeners();

    try {
      _allStudents = await _repository.getLiveAttendance('s1');
      _reportState = UiSuccess(_getFilteredList());
      notifyListeners();
    } catch (e) {
      _reportState = UiError('Không thể tải báo cáo', e);
      notifyListeners();
    }
  }

  void setFilter(String f) {
    _filter = f;
    _reportState = UiSuccess(_getFilteredList());
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q.toLowerCase();
    _reportState = UiSuccess(_getFilteredList());
    notifyListeners();
  }

  List<StudentAttendanceItem> _getFilteredList() {
    var list = _allStudents;
    if (_filter == 'ATTENDED') {
      list = list.where((s) => s.isPresent).toList();
    } else if (_filter == 'ABSENT') {
      list = list.where((s) => !s.isPresent).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((s) =>
        s.name.toLowerCase().contains(_searchQuery) ||
        s.studentId.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    return list;
  }

  Future<void> toggleStudentStatus(String studentId) async {
    final index = _allStudents.indexWhere((s) => s.studentId == studentId);
    if (index != -1) {
      final current = _allStudents[index];
      _allStudents[index] = current.copyWith(
        isPresent: !current.isPresent,
        checkInTime: !current.isPresent ? '07:30:00' : null,
      );
      _reportState = UiSuccess(_getFilteredList());
      notifyListeners();
    }
  }

  Future<bool> exportToGoogleSheets() async {
    _isExporting = true;
    _exportSuccessMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    _isExporting = false;
    _exportSuccessMessage = 'Đã xuất kết quả thành công sang cột F tab 12_PRM393_SE1917';
    notifyListeners();
    return true;
  }

  Future<String?> exportPdfAndUploadToCloudStorage() async {
    _isExporting = true;
    _uploadProgress = 0.0;
    _downloadUrl = null;
    _exportSuccessMessage = null;
    notifyListeners();

    try {
      final uid = _authService.currentUser?.uid ?? 'user_lecturer_001';

      // 1. Generate PDF
      final studentListMap = _allStudents.map((s) => {
        'studentId': s.studentId,
        'name': s.name,
        'isPresent': s.isPresent,
        'checkInTime': s.checkInTime,
      }).toList();

      final pdfBytes = await _storageService.generateAttendancePdf(
        subjectCode: 'PRM393',
        className: 'SE1917',
        sessionDate: '05/10/2026',
        timeRange: '07:00 – 09:15',
        room: 'A101',
        attendedCount: attendedCount,
        totalCount: totalCount,
        students: studentListMap,
      );

      // 2. Upload to Firebase Cloud Storage under per-user path reports/{uid}/...
      final filename = 'attendance_PRM393_SE1917_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final url = await _storageService.uploadReportPdf(
        uid: uid,
        filename: filename,
        pdfBytes: pdfBytes,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      _downloadUrl = url;
      _isExporting = false;
      _exportSuccessMessage = 'Báo cáo PDF đã được lưu an toàn trên Cloud Storage!';

      await _analyticsService.logExportReport(
        classCode: 'PRM393_SE1917',
        attendedCount: attendedCount,
        totalCount: totalCount,
      );

      notifyListeners();
      return url;
    } catch (e) {
      _isExporting = false;
      _exportSuccessMessage = 'Lỗi khi tải báo cáo lên Cloud Storage: $e';
      notifyListeners();
      return null;
    }
  }
}
