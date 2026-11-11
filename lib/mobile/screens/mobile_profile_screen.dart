import 'package:flutter/material.dart';

import '../services/mobile_auth_service.dart';

class MobileProfileScreen extends StatelessWidget {
  const MobileProfileScreen({
    super.key,
    required this.authService,
    required this.onLoggedOut,
  });

  final MobileAuthService authService;
  final VoidCallback onLoggedOut;

  void _showChangeServerDialog(BuildContext context) {
    final urlController = TextEditingController(text: authService.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cài đặt Máy chủ (API)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nhập địa chỉ máy chủ backend Spring Boot kết nối:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF3A504E)),
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await authService.updateBaseUrl(newUrl);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cập nhật máy chủ: $newUrl')),
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng điểm danh không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ở lại')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await authService.signOut();
              onLoggedOut();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fptOrange = Color(0xFFF37021);
    const ink = Color(0xFF3A504E);
    final user = authService.currentUser;

    final initial = (user?.fullName.isNotEmpty == true)
        ? user!.fullName.characters.first.toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Hồ sơ & Cài đặt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Student Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: fptOrange.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: fptOrange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Sinh viên FPT',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0ED),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user?.studentCode != null && user!.studentCode!.isNotEmpty
                              ? 'MSSV: ${user.studentCode}'
                              : 'Vai trò: ${user?.role ?? "STUDENT"}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'HỆ THỐNG & KẾT NỐI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 10),

          // Server settings item
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dns_rounded, color: ink, size: 20),
              ),
              title: const Text('Địa chỉ máy chủ (API URL)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                authService.baseUrl,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              onTap: () => _showChangeServerDialog(context),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'HƯỚNG DẪN ĐIỂM DANH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDF2F7)),
            ),
            child: const Column(
              children: [
                _GuideStep(step: '1', text: 'Giảng viên mở buổi học và chiếu mã QR trên màn hình.'),
                Divider(height: 18),
                _GuideStep(step: '2', text: 'Chuyển sang tab "Quét QR", hướng camera vào mã chiếu.'),
                Divider(height: 18),
                _GuideStep(step: '3', text: 'Hệ thống tự động xác nhận có mặt và cập nhật vào lịch sử.'),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Logout Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Color(0xFFFFD0CC)),
              backgroundColor: const Color(0xFFFFECEB).withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => _confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              'Đăng xuất tài khoản',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.step, required this.text});
  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F0ED),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3A504E)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }
}
