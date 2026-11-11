import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_typography.dart';
import '../../viewmodels/schedule_view_model.dart';
import '../../widgets/campus_app_bar.dart';
import '../../widgets/campus_buttons.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});

  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  late final TextEditingController _dateController;
  final TextEditingController _roomController = TextEditingController(text: 'A101');
  int _selectedSlot = 1;
  String _selectedSlotRange = 'Slot 1 · 07:00–09:15';

  @override
  void initState() {
    super.initState();
    final initialDate = DateTime.now().add(const Duration(days: 7));
    _dateController = TextEditingController(
      text: '${initialDate.day.toString().padLeft(2, '0')}/${initialDate.month.toString().padLeft(2, '0')}/${initialDate.year}',
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: const CampusAppBar(
        title: 'Xếp lịch tiết học',
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
            Text('Tạo lịch cho lớp', style: AppTypography.displayLarge.copyWith(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              'Chọn lớp, ngày, slot và phòng học.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimens.space20),

            // Form Field 1: Lớp học
            Text('LỚP HỌC *', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.textPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRM393 · SE1917', style: AppTypography.labelLarge),
                        Text('Mobile Programming · Học kỳ FA2026', style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEAA5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('FA2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Form Field 2: Ngày học
            Text('NGÀY HỌC *', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Semantics(
              textField: true,
              label: 'Ngày học, định dạng ngày tháng năm',
              child: TextField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Ngày học (dd/MM/yyyy)',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2027, 12, 31),
                    );
                    if (picked != null) {
                      setState(() {
                        _dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                      });
                    }
                  },
                ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Định dạng: Ngày / Tháng / Năm. Không được chọn ngày đã qua.',
              style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
            ),
            const SizedBox(height: AppDimens.space16),

            // Form Field 3: Slot học
            Text('SLOT HỌC *', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                border: Border.all(color: AppColors.borderCard),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedSlot,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  items: const [
                    DropdownMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: AppColors.textMuted),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Slot 1 · 07:00–09:15', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Ca học sáng sớm', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: AppColors.textMuted),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Slot 2 · 09:30–11:45', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Ca học sáng chính', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedSlot = val;
                        _selectedSlotRange = val == 1 ? 'Slot 1 · 07:00–09:15' : 'Slot 2 · 09:30–11:45';
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Form Field 4: Phòng học
            Text('PHÒNG HỌC *', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Semantics(
              textField: true,
              label: 'Phòng học',
              child: TextField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Phòng học',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space20),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(AppDimens.space16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7F4),
                borderRadius: BorderRadius.circular(AppDimens.radiusCard),
                border: Border.all(color: const Color(0xFFD6E4DC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 16, color: AppColors.primaryDark),
                          const SizedBox(width: 6),
                          Text(
                            'TÓM TẮT LỊCH TIẾT HỌC',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Sẽ tạo mới', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderCard),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRM393 · SE1917', style: AppTypography.titleSmall.copyWith(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          '${_dateController.text} • Slot $_selectedSlot\n$_selectedSlotRange • Phòng ${_roomController.text}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Sau khi lưu, tiết học ở trạng thái Chưa mở. Bạn sẽ mở điểm danh khi đến giờ học.',
                          style: AppTypography.bodySmall.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.space24),

            // Buttons
            PrimaryGoldButton(
              text: 'Lưu lịch học',
              icon: const Icon(Icons.save_outlined, size: 18),
              onPressed: () async {
                final date = _parseDate(_dateController.text);
                final today = DateTime.now();
                final startOfToday = DateTime(today.year, today.month, today.day);
                if (date == null || date.isBefore(startOfToday)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ngày học không hợp lệ. Hãy chọn hôm nay hoặc một ngày trong tương lai.')),
                  );
                  return;
                }
                final success = await scheduleVm.createNewSessionSchedule(
                  classItem: const ClassModel(
                    id: 'c1',
                    subjectCode: 'PRM393',
                    className: 'SE1917',
                    semester: 'FA2026',
                    studentCount: 35,
                    sessionCount: 8,
                  ),
                  date: date,
                  slot: _selectedSlot,
                  timeRange: _selectedSlotRange,
                  room: _roomController.text,
                );

                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lịch tiết học đã được tạo thành công!')),
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Hủy bỏ', style: AppTypography.labelLarge.copyWith(color: AppColors.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseDate(String input) {
    final parts = input.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day ? parsed : null;
  }
}
