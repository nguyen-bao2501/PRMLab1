import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prm/services/api_service.dart';
import 'package:prm/services/schedule_image_parser.dart';

void main() {
  late Json input;
  setUp(() {
    input = jsonDecode(
      File('test/fixtures/weekly_schedule_ocr.json').readAsStringSync(),
    ) as Json;
  });
  test(
    'Real Windows OCR of lecturer image yields 20 correct weekly lessons',
    () {
      final result = ScheduleImageParser.parse(input);
      expect(result.weekStart, DateTime(2026, 9, 7));
      expect(result.rows.length, 20);
      expect(
        result.rows
            .map((r) => '${r.classCode}-${r.subjectCode}')
            .toSet()
            .length,
        10,
      );
      expect(result.rows.where((r) => r.day == 6), isEmpty);
      expect(result.rows.where((r) => r.slot == 5), isEmpty);
      final expected = {
        '0/1': 'SE1917/PRN232/NVH 602',
        '0/2': 'SE1917/PRM393/NVH 602',
        '0/3': 'SE1920/PRN232/NVH 606',
        '0/4': 'SE1920/PRM393/NVH 606',
        '1/2': 'SE1927/SWD392/NVH 611',
        '1/3': 'SE1922/PRM393/NVH 604',
        '1/4': 'SE1928/PRM393/NVH 606',
        '2/1': 'SE1913/PRM393/NVH 604',
        '2/3': 'SE1919/PRN232/NVH 602',
        '2/4': 'SE1919/PRM393/NVH 602',
      };
      for (final row in result.rows) {
        expect(
          '${row.classCode}/${row.subjectCode}/${row.room}',
          expected['${row.day % 3}/${row.slot}'],
        );
      }
    },
  );
  test(
    'Missing year requires manual week selection instead of inventing dates',
    () {
      (input['words'] as List).removeWhere((w) => w['text'] == '2026');
      expect(ScheduleImageParser.parse(input).weekStart, isNull);
    },
  );
  test('Missing room stays blank for required manual correction', () {
    (input['words'] as List).removeWhere(
      (w) => w['text'] == '602' && w['x'] == 263 && w['y'] == 255,
    );
    final row = ScheduleImageParser.parse(input).rows
        .firstWhere((r) => r.day == 0 && r.slot == 1);
    expect(row.room, isEmpty);
  });
  test('Cropped or non-schedule images fail explicitly', () {
    (input['words'] as List).removeWhere((w) => w['text'] == 'Slot');
    expect(() => ScheduleImageParser.parse(input), throwsFormatException);
  });
  test('Unreadable class cell remains editable and unselected instead of disappearing', () {
    (input['words'] as List).removeWhere((w) => w['x'] == 979 && w['y'] == 569);
    final parsed = ScheduleImageParser.parse(input);
    expect(parsed.rows.length, 20);
    final row = parsed.rows.singleWhere((r) => r.day == 3 && r.slot == 4);
    expect(row.classCode, isEmpty);
    expect(row.subjectCode, isEmpty);
    expect(row.room, 'NVH 606');
    expect(row.selected, isFalse);
  });
}
