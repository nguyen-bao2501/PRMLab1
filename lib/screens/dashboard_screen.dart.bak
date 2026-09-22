import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/browser_launcher.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/attendance_store.dart';
import '../services/google_auth.dart';
import '../services/desktop_session.dart';
import 'import_classes_dialog.dart';

const green = Color(0xFF15966A);
const line = Color(0xFFE8EDF2);
const paleOrange = Color(0xFFFFF2E8);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.store, this.googleSignIn});
  final Future<String> Function()? googleSignIn;
  final AttendanceStore? store;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AttendanceStore s;
  int page = 0;
  String search = '', filter = 'ALL';
  final email = TextEditingController(text: 'devtest@gmail.com');
  final server = TextEditingController();
  String devRole = 'TEACHER';
  Timer? clock;
  @override
  void initState() {
    super.initState();
    s =
        widget.store ??
        AttendanceStore(ApiService(), session: DesktopSession());
    server.text = s.api.baseUrl;
    s.addListener(changed);
    if (widget.store == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(s.restoreSession());
      });
    }
    clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && s.selectedSession != null) setState(() {});
    });
  }

  void changed() {
    if (!mounted) return;
    if (s.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    clock?.cancel();
    s.removeListener(changed);
    if (widget.store == null) s.dispose();
    email.dispose();
    server.dispose();
    super.dispose();
  }

  String str(Json? data, String key, [String fallback = '—']) =>
      data?[key]?.toString() ?? fallback;
  String date(dynamic value, {bool time = false}) {
    final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (d == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return time
        ? '${two(d.hour)}:${two(d.minute)}:${two(d.second)}'
        : '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  void toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> action(Future<void> Function() task, [String? success]) async {
    final ok = await s.run(task);
    if (ok && success != null) toast(success);
  }

  Widget title(String text, {double size = 22}) => Text(
    text,
    style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: ink),
  );
  Widget subtitle(String text) => Text(
    text,
    style: const TextStyle(color: muted, fontSize: 13, height: 1.6),
  );
  Widget panel(Widget child, {EdgeInsets padding = const EdgeInsets.all(24)}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(color: Colors.transparent, child: child),
      );
  Widget brand({bool white = false}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final pair in [
        ('F', const Color(0xFF1675BC)),
        ('P', fptOrange),
        ('T', const Color(0xFF49A942)),
      ])
        Container(
          margin: const EdgeInsets.only(right: 3),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: pair.$2,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            pair.$1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      const SizedBox(width: 6),
      Text(
        'UNIVERSITY',
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1,
          fontWeight: FontWeight.w800,
          color: white ? Colors.white : ink,
        ),
      ),
    ],
  );
  Widget badge(String label, {Color color = green}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
  Widget button(
    String label,
    IconData icon,
    VoidCallback? callback, {
    bool primary = false,
  }) => primary
      ? FilledButton.icon(
          onPressed: s.busy ? null : callback,
          icon: Icon(icon, size: 18),
          label: Text(label),
        )
      : OutlinedButton.icon(
          onPressed: s.busy ? null : callback,
          icon: Icon(icon, size: 18),
          label: Text(label),
        );
  @override
  Widget build(BuildContext context) {
    if (s.user == null) return login();
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1050;
          return Row(
            children: [
              sidebar(wide),
              Expanded(
                child: Column(
                  children: [
                    header(),
                    if (s.busy) const LinearProgressIndicator(minHeight: 2),
                    if (s.error != null) errorBanner(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(wide ? 32 : 20),
                        child: s.student
                            ? studentPage()
                            : switch (page) {
                                0 => overview(),
                                1 => classesPage(),
                                2 => sessionsPage(),
                                3 => attendancePage(),
                                4 => reportsPage(),
                                _ => settingsPage(),
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget errorBanner() => Container(
    color: const Color(0xFFFFF0EC),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.deepOrange, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            s.error!,
            style: const TextStyle(color: Color(0xFFB34720)),
          ),
        ),
        IconButton(
          tooltip: 'Đóng thông báo',
          onPressed: () => setState(() => s.error = null),
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    ),
  );
  Widget login() => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/fpt_bg.jpg',
          fit: BoxFit.cover,
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 480,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  brand(),
                  const SizedBox(height: 32),
                  const Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Để tiếp tục sử dụng ứng dụng điểm danh\nFPT University',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (s.error != null) ...[
                    errorBanner(),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: s.busy ? null : () => action(() async {
                        applyServer();
                        await s.authenticate(
                          () async => s.api.googleLogin(
                            await (widget.googleSignIn ?? GoogleAuth.signIn)(),
                          ),
                        );
                      }),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (s.busy)
                            const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                                width: 18,
                                height: 18,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.g_mobiledata,
                                  color: Color(0xFF3B82F6),
                                  size: 18,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Text(
                            s.busy ? 'Đang đăng nhập…' : 'Đăng nhập bằng Google',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Hoặc',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF94A3B8)),
                      SizedBox(width: 8),
                      Text(
                        'Chỉ dành cho sinh viên và giảng viên FPT University',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                  if (const bool.fromEnvironment('ENABLE_DEV_LOGIN')) ...[
                    const SizedBox(height: 32),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text(
                        'Cấu hình kết nối & Developer',
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                      children: [
                        TextField(
                          controller: server,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ backend',
                            hintText: 'http://localhost:8080',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: email,
                          decoration: const InputDecoration(
                            labelText: 'Email kiểm thử',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: devRole,
                          decoration: const InputDecoration(
                            labelText: 'Vai trò',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'TEACHER',
                              child: Text('Giảng viên'),
                            ),
                            DropdownMenuItem(
                              value: 'STUDENT',
                              child: Text('Sinh viên'),
                            ),
                          ],
                          onChanged: (v) => setState(() => devRole = v!),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: button(
                            'Đăng nhập thử nghiệm',
                            Icons.code,
                            () => action(() async {
                              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(email.text.trim())) {
                                throw const ApiException(
                                  'Vui lòng nhập email hợp lệ.',
                                );
                              }
                              applyServer();
                              await s.authenticate(
                                () => s.api.devLogin(
                                  email.text.trim(),
                                  devRole,
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  void applyServer() {
    final uri = Uri.tryParse(server.text.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty) {
      throw const ApiException('Địa chỉ backend không hợp lệ.');
    }
    s.api.baseUrl = server.text.trim().replaceAll(RegExp(r'/+$'), '');
  }

  Widget sidebar(bool wide) => Container(
    width: wide ? 242 : 76,
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(right: BorderSide(color: line)),
    ),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: 30,
            horizontal: wide ? 22 : 10,
          ),
          child: wide
              ? brand()
              : const Icon(Icons.school_rounded, color: fptOrange, size: 34),
        ),
        if (wide)
          const Padding(
            padding: EdgeInsets.fromLTRB(26, 5, 20, 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'KHÔNG GIAN GIẢNG DẠY',
                style: TextStyle(
                  color: muted,
                  letterSpacing: 1.3,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (!s.student) ...[
          nav(0, 'Tổng quan', Icons.grid_view_rounded, wide),
          nav(1, 'Lớp học của tôi', Icons.school_outlined, wide),
          nav(2, 'Buổi học', Icons.calendar_month_outlined, wide),
          nav(3, 'Điểm danh', Icons.qr_code_scanner_rounded, wide),
          nav(4, 'Báo cáo', Icons.bar_chart_rounded, wide),
        ] else
          nav(0, 'Điểm danh cá nhân', Icons.fact_check_outlined, wide),
        const Spacer(),
        if (wide && MediaQuery.sizeOf(context).height >= 800)
          Padding(
            padding: const EdgeInsets.all(18),
            child: Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: paleOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: fptOrange,
                    size: 22,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bắt đầu thật đơn giản',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  subtitle('Tạo lớp, nhập danh sách và mở phiên điểm danh.'),
                ],
              ),
            ),
          ),
        if (!s.student)
          nav(5, 'Tài khoản & kết nối', Icons.settings_outlined, wide),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Tooltip(
            message: 'Đăng xuất',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: s.busy
                  ? null
                  : () {
                      s.logout();
                      setState(() {
                        page = 0;
                        search = '';
                        filter = 'ALL';
                      });
                    },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: muted, size: 21),
                    if (wide) ...[
                      const SizedBox(width: 12),
                      const Text('Đăng xuất', style: TextStyle(color: muted)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  Widget nav(int index, String label, IconData icon, bool wide) {
    final active = page == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Tooltip(
        message: wide ? '' : label,
        child: Material(
          color: active ? paleOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => setState(() {
              page = index;
              search = '';
              filter = 'ALL';
            }),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: active ? fptOrange : muted, size: 22),
                  if (wide) ...[
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: active ? fptOrange : ink,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (active)
                      const Icon(
                        Icons.chevron_right,
                        color: fptOrange,
                        size: 18,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget header() => Container(
    height: 83,
    padding: const EdgeInsets.symmetric(horizontal: 26),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: [
        const Icon(Icons.home_outlined, color: muted, size: 19),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            'Cổng ${s.student ? 'sinh viên' : 'giảng viên'}  /  ${s.student ? 'Điểm danh' : ['Tổng quan', 'Lớp học', 'Buổi học', 'Điểm danh', 'Báo cáo', 'Tài khoản'][page]}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 13),
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Đồng bộ dữ liệu',
          onPressed: s.busy
              ? null
              : () => action(() async {
                  await s.reload();
                  if (s.selectedSession != null) {
                    await s.selectSession(s.selectedSession!);
                  }
                }),
          icon: const Icon(Icons.sync, color: muted, size: 21),
        ),
        const SizedBox(width: 15),
        PopupMenuButton<String>(
          tooltip: 'Tài khoản',
          offset: const Offset(0, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              s.logout();
              setState(() {
                page = 0;
                search = '';
                filter = 'ALL';
              });
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
          child: const CircleAvatar(
            radius: 19,
            backgroundColor: paleOrange,
            child: Icon(Icons.person_outline, color: fptOrange, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              str(s.user, 'fullName', 'Giảng viên'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Text(
              s.student ? 'Sinh viên' : 'Giảng viên',
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
  Widget heading(
    String eyebrow,
    String text,
    String description, {
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: LayoutBuilder(
      builder: (context, c) {
        final body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: fptOrange,
                fontSize: 10,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            title(text, size: 28),
            const SizedBox(height: 6),
            subtitle(description),
          ],
        );
        return c.maxWidth > 720
            ? Row(
                children: [
                  Expanded(child: body),
                  ?trailing,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  body,
                  if (trailing != null) ...[
                    const SizedBox(height: 16),
                    trailing,
                  ],
                ],
              );
      },
    ),
  );
  Widget empty(String heading, String text, IconData icon, {Widget? action}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F7FA),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: muted, size: 33),
              ),
              const SizedBox(height: 18),
              title(heading, size: 17),
              const SizedBox(height: 8),
              subtitle(text),
              if (action != null) ...[const SizedBox(height: 20), action],
            ],
          ),
        ),
      );
  Widget stat(
    String label,
    String value,
    String note,
    IconData icon,
    Color color,
  ) => panel(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: muted, fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(note, style: const TextStyle(fontSize: 11, color: muted)),
      ],
    ),
  );
  Widget grid(List<Widget> items, {double minWidth = 210}) => LayoutBuilder(
    builder: (context, c) {
      final count = (c.maxWidth / minWidth).floor().clamp(1, items.length);
      final width = (c.maxWidth - (count - 1) * 16) / count;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: items.map((w) => SizedBox(width: width, child: w)).toList(),
      );
    },
  );
  Widget overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'TEACHING WORKSPACE',
        'Một ngày dạy học hiệu quả',
        'Quản lý lớp học và theo dõi điểm danh trong một không gian.',
        trailing: badge(date(DateTime.now().toIso8601String()), color: muted),
      ),
      Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF173A50), Color(0xFF28546B)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ít thao tác hơn. Nhiều kết nối hơn.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Mở buổi học, chia sẻ mã QR và để điểm danh tự cập nhật.',
                    style: TextStyle(color: Color(0xFFB9CEDB), height: 1.6),
                  ),
                  const SizedBox(height: 22),
                  button(
                    'Đến lớp học của tôi',
                    Icons.arrow_forward_rounded,
                    () => setState(() => page = 1),
                    primary: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            const Icon(
              Icons.qr_code_2_rounded,
              size: 100,
              color: Color(0xFFD5E3EA),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      grid([
        stat(
          'Lớp học của tôi',
          '${s.classes.length}',
          'Lớp đang hoạt động',
          Icons.school_outlined,
          fptOrange,
        ),
        stat(
          'Sinh viên trong các lớp',
          '${s.classes.fold<int>(0, (n, c) => n + ((c['studentCount'] as num?)?.toInt() ?? 0))}',
          'Tổng lượt ghi danh',
          Icons.people_outline,
          const Color(0xFF1675BC),
        ),
        stat(
          'Buổi học đã tạo',
          '${s.classes.fold<int>(0, (n, c) => n + ((c['totalSessions'] as num?)?.toInt() ?? 0))}',
          'Trong các lớp hiện tại',
          Icons.calendar_today_outlined,
          green,
        ),
      ]),
      const SizedBox(height: 30),
      Row(
        children: [
          Expanded(child: title('Lớp học của tôi', size: 19)),
          TextButton(
            onPressed: () => setState(() => page = 1),
            child: const Text('Xem tất cả →'),
          ),
        ],
      ),
      const SizedBox(height: 16),
      if (s.classes.isEmpty)
        panel(
          empty(
            'Sẵn sàng cho lớp học đầu tiên?',
            'Tạo lớp học rồi nhập danh sách sinh viên từ Google Sheet.',
            Icons.school_outlined,
            action: button(
              'Tạo lớp học',
              Icons.add,
              createClass,
              primary: true,
            ),
          ),
        )
      else
        classGrid(s.classes.take(3).toList()),
    ],
  );
  Widget classesPage() {
    final list = s.classes
        .where(
          (c) => '${c['classCode']} ${c['subjectCode']} ${c['semester']}'
              .toLowerCase()
              .contains(search.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'CLASS MANAGEMENT',
          'Lớp học của tôi',
          'Tổ chức lớp học, quản lý danh sách và bắt đầu điểm danh.',
          trailing: button(
            'Tạo lớp học',
            Icons.add,
            createClass,
            primary: true,
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            searchBox('Tìm mã lớp, mã môn, học kỳ…'),
            button(
              'Nhập tất cả lớp từ Sheet',
              Icons.library_add_outlined,
              importAllClasses,
              primary: true,
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (list.isEmpty)
          panel(
            empty(
              'Chưa có lớp học phù hợp',
              'Tạo lớp mới hoặc thay đổi nội dung tìm kiếm.',
              Icons.search_off,
            ),
          )
        else
          classGrid(list),
      ],
    );
  }

  Widget classGrid(List<Json> list) => grid(
    list
        .map(
          (c) => panel(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: paleOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        color: fptOrange,
                      ),
                    ),
                    const Spacer(),
                    badge(str(c, 'semester'), color: muted),
                  ],
                ),
                const SizedBox(height: 23),
                title(str(c, 'classCode')),
                const SizedBox(height: 5),
                subtitle('Môn học • ${str(c, 'subjectCode')}'),
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 17, color: muted),
                    const SizedBox(width: 7),
                    Text(
                      '${c['studentCount'] ?? 0} sinh viên',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      '${c['totalSessions'] ?? 0} buổi học',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c['sheetName'] == null
                            ? 'Chưa liên kết Sheet'
                            : 'Đã liên kết Google Sheet',
                        style: TextStyle(
                          fontSize: 11,
                          color: c['sheetName'] == null ? muted : green,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: s.busy
                          ? null
                          : () => action(() async {
                              await s.selectClass(c);
                              setState(() => page = 2);
                            }),
                      child: const Text('Mở lớp →'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .toList(),
    minWidth: 285,
  );
  Widget searchBox(String hint) => SizedBox(
    width: 430,
    child: TextField(
      key: ValueKey('search-$page'),
      onChanged: (value) => setState(() => search = value),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 21),
        isDense: true,
      ),
    ),
  );
  Widget classPicker() => DropdownButtonFormField<int>(
    key: ValueKey('class-${s.selectedClass?['id']}'),
    initialValue: s.selectedClass?['id'] as int?,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Lớp học',
      prefixIcon: Icon(Icons.school_outlined, size: 20),
    ),
    items: s.classes
        .map(
          (c) => DropdownMenuItem(
            value: c['id'] as int,
            child: Text(
              '${c['classCode']} • ${c['subjectCode']}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: s.busy
        ? null
        : (id) => action(
            () => s.selectClass(s.classes.firstWhere((c) => c['id'] == id)),
          ),
  );
  Widget sessionPicker() => DropdownButtonFormField<int>(
    key: ValueKey(
      'session-${s.selectedClass?['id']}-${s.selectedSession?['id']}',
    ),
    initialValue: s.sessions.any((x) => x['id'] == s.selectedSession?['id'])
        ? (s.selectedSession?['id'] as int?)
        : null,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Buổi học',
      prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
    ),
    items: s.sessions
        .map(
          (x) => DropdownMenuItem(
            value: x['id'] as int,
            child: Text(
              '#${x['id']} • ${date(x['startTime'])} • ${x['room'] ?? 'Chưa có phòng'}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: s.busy
        ? null
        : (id) => action(
            () => s.selectSession(s.sessions.firstWhere((x) => x['id'] == id)),
          ),
  );
  Widget selectors() => panel(
    LayoutBuilder(
      builder: (context, c) => c.maxWidth < 580
          ? Column(
              children: [
                classPicker(),
                const SizedBox(height: 16),
                sessionPicker(),
              ],
            )
          : Row(
              children: [
                Expanded(child: classPicker()),
                const SizedBox(width: 18),
                Expanded(child: sessionPicker()),
              ],
            ),
    ),
    padding: const EdgeInsets.all(18),
  );
  Widget sessionsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'SESSION MANAGEMENT',
        'Buổi học',
        'Chọn lớp học để quản lý các phiên điểm danh.',
        trailing: button(
          'Bắt đầu điểm danh (Slot hiện tại)',
          Icons.add,
          s.selectedClass == null ? null : createSession,
          primary: true,
        ),
      ),
      classPicker(),
      const SizedBox(height: 12),
      Align(
        alignment: Alignment.centerLeft,
        child: button(
          'Nhập tất cả lớp từ Sheet',
          Icons.library_add_outlined,
          importAllClasses,
        ),
      ),
      const SizedBox(height: 24),
      if (s.selectedClass != null) ...[
        panel(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  title(
                    '${str(s.selectedClass, 'classCode')} / ${str(s.selectedClass, 'subjectCode')}',
                  ),
                  badge(
                    '${s.selectedClass!['studentCount'] ?? 0} sinh viên',
                    color: const Color(0xFF1675BC),
                  ),
                  badge(str(s.selectedClass, 'semester'), color: muted),
                ],
              ),
              const SizedBox(height: 12),
              subtitle(
                'Google Sheet: ${str(s.selectedClass, 'sheetName', 'Chưa liên kết')}',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  button(
                    'Nhập từ Google Sheet',
                    Icons.table_chart_outlined,
                    importSheet,
                  ),
                  button('Xóa lớp học', Icons.delete_outline, deleteClass),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
      if (s.selectedClass == null)
        panel(
          empty(
            'Chọn một lớp học',
            'Danh sách buổi học sẽ xuất hiện tại đây.',
            Icons.calendar_month_outlined,
          ),
        )
      else if (s.sessions.isEmpty)
        panel(
          empty(
            'Chưa có buổi học',
            'Bắt đầu điểm danh để nhận mã QR.',
            Icons.event_available_outlined,
            action: button(
              'Bắt đầu điểm danh (Slot hiện tại)',
              Icons.add,
              createSession,
              primary: true,
            ),
          ),
        )
      else
        panel(
          Column(
            children: s.sessions
                .map(
                  (x) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: paleOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        color: fptOrange,
                        size: 21,
                      ),
                    ),
                    title: Text(
                      'Buổi #${x['id']} • ${date(x['startTime'])}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${date(x['startTime'], time: true)}  ·  Phòng ${x['room'] ?? '—'}',
                    ),
                    trailing: badge(
                      x['status'] == 'OPEN' ? 'Đang mở' : 'Đã đóng',
                      color: x['status'] == 'OPEN' ? green : muted,
                    ),
                    onTap: s.busy
                        ? null
                        : () => action(() async {
                            await s.selectSession(x);
                            setState(() => page = 3);
                          }),
                  ),
                )
                .toList(),
          ),
        ),
    ],
  );
  Widget attendancePage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'LIVE ATTENDANCE',
        'Điểm danh lớp học',
        'Một mã QR. Cả lớp kết nối. Kết quả cập nhật mỗi 5 giây.',
        trailing: button(
          'Bắt đầu điểm danh (Slot hiện tại)',
          Icons.add,
          s.selectedClass == null ? null : createSession,
          primary: true,
        ),
      ),
      selectors(),
      const SizedBox(height: 22),
      if (s.selectedSession == null)
        panel(
          empty(
            'Chọn buổi học để điểm danh',
            'Chọn lớp và buổi học ở phía trên, hoặc tạo một buổi mới.',
            Icons.qr_code_scanner,
          ),
        )
      else ...[
        grid([
          stat(
            'Sĩ số lớp',
            '${s.total}',
            'Sinh viên đã ghi danh',
            Icons.people_outline,
            const Color(0xFF1675BC),
          ),
          stat(
            'Đã điểm danh',
            '${s.present}',
            'Có mặt và đi muộn',
            Icons.task_alt,
            green,
          ),
          stat(
            s.open ? 'Chưa điểm danh' : 'Không có mặt',
            '${s.remaining}',
            s.open ? 'Đang chờ sinh viên' : 'Theo kết quả buổi học',
            Icons.schedule,
            fptOrange,
          ),
          stat(
            'Tỷ lệ tham gia',
            '${s.total == 0 ? 0 : (s.present * 100 / s.total).round()}%',
            'Trên tổng sĩ số lớp',
            Icons.pie_chart_outline,
            const Color(0xFF7D68C4),
          ),
        ], minWidth: 175),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, c) => c.maxWidth >= 810
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 302, child: qrPanel()),
                    const SizedBox(width: 20),
                    Expanded(child: attendanceTable()),
                  ],
                )
              : Column(
                  children: [
                    qrPanel(),
                    const SizedBox(height: 20),
                    attendanceTable(),
                  ],
                ),
        ),
      ],
    ],
  );
  int get qrSeconds =>
      (DateTime.tryParse(str(s.selectedSession, 'qrExpiresAt'))
                  ?.difference(DateTime.now())
                  .inSeconds ??
              0)
          .clamp(0, 86400);
  Widget qrGraphic({double size = 212}) {
    final valid =
        s.open && qrSeconds > 0 && s.selectedSession?['qrUrl'] != null;
    return Container(
      width: size + 26,
      height: size + 26,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(15),
      ),
      child: valid
          ? QrImageView(
              data: s.selectedSession!['qrUrl'] as String,
              version: QrVersions.auto,
              size: size,
              padding: const EdgeInsets.all(6),
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, size: 70, color: line),
                const SizedBox(height: 12),
                Text(
                  !s.open
                      ? 'Phiên đã đóng'
                      : qrSeconds == 0
                      ? 'Mã QR đã hết hạn'
                      : 'Chưa có link điểm danh',
                  style: const TextStyle(color: muted),
                ),
                if (s.open)
                  const Text(
                    'Cấu hình HTTPS rồi làm mới QR',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
              ],
            ),
    );
  }

  Widget qrPanel() => panel(
    Column(
      children: [
        Row(
          children: [
            Expanded(child: title('Mã QR điểm danh', size: 17)),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: s.open ? green : muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            subtitle('Buổi #${s.selectedSession!['id']}'),
            const Spacer(),
            badge(
              s.open ? 'Đang mở' : 'Đã đóng',
              color: s.open ? green : muted,
            ),
          ],
        ),
        const SizedBox(height: 23),
        qrGraphic(),
        const SizedBox(height: 17),
        if (s.open)
          badge(
            'Hiệu lực còn ${qrSeconds ~/ 60}:${(qrSeconds % 60).toString().padLeft(2, '0')}',
            color: qrSeconds > 30 ? fptOrange : Colors.red,
          ),
        const SizedBox(height: 15),
        subtitle(
          'Quét bằng camera điện thoại để mở form.\nĐăng nhập Google rồi xác nhận điểm danh.',
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: button(
            'Làm mới QR',
            Icons.refresh_rounded,
            s.open ? () => action(s.refreshQr) : null,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: button(
            'Trình chiếu mã QR',
            Icons.fullscreen_rounded,
            s.open && qrSeconds > 0 && s.selectedSession?['qrToken'] != null
                ? presentQr
                : null,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 19),
          child: Divider(height: 1),
        ),
        Row(
          children: [
            const Icon(Icons.meeting_room_outlined, color: muted, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Phòng ${str(s.selectedSession, 'room')}')),
            Text(
              date(s.selectedSession?['startTime'], time: true),
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: button(
            'Kết thúc điểm danh',
            Icons.stop_circle_outlined,
            s.open ? closeSession : null,
            primary: true,
          ),
        ),
      ],
    ),
    padding: const EdgeInsets.all(22),
  );
  Widget attendanceTable() {
    final rows = s.attendances
        .where(
          (a) =>
              (filter == 'ALL' || a['status'] == filter) &&
              '${a['studentName']} ${a['studentCode']} ${a['email']}'
                  .toLowerCase()
                  .contains(search.toLowerCase()),
        )
        .toList();
    return panel(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: title(
                  s.student ? 'Lịch sử điểm danh' : 'Danh sách điểm danh',
                  size: 18,
                ),
              ),
              if (!s.student)
                IconButton(
                  tooltip: 'Xuất Google Sheet',
                  onPressed: s.busy ? null : exportSession,
                  icon: const Icon(Icons.ios_share, size: 21, color: muted),
                ),
            ],
          ),
          const SizedBox(height: 5),
          subtitle(
            s.lastSync == null
                ? 'Chưa đồng bộ'
                : 'Cập nhật lúc ${date(s.lastSync!.toIso8601String(), time: true)}',
          ),
          const SizedBox(height: 18),
          searchBox('Tìm tên, mã sinh viên, email…'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                [
                      ('ALL', 'Tất cả'),
                      ('PRESENT', 'Có mặt'),
                      ('LATE', 'Đi muộn'),
                      ('ABSENT', 'Vắng'),
                      ('EXCUSED', 'Có phép'),
                    ]
                    .map(
                      (f) => ChoiceChip(
                        label: Text(f.$2, style: const TextStyle(fontSize: 11)),
                        selected: filter == f.$1,
                        onSelected: (_) => setState(() => filter = f.$1),
                        showCheckmark: false,
                        selectedColor: paleOrange,
                        side: BorderSide(
                          color: filter == f.$1
                              ? fptOrange.withValues(alpha: .25)
                              : line,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 17),
          if (rows.isEmpty)
            empty(
              'Chưa có kết quả',
              s.open
                  ? 'Kết quả sẽ xuất hiện khi sinh viên điểm danh.'
                  : 'Không có bản ghi phù hợp với bộ lọc.',
              Icons.fact_check_outlined,
            )
          else
            LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: c.maxWidth),
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(
                      Color(0xFFF7F9FB),
                    ),
                    headingRowHeight: 43,
                    dataRowMinHeight: 66,
                    dataRowMaxHeight: 66,
                    horizontalMargin: 12,
                    columnSpacing: 23,
                    dividerThickness: .5,
                    columns: [
                      const DataColumn(
                        label: Text(
                          'SINH VIÊN',
                          style: TextStyle(
                            fontSize: 10,
                            color: muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (s.student)
                        const DataColumn(
                          label: Text(
                            'BUỔI',
                            style: TextStyle(fontSize: 10, color: muted),
                          ),
                        ),
                      const DataColumn(
                        label: Text(
                          'THỜI GIAN',
                          style: TextStyle(
                            fontSize: 10,
                            color: muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const DataColumn(
                        label: Text(
                          'TRẠNG THÁI',
                          style: TextStyle(
                            fontSize: 10,
                            color: muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    rows: rows
                        .map(
                          (a) => DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFFF0F4F8),
                                      child: Text(
                                        str(
                                              a,
                                              'studentName',
                                              '?',
                                            ).characters.firstOrNull ??
                                            '?',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: muted,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          str(a, 'studentName'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          str(a, 'studentCode'),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (s.student)
                                DataCell(Text('#${a['sessionId']}')),
                              DataCell(
                                Text(
                                  s.student
                                      ? '${date(a['checkInTime'])}\n${date(a['checkInTime'], time: true)}'
                                      : date(a['checkInTime'], time: true),
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              DataCell(
                                badge(
                                  switch (a['status']) {
                                    'PRESENT' => 'Có mặt',
                                    'LATE' => 'Đi muộn',
                                    'ABSENT' => 'Vắng',
                                    'EXCUSED' => 'Có phép',
                                    _ => str(a, 'status'),
                                  },
                                  color: switch (a['status']) {
                                    'PRESENT' => green,
                                    'LATE' => fptOrange,
                                    'ABSENT' => const Color(0xFFD65B5B),
                                    _ => muted,
                                  },
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 15),
          subtitle(
            '${rows.length} bản ghi${s.open ? ' • Tự động đồng bộ mỗi 5 giây' : ''}',
          ),
        ],
      ),
      padding: const EdgeInsets.all(21),
    );
  }

  Widget reportsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'ATTENDANCE REPORTS',
        'Báo cáo điểm danh',
        'Xuất kết quả buổi học vào Google Sheet đã liên kết với lớp.',
      ),
      selectors(),
      const SizedBox(height: 24),
      panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.table_chart_outlined, color: green, size: 37),
            const SizedBox(height: 16),
            title('Kết quả sẵn sàng cho Google Sheet'),
            const SizedBox(height: 10),
            subtitle(
              'Báo cáo ghi mã A (có mặt) và AS (vắng) vào cột F của tab đã nhập.\nMỗi lần xuất sẽ cập nhật cột điểm danh trên tab đó.',
            ),
            const SizedBox(height: 24),
            if (s.selectedSession != null) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  badge('Buổi #${s.selectedSession!['id']}', color: muted),
                  badge('${s.present} có mặt'),
                  badge('${s.remaining} chưa có mặt', color: fptOrange),
                ],
              ),
              const SizedBox(height: 22),
            ],
            button(
              'Xuất báo cáo Google Sheet',
              Icons.ios_share_rounded,
              s.selectedSession == null ? null : exportSession,
              primary: true,
            ),
          ],
        ),
      ),
    ],
  );
  Widget settingsPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'ACCOUNT & CONNECTION',
        'Tài khoản & kết nối',
        'Thông tin được xác thực bởi hệ thống của nhà trường.',
      ),
      panel(
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFFFF2E8),
              backgroundImage: str(s.user, 'avatarUrl').isNotEmpty
                  ? NetworkImage(str(s.user, 'avatarUrl'))
                  : null,
              child: str(s.user, 'avatarUrl').isEmpty
                  ? Text(
                      str(s.user, 'fullName').isNotEmpty
                          ? str(s.user, 'fullName')[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        color: fptOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title(str(s.user, 'fullName'), size: 24),
                  const SizedBox(height: 8),
                  subtitle(str(s.user, 'email')),
                  const SizedBox(height: 12),
                  badge(str(s.user, 'role') == 'TEACHER' ? 'GIẢNG VIÊN' : 'SINH VIÊN', color: fptOrange),
                ],
              ),
            ),
            button(
              'Đồng bộ dữ liệu',
              Icons.sync,
              () => action(() async {
                s.user = await s.api.me();
              }),
            ),
          ],
        ),
      ),
    ],
  );
  Widget studentPage() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      heading(
        'STUDENT ATTENDANCE',
        'Điểm danh cá nhân',
        'Nhập mã QR được giảng viên cung cấp để xác nhận có mặt.',
        trailing: button(
          'Nhập mã điểm danh',
          Icons.qr_code,
          checkIn,
          primary: true,
        ),
      ),
      attendanceTable(),
    ],
  );

  Future<Map<String, String>?> form(
    String titleText,
    Map<String, String> fields, {
    String submit = 'Lưu',
    Set<String> optional = const {},
  }) async {
    final controllers = {
      for (final key in fields.keys) key: TextEditingController(),
    };
    final key = GlobalKey<FormState>();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titleText),
        content: SizedBox(
          width: 420,
          child: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: fields.entries
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: TextFormField(
                          controller: controllers[field.key],
                          decoration: InputDecoration(labelText: field.value),
                          validator: (v) =>
                              !optional.contains(field.key) &&
                                  (v == null || v.trim().isEmpty)
                              ? 'Vui lòng nhập ${field.value.toLowerCase()}'
                              : null,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(
                  context,
                  controllers.map((k, v) => MapEntry(k, v.text.trim())),
                );
              }
            },
            child: Text(submit),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final c in controllers.values) {
      c.dispose();
    }
    return result;
  }

  Future<bool> confirm(String name, String text, String accept) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(name),
          content: SizedBox(width: 420, child: Text(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(accept),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> createClass() async {
    final data = await form(
      'Tạo lớp học mới',
      {
        'classCode': 'Mã lớp',
        'subjectCode': 'Mã môn học',
        'semester': 'Học kỳ',
      },
      submit: 'Tạo lớp',
      optional: {'semester'},
    );
    if (data == null || !mounted) return;
    await action(() async {
      final item = await s.api.createClass(data);
      await s.reload();
      await s.selectClass(item);
      if (mounted) setState(() => page = 2);
    }, 'Đã tạo lớp học.');
  }

  Future<void> createSession() async {
    final id = s.selectedClass!['id'] as int;
    await action(() async {
      // Gọi API trực tiếp không cần nhập thông tin
      final item = await s.api.createSession(id, ''); 
      await s.reload();
      await s.selectSession(item);
      if (mounted) setState(() => page = 3);
    }, 'Buổi điểm danh đã mở.');
  }

  Future<void> deleteClass() async {
    final item = s.selectedClass!;
    if (!await confirm(
          'Xóa lớp ${item['classCode']}?',
          'Lớp học sẽ bị vô hiệu hóa và không còn xuất hiện trong danh sách hoạt động.',
          'Xóa lớp',
        ) ||
        !mounted) {
      return;
    }
    await action(() async {
      await s.api.deleteClass(item['id'] as int);
      await s.reload();
      if (mounted) setState(() => page = 1);
    }, 'Đã xóa lớp học.');
  }

  Future<void> closeSession() async {
    if (!await confirm(
          'Kết thúc điểm danh?',
          'Mã QR sẽ ngừng hoạt động. Backend sẽ ghi nhận vắng cho sinh viên chưa điểm danh.',
          'Kết thúc',
        ) ||
        !mounted) {
      return;
    }
    await action(s.closeSession, 'Đã kết thúc buổi điểm danh.');
  }

  Future<void> importAllClasses() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ImportClassesDialog(api: s.api),
    );
    if (!mounted || changed != true) return;
    await action(() async {
      await s.reload();
      if (mounted)
        setState(() {
          page = 1;
          search = '';
        });
    });
  }

  Future<void> importSheet() async {
    final id = s.selectedClass!['id'] as int;
    final data = await form('Liên kết Google Sheet', {
      'spreadsheetId': 'ID hoặc đường dẫn Google Sheet',
    }, submit: 'Lấy danh sách tab');
    if (data == null || !mounted) return;
    var sheetId = data['spreadsheetId']!;
    final match = RegExp(r'/spreadsheets/d/([^/]+)').firstMatch(sheetId);
    if (match != null) sheetId = match.group(1)!;
    List<Json> tabs = [];
    if (!await s.run(() async {
          tabs = await s.api.sheetTabs(sheetId);
        }) ||
        !mounted) {
      return;
    }
    if (tabs.isEmpty) {
      toast('Google Sheet không có tab để nhập.');
      return;
    }
    final tab = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Chọn tab danh sách sinh viên'),
        children: tabs
            .map(
              (t) => SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(context, t['sheetName'] as String),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        str(t, 'sheetName'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${str(t, 'subjectCode')} • ${str(t, 'classCode')}',
                        style: const TextStyle(color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (tab == null || !mounted) return;
    await action(() async {
      final result = await s.api.importSheet(id, sheetId, tab);
      await s.reload();
      if (s.selectedClass != null) await s.selectClass(s.selectedClass!);
      toast(
        'Đã nhập ${result['rowsImported']} sinh viên; bỏ qua ${result['rowsSkipped']} dòng.',
      );
    });
  }

  Future<void> exportSession() async {
    if (s.selectedSession == null) return;
    final id = s.selectedSession!['id'] as int;
    if (!await confirm(
          'Xuất báo cáo buổi #$id?',
          '${s.open ? 'Buổi học còn mở, kết quả có thể chưa đầy đủ. ' : ''}Thao tác sẽ cập nhật cột F trên Google Sheet của lớp, thay thế kết quả đã xuất trước đó.',
          'Xuất báo cáo',
        ) ||
        !mounted) {
      return;
    }
    await action(() async {
      final result = await s.api.exportSession(id);
      if (!mounted) return;
      final url = result['spreadsheetUrl']?.toString();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Đã xuất báo cáo'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result['presentCount']} có mặt • ${result['absentCount']} vắng\nTab: ${result['sheetName']}',
                ),
                if (url != null) ...[
                  const SizedBox(height: 18),
                  SelectableText(url),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            if (url != null)
              FilledButton(
                onPressed: () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null &&
                      uri.scheme == 'https' &&
                      uri.host == 'docs.google.com') {
                    try {
                      if (!await launchUrl(uri)) {
                        toast(
                          'Không mở được trình duyệt. Bạn có thể sao chép đường dẫn.',
                        );
                      }
                    } catch (_) {
                      toast(
                        'Không mở được trình duyệt. Bạn có thể sao chép đường dẫn.',
                      );
                    }
                  }
                },
                child: const Text('Mở Google Sheet'),
              ),
          ],
        ),
      );
    });
  }

  Future<void> checkIn() async {
    final data = await form('Điểm danh bằng mã QR', {
      'qrToken': 'Mã QR token',
    }, submit: 'Xác nhận điểm danh');
    if (data == null || !mounted) return;
    await action(() async {
      await s.api.checkIn(data['qrToken']!);
      await s.reload();
    }, 'Điểm danh thành công.');
  }

  Future<void> presentQr() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: StreamBuilder<int>(
          stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
          builder: (context, snapshot) => Container(
            color: const Color(0xFFF6F8FA),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      brand(),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Đóng trình chiếu',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          title(
                            '${str(s.selectedClass, 'classCode')} • Phòng ${str(s.selectedSession, 'room')}',
                            size: 30,
                          ),
                          const SizedBox(height: 12),
                          subtitle(
                            'Mở ứng dụng sinh viên và quét mã để điểm danh',
                          ),
                          const SizedBox(height: 30),
                          qrGraphic(size: 330),
                          const SizedBox(height: 22),
                          badge(
                            s.open
                                ? 'Còn ${qrSeconds ~/ 60}:${(qrSeconds % 60).toString().padLeft(2, '0')}'
                                : 'Đã kết thúc',
                            color: fptOrange,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${s.present} / ${s.total} sinh viên đã điểm danh',
                          ),
                          const SizedBox(height: 25),
                          if (s.open)
                            button(
                              'Làm mới QR',
                              Icons.refresh,
                              () => action(s.refreshQr),
                            ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
