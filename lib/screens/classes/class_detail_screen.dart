import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/class_view_model.dart';
import '../../viewmodels/live_attendance_view_model.dart';
import '../../viewmodels/report_view_model.dart';
import '../../viewmodels/schedule_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';
import '../../widgets/campus_cards.dart';
import '../attendance/live_attendance_screen.dart';
import '../reports/attendance_report_screen.dart';
import '../schedule/create_schedule_screen.dart';
import '../schedule/session_detail_screen.dart';
import 'import_sheet_screen.dart';

class ClassDetailScreen extends StatelessWidget {
  const ClassDetailScreen({super.key, required this.classItem});

  final ClassModel classItem;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClassViewModel>();
    final absentStudents = vm.topAbsentStudents;
    final bannedStudents = absentStudents
        .where((student) => student.absentCount > 4)
        .toList();
    final concerningStudents = absentStudents
        .where((student) => student.absentCount >= 3 && student.absentCount <= 4)
        .toList();
    final totalAbsences = absentStudents.fold<int>(
      0,
      (total, student) => total + student.absentCount,
    );
    final completedSessions = absentStudents.isEmpty
        ? 0
        : absentStudents.map((student) => student.totalSessions).reduce(
              (value, element) => value > element ? value : element,
            );
    final absenceRate = classItem.studentCount == 0 || completedSessions == 0
        ? 0.0
        : totalAbsences / (classItem.studentCount * completedSessions) * 100;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CampusAppBar(
        title: 'Chi tiết lớp',
        showBack: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (val) {
              if (val == 'export_pdf') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Xem báo cáo & Xuất PDF'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Class Info Header Card
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
                      const Icon(Icons.menu_book_rounded, color: AppColors.textPrimary, size: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(classItem.semester, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    classItem.subjectCode,
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  Text(
                    'LỚP ${classItem.className}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text('${classItem.studentCount} sinh viên', style: AppTypography.bodySmall),
                      const SizedBox(width: 16),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text('${classItem.sessionCount} buổi học', style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.statusSuccess,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Đã liên kết Google Sheet',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.statusSuccess),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.insert_drive_file_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          classItem.sheetTab ?? '12_PRM393_SE1917',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              text: 'Nhập từ Google Sheet',
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              onPressed: () {
                vm.startImportFlow(classItem);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportSheetScreen()),
                );
              },
            ),
            const SizedBox(height: AppDimens.space24),

            // Section: Tiết học
            Text('Tiết học', style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              '8 tiết · 5 đã kết thúc · 1 đang điểm danh · 2 chưa mở',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimens.space12),

            // Session Items
            _buildSessionRow(
              context: context,
              dateStr: '03/10\nT7',
              slotTitle: 'Slot 2 · 09:30 – 11:45',
              room: 'Phòng A101',
              statusLabel: 'Đang điểm danh',
              statusType: StatusType.success,
              isActive: true,
              onTap: () {
                final session = SessionModel(
                  id: 's1',
                  classId: classItem.id,
                  subjectCode: classItem.subjectCode,
                  className: classItem.className,
                  room: 'A101',
                  slot: 2,
                  timeRange: 'Slot 2 · 09:30 – 11:45',
                  date: '03/10/2026',
                  dayOfWeek: 'T7',
                  status: SessionStatus.active,
                  attendedCount: 28,
                  totalCount: 35,
                );
                context.read<LiveAttendanceViewModel>().initialize(session);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LiveAttendanceScreen()),
                );
              },
            ),

            _buildSessionRow(
              context: context,
              dateStr: '04/10\nCN',
              slotTitle: 'Slot 1 · 07:00 – 09:15',
              room: 'Phòng A101',
              statusLabel: 'Chưa mở',
              statusType: StatusType.neutral,
              isActive: false,
              onTap: () {
                final session = SessionModel(
                  id: 's3',
                  classId: classItem.id,
                  subjectCode: classItem.subjectCode,
                  className: classItem.className,
                  room: 'A101',
                  slot: 1,
                  timeRange: 'Slot 1 · 07:00 – 09:15',
                  date: '04/10/2026',
                  dayOfWeek: 'CN',
                  status: SessionStatus.upcoming,
                );
                context.read<ScheduleViewModel>().selectSession(session);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SessionDetailScreen()),
                );
              },
            ),

            _buildSessionRow(
              context: context,
              dateStr: '06/10\nT2',
              slotTitle: 'Slot 2 · 09:30 – 11:45',
              room: 'Phòng A101',
              statusLabel: 'Chưa mở',
              statusType: StatusType.neutral,
              isActive: false,
              onTap: () {
                final session = SessionModel(
                  id: 's4',
                  classId: classItem.id,
                  subjectCode: classItem.subjectCode,
                  className: classItem.className,
                  room: 'A101',
                  slot: 2,
                  timeRange: 'Slot 2 · 09:30 – 11:45',
                  date: '06/10/2026',
                  dayOfWeek: 'T2',
                  status: SessionStatus.upcoming,
                );
                context.read<ScheduleViewModel>().selectSession(session);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SessionDetailScreen()),
                );
              },
            ),

            // Accordion: Đã kết thúc (5) Lịch sử
            InkWell(
              onTap: () {
                context.read<ReportViewModel>().loadReport();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
                );
              },
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Đã kết thúc (5)   Lịch sử', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                    const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // Section: Quản lý chuyên cần
            Text(
              'Quản lý chuyên cần',
              style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Theo dõi sĩ số và cảnh báo điều kiện dự thi.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimens.space12),
            Row(
              children: [
                _buildAttendanceMetric(
                  icon: Icons.groups_outlined,
                  label: 'Thành viên',
                  value: '${classItem.studentCount}',
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
                _buildAttendanceMetric(
                  icon: Icons.warning_amber_rounded,
                  label: 'Cần lưu ý',
                  value: '${concerningStudents.length}',
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                _buildAttendanceMetric(
                  icon: Icons.block_outlined,
                  label: 'Cấm thi',
                  value: '${bannedStudents.length}',
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space24),

            // Section: Tổng quan khóa học
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
                  Text('Tổng quan khóa học', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                  Text('Thống kê điểm danh tích lũy', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: AppDimens.space16),

                  // Attendance Rate Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('TỶ LỆ VẮNG', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                                Text('${absenceRate.toStringAsFixed(1)}%', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, fontSize: 24)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$totalAbsences / ${classItem.studentCount * completedSessions} lượt vắng',
                                style: const TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('• Chỉ tính các tiết đã kết thúc.', style: AppTypography.bodySmall.copyWith(fontSize: 12)),
                        Text('• Tỷ lệ tính trên các bản ghi điểm danh thực tế.', style: AppTypography.bodySmall.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Top absent students list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sinh viên vắng nhiều nhất', style: AppTypography.labelLarge),
                      Text('(Tổng cộng $totalAbsences lượt)', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (absentStudents.isEmpty)
                    Text('Chưa có dữ liệu điểm danh đã hoàn tất.', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted))
                  else
                    ...absentStudents.map(_buildAbsentStudentRow),
                  if (bannedStudents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Sinh viên vắng quá 4 buổi được gắn trạng thái cấm thi.',
                      style: AppTypography.bodySmall.copyWith(color: const Color(0xFFDC2626)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionRow({
    required BuildContext context,
    required String dateStr,
    required String slotTitle,
    required String room,
    required String statusLabel,
    required StatusType statusType,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space10),
      padding: const EdgeInsets.all(AppDimens.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(
          color: isActive ? AppColors.statusSuccess.withValues(alpha: 0.6) : AppColors.borderCard,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.statusSuccessBg : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                dateStr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isActive ? AppColors.statusSuccess : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(slotTitle, style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                  Text(room, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            StatusBadgePill(label: statusLabel, statusType: statusType),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          border: Border.all(color: AppColors.borderCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.titleLarge.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsentStudentRow(AbsentSummaryItem student) {
    final isBanned = student.absentCount > 4;
    final isWarning = student.absentCount >= 3;
    final bg = isBanned
        ? const Color(0xFFFEE2E2)
        : isWarning
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFF3F4F6);
    final fg = isBanned
        ? const Color(0xFFDC2626)
        : isWarning
            ? const Color(0xFFD97706)
            : const Color(0xFF6B7280);
    final badgeText = isBanned
        ? 'Cấm thi · vắng ${student.absentCount} buổi'
        : 'Vắng ${student.absentCount}/${student.totalSessions} buổi (${student.percent.toStringAsFixed(0)}%)';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
              Text(student.studentId, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
