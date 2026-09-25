import 'api_service.dart';

class SheetImportResult {
  const SheetImportResult(
    this.tab, {
    this.imported = 0,
    this.skipped = 0,
    this.error,
  });
  final String tab;
  final int imported, skipped;
  final String? error;
  bool get success => error == null;
}

/// Uses existing class/create/import endpoints, one tab at a time.
/// Keeping the full tab name as class code separates subjects in the same cohort.
class SheetClassImporter {
  SheetClassImporter(this.api);
  final ApiService api;

  static String spreadsheetId(String input) {
    final value = input.trim();
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      if (uri.scheme != 'https' || uri.host != 'docs.google.com') {
        throw const ApiException(
          'Vui lòng nhập đường dẫn Google Sheet hoặc ID spreadsheet.',
        );
      }
      final match = RegExp(r'^/spreadsheets/d/([a-zA-Z0-9_-]+)(?:/|$)')
          .firstMatch(uri.path);
      if (match != null) return match.group(1)!;
    } else if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return value;
    }
    throw const ApiException('Không tìm thấy ID Google Sheet hợp lệ.');
  }

  Future<List<SheetImportResult>> importTabs({
    required String spreadsheetId,
    required List<Json> tabs,
    String semester = '',
    void Function(int completed, String tab)? onProgress,
  }) async {
    final classes = await api.classes();
    final results = <SheetImportResult>[];
    for (final tab in tabs) {
      final name = tab['sheetName']?.toString().trim() ?? '';
      final subject = tab['subjectCode']?.toString().trim() ?? '';
      onProgress?.call(results.length, name);
      if (name.isEmpty || subject.isEmpty) {
        results.add(
          SheetImportResult(
            name,
            error: 'Chưa xác định mã môn. Điền mã môn trong danh sách tab rồi nhập lại.',
          ),
        );
        continue;
      }
      try {
        // Never overwrite another spreadsheet's mapping just because a tab name matches.
        final mapped = classes
            .where(
              (c) =>
                  c['spreadsheetId'] == spreadsheetId && c['sheetName'] == name,
            )
            .toList();
        if (mapped.length > 1)
          throw const ApiException(
            'Tab đang liên kết với nhiều lớp. Vui lòng kiểm tra các lớp trước khi nhập.',
          );
        Json? classroom = mapped.isEmpty ? null : mapped.single;
        if (classroom == null) {
          final sameCode = classes
              .where((c) => c['classCode'] == name)
              .toList();
          if (sameCode.length > 1) {
            throw const ApiException(
              'Có nhiều lớp cùng mã ở các môn/học kỳ. Chọn đúng lớp và nhập Sheet từ chi tiết lớp.',
            );
          }
          if (sameCode.isNotEmpty) {
            final existing = sameCode.single;
            final existingSid = existing['spreadsheetId']?.toString();
            if (existingSid != null && existingSid.isNotEmpty && existingSid != spreadsheetId) {
              throw const ApiException(
                'Tên lớp đã tồn tại hoặc đang liên kết Sheet khác. Đổi tên tab để tạo lớp riêng.',
              );
            }
            classroom = existing;
          } else {
            classroom = await api.createClass({
              'classCode': name,
              'subjectCode': subject,
              if (semester.isNotEmpty) 'semester': semester,
            });
            classes.add(classroom);
          }
        }
        final result = await api.importSheet(
          classroom['id'] as int,
          spreadsheetId,
          name,
        );
        classroom['spreadsheetId'] = spreadsheetId;
        classroom['sheetName'] = name;
        results.add(
          SheetImportResult(
            name,
            imported: (result['rowsImported'] as num?)?.toInt() ?? 0,
            skipped: (result['rowsSkipped'] as num?)?.toInt() ?? 0,
          ),
        );
      } on ApiException catch (e) {
        results.add(SheetImportResult(name, error: e.message));
        if (e.statusCode == 401 || e.statusCode == 403) {
          for (final pending in tabs.skip(results.length)) {
            results.add(
              SheetImportResult(
                pending['sheetName']?.toString() ?? '',
                error: 'Chưa nhập: cần kiểm tra lại quyền đăng nhập.',
              ),
            );
          }
          break;
        }
      }
    }
    onProgress?.call(results.length, 'Hoàn tất');
    return results;
  }
}
