import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prm/services/api_service.dart';
import 'package:prm/services/attendance_store.dart';

http.Response ok(dynamic data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
void main() {
  test('All API methods use the backend contract, bearer token and encoded queries', () async {
    final requests = <http.Request>[];
    final api = ApiService(
      baseUrl: 'http://localhost:8080/',
      client: MockClient((r) async {
        requests.add(r);
        if (r.method == 'GET' &&
            [
              '/v1/classes',
              '/v1/classes/sheet-tabs',
              '/v1/sessions',
              '/v1/attendances',
              '/v1/attendances/me',
            ].contains(r.url.path)) {
          return ok([]);
        }
        return ok({});
      }),
    )..token = 'jwt-test';
    await api.googleLogin('google-id-token');
    await api.devLogin('teacher@fpt.edu.vn', 'TEACHER');
    await api.me();
    await api.classes();
    await api.classDetail(7);
    await api.createClass({
      'classCode': 'SE1917',
      'subjectCode': 'PRM393',
      'semester': 'FA2026',
    });
    await api.deleteClass(7);
    await api.sheetTabs('sheet/id & x');
    await api.importSheet(7, 'sheet', 'Môn & Lớp');
    await api.sessions(7);
    await api.createSession(7, 'A101');
    await api.session(9);
    await api.refreshQr(9);
    await api.closeSession(9);
    await api.attendances(9);
    await api.checkIn('token-qr');
    await api.myAttendances();
    await api.exportSession(9);
    expect(requests.map((r) => '${r.method} ${r.url.path}').toList(), [
      'POST /v1/auth/google',
      'POST /v1/dev/login',
      'GET /v1/auth/me',
      'GET /v1/classes',
      'GET /v1/classes/7',
      'POST /v1/classes',
      'DELETE /v1/classes/7',
      'GET /v1/classes/sheet-tabs',
      'POST /v1/classes/7/import-sheet',
      'GET /v1/sessions',
      'POST /v1/sessions',
      'GET /v1/sessions/9',
      'POST /v1/sessions/9/refresh-qr',
      'POST /v1/sessions/9/close',
      'GET /v1/attendances',
      'POST /v1/attendances/check-in',
      'GET /v1/attendances/me',
      'POST /v1/exports/session/9',
    ]);
    expect(
      requests.every((r) => r.headers['Authorization'] == 'Bearer jwt-test'),
      isTrue,
    );
    expect(jsonDecode(requests[0].body), {'idToken': 'google-id-token'});
    expect(requests[7].url.queryParameters['spreadsheetId'], 'sheet/id & x');
    expect(jsonDecode(requests[8].body), {
      'spreadsheetId': 'sheet',
      'sheetName': 'Môn & Lớp',
    });
    expect(requests[9].url.queryParameters, {'classId': '7'});
    expect(jsonDecode(requests[10].body)['classId'], 7);
    expect(jsonDecode(requests[10].body)['startTime'], endsWith('Z'));
    expect(requests[14].url.queryParameters, {'sessionId': '9'});
    expect(jsonDecode(requests[15].body)['qrToken'], 'token-qr');
    api.dispose();
  });
  test('API propagates backend errors and handles invalid responses', () async {
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'success': false, 'message': 'Lớp chưa import Sheet'}),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await expectLater(
      api.exportSession(1),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Lớp chưa import Sheet',
        ),
      ),
    );
    api.dispose();
    final bad = ApiService(
      client: MockClient((_) async => http.Response('<html>Error</html>', 502)),
    );
    await expectLater(bad.classes(), throwsA(isA<ApiException>()));
    bad.dispose();
  });
  test(
    '401 clears authentication and prevents stale data from remaining visible',
    () async {
      final store = AttendanceStore(
        ApiService(client: MockClient((_) async => http.Response('{}', 401)))
          ..token = 'expired',
        autoPoll: false,
      )..user = {'role': 'TEACHER'};
      final result = await store.run(store.reload);
      expect(result, isFalse);
      expect(store.user, isNull);
      expect(store.api.token, isNull);
      expect(store.error, contains('hết hạn'));
      store.dispose();
    },
  );
  test('Polling preserves issued QR, counts present/late only and clears QR on close', () async {
    var closed = false;
    final store =
        AttendanceStore(
            ApiService(
              client: MockClient((r) async {
                if (r.url.path == '/v1/sessions/9') {
                  return ok({
                    'id': 9,
                    'status': closed ? 'CLOSED' : 'OPEN',
                    'totalStudents': 4,
                    'qrToken': null,
                  });
                }
                return ok([
                  {'status': 'PRESENT'},
                  {'status': 'LATE'},
                  {'status': 'ABSENT'},
                  {'status': 'EXCUSED'},
                ]);
              }),
            ),
            autoPoll: false,
          )
          ..user = {'role': 'TEACHER'}
          ..selectedSession = {
            'id': 9,
            'status': 'OPEN',
            'qrToken': 'issued-token',
          };
    await store.poll();
    expect(store.selectedSession!['qrToken'], 'issued-token');
    expect(store.present, 2);
    expect(store.remaining, 2);
    closed = true;
    await store.poll();
    expect(store.open, isFalse);
    expect(store.selectedSession!['qrToken'], isNull);
    store.dispose();
  });
  test(
    'Student login loads personal history without teacher endpoints',
    () async {
      final paths = <String>[];
      final store = AttendanceStore(
        ApiService(
          client: MockClient((r) async {
            paths.add(r.url.path);
            if (r.url.path == '/v1/dev/login') {
              return ok({'accessToken': 'student-jwt'});
            }
            if (r.url.path == '/v1/auth/me') {
              return ok({'role': 'STUDENT', 'id': 1});
            }
            return ok([]);
          }),
        ),
        autoPoll: false,
      );
      await store.authenticate(
        () => store.api.devLogin('student@fpt.edu.vn', 'STUDENT'),
      );
      expect(paths, ['/v1/dev/login', '/v1/auth/me', '/v1/attendances/me']);
      expect(store.student, isTrue);
      store.dispose();
    },
  );
}
