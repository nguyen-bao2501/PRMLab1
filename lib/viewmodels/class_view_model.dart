import 'package:flutter/material.dart';
import '../firebase/firebase_analytics_service.dart';
import '../models/app_models.dart';
import '../models/ui_state.dart';
import '../services/class_repository.dart';

class ClassViewModel extends ChangeNotifier {
  ClassViewModel({
    required ClassRepository repository,
    required FirebaseAnalyticsService analyticsService,
  })  : _repository = repository,
        _analyticsService = analyticsService;

  final ClassRepository _repository;
  final FirebaseAnalyticsService _analyticsService;

  UiState<List<ClassModel>> _classesState = const UiInitial();
  UiState<List<ClassModel>> get classesState => _classesState;

  ClassModel? _selectedClass;
  ClassModel? get selectedClass => _selectedClass;

  List<AbsentSummaryItem> _topAbsentStudents = [];
  List<AbsentSummaryItem> get topAbsentStudents => _topAbsentStudents;

  String? _detailError;
  String? get detailError => _detailError;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // For Stepper in 03.03 (Import from Sheet)
  int _importStep = 0;
  int get importStep => _importStep;
  String _sheetUrl = '';
  String get sheetUrl => _sheetUrl;
  List<String> _availableTabs = [];
  List<String> get availableTabs => _availableTabs;
  String? _selectedTab;
  String? get selectedTab => _selectedTab;
  bool _isImporting = false;
  bool get isImporting => _isImporting;
  int _importedCount = 0;
  int get importedCount => _importedCount;

  Future<void> loadClasses({String? query}) async {
    _classesState = const UiLoading('Đang tải danh sách lớp học...');
    _searchQuery = query ?? '';
    notifyListeners();

    try {
      final classes = await _repository.getClasses(query: _searchQuery);
      if (classes.isEmpty) {
        _classesState = const UiEmpty('Không tìm thấy lớp học nào phù hợp.');
      } else {
        _classesState = UiSuccess(classes);
      }
      if (_searchQuery.isNotEmpty) {
        await _analyticsService.logSearchClasses(
          searchTerm: _searchQuery,
          resultCount: classes.length,
        );
      }
      notifyListeners();
    } catch (e) {
      _classesState = UiError('Không thể tải danh sách lớp học', e);
      notifyListeners();
    }
  }

  void searchClasses(String query) {
    _searchQuery = query;
    loadClasses(query: query);
  }

  Future<void> selectClass(ClassModel classItem) async {
    _selectedClass = classItem;
    _topAbsentStudents = [];
    _detailError = null;
    await _analyticsService.logViewClassDetail(
      classId: classItem.id,
      subjectCode: classItem.subjectCode,
    );
    try {
      _topAbsentStudents = await _repository.getTopAbsentStudents(classItem.id);
    } catch (_) {
      _detailError = 'Không thể tải danh sách sinh viên vắng nhiều.';
    }
    notifyListeners();
  }

  void startImportFlow(ClassModel classItem) {
    _selectedClass = classItem;
    _importStep = 0;
    _sheetUrl = classItem.sheetUrl ?? 'https://docs.google.com/spreadsheets/d/1BxiM/v';
    _availableTabs = [];
    _selectedTab = null;
    _isImporting = false;
    _importedCount = 0;
    notifyListeners();
  }

  void setSheetUrl(String url) {
    _sheetUrl = url;
    notifyListeners();
  }

  Future<bool> fetchSheetTabs() async {
    _isImporting = true;
    notifyListeners();
    try {
      _availableTabs = await _repository.fetchSheetTabs(_sheetUrl);
      if (_availableTabs.isNotEmpty) {
        _selectedTab = _availableTabs.first;
      }
      _importStep = 1;
      _isImporting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isImporting = false;
      notifyListeners();
      return false;
    }
  }

  void selectSheetTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  Future<bool> completeImport() async {
    if (_selectedClass == null || _selectedTab == null) return false;
    _isImporting = true;
    notifyListeners();
    try {
      _importedCount = await _repository.importStudentsFromSheet(
        _selectedClass!.id,
        _sheetUrl,
        _selectedTab!,
      );
      _importStep = 2;
      _isImporting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isImporting = false;
      notifyListeners();
      return false;
    }
  }
}
