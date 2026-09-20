import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prm/services/api_service.dart';
import 'package:prm/services/sheet_class_importer.dart';

http.Response ok(dynamic data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  test('Extract spreadsheet id from URL with gid, reject unrelated URLs', () {
    expect(
      SheetClassImporter.spreadsheetId(
        'https://docs.google.com/spreadsheets/d/abc_123/edit?gid=42#gid=42',
      ),
      'abc_123',
    );
    expect(SheetClassImporter.spreadsheetId(' abc_123 '), 'abc_123');
    expect(
      () => SheetClassImporter.spreadsheetId(
        'https://example.com/spreadsheets/d/abc',
      ),
      throwsA(isA<ApiException>()),
    );
  });
  test('Imports every tab as its own subject class, then reuses mappings on repeat', () async {
    final classrooms = <Json>[];
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((r) async {
        requests.add(r);
        if (r.method == 'GET') return ok(classrooms);
        final body = jsonDecode(r.body) as Json;
        if (r.url.path == '/v1/classes') {
          final classroom = {...body, 'id': classrooms.length + 1};
          classrooms.add(classroom);
          return ok(classroom);
        }
        final id = int.parse(r.url.path.split('/')[3]);
        classrooms[id - 1].addAll(body);
        return ok({'rowsImported': 2, 'rowsSkipped': 1});
      }),
    );
    addTearDown(api.dispose);
    final importer = SheetClassImporter(api);
    final tabs = [
      {
        'sheetName': '11_PRN232_SE1917',
        'subjectCode': 'PRN232',
        'classCode': 'SE1917',
      },
      {
        'sheetName': '12_PRM393_SE1917',
        'subjectCode': 'PRM393',
        'classCode': 'SE1917',
      },
    ];
    final first = await importer.importTabs(
      spreadsheetId: 'source',
      tabs: tabs,
      semester: 'FA2026',
    );
    expect(first.every((r) => r.success), isTrue);
    expect(classrooms.map((c) => c['classCode']), [
      '11_PRN232_SE1917',
      '12_PRM393_SE1917',
    ]);
    expect(classrooms.every((c) => c['semester'] == 'FA2026'), isTrue);
    final repeat = await importer.importTabs(
      spreadsheetId: 'source',
      tabs: tabs,
    );
    expect(repeat.every((r) => r.success), isTrue);
    expect(
      requests
          .where((r) => r.method == 'POST' && r.url.path == '/v1/classes')
          .length,
      2,
    );
    expect(
      requests.where((r) => r.url.path.endsWith('/import-sheet')).length,
      4,
    );
  });
  test(
    'Does not overwrite another spreadsheet mapping with the same tab name',
    () async {
      var mutations = 0;
      final api = ApiService(
        client: MockClient((r) async {
          if (r.method == 'GET')
            return ok([
              {
                'id': 1,
                'classCode': 'PRM393_SE1917',
                'subjectCode': 'PRM393',
                'sheetName': 'PRM393_SE1917',
                'spreadsheetId': 'other',
              },
            ]);
          mutations++;
          return ok({});
        }),
      );
      addTearDown(api.dispose);
      final result = await SheetClassImporter(api).importTabs(
        spreadsheetId: 'source',
        tabs: [
          {'sheetName': 'PRM393_SE1917', 'subjectCode': 'PRM393'},
        ],
      );
      expect(result.single.success, isFalse);
      expect(mutations, 0);
    },
  );
  test('Continues after one tab fails and reuses an unlinked class from a previous attempt', () async {
    final importedIds = <int>[];
    var created = 0;
    final api = ApiService(
      client: MockClient((r) async {
        if (r.method == 'GET')
          return ok([
            {
              'id': 1,
              'classCode': 'bad',
              'subjectCode': 'PRM393',
              'sheetName': null,
            },
            {
              'id': 2,
              'classCode': 'good',
              'subjectCode': 'PRN232',
              'sheetName': null,
            },
          ]);
        if (r.url.path == '/v1/classes') {
          created++;
          return ok({});
        }
        final id = int.parse(r.url.path.split('/')[3]);
        importedIds.add(id);
        if (id == 1)
          return http.Response('{"success":false,"message":"Empty tab"}', 400);
        return ok({'rowsImported': 5, 'rowsSkipped': 0});
      }),
    );
    addTearDown(api.dispose);
    final result = await SheetClassImporter(api).importTabs(
      spreadsheetId: 'source',
      tabs: [
        {'sheetName': 'bad', 'subjectCode': 'PRM393'},
        {'sheetName': 'good', 'subjectCode': 'PRN232'},
        {'sheetName': 'notes'},
      ],
    );
    expect(created, 0);
    expect(importedIds, [1, 2]);
    expect(result.map((r) => r.success), [false, true, false]);
    expect(result[1].imported, 5);
  });
}
