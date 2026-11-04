import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ui_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/report_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';
import '../../widgets/campus_cards.dart';
import '../../widgets/state_views.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportViewModel>().loadReport();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: CampusAppBar(
        title: 'Báo cáo điểm danh',
        subtitle: 'FPT Attendance System',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () => vm.loadReport(),
            tooltip: 'Làm mới',
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
            // Card 1: Selector (Lớp học & Tiết học)
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
                  Text('LỚP HỌC', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school_outlined, size: 18, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Text('PRM393 · SE1917', style: AppTypography.labelLarge),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEAA5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('FA2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('TIẾT HỌC', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.textPrimary),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('05/10/2026 · Slot 1', style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                            Text('07:00 – 09:15 · Phòng A101', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space14),

            // Card 2: Summary Stats
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
                      const StatusBadgePill(label: 'Đã kết thúc', statusType: StatusType.success),
                      Text('Sĩ số: ${vm.totalCount} sinh viên', style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.statusSuccessBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Có mặt', style: AppTypography.bodySmall.copyWith(color: AppColors.statusSuccess)),
                                  Text(
                                    '${vm.attendedCount}',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: AppColors.statusSuccess,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFFD1FAE5),
                                child: Icon(Icons.check, size: 18, color: AppColors.statusSuccess),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.statusDangerBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vắng', style: AppTypography.bodySmall.copyWith(color: AppColors.dangerRed)),
                                  Text(
                                    '${vm.absentCount}',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: AppColors.dangerRed,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFFFEE2E2),
                                child: Icon(Icons.close, size: 18, color: AppColors.dangerRed),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEAA5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tỷ lệ tham gia: ${vm.attendanceRate.toInt()}%', style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                              Text('${vm.attendedCount}/${vm.totalCount} sinh viên đã điểm danh', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Đạt chỉ tiêu', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space14),

            // Card 3: Detailed Student Results
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
                      Text('Kết quả chi tiết', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                      Text('${vm.totalCount} sinh viên', style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _searchController,
                    onChanged: (val) => vm.setSearchQuery(val),
                    decoration: const InputDecoration(
                      hintText: 'Tìm tên, MSSV hoặc email...',
                      prefixIcon: Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Segment Tabs
                  Row(
                    children: [
                      _buildReportTab('Tất cả (${vm.totalCount})', vm.filter == 'ALL', () => vm.setFilter('ALL')),
                      const SizedBox(width: 8),
                      _buildReportTab('Có mặt (${vm.attendedCount})', vm.filter == 'ATTENDED', () => vm.setFilter('ATTENDED')),
                      const SizedBox(width: 8),
                      _buildReportTab('Vắng (${vm.absentCount})', vm.filter == 'ABSENT', () => vm.setFilter('ABSENT')),
                    ],
                  ),
                  const SizedBox(height: 14),

                  switch (vm.reportState) {
                    UiLoading(:final message) => AppLoadingView(message: message ?? 'Đang tải...'),
                    UiError(:final message) => AppErrorView(message: message, onRetry: () => vm.loadReport()),
                    UiSuccess(:final data) => Column(
                        children: data.map((student) {
                          return AttendanceStudentTile(
                            name: student.name,
                            studentId: student.studentId,
                            statusLabel: student.isPresent ? 'Có mặt ${student.checkInTime ?? ""}' : 'Vắng —',
                            statusType: student.isPresent ? StatusType.success : StatusType.danger,
                            onEdit: () {
                              vm.toggleStudentStatus(student.studentId);
                            },
                          );
                        }).toList(),
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space14),

            // Card 4: Xuất kết quả
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
                    children: [
                      const Icon(Icons.description, color: AppColors.statusSuccess, size: 22),
                      const SizedBox(width: 8),
                      Text('Xuất kết quả', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Tab đã liên kết: ', style: AppTypography.bodySmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '12_PRM393_SE1917',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF9C3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFEF08A)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Color(0xFF854D0E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kết quả sẽ được ghi vào cột F của tab này, thay thế kết quả đã xuất trước đó.',
                            style: AppTypography.bodySmall.copyWith(color: const Color(0xFF854D0E), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Button 1: Google Sheets Export
                  PrimaryGoldButton(
                    text: 'Xuất sang Google Sheets',
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    isLoading: vm.isExporting && vm.downloadUrl == null,
                    onPressed: () async {
                      await vm.exportToGoogleSheets();
                      if (context.mounted && vm.exportSuccessMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(vm.exportSuccessMessage!),
                            backgroundColor: AppColors.statusSuccess,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Button 2: Firebase Cloud Storage PDF Export (Lab 3 requirement)
                  SecondaryOutlineButton(
                    text: 'Xuất báo cáo PDF lên Firebase Cloud Storage',
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primaryDark),
                    onPressed: () async {
                      final url = await vm.exportPdfAndUploadToCloudStorage();
                      if (context.mounted && url != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã tải PDF lên Firebase Cloud Storage (reports/{uid}/...)!'),
                            backgroundColor: AppColors.primaryDark,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),

                  // Progress & Download URL Evidence Display
                  if (vm.isExporting && vm.uploadProgress > 0) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: vm.uploadProgress,
                      color: AppColors.accentGold,
                      backgroundColor: AppColors.surfaceMuted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tiến trình tải lên Cloud: ${(vm.uploadProgress * 100).toInt()}%',
                      style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],

                  if (vm.downloadUrl != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.statusSuccessBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đường dẫn tải PDF từ Firebase Storage:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.statusSuccess),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            vm.downloadUrl!,
                            style: const TextStyle(fontSize: 10, color: AppColors.primaryDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryDark : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
