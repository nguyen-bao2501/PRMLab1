import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/live_attendance_view_model.dart';
import '../../viewmodels/report_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';
import '../../widgets/campus_cards.dart';
import '../reports/attendance_report_screen.dart';

class LiveAttendanceScreen extends StatelessWidget {
  const LiveAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LiveAttendanceViewModel>();
    final session = vm.currentSession;

    final secondsStr = vm.countdownSeconds.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CampusAppBar(
        title: 'Điểm danh',
        subtitle: 'Rời màn hình không làm tắt phiên',
        showBack: true,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.statusSuccessBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppColors.statusSuccess, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Cập nhật 5s',
                  style: TextStyle(color: AppColors.statusSuccess, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
            // Top Live Session Header Card
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
                      const StatusBadgePill(
                        label: 'Đang điểm danh trực tiếp',
                        statusType: StatusType.success,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Slot ${session?.slot ?? 2}',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${session?.subjectCode ?? "PRM393"} · ${session?.className ?? "SE1917"}',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${session?.timeRange ?? "09:30 - 11:45"} · ${session?.date ?? "03/10/2026"}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Phòng ${session?.room ?? "A101"} (Cơ sở Hòa Lạc)',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space14),

            // 4 Metric Stats (2x2 Grid)
            Row(
              children: [
                Expanded(
                  child: _buildMetricMiniCard('Sĩ số', '${vm.totalCount}', 'sinh viên', AppColors.textPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricMiniCard(
                    'Đã điểm danh',
                    '${vm.attendedCount}',
                    '${vm.attendanceRate.toInt()}%',
                    AppColors.statusSuccess,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricMiniCard(
                    'Chưa điểm danh',
                    '${vm.absentCount}',
                    '${100 - vm.attendanceRate.toInt()}%',
                    AppColors.dangerRed,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tỷ lệ tham gia', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${vm.attendanceRate.toInt()}%',
                              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF1D4ED8)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('Tốt', style: TextStyle(color: Color(0xFF1E40AF), fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space16),

            // QR Code Box Card
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
                      Text(
                        'QUÉT MÃ ĐỂ ĐIỂM DANH',
                        style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccessBg,
                          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.statusSuccess),
                            const SizedBox(width: 4),
                            Text(
                              'Còn 00:$secondsStr',
                              style: const TextStyle(
                                color: AppColors.statusSuccess,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Large QR Code
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderCard, width: 2),
                      ),
                      child: QrImageView(
                        data: vm.qrToken,
                        version: QrVersions.auto,
                        size: 200.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1B3B36),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF1B3B36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '(Mô phỏng dữ liệu token an toàn - làm mới mỗi 45s)',
                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: SecondaryOutlineButton(
                          text: 'Làm mới QR',
                          icon: const Icon(Icons.refresh, size: 16),
                          height: 42,
                          onPressed: () => vm.refreshQr(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SecondaryOutlineButton(
                          text: 'Phóng to QR',
                          icon: const Icon(Icons.zoom_in, size: 18),
                          height: 42,
                          onPressed: () {
                            _showEnlargedQrDialog(context, vm.qrToken);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // Section: Danh sách điểm danh
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Danh sách điểm danh', style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccessBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${vm.attendedCount}',
                        style: const TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                Text('Mới nhất lên đầu', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),

            // Search
            TextField(
              onChanged: (val) => vm.setSearchKeyword(val),
              decoration: const InputDecoration(
                hintText: 'Tìm tên, MSSV hoặc email...',
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 10),

            // Filter Tabs
            Row(
              children: [
                _buildFilterTab(
                  label: 'Tất cả (${vm.totalCount})',
                  isSelected: vm.currentFilter == AttendanceFilter.all,
                  onTap: () => vm.setFilter(AttendanceFilter.all),
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  label: 'Có mặt (${vm.attendedCount})',
                  isSelected: vm.currentFilter == AttendanceFilter.attended,
                  onTap: () => vm.setFilter(AttendanceFilter.attended),
                ),
                const SizedBox(width: 8),
                _buildFilterTab(
                  label: 'Chưa điểm danh (${vm.absentCount})',
                  isSelected: vm.currentFilter == AttendanceFilter.absent,
                  onTap: () => vm.setFilter(AttendanceFilter.absent),
                  badgeColor: AppColors.statusDangerBg,
                  textColor: AppColors.dangerRed,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // List of students
            ...vm.students.map((student) {
              return AttendanceStudentTile(
                name: student.name,
                studentId: student.studentId,
                statusLabel: student.isPresent ? 'Có mặt' : 'Vắng',
                statusType: student.isPresent ? StatusType.success : StatusType.danger,
                time: student.checkInTime,
                onEdit: () {
                  vm.updateStudentStatus(student.studentId, !student.isPresent);
                },
              );
            }),
            const SizedBox(height: AppDimens.space16),

            // Bottom Progress Bar
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
                      Text(
                        'Đã điểm danh: ${vm.attendedCount}/${vm.totalCount} sinh viên (${vm.attendanceRate.toInt()}%)',
                        style: AppTypography.labelLarge.copyWith(fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.statusSuccessBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${vm.attendanceRate.toInt()}%',
                          style: const TextStyle(color: AppColors.statusSuccess, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: vm.totalCount > 0 ? (vm.attendedCount / vm.totalCount) : 0,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation(AppColors.statusSuccess),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Còn ${vm.absentCount} sinh viên chưa quét', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                      Text('⏱ Kết thúc sẽ tính vắng', style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.dangerRed)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Sticky Red Action Button
            DangerActionButton(
              text: 'Kết thúc điểm danh (Đã điểm danh ${vm.attendedCount}/${vm.totalCount} SV)',
              icon: const Icon(Icons.stop_circle_outlined, size: 20),
              onPressed: () {
                _showFinalizeDialog(context, vm);
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Chốt phiên điểm danh - ${vm.absentCount} sinh viên chưa quét sẽ được ghi nhận vắng',
                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: AppDimens.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMiniCard(String label, String value, String sub, Color valColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: valColor),
              ),
              Text(
                sub,
                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
    Color? textColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryDark
                : badgeColor ?? Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primaryDark : AppColors.borderCard,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : textColor ?? AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _showEnlargedQrDialog(BuildContext context, String token) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mã QR Điểm Danh Lớp'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: Center(
            child: QrImageView(
              data: token,
              version: QrVersions.auto,
              size: 280.0,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showFinalizeDialog(BuildContext context, LiveAttendanceViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chốt kết thúc điểm danh?'),
        content: Text(
          'Đã có ${vm.attendedCount}/${vm.totalCount} sinh viên có mặt. ${vm.absentCount} sinh viên còn lại sẽ được tính vắng buổi học này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await vm.finalizeAttendance();
              if (context.mounted) {
                context.read<ReportViewModel>().loadReport();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AttendanceReportScreen()),
                );
              }
            },
            child: const Text('Xác nhận kết thúc'),
          ),
        ],
      ),
    );
  }
}
