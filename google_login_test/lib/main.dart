import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'google_web_sign_in_button.dart';

const _googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue: String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID'),
);
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

void main() => runApp(const GoogleLoginTestApp());

class GoogleLoginTestApp extends StatelessWidget {
  const GoogleLoginTestApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Google Login Test',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const GoogleLoginPage(),
      );
}

class GoogleLoginPage extends StatefulWidget {
  const GoogleLoginPage({super.key});

  @override
  State<GoogleLoginPage> createState() => _GoogleLoginPageState();
}

class _GoogleLoginPageState extends State<GoogleLoginPage> {
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // The Web plugin requires [clientId] and rejects [serverClientId]. Native
    // platforms use [serverClientId] to request an ID token for the backend.
    clientId: kIsWeb && _googleClientId.isNotEmpty ? _googleClientId : null,
    serverClientId:
        !kIsWeb && _googleClientId.isNotEmpty ? _googleClientId : null,
  );

  StreamSubscription<GoogleSignInAccount?>? _webSignInSubscription;
  bool _loading = false;
  String _result = 'Chua dang nhap';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // The Google Identity Web button publishes an account through this stream.
      _webSignInSubscription = _googleSignIn.onCurrentUserChanged.listen(
        (account) {
          if (account != null) _submitGoogleAccount(account);
        },
        onError: (Object error) {
          if (mounted) setState(() => _result = 'Dang nhap that bai:\n$error');
        },
      );
    }
  }

  Future<void> _login() async {
    if (_googleClientId.isEmpty) {
      setState(() => _result = 'Thieu GOOGLE_CLIENT_ID. Xem README.');
      return;
    }

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        setState(() => _result = 'Da huy dang nhap Google.');
        return;
      }

      await _submitGoogleAccount(account);
    } catch (error) {
      setState(() => _result = 'Dang nhap that bai:\n$error');
    }
  }

  Future<void> _submitGoogleAccount(GoogleSignInAccount account) async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {

      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        throw StateError('Google khong tra ve idToken. Hay dang nhap lai.');
      }

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/v1/auth/google'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final body = response.body.isEmpty ? '(empty)' : response.body;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode}\n$body');
      }
      setState(() => _result = 'HTTP ${response.statusCode}\n$body');
    } catch (error) {
      setState(() => _result = 'Dang nhap that bai:\n$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _webSignInSubscription?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    await _googleSignIn.signOut();
    setState(() => _result = 'Da dang xuat Google.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Google Login Test')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('API: $_apiBaseUrl'),
              const SizedBox(height: 20),
              if (kIsWeb)
                IgnorePointer(
                  ignoring: _loading,
                  child: buildGoogleWebSignInButton(),
                )
              else
                FilledButton.icon(
                  onPressed: _loading ? null : _login,
                  icon: const Icon(Icons.login),
                  label: Text(
                    _loading ? 'Dang xu ly...' : 'Dang nhap bang Google',
                  ),
                ),
              TextButton(
                onPressed: _loading ? null : _logout,
                child: const Text('Dang xuat'),
              ),
              const SizedBox(height: 20),
              const Text('Ket qua:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(child: SelectableText(_result)),
              ),
            ],
          ),
        ),
      );
}
