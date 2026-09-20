import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:8080',
          );

  final http.Client _client;
  String baseUrl;
  String? token;

  Future<dynamic> request(
    String method,
    String path, {
    Json? body,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/v1$path')
        .replace(queryParameters: query);
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
      Json payload = {};
      if (response.body.isNotEmpty) {
        try {
          payload = jsonDecode(utf8.decode(response.bodyBytes)) as Json;
        } catch (_) {
          throw ApiException(
            'Máy chủ trả về dữ liệu không hợp lệ (${response.statusCode}). Kiểm tra địa chỉ backend.',
            response.statusCode,
          );
        }
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          payload['success'] == false) {
        throw ApiException(
          response.statusCode == 401
              ? 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'
              : payload['message']?.toString() ??
                    'Yêu cầu thất bại (${response.statusCode}).',
          response.statusCode,
        );
      }
      return payload['data'];
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on http.ClientException {
      throw const ApiException(
        'Không kết nối được backend. Kiểm tra địa chỉ máy chủ và kết nối mạng.',
      );
    }
  }

  Future<Json> googleLogin(String idToken) async =>
      await request('POST', '/auth/google', body: {'idToken': idToken}) as Json;
  Future<Json> devLogin(String email, String role) async =>
      await request('POST', '/dev/login', body: {'email': email, 'role': role})
          as Json;
  Future<Json> me() async => await request('GET', '/auth/me') as Json;
  Future<List<Json>> classes() async => _list(await request('GET', '/classes'));
  Future<Json> classDetail(int id) async =>
      await request('GET', '/classes/$id') as Json;
  Future<Json> createClass(Json body) async =>
      await request('POST', '/classes', body: body) as Json;
  Future<void> deleteClass(int id) async => request('DELETE', '/classes/$id');
  Future<List<Json>> sheetTabs(String id) async => _list(
    await request('GET', '/classes/sheet-tabs', query: {'spreadsheetId': id}),
  );
  Future<Json> importSheet(int id, String spreadsheet, String tab) async =>
      await request(
        'POST',
        '/classes/$id/import-sheet',
        body: {'spreadsheetId': spreadsheet, 'sheetName': tab},
      ) as Json;
  Future<List<Json>> sessions(int classId) async =>
      _list(await request('GET', '/sessions', query: {'classId': '$classId'}));
  Future<Json> createSession(int classId, String room) async => await request(
    'POST',
    '/sessions',
    body: {
      'classId': classId,
      'room': room,
      'startTime': DateTime.now().toUtc().toIso8601String(),
    },
  ) as Json;
  Future<Json> session(int id) async =>
      await request('GET', '/sessions/$id') as Json;
  Future<Json> refreshQr(int id) async =>
      await request('POST', '/sessions/$id/refresh-qr') as Json;
  Future<Json> closeSession(int id) async =>
      await request('POST', '/sessions/$id/close') as Json;
  Future<List<Json>> attendances(int id) async =>
      _list(await request('GET', '/attendances', query: {'sessionId': '$id'}));
  Future<Json> checkIn(String qrToken) async => await request(
    'POST',
    '/attendances/check-in',
    body: {'qrToken': qrToken, 'deviceInfo': 'FPT Attendance Desktop'},
  ) as Json;
  Future<List<Json>> myAttendances() async =>
      _list(await request('GET', '/attendances/me'));
  Future<Json> exportSession(int id) async =>
      await request('POST', '/exports/session/$id') as Json;
  static List<Json> _list(dynamic value) =>
      (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  void dispose() => _client.close();
}
