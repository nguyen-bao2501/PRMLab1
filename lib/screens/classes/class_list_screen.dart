import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ui_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/class_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';
import '../../widgets/campus_cards.dart';
import '../../widgets/state_views.dart';
import 'class_detail_screen.dart';
import 'import_sheet_screen.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClassViewModel>().loadClasses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClassViewModel>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CampusAppBar(
        title: 'CAMPUS / LỚP HỌC',
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.loadClasses(query: _searchController.text),
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
              Text(
                'Lớp học của tôi',
                style: AppTypography.displayLarge.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                'Tổ chức lớp học, quản lý danh sách và bắt đầu điểm danh.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppDimens.space16),

              // Action buttons
              PrimaryGoldButton(
                text: '+ Tạo lớp học',
                onPressed: () {
                  _showCreateClassDialog(context);
                },
              ),
              const SizedBox(height: AppDimens.space10),
              SecondaryOutlineButton(
                text: 'Nhập tất cả lớp từ Sheet',
                icon: const Icon(Icons.description_outlined, size: 18),
                onPressed: () {
                  if (vm.classesState case UiSuccess(:final data) when data.isNotEmpty) {
                    vm.startImportFlow(data.first);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ImportSheetScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: AppDimens.space16),

              // Search & Filter
              TextField(
                controller: _searchController,
                onChanged: (val) => vm.searchClasses(val),
                decoration: InputDecoration(
                  hintText: 'Tìm mã lớp, mã môn, học kỳ...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            vm.searchClasses('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppDimens.space10),

              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: AppColors.borderCard),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tất cả học kỳ', style: AppTypography.bodyMedium),
                    const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.space16),

              // Classes List State
              switch (vm.classesState) {
                UiLoading(:final message) => AppLoadingView(message: message ?? 'Đang tải...'),
                UiError(:final message) => AppErrorView(
                    message: message,
                    onRetry: () => vm.loadClasses(),
                  ),
                UiEmpty(:final message) => AppEmptyView(
                    title: 'Không có lớp học nào',
                    description: message,
                  ),
                UiSuccess(:final data) => Column(
                    children: data.map((classItem) {
                      return ClassItemCard(
                        subjectCode: classItem.subjectCode,
                        className: classItem.className,
                        semester: classItem.semester,
                        studentCount: classItem.studentCount,
                        sessionCount: classItem.sessionCount,
                        isLinkedSheet: classItem.isLinkedSheet,
                        onTap: () {
                          vm.selectClass(classItem);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClassDetailScreen(classItem: classItem),
                            ),
                          );
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

  void _showCreateClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo lớp học mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Mã môn (ví dụ: PRM393)')),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Tên lớp (ví dụ: SE1917)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lớp học đã được tạo thành công!')),
              );
            },
            child: const Text('Tạo lớp'),
          ),
        ],
      ),
    );
  }
}
