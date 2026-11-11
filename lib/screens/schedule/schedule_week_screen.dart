import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../models/ui_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/live_attendance_view_model.dart';
import '../../viewmodels/schedule_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';
import '../../widgets/campus_cards.dart';
import '../../widgets/state_views.dart';
import '../attendance/live_attendance_screen.dart';
import 'create_schedule_screen.dart';
import 'session_detail_screen.dart';

class ScheduleWeekScreen extends StatefulWidget {
  const ScheduleWeekScreen({super.key});

  @override
  State<ScheduleWeekScreen> createState() => _ScheduleWeekScreenState();
}

class _ScheduleWeekScreenState extends State<ScheduleWeekScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleViewModel>().loadSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScheduleViewModel>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CampusAppBar(
        title: 'CAMPUS / LỊCH DẠY',
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.loadSchedule(),
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
              const CampusHeroCard(
                title: 'Lịch dạy',
                subtitle: 'Theo dõi lịch tuần và quản lý từng tiết học.',
                updateTime: '09:40',
              ),
              const SizedBox(height: AppDimens.space14),

              // Action Buttons
              PrimaryGoldButton(
                text: 'Xếp lịch tiết học',
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateScheduleScreen()),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space10),
              SecondaryOutlineButton(
                text: 'Đọc lịch từ ảnh',
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng OCR Lịch học đang sẵn sàng!')),
                  );
                },
              ),
              const SizedBox(height: AppDimens.space16),

              // Week Calendar Strip Card
              Container(
                padding: const EdgeInsets.all(AppDimens.space16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {},
                            ),
                            const SizedBox(width: 8),
                            Text('28/09 – 04/10/2026', style: AppTypography.labelLarge),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.statusBlueBg,
                            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                          ),
                          child: Text(
                            'Hôm nay',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.statusBlue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Day Columns (T2 -> CN)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: vm.weekDays.map((day) {
                        final isSelected = day.day == vm.selectedDate.day;
                        final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                        final label = dayLabels[day.weekday - 1];

                        return InkWell(
                          onTap: () => vm.selectDate(day),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 38,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryDark : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white70 : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  day.day.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFACC15),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space20),

              // Sessions in selected date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thứ Bảy, 03/10',
                    style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('2 tiết học', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space12),

              switch (vm.scheduleState) {
                UiLoading(:final message) => AppLoadingView(message: message ?? 'Đang tải...'),
                UiError(:final message) => AppErrorView(
                    message: message,
                    onRetry: () => vm.loadSchedule(),
                  ),
                UiEmpty(:final message) => AppEmptyView(
                    title: 'Không có lịch dạy',
                    description: message,
                  ),
                UiSuccess(:final data) => Column(
                    children: data.map((session) {
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
                            vm.selectSession(session);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SessionDetailScreen()),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
