import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../models/ui_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../../viewmodels/live_attendance_view_model.dart';
import '../../viewmodels/schedule_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';
import '../../widgets/campus_cards.dart';
import '../../widgets/state_views.dart';
import '../attendance/live_attendance_screen.dart';
import '../classes/class_list_screen.dart';
import '../profile/profile_firebase_screen.dart';
import '../schedule/create_schedule_screen.dart';
import '../schedule/schedule_week_screen.dart';
import '../schedule/session_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;
    final initialLetter = (user?.displayName.isNotEmpty == true) ? user!.displayName[0].toUpperCase() : 'GV';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CampusAppBar(
        title: 'CAMPUS / TỔNG QUAN',
        subtitle: user?.role == 'STUDENT' ? 'Cổng thông tin sinh viên' : 'Bảng điều khiển giảng viên',
        avatarLetter: initialLetter,
        onAvatarTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfileFirebaseScreen()),
          );
        },
      ),
      drawer: _buildAppDrawer(context, user),
      body: RefreshIndicator(
        onRefresh: () => vm.loadDashboard(),
        color: AppColors.accentGold,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Card
              CampusHeroCard(
                title: 'Tổng quan giảng dạy',
                subtitle: 'Quản lý lớp, lịch dạy và điểm danh.',
                updateTime: switch (vm.state) {
                  UiSuccess(:final data) => data.lastUpdated,
                  _ => '09:40',
                },
              ),
              const SizedBox(height: AppDimens.space14),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: PrimaryGoldButton(
                      text: '+ Tạo lớp học',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ClassListScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimens.space10),
                  Expanded(
                    child: SecondaryOutlineButton(
                      text: 'Xếp lịch',
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CreateScheduleScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // OCR Schedule Button (Controlled via Firebase Remote Config)
              if (vm.isOcrEnabled) ...[
                const SizedBox(height: AppDimens.space10),
                SecondaryOutlineButton(
                  text: 'Đọc lịch từ ảnh',
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng OCR Lịch học đang kích hoạt qua Firebase Remote Config!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: AppDimens.space16),

              // Filters & Auto-sync bar
              Container(
                padding: const EdgeInsets.all(AppDimens.space12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tất cả học kỳ', style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
                                const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              // theme đặt minimumSize rộng vô hạn → vỡ layout trong Row
                              minimumSize: const Size(0, 42),
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.borderCard),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => vm.syncNow(),
                            icon: const Icon(Icons.refresh, size: 16, color: AppColors.textPrimary),
                            label: Text('Đồng bộ', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tự đồng bộ 30 giây', style: AppTypography.bodyMedium),
                        Switch(
                          value: vm.autoSyncEnabled,
                          activeTrackColor: AppColors.statusSuccess,
                          onChanged: (val) => vm.toggleAutoSync(val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              // UI State Switcher
              switch (vm.state) {
                UiLoading(:final message) => AppLoadingView(message: message ?? 'Đang tải...'),
                UiError(:final message) => AppErrorView(
                    message: message,
                    onRetry: () => vm.loadDashboard(),
                  ),
                UiEmpty(:final message) => AppEmptyView(
                    title: 'Chưa có dữ liệu',
                    description: message,
                  ),
                UiSuccess(:final data) => _buildDashboardContent(context, data),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two Metric Stat Cards
        Row(
          children: [
            Expanded(
              child: MetricStatCard(
                title: 'Tiết hôm nay',
                value: data.todaySessions.length.toString(),
                icon: Icons.calendar_month_rounded,
                iconBg: AppColors.statusBlueBg,
                iconColor: AppColors.statusBlue,
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: MetricStatCard(
                title: 'Đang điểm danh',
                value: data.activeSessionsCount.toString(),
                icon: Icons.wifi_tethering_rounded,
                iconBg: AppColors.statusSuccessBg,
                iconColor: AppColors.statusSuccess,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space20),

        // Section: Tiết hôm nay
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tiết hôm nay', style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('09:40 Hiện tại', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space12),

        ...data.todaySessions.map((session) {
          final isActive = session.status == SessionStatus.active;
          return TeachingSessionCard(
            subjectCode: session.subjectCode,
            className: session.className,
            room: session.room,
            timeSlot: session.timeRange,
            statusLabel: isActive ? 'Đang điểm danh' : 'Chưa đến giờ',
            statusType: isActive ? StatusType.success : StatusType.warning,
            actionText: isActive ? 'Xem điểm danh' : 'Xem chi tiết',
            isActive: isActive,
            onAction: () {
              if (isActive) {
                context.read<LiveAttendanceViewModel>().initialize(session);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LiveAttendanceScreen()),
                );
              } else {
                context.read<ScheduleViewModel>().selectSession(session);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SessionDetailScreen()),
                );
              }
            },
          );
        }),

        const SizedBox(height: AppDimens.space16),

        // Section: Các tiết sắp tới
        Text('Các tiết sắp tới', style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppDimens.space12),

        ...data.upcomingSessions.map((session) {
          return TeachingSessionCard(
            subjectCode: session.subjectCode,
            className: session.className,
            room: session.room,
            timeSlot: session.timeRange,
            statusLabel: 'Ngày mai',
            statusType: StatusType.blue,
            actionText: 'Xem chi tiết',
            isActive: false,
            onAction: () {
              context.read<ScheduleViewModel>().selectSession(session);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SessionDetailScreen()),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildAppDrawer(BuildContext context, UserModel? user) {
    final initialLetter = (user?.displayName.isNotEmpty == true) ? user!.displayName[0].toUpperCase() : 'GV';
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFD6E9A4),
                  child: Text(initialLetter, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 20)),
                ),
                const SizedBox(height: 10),
                Text(user?.displayName ?? 'Giảng viên FPT', style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                Text(user?.email ?? 'gv_campus@fpt.edu.vn', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Tổng quan giảng dạy'),
            selected: true,
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.class_outlined),
            title: const Text('Lớp học của tôi'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClassListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Lịch dạy tuần'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScheduleWeekScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_outlined, color: AppColors.fptOrange),
            title: const Text('Firebase Demo Area'),
            subtitle: const Text('Chấm điểm 6 dịch vụ Cloud'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileFirebaseScreen()));
            },
          ),
        ],
      ),
    );
  }
}
