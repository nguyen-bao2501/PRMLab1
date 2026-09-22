import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prm/services/api_service.dart';
import 'package:prm/services/attendance_store.dart';
import 'package:prm/services/desktop_session.dart';

class MemorySession extends DesktopSession {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

void main() {
  for (final status in [200, 401, 503]) {
    test('Restore session with backend status $status', () async {
      final session = MemorySession()
        ..value = jsonEncode({
          'baseUrl': 'http://localhost:8080',
          'token': 'saved-token',
        });
      final store = AttendanceStore(
        ApiService(
          client: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer saved-token');
            return http.Response(
              jsonEncode({
                'success': status == 200,
                'data': request.url.path.endsWith('/me')
                    ? {'role': 'TEACHER'}
                    : [],
              }),
              status,
            );
          }),
        ),
        autoPoll: false,
        session: session,
      );
      addTearDown(store.dispose);
      await store.restoreSession();
      expect(store.user != null, status == 200);
      expect(session.value != null, status != 401);
      expect(store.busy, false);
      store.logout();
      await Future<void>.delayed(Duration.zero);
      expect(session.value, isNull);
    });
  }
  test('Saved credentials are never sent to a different backend', () async {
    final session = MemorySession()
      ..value = jsonEncode({
        'baseUrl': 'https://another.example',
        'token': 'saved-token',
      });
    final store = AttendanceStore(
      ApiService(
        client: MockClient((_) async {
          fail('Must not send token to a different backend');
        }),
      ),
      autoPoll: false,
      session: session,
    );
    addTearDown(store.dispose);
    await store.restoreSession();
    expect(store.api.token, isNull);
  });
  test('Successful login persists backend session', () async {
    final session = MemorySession();
    final store = AttendanceStore(
      ApiService(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': request.url.path.endsWith('/me')
                  ? {'role': 'TEACHER'}
                  : [],
            }),
            200,
          );
        }),
      ),
      autoPoll: false,
      session: session,
    );
    addTearDown(store.dispose);
    await store.authenticate(() async => {'accessToken': 'new-token'});
    expect(jsonDecode(session.value!)['token'], 'new-token');
  });
}
