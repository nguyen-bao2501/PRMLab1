import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm/main.dart';
import 'package:prm/services/api_service.dart';
import 'package:prm/services/attendance_store.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AttendanceStore fixture() {
  final store = AttendanceStore(ApiService(), autoPoll: false);
  store.user = {
    'fullName': 'Nguyễn Minh Anh',
    'email': 'anh@fpt.edu.vn',
    'role': 'TEACHER',
  };
  store.classes = [
    {
      'id': 1,
      'classCode': 'SE1917',
      'subjectCode': 'PRM393',
      'semester': 'FA2026',
      'studentCount': 32,
      'totalSessions': 8,
      'sheetName': 'PRM393_SE1917',
    },
  ];
  store.selectedClass = store.classes.first;
  store.selectedSession = {
    'id': 8,
    'classId': 1,
    'classCode': 'SE1917',
    'room': 'BE-301',
    'startTime': '2026-09-21T02:00:00Z',
    'status': 'OPEN',
    'totalStudents': 32,
    'qrToken': 'test-only-preview-token',
    'qrUrl': 'https://attendance.example/check-in.html#token=0123456789abcdef0123456789abcdef',
    'qrExpiresAt': DateTime.now()
        .add(const Duration(minutes: 8))
        .toIso8601String(),
  };
  store.sessions = [store.selectedSession!];
  store.attendances = List.generate(
    6,
    (i) => {
      'studentName': [
        'Nguyễn Hoàng Nam',
        'Trần Minh Thư',
        'Lê Quang Huy',
        'Phạm Ngọc Anh',
        'Võ Tuấn Kiệt',
        'Đặng Thanh Hà',
      ][i],
      'studentCode': 'SE19${1200 + i}',
      'email': 'student$i@fpt.edu.vn',
      'status': i == 4 ? 'LATE' : 'PRESENT',
      'checkInTime': '2026-09-21T02:0$i:12Z',
    },
  );
  store.lastSync = DateTime.now();
  return store;
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/previews/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('fpt_attendance/desktop'),
          (_) async => null,
        );
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    final font = File('C:/Windows/Fonts/segoeui.ttf');
    if (await font.exists()) {
      final loader = FontLoader('Segoe UI')
        ..addFont(
          font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
  });
  testWidgets('Studio pages render at desktop and phone widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = fixture();
    addTearDown(store.dispose);
    store.classes.addAll([
      {
        ...store.classes.first,
        'id': 2,
        'classCode': 'SE1920',
        'subjectCode': 'PRN232',
      },
      {
        ...store.classes.first,
        'id': 3,
        'classCode': 'SE1908',
        'subjectCode': 'SWP391',
      },
    ]);
    for (final width in [1440.0, 390.0]) {
      tester.view.physicalSize = Size(width, 1000);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: AttendanceApp(store: store),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Overview at $width');
      await screenshot(tester, key, 'studio-overview-${width.round()}');
      final pages = {
        'Lớp học của tôi': 'classes',
        'Buổi học': 'sessions',
        'Điểm danh': 'attendance',
        'Báo cáo': 'reports',
        'Tài khoản & kết nối': 'account',
      };
      for (final entry in pages.entries) {
        if (width < 700) {
          await tester.tap(find.byTooltip('Mở điều hướng'));
          await tester.pumpAndSettle();
        }
        await tester.tap(
          width < 700
              ? find.descendant(
                  of: find.byType(Drawer),
                  matching: find.text(entry.key),
                )
              : find.text(entry.key).first,
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} at $width',
        );
        await screenshot(tester, key, 'studio-${entry.value}-${width.round()}');
      }
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets('Login shows real authentication and no fake dashboard data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const AttendanceApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập với Google'), findsOneWidget);
    expect(find.text('Đăng nhập với devtest'), findsNothing);
    expect(find.text('Đăng nhập dành cho developer'), findsNothing);
    expect(find.text('Chào mừng trở lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await screenshot(tester, key, 'login');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Login and connection settings fit a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: const AttendanceApp()),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cấu hình kết nối'));
    await tester.pumpAndSettle();
    expect(find.text('Địa chỉ backend'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await screenshot(tester, key, 'studio-login-390');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Google exchanges ID token for backend session', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final requests = <http.Request>[];
    final store = AttendanceStore(
      ApiService(
        client: MockClient((request) async {
          requests.add(request);
          final dynamic data = switch (request.url.path) {
            '/v1/auth/google' => {'accessToken': 'google-jwt'},
            '/v1/auth/me' => {
              'fullName': 'Dev TEACHER',
              'email': 'devtest@gmail.com',
              'role': 'TEACHER',
            },
            '/v1/classes' => <dynamic>[],
            _ => throw StateError('Unexpected endpoint: ${request.url.path}'),
          };
          return http.Response(
            jsonEncode({'success': true, 'data': data}),
            200,
          );
        }),
      ),
      autoPoll: false,
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(
      AttendanceApp(store: store, googleSignIn: () async => 'google-id-token'),
    );
    await tester.tap(find.text('Đăng nhập với Google'));
    await tester.pumpAndSettle();
    expect(jsonDecode(requests.first.body), {'idToken': 'google-id-token'});
    expect(requests.map((r) => r.url.path).toList(), [
      '/v1/auth/google',
      '/v1/auth/me',
      '/v1/classes',
    ]);
    expect(requests[1].headers['Authorization'], 'Bearer google-jwt');
    expect(find.text('Một ngày dạy học hiệu quả'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Desktop attendance renders, filters rows and hides expired QR', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = fixture();
    addTearDown(store.dispose);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AttendanceApp(store: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Điểm danh'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Nguyễn Hoàng Nam'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await screenshot(tester, key, 'attendance');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Đi muộn'));
    await tester.pump();
    expect(find.text('Võ Tuấn Kiệt'), findsOneWidget);
    expect(find.text('Nguyễn Hoàng Nam'), findsNothing);
    store.selectedSession!['qrExpiresAt'] = DateTime.now()
        .subtract(const Duration(seconds: 2))
        .toIso8601String();
    store.notifyListeners();
    await tester.pump();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Mã QR đã hết hạn'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Short desktop viewport keeps sidebar and actions accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = fixture();
    addTearDown(store.dispose);
    await tester.pumpWidget(AttendanceApp(store: store));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Điểm danh'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Compact desktop navigation and teacher screens do not overflow',
    (tester) async {
      tester.view.physicalSize = const Size(900, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final store = fixture();
      addTearDown(store.dispose);
      await tester.pumpWidget(AttendanceApp(store: store));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      for (final tooltip in [
        'Lớp học của tôi',
        'Buổi học',
        'Điểm danh',
        'Báo cáo',
        'Tài khoản & kết nối',
      ]) {
        await tester.tap(find.byTooltip(tooltip));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tooltip);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
