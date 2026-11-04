import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/class_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';

class ImportSheetScreen extends StatefulWidget {
  const ImportSheetScreen({super.key});

  @override
  State<ImportSheetScreen> createState() => _ImportSheetScreenState();
}

class _ImportSheetScreenState extends State<ImportSheetScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<ClassViewModel>();
    _urlController = TextEditingController(text: vm.sheetUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClassViewModel>();
    final classItem = vm.selectedClass;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CampusAppBar(
        title: 'Chi tiết lớp',
        subtitle: 'Nhập sinh viên từ Sheet',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        child: Column(
          children: [
            // Top Class Summary Card
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
                        Row(
                          children: [
                            Text(
                              '${classItem?.subjectCode ?? "PRM393"} · ${classItem?.className ?? "SE1917"}',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCEAA5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                classItem?.semester ?? 'FA2026',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nhập danh sách vào lớp này',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // Stepper (1 Chọn file -> 2 Chọn tab -> 3 Kết quả)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: Row(
                children: [
                  _buildStepNode(1, 'Chọn file', vm.importStep >= 0, vm.importStep == 0),
                  _buildStepDivider(vm.importStep >= 1),
                  _buildStepNode(2, 'Chọn tab', vm.importStep >= 1, vm.importStep == 1),
                  _buildStepDivider(vm.importStep >= 2),
                  _buildStepNode(3, 'Kết quả', vm.importStep >= 2, vm.importStep == 2),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            // Main Stepper Content
            if (vm.importStep == 0) _buildStep1File(context, vm),
            if (vm.importStep == 1) _buildStep2Tab(context, vm),
            if (vm.importStep == 2) _buildStep3Result(context, vm),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNode(int step, String label, bool isDone, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive
              ? AppColors.primaryDark
              : isDone
                  ? AppColors.statusSuccess
                  : AppColors.surfaceMuted,
          child: Text(
            step.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: (isActive || isDone) ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isDone ? AppColors.statusSuccess : AppColors.borderCard,
      ),
    );
  }

  Widget _buildStep1File(BuildContext context, ClassViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kết nối Google Sheet', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Nhập đường dẫn hoặc ID file chứa danh sách sinh viên lớp học.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimens.space16),

          Text(
            'Đường dẫn hoặc ID Google Sheet *',
            style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _urlController,
            onChanged: (val) => vm.setSheetUrl(val),
            decoration: InputDecoration(
              hintText: 'https://docs.google.com/spreadsheets/d/...',
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _urlController.clear();
                        vm.setSheetUrl('');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Alert box with shield icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'File cần được cấp quyền Người xem (Viewer) cho email hệ thống. Nếu chưa cấp quyền, vui lòng chia sẻ quyền trước khi tiếp tục.',
                    style: AppTypography.bodySmall.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          PrimaryGoldButton(
            text: 'Lấy danh sách tab →',
            isLoading: vm.isImporting,
            onPressed: () {
              vm.fetchSheetTabs();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Tab(BuildContext context, ClassViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chọn Tab dữ liệu', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Chọn sheet chứa danh sách sinh viên lớp ${vm.selectedClass?.className ?? ""}.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),

          ...vm.availableTabs.map((tab) {
            final isSelected = vm.selectedTab == tab;
            return InkWell(
              onTap: () => vm.selectSheetTab(tab),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE8F0ED) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryDark : AppColors.borderCard,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(tab, style: AppTypography.labelLarge),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          PrimaryGoldButton(
            text: 'Tiến hành nhập dữ liệu →',
            isLoading: vm.isImporting,
            onPressed: () {
              vm.completeImport();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Result(BuildContext context, ClassViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        border: Border.all(color: AppColors.borderCard),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.statusSuccessBg,
            child: Icon(Icons.check, size: 36, color: AppColors.statusSuccess),
          ),
          const SizedBox(height: 16),
          Text('Nhập dữ liệu thành công!', style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Đã đồng bộ ${vm.importedCount} sinh viên từ tab ${vm.selectedTab ?? ""} vào lớp ${vm.selectedClass?.subjectCode ?? ""}.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 24),
          PrimaryGoldButton(
            text: 'Hoàn tất & Quay lại',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
