import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/live_attendance_view_model.dart';
import '../../viewmodels/schedule_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';
import '../../widgets/campus_cards.dart';
import '../attendance/live_attendance_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();
    final session = scheduleVm.selectedSession ??
        const SessionModel(
          id: 's_default',
          classId: 'c1',
          subjectCode: 'PRM393',
          className: 'SE1917',
          room: 'A101',
          slot: 1,
          timeRange: '07:00 – 09:15',
          date: '04/10/2026',
          dayOfWeek: 'CN',
          status: SessionStatus.upcoming,
        );

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CampusAppBar(
        title: 'Chi tiết tiết học',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        child: Column(
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.textPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.subjectCode, style: AppTypography.titleLarge.copyWith(fontSize: 18)),
                        Text('LỚP ${session.className}', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEAA5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('FA2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space14),

            // Section 1: Thông tin tiết học
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin tiết học', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),

                  _buildInfoRow(Icons.calendar_today_outlined, 'Ngày học', 'Thứ Bảy, ${session.date}', AppColors.statusSuccess),
                  const Divider(height: 18),
                  _buildInfoRow(Icons.access_time, 'Ca học', 'Slot ${session.slot}', AppColors.accentGold),
                  const Divider(height: 18),
                  _buildInfoRow(Icons.schedule, 'Khung giờ', session.timeRange, AppColors.statusBlue),
                  const Divider(height: 18),
                  _buildInfoRow(Icons.location_on_outlined, 'Phòng học', 'Phòng ${session.room}', AppColors.primaryDark),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space14),

            // Section 2: Trạng thái điểm danh
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
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
                      Text('Trạng thái điểm danh', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                      const StatusBadgePill(label: 'Chưa mở', statusType: StatusType.neutral),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Alert box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFB45309)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tiết học chưa đến giờ điểm danh. Bạn có thể bấm "Bắt đầu điểm danh" để mở phiên sớm.',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF92400E),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  PrimaryGoldButton(
                    text: 'Bắt đầu điểm danh',
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    onPressed: () {
                      final liveSession = SessionModel(
                        id: session.id,
                        classId: session.classId,
                        subjectCode: session.subjectCode,
                        className: session.className,
                        room: session.room,
                        slot: session.slot,
                        timeRange: session.timeRange,
                        date: session.date,
                        dayOfWeek: session.dayOfWeek,
                        status: SessionStatus.active,
                        attendedCount: 28,
                        totalCount: 35,
                      );
                      context.read<LiveAttendanceViewModel>().initialize(liveSession);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LiveAttendanceScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sau khi bấm bắt đầu, hệ thống sẽ mở phiên điểm danh và tự động tạo mã QR động cho sinh viên quét.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
        const Spacer(),
        Text(value, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
      ],
    );
  }
}
