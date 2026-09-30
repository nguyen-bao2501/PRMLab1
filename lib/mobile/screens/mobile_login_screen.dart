import 'package:flutter/material.dart';

import '../services/mobile_auth_service.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({
    super.key,
    required this.authService,
    required this.onLoginSuccess,
  });

  final MobileAuthService authService;
  final VoidCallback onLoginSuccess;

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final _emailController = TextEditingController(text: 'student1@fpt.edu.vn');
  bool _isDevMode = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _errorMessage = null);
    try {
      await widget.authService.signInWithGoogle();
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  Future<void> _handleDevSignIn() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập email để đăng nhập thử nghiệm.');
      return;
    }
    setState(() => _errorMessage = null);
    try {
      await widget.authService.signInWithDev(email, role: 'STUDENT');
      if (mounted) widget.onLoginSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  void _showServerSettingsDialog() {
    final urlController = TextEditingController(text: widget.authService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: Color(0xFFF37021)),
            SizedBox(width: 10),
            Text('Cài đặt Máy chủ (API)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập địa chỉ máy chủ backend Spring Boot (ví dụ: máy tính chạy port 8080 trong mạng LAN):',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://192.168.1.x:8080',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('10.0.2.2 (Emulator)', style: TextStyle(fontSize: 11)),
                  onPressed: () => urlController.text = 'http://10.0.2.2:8080',
                ),
                ActionChip(
                  label: const Text('localhost', style: TextStyle(fontSize: 11)),
                  onPressed: () => urlController.text = 'http://localhost:8080',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3A504E)),
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await widget.authService.updateBaseUrl(newUrl);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật server: ${widget.authService.baseUrl}')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fptOrange = Color(0xFFF37021);
    const ink = Color(0xFF3A504E);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: ink),
            tooltip: 'Cài đặt máy chủ',
            onPressed: _showServerSettingsDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & Header Brand
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: fptOrange.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 54,
                    color: fptOrange,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'FPT UNIVERSITY',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: fptOrange,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Điểm danh Sinh viên (Mobile Pass)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 32),

                // Main Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Chào mừng bạn,',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Đăng nhập bằng tài khoản sinh viên FPT để sẵn sàng quét mã điểm danh.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD0CC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFFC53030),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Google Sign-In Button
                      ListenableBuilder(
                        listenable: widget.authService,
                        builder: (context, _) {
                          final loading = widget.authService.isLoading;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 1,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: loading ? null : _handleGoogleSignIn,
                            child: loading && !_isDevMode
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'https://fonts.gstatic.com/s/i/productlogos/googleg/v6/24px.svg',
                                        height: 20,
                                        width: 20,
                                        errorBuilder: (context, error, stackTrace) => const Icon(
                                          Icons.account_circle,
                                          color: Colors.blueAccent,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Đăng nhập với Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Toggle Dev Login
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: InkWell(
                              onTap: () => setState(() => _isDevMode = !_isDevMode),
                              child: Text(
                                _isDevMode ? 'Ẩn chế độ thử nghiệm' : 'Chế độ Dev Login',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8B9D9B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      if (_isDevMode) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE3E8EF)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.science_outlined, size: 16, color: ink),
                                  SizedBox(width: 6),
                                  Text(
                                    'Đăng nhập nhanh (Bỏ qua Google)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  labelText: 'Email sinh viên trong lớp',
                                  hintText: 'student1@fpt.edu.vn',
                                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                children: [
                                  ActionChip(
                                    label: const Text('student1@fpt.edu.vn', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _emailController.text = 'student1@fpt.edu.vn',
                                  ),
                                  ActionChip(
                                    label: const Text('student2@fpt.edu.vn', style: TextStyle(fontSize: 11)),
                                    onPressed: () => _emailController.text = 'student2@fpt.edu.vn',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ListenableBuilder(
                                listenable: widget.authService,
                                builder: (context, _) {
                                  final loading = widget.authService.isLoading;
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: ink,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: loading ? null : _handleDevSignIn,
                                    child: loading && _isDevMode
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Đăng nhập Dev'),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Footer Base URL Info
                InkWell(
                  onTap: _showServerSettingsDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_queue_rounded, size: 14, color: Colors.black45),
                        const SizedBox(width: 6),
                        Text(
                          'Server: ${widget.authService.baseUrl}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit_outlined, size: 12, color: Colors.black38),
                      ],
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
