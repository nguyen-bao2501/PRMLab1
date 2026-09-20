import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'browser_launcher.dart';

import 'api_service.dart';

/// Installed-app OAuth: system browser, loopback callback, state and PKCE.
class GoogleAuth {
  static const clientId = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID');
  static const clientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
  );

  static Future<String> signIn() async {
    if (clientId.isEmpty) {
      throw const ApiException(
        'Chưa cấu hình Google OAuth Desktop. Xem hướng dẫn trong DESKTOP.md.',
      );
    }
    String random() =>
        base64UrlEncode(List.generate(32, (_) => Random.secure().nextInt(256)))
            .replaceAll('=', '');
    final verifier = random();
    final state = random();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirect = 'http://127.0.0.1:${server.port}/callback';
    final result = Completer<String>();
    final subscription = server.listen((request) async {
      final params = request.uri.queryParameters;
      if (request.uri.path != '/callback' || params['state'] != state) {
        request.response.statusCode = 400;
        await request.response.close();
        return;
      }
      request.response.headers.contentType = ContentType.html;
      request.response.write(
        '<meta charset="utf-8"><h2>FPT Attendance</h2><p>Bạn có thể đóng tab này và quay lại ứng dụng.</p>',
      );
      await request.response.close();
      if (!result.isCompleted) {
        if (params['code'] != null) {
          result.complete(params['code']);
        } else {
          result.completeError(
            const ApiException('Đăng nhập Google đã bị hủy.'),
          );
        }
      }
    });
    try {
      final uri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirect,
        'response_type': 'code',
        'scope': 'openid email profile',
        'state': state,
        'prompt': 'select_account',
        'code_challenge': base64UrlEncode(
          sha256.convert(utf8.encode(verifier)).bytes,
        ).replaceAll('=', ''),
        'code_challenge_method': 'S256',
      });
      if (!await launchUrl(uri)) {
        throw const ApiException(
          'Không thể mở trình duyệt để đăng nhập Google.',
        );
      }
      final code = await result.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () =>
            throw const ApiException('Đã hết thời gian chờ đăng nhập Google.'),
      );
      final response = await http
          .post(
            Uri.https('oauth2.googleapis.com', '/token'),
            body: {
              'client_id': clientId,
              if (clientSecret.isNotEmpty) 'client_secret': clientSecret,
              'code': code,
              'code_verifier': verifier,
              'redirect_uri': redirect,
              'grant_type': 'authorization_code',
            },
          )
          .timeout(const Duration(seconds: 20));
      final body = jsonDecode(response.body) as Json;
      if (response.statusCode != 200 || body['id_token'] == null) {
        throw const ApiException(
          'Google không cấp ID token. Kiểm tra cấu hình OAuth Desktop.',
        );
      }
      return body['id_token'] as String;
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  }
}
