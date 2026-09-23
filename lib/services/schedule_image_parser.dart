import 'api_service.dart';

class OcrWord {
  OcrWord(Json json)
    : text = json['text'] as String,
      x = (json['x'] as num).toDouble(),
      y = (json['y'] as num).toDouble(),
      width = (json['w'] as num).toDouble(),
      height = (json['h'] as num).toDouble();
  final String text;
  final double x, y, width, height;
}

class ScheduleDraft {
  ScheduleDraft({
    required this.day,
    required this.slot,
    required this.classCode,
    required this.subjectCode,
    required this.room,
    required this.raw,
  });
  int day, slot;
  String classCode, subjectCode, room;
  final String raw;
  bool selected = true;
}

class ScheduleRecognition {
  ScheduleRecognition(this.rows, this.weekStart, this.warnings);
  final List<ScheduleDraft> rows;
  final DateTime? weekStart;
  final List<String> warnings;
}

/// Spatial parser for the FPT weekly table: dates across, Slot labels down.
/// OCR content is only data; it never supplies executable commands or API paths.
class ScheduleImageParser {
  static ScheduleRecognition parse(Json document) {
    final words = (document['words'] as List)
        .map((w) => OcrWord(Map<String, dynamic>.from(w as Map)))
        .toList();
    final width = (document['width'] as num).toDouble();
    final height = (document['height'] as num).toDouble();
    final warnings = <String>[];
    final slots = <(int, double)>[];
    for (final w in words.where(
      (w) => w.x < width * .18 && w.text.toLowerCase().startsWith('slot'),
    )) {
      final nearby =
          words
              .where(
                (n) => (n.y - w.y).abs() < 8 && n.x >= w.x && n.x < w.x + 100,
              )
              .toList()
            ..sort((a, b) => a.x.compareTo(b.x));
      final match = RegExp(
        r'slot\s*(\d)',
        caseSensitive: false,
      ).firstMatch(nearby.map((w) => w.text).join(' '));
      if (match != null) slots.add((int.parse(match[1]!), w.y));
    }
    slots.sort((a, b) => a.$2.compareTo(b.$2));
    if (slots.isEmpty)
      throw const FormatException(
        'Không nhận diện được hàng Slot. Chọn ảnh đầy đủ bảng lịch, rõ chữ.',
      );
    final datePattern = RegExp(r'^(\d{2})/(\d{2})$');
    final dates =
        words
            .where(
              (w) =>
                  w.x > width * .12 &&
                  w.y < slots.first.$2 &&
                  datePattern.hasMatch(w.text),
            )
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));
    if (dates.length < 6 || dates.length > 7)
      throw const FormatException(
        'Cần thấy ngày của ít nhất 6 cột trong lịch tuần. Hãy chọn ảnh đầy đủ phần tiêu đề.',
      );
    final steps = <double>[
      for (var i = 1; i < dates.length; i++) dates[i].x - dates[i - 1].x,
    ]..sort();
    final step = steps[steps.length ~/ 2];
    if (steps.any((s) => (s - step).abs() > step * .2))
      throw const FormatException(
        'Các cột ngày không đều hoặc ảnh bị nghiêng. Hãy dùng ảnh chụp màn hình lịch tuần.',
      );
    final yearWords = words.where(
      (w) => w.y < slots.first.$2 && RegExp(r'^20\d{2}$').hasMatch(w.text),
    );
    DateTime? monday;
    if (yearWords.length == 1) {
      final first = datePattern.firstMatch(dates.first.text)!;
      final candidate = DateTime(
        int.parse(yearWords.first.text),
        int.parse(first[2]!),
        int.parse(first[1]!),
      );
      if (candidate.weekday == DateTime.monday) monday = candidate;
    }
    if (monday == null)
      warnings.add(
        'Không xác định chắc chắn năm/ngày đầu tuần. Bạn cần chọn lại thứ Hai của tuần.',
      );
    if (monday != null) {
      for (var i = 0; i < dates.length; i++) {
        final expected = monday.add(Duration(days: i));
        final m = datePattern.firstMatch(dates[i].text)!;
        if (expected.day != int.parse(m[1]!) ||
            expected.month != int.parse(m[2]!)) {
          throw const FormatException(
            'Ngày trong ảnh không liên tiếp. Kiểm tra lại ảnh lịch tuần.',
          );
        }
      }
    }
    final rows = <ScheduleDraft>[];
    final code = RegExp(
      r'([A-Z]{2})([0-9IO]{4,6})[-–]([A-Z]{2,4})([0-9IO]{3})',
    );
    String digits(String value) =>
        value.replaceAll('I', '1').replaceAll('O', '0');
    for (var r = 0; r < slots.length; r++) {
      final (slot, y) = slots[r];
      if (slot < 1 || slot > 6) continue;
      final bottom = r + 1 < slots.length ? slots[r + 1].$2 - 7 : height;
      for (var day = 0; day < 7; day++) {
        final left = dates.first.x + day * step - 12;
        final cell =
            words
                .where(
                  (w) =>
                      w.x >= left &&
                      w.x < left + step &&
                      w.y >= y - 7 &&
                      w.y < bottom,
                )
                .toList()
              ..sort(
                (a, b) => (a.y - b.y).abs() < 8
                    ? a.x.compareTo(b.x)
                    : a.y.compareTo(b.y),
              );
        final raw = cell.map((w) => w.text).join(' ');
        final compact = raw.toUpperCase().replaceAll(RegExp(r'\s+'), '');
        final matches = code.allMatches(compact).toList();
        if (matches.length != 1) {
          if (cell.any((w) => RegExp(r'[A-Za-z]{2,}').hasMatch(w.text))) {
            final room = RegExp(r'AT([A-Z]+)([0-9]{2,4})').firstMatch(compact);
            rows.add(
              ScheduleDraft(
                day: day,
                slot: slot,
                classCode: '',
                subjectCode: '',
                room: room == null ? '' : '${room[1]} ${room[2]}',
                raw: raw,
              )..selected = false,
            );
            warnings.add(
              'Có ô chưa đọc đủ mã lớp/môn. Dòng này được giữ lại và bỏ chọn; hãy điền thông tin rồi chọn nhập.',
            );
          }
          continue;
        }
        final match = matches.single;
        final room = RegExp(r'AT([A-Z]+)([0-9]{2,4})')
            .firstMatch(compact.substring(match.end));
        rows.add(
          ScheduleDraft(
            day: day,
            slot: slot,
            classCode: '${match[1]}${digits(match[2]!)}',
            subjectCode: '${match[3]}${digits(match[4]!)}',
            room: room == null ? '' : '${room[1]} ${room[2]}',
            raw: raw,
          ),
        );
      }
    }
    if (rows.isEmpty)
      throw const FormatException(
        'Không đọc được lớp/môn từ ảnh. Hãy dùng ảnh rõ chữ và đủ các cột.',
      );
    warnings.add(
      'OCR có thể nhầm I/1 hoặc O/0. Kiểm tra tất cả lớp, môn, phòng và ngày trước khi lưu.',
    );
    return ScheduleRecognition(rows, monday, warnings);
  }
}
