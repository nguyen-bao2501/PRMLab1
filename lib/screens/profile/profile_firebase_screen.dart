import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/firebase_demo_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';
import '../../widgets/campus_cards.dart';
import '../reports/attendance_report_screen.dart';

class ProfileFirebaseScreen extends StatelessWidget {
  const ProfileFirebaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final fbVm = context.watch<FirebaseDemoViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CampusAppBar(
        title: 'HỒ SƠ & FIREBASE DEMO',
        subtitle: 'Khu vực chấm điểm 6 dịch vụ Cloud',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFD6E9A4),
                    child: Text(
                      user?.displayName.isNotEmpty == true ? user!.displayName[0] : 'N',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Giảng viên FPT',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.email ?? 'giangvien@fpt.edu.vn',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const StatusBadgePill(label: 'Đã xác thực Google', statusType: StatusType.success),
                            const SizedBox(width: 8),
                            Text('UID: ${user?.uid.substring(0, user.uid.length > 8 ? 8 : user.uid.length) ?? "anon"}...',
                                style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space14),

            // Demo Status Message
            if (fbVm.statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccessBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.statusSuccess),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.statusSuccess, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fbVm.statusMessage!,
                        style: const TextStyle(color: AppColors.statusSuccess, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space14),
            ],

            // Section: 6 Dịch Vụ Firebase Chấm Điểm
            Text('MINH CHỨNG 6 DỊCH VỤ FIREBASE (LAB 3)',
                style: AppTypography.labelLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            // 1. Firebase Auth
            _buildServiceCard(
              title: '1. Firebase Authentication',
              status: authVm.isAuthenticated ? 'Đang hoạt động' : 'Chưa đăng nhập',
              isSuccess: authVm.isAuthenticated,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đăng nhập bằng Google Sign-In & routing theo auth state.', style: AppTypography.bodySmall),
                  const SizedBox(height: 8),
                  SecondaryOutlineButton(
                    text: 'Đăng xuất tài khoản (Xóa cache)',
                    icon: const Icon(Icons.logout, size: 16),
                    height: 38,
                    onPressed: () async {
                      await authVm.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Firebase Cloud Storage
            _buildServiceCard(
              title: '2. Firebase Cloud Storage',
              status: 'reports/{uid}/...',
              isSuccess: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tạo file PDF báo cáo điểm danh và tải lên đường dẫn riêng của user.', style: AppTypography.bodySmall),
                  const SizedBox(height: 8),
                  PrimaryGoldButton(
                    text: 'Mở màn hình Xuất PDF & Storage',
                    height: 38,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. Firebase Cloud Messaging (FCM)
            _buildServiceCard(
              title: '3. Cloud Messaging (FCM)',
              status: '${fbVm.notifications.length} tin nhắn',
              isSuccess: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nhận thông báo ở foreground, background và terminated.', style: AppTypography.bodySmall),
                  const SizedBox(height: 8),
                  SecondaryOutlineButton(
                    text: 'Giả lập nhận thông báo mới',
                    icon: const Icon(Icons.notifications_active_outlined, size: 16),
                    height: 38,
                    onPressed: () => fbVm.addMockPushNotification(),
                  ),
                  if (fbVm.notifications.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...fbVm.notifications.map((n) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(n.body, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. Firebase Analytics
            _buildServiceCard(
              title: '4. Firebase Analytics',
              status: '7+ Events được ghi',
              isSuccess: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tự động ghi nhận: login, logout, search, view_class, view_schedule, start_attendance, export_report.', style: AppTypography.bodySmall),
                  const SizedBox(height: 6),
                  Text('Mã định danh User ID đã gán: ${user?.uid ?? "anon"}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 5. Firebase Crashlytics
            _buildServiceCard(
              title: '5. Firebase Crashlytics',
              status: 'Handled error & Test crash',
              isSuccess: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ghi nhận non-fatal error và kích hoạt crash thử nghiệm đính kèm custom keys.', style: AppTypography.bodySmall),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryOutlineButton(
                          text: 'Gửi Non-Fatal Error',
                          height: 38,
                          onPressed: () => fbVm.sendTestNonFatalError(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DangerActionButton(
                          text: 'Test Crash App',
                          onPressed: () => fbVm.triggerTestCrash(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 6. Firebase Remote Config
            _buildServiceCard(
              title: '6. Firebase Remote Config',
              status: 'Thay đổi không cần build',
              isSuccess: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Bật/Tắt nút OCR Lịch học: ${fbVm.ocrEnabled ? "ĐANG BẬT" : "TẮT"}', style: AppTypography.bodySmall),
                  Text('• Thời gian tự đồng bộ: ${fbVm.syncInterval} giây', style: AppTypography.bodySmall),
                  Text('• Banner thông báo: "${fbVm.announcementText}"', style: AppTypography.bodySmall),
                  const SizedBox(height: 10),
                  PrimaryGoldButton(
                    text: 'Fetch & Activate từ Console',
                    icon: const Icon(Icons.sync, size: 16),
                    height: 38,
                    onPressed: () => fbVm.fetchRemoteConfig(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String status,
    required bool isSuccess,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.statusSuccessBg : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSuccess ? AppColors.statusSuccess : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
