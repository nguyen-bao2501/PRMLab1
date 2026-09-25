import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prm/screens/import_schedule_image_dialog.dart';
import 'package:prm/services/api_service.dart';
import 'package:prm/services/schedule_image_parser.dart';
import 'package:prm/services/schedule_ocr.dart';

void main() {
  testWidgets(
    'Preview never saves until teacher reviews and submits the selected week',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final calls = <Json>[];
      final api = ApiService(
        client: MockClient((r) async {
          expect(r.url.path, '/v1/sessions/import-schedule');
          calls.add(jsonDecode(r.body) as Json);
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'createdClasses': 10,
                'createdLessons': 20,
                'skipped': 0,
              },
            }),
            200,
          );
        }),
      );
      addTearDown(api.dispose);
      final data = jsonDecode(
        File('test/fixtures/weekly_schedule_ocr.json').readAsStringSync(),
      ) as Json;
      final image = File('assets/images/fpt_logo.png').readAsBytesSync();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportScheduleImageDialog(
              api: api,
              readImage: () async =>
                  ScheduleImageRead(image, ScheduleImageParser.parse(data)),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Chọn ảnh lịch dạy'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      expect(find.textContaining('20 dòng lịch'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Nhập lịch đã kiểm tra'),
            )
            .onPressed,
        isNull,
      );
      final term = find.byType(TextFormField).first;
      await tester.ensureVisible(term);
      await tester.enterText(term, 'FA2026');
      final check = find.byType(CheckboxListTile);
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nhập lịch đã kiểm tra'));
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(calls.single['semester'], 'FA2026');
      final rows = calls.single['lessons'] as List;
      expect(rows, hasLength(20));
      expect(rows.first['date'], '2026-09-07');
      expect(rows.first['classCode'], 'SE1917');
      expect(find.textContaining('Đã tạo 10 lớp–môn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Cancelled image picker does not create a preview or save', (
    tester,
  ) async {
    final api = ApiService(
      client: MockClient(
        (_) async => throw StateError('No API calls expected'),
      ),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportScheduleImageDialog(
            api: api,
            readImage: () async => null,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Chọn ảnh lịch dạy'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập lịch đã kiểm tra'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Allows selecting Block 10, Block 3, or Full Semester block options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = <Json>[];
    final api = ApiService(
      client: MockClient((r) async {
        calls.add(jsonDecode(r.body) as Json);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'createdClasses': 1, 'createdLessons': 10, 'skipped': 0},
          }),
          200,
        );
      }),
    );
    addTearDown(api.dispose);
    final data = jsonDecode(
      File('test/fixtures/weekly_schedule_ocr.json').readAsStringSync(),
    ) as Json;
    final image = File('assets/images/fpt_logo.png').readAsBytesSync();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImportScheduleImageDialog(
            api: api,
            readImage: () async =>
                ScheduleImageRead(image, ScheduleImageParser.parse(data)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Chọn ảnh lịch dạy'));
    await tester.pumpAndSettle();

    final term = find.byType(TextFormField).first;
    await tester.ensureVisible(term);
    await tester.enterText(term, 'FA2026');

    // Toggle applyWholeSemester switch
    final switchTile = find.byType(SwitchListTile);
    await tester.ensureVisible(switchTile);
    await tester.tap(switchTile);
    await tester.pumpAndSettle();

    // Default is Block 10 (2026-09-07 -> 2026-11-15)
    expect(find.textContaining('07/09/2026 ➔ 15/11/2026'), findsOneWidget);

    // Select Block 3 (Tuần 13 - 15: 2026-11-30 -> 2026-12-20, cách 2 tuần thi)
    final block3Chip = find.text('Block 3 tuần');
    await tester.ensureVisible(block3Chip);
    await tester.tap(block3Chip);
    await tester.pumpAndSettle();
    expect(find.textContaining('30/11/2026 ➔ 20/12/2026'), findsOneWidget);

    // Select Full Semester 15 weeks (2026-09-07 -> 2026-12-20)
    final fullChip = find.text('Cả kỳ học');
    await tester.ensureVisible(fullChip);
    await tester.tap(fullChip);
    await tester.pumpAndSettle();
    expect(find.textContaining('07/09/2026 ➔ 20/12/2026'), findsOneWidget);

    // Review and save
    final check = find.byType(CheckboxListTile);
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nhập lịch đã kiểm tra'));
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single['applyWholeSemester'], isTrue);
    expect(calls.single['applyFrom'], '2026-09-07');
    expect(calls.single['applyUntil'], '2026-12-20');
  });
}

