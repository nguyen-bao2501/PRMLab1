import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/schedule_image_parser.dart';
import '../services/schedule_ocr.dart';

class ImportScheduleImageDialog extends StatefulWidget {
  const ImportScheduleImageDialog({
    super.key,
    required this.api,
    this.readImage,
  });
  final ApiService api;
  final Future<ScheduleImageRead?> Function()? readImage;
  @override
  State<ImportScheduleImageDialog> createState() =>
      _ImportScheduleImageDialogState();
}

enum SemesterBlockMode {
  block10,
  block3,
  full,
  custom,
}

class _ImportScheduleImageDialogState extends State<ImportScheduleImageDialog> {
  final form = GlobalKey<FormState>();
  final semester = TextEditingController();
  ScheduleImageRead? read;
  DateTime? monday, applyFrom, applyUntil;
  bool applyWholeSemester = false;
  SemesterBlockMode blockMode = SemesterBlockMode.block10;
  bool busy = false, reviewed = false;
  String? error, result;

  void _updateApplyDates() {
    if (monday == null) return;
    switch (blockMode) {
      case SemesterBlockMode.block10:
        applyFrom = monday;
        applyUntil = monday!.add(const Duration(days: 7 * 10 - 1));
        break;
      case SemesterBlockMode.block3:
        applyFrom = monday!.add(const Duration(days: 7 * 12));
        applyUntil = monday!.add(const Duration(days: 7 * 15 - 1));
        break;
      case SemesterBlockMode.full:
        applyFrom = monday;
        applyUntil = monday!.add(const Duration(days: 7 * 15 - 1));
        break;
      case SemesterBlockMode.custom:
        applyFrom ??= monday;
        applyUntil ??= monday!.add(const Duration(days: 7 * 10 - 1));
        break;
    }
  }

  String _getBlockDescription() {
    switch (blockMode) {
      case SemesterBlockMode.block10:
        return 'Block 10 tuần';
      case SemesterBlockMode.block3:
        return 'Block 3 tuần (bắt đầu sau 2 tuần thi)';
      case SemesterBlockMode.full:
        return 'Cả kỳ học (15 tuần)';
      case SemesterBlockMode.custom:
        final days = applyUntil != null && applyFrom != null
            ? applyUntil!.difference(applyFrom!).inDays + 1
            : 0;
        final weeks = (days / 7).ceil();
        return 'Tùy chỉnh ($days ngày ~ $weeks tuần)';
    }
  }

  @override
  void dispose() {
    semester.dispose();
    super.dispose();
  }

  String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  Future<void> choose() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final data = await (widget.readImage ?? ScheduleOcr().pickAndRead)();
      if (data != null && mounted)
        setState(() {
          read = data;
          monday = data.recognition.weekStart;
          _updateApplyDates();
          applyWholeSemester = false;
          reviewed = false;
          result = null;
        });
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is ApiException
              ? e.message
              : e is FormatException
              ? e.message
              : 'Không đọc được ảnh. Vui lòng chọn ảnh PNG/JPG rõ chữ.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final selected = read!.recognition.rows.where((r) => r.selected).toList();
    if (monday == null ||
        monday!.weekday != DateTime.monday ||
        selected.isEmpty ||
        !reviewed) {
      setState(
        () => error =
            'Chọn thứ Hai đầu tuần, ít nhất một tiết và xác nhận đã kiểm tra.',
      );
      return;
    }
    if (applyWholeSemester &&
        (applyFrom == null ||
            applyUntil == null ||
            applyUntil!.isBefore(applyFrom!))) {
      setState(() => error = 'Chọn ngày bắt đầu và ngày kết thúc của học kỳ.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await widget.api.importSchedule(
        semester.text.trim(),
        selected.map((r) {
          final d = monday!.add(Duration(days: r.day));
          return <String, dynamic>{
            'classCode': r.classCode.trim().toUpperCase(),
            'subjectCode': r.subjectCode.trim().toUpperCase(),
            'room': r.room.trim(),
            'date':
                '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
            'slot': r.slot,
          };
        }).toList(),
        applyWholeSemester: applyWholeSemester,
        applyFrom: applyWholeSemester ? isoDate(applyFrom!) : null,
        applyUntil: applyWholeSemester ? isoDate(applyUntil!) : null,
      );
      if (mounted)
        setState(
          () => result =
              'Đã tạo ${response['createdClasses']} lớp–môn, ${response['createdLessons']} tiết; bỏ qua ${response['skipped']} tiết đã có.',
        );
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is ApiException
              ? e.message
              : 'Không nhập được lịch. Hãy thử lại; tiết đã có sẽ được bỏ qua.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('Đọc lịch dạy từ ảnh'),
      content: SizedBox(
        width: 1100,
        height: MediaQuery.sizeOf(context).height * .72,
        child: Form(
          key: form,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn ảnh đầy đủ tiêu đề năm/ngày và các hàng Slot. OCR chạy trên Windows; ảnh không được gửi lên máy chủ.',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy || result != null ? null : choose,
                  icon: const Icon(Icons.image_search),
                  label: Text(
                    read == null ? 'Chọn ảnh lịch dạy' : 'Chọn ảnh khác',
                  ),
                ),
                if (busy) const LinearProgressIndicator(),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (result != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      result!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (read != null) ...[
                  SizedBox(
                    height: 420,
                    width: double.infinity,
                    child: InteractiveViewer(
                      constrained: false,
                      boundaryMargin: const EdgeInsets.all(48),
                      minScale: .25,
                      maxScale: 6,
                      child: Image.memory(read!.image),
                    ),
                  ),
                  ...read!.recognition.warnings.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        w,
                        style: const TextStyle(color: Colors.deepOrange),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: semester,
                    onChanged: (_) {
                      if (reviewed) setState(() => reviewed = false);
                    },
                    enabled: !busy && result == null,
                    decoration: const InputDecoration(
                      labelText: 'Học kỳ (bắt buộc, ví dụ FA2026)',
                    ),
                    maxLength: 40,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nhập học kỳ của lịch này'
                        : null,
                  ),
                  TextButton.icon(
                    onPressed: busy || result != null
                        ? null
                        : () async {
                            final selected = await showDatePicker(
                              context: context,
                              initialDate: monday ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100, 12, 31),
                            );
                            if (selected != null && mounted)
                              setState(() {
                                monday = selected;
                                _updateApplyDates();
                                reviewed = false;
                              });
                          },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      monday == null
                          ? 'Chọn thứ Hai đầu tuần học kỳ (Tuần 1)'
                          : 'Thứ Hai đầu kỳ: ${date(monday!)}',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: applyWholeSemester,
                    onChanged: busy || result != null
                        ? null
                        : (value) => setState(() {
                            applyWholeSemester = value;
                            if (value) {
                              _updateApplyDates();
                            }
                            reviewed = false;
                          }),
                    title: const Text('Áp dụng lịch này theo Block / Cả kỳ'),
                    subtitle: const Text(
                      'Tự động lặp lịch học theo Block 10 tuần, Block 3 tuần hoặc trọn kỳ học 13 tuần.',
                    ),
                  ),
                  if (applyWholeSemester) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lựa chọn Phạm vi áp dụng:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                selected: blockMode == SemesterBlockMode.block10,
                                label: const Text('Block 10 tuần'),
                                avatar: const Icon(Icons.looks_3_outlined, size: 18),
                                onSelected: busy || result != null
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          setState(() {
                                            blockMode = SemesterBlockMode.block10;
                                            _updateApplyDates();
                                            reviewed = false;
                                          });
                                        }
                                      },
                              ),
                              ChoiceChip(
                                selected: blockMode == SemesterBlockMode.block3,
                                label: const Text('Block 3 tuần'),
                                avatar: const Icon(Icons.date_range, size: 18),
                                onSelected: busy || result != null
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          setState(() {
                                            blockMode = SemesterBlockMode.block3;
                                            _updateApplyDates();
                                            reviewed = false;
                                          });
                                        }
                                      },
                              ),
                              ChoiceChip(
                                selected: blockMode == SemesterBlockMode.full,
                                label: const Text('Cả kỳ học'),
                                avatar: const Icon(Icons.calendar_view_month, size: 18),
                                onSelected: busy || result != null
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          setState(() {
                                            blockMode = SemesterBlockMode.full;
                                            _updateApplyDates();
                                            reviewed = false;
                                          });
                                        }
                                      },
                              ),
                              ChoiceChip(
                                selected: blockMode == SemesterBlockMode.custom,
                                label: const Text('Tùy chỉnh ngày'),
                                avatar: const Icon(Icons.edit_calendar, size: 18),
                                onSelected: busy || result != null
                                    ? null
                                    : (selected) {
                                        if (selected) {
                                          setState(() {
                                            blockMode = SemesterBlockMode.custom;
                                            _updateApplyDates();
                                            reviewed = false;
                                          });
                                        }
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (applyFrom != null && applyUntil != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Khoảng ngày áp dụng: ${date(applyFrom!)} ➔ ${date(applyUntil!)} (${_getBlockDescription()})',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (blockMode == SemesterBlockMode.custom) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton.icon(
                                  onPressed: busy || result != null
                                      ? null
                                      : () async {
                                          final selected = await showDatePicker(
                                            context: context,
                                            initialDate: applyFrom ?? monday ?? DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100, 12, 31),
                                          );
                                          if (selected != null && mounted) {
                                            setState(() {
                                              applyFrom = selected;
                                              if (applyUntil == null ||
                                                  applyUntil!.isBefore(selected)) {
                                                applyUntil = selected.add(
                                                  const Duration(days: 7 * 10 - 1),
                                                );
                                              }
                                              reviewed = false;
                                            });
                                          }
                                        },
                                  icon: const Icon(Icons.event),
                                  label: Text(
                                    applyFrom == null
                                        ? 'Chọn ngày bắt đầu'
                                        : 'Bắt đầu: ${date(applyFrom!)}',
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: busy || result != null
                                      ? null
                                      : () async {
                                          final selected = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                applyUntil ?? applyFrom ?? DateTime.now(),
                                            firstDate: applyFrom ?? DateTime(2000),
                                            lastDate: DateTime(2100, 12, 31),
                                          );
                                          if (selected != null && mounted) {
                                            setState(() {
                                              applyUntil = selected;
                                              reviewed = false;
                                            });
                                          }
                                        },
                                  icon: const Icon(Icons.event_available),
                                  label: Text(
                                    applyUntil == null
                                        ? 'Chọn ngày kết thúc'
                                        : 'Kết thúc: ${date(applyUntil!)}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Các buổi được tạo ở trạng thái chưa điểm danh; bạn chỉ mở QR khi đến giờ học.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${read!.recognition.rows.length} dòng lịch · kiểm tra và chọn các dòng muốn nhập',
                  ),
                  TextButton.icon(
                    onPressed: busy || result != null
                        ? null
                        : () => setState(() {
                            read!.recognition.rows.add(
                              ScheduleDraft(
                                day: 0,
                                slot: 1,
                                classCode: '',
                                subjectCode: '',
                                room: '',
                                raw: 'Bổ sung thủ công',
                              ),
                            );
                            reviewed = false;
                          }),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm tiết bị thiếu'),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      key: ObjectKey(read),
                      columns: const [
                        DataColumn(label: Text('Nhập')),
                        DataColumn(label: Text('Thứ')),
                        DataColumn(label: Text('Slot')),
                        DataColumn(label: Text('Mã lớp')),
                        DataColumn(label: Text('Môn')),
                        DataColumn(label: Text('Phòng')),
                        DataColumn(label: Text('Chữ OCR')),
                      ],
                      rows: read!.recognition.rows
                          .map(
                            (r) => DataRow(
                              cells: [
                                DataCell(
                                  Checkbox(
                                    value: r.selected,
                                    onChanged: busy || result != null
                                        ? null
                                        : (v) => setState(() {
                                            r.selected = v!;
                                            reviewed = false;
                                          }),
                                  ),
                                ),
                                DataCell(
                                  DropdownButton<int>(
                                    value: r.day,
                                    items: List.generate(
                                      7,
                                      (i) => DropdownMenuItem(
                                        value: i,
                                        child: Text(
                                          i == 6 ? 'CN' : 'Thứ ${i + 2}',
                                        ),
                                      ),
                                    ),
                                    onChanged: busy || result != null
                                        ? null
                                        : (v) => setState(() {
                                            r.day = v!;
                                            reviewed = false;
                                          }),
                                  ),
                                ),
                                DataCell(
                                  DropdownButton<int>(
                                    value: r.slot,
                                    items: List.generate(
                                      6,
                                      (i) => DropdownMenuItem(
                                        value: i + 1,
                                        child: Text('${i + 1}'),
                                      ),
                                    ),
                                    onChanged: busy || result != null
                                        ? null
                                        : (v) => setState(() {
                                            r.slot = v!;
                                            reviewed = false;
                                          }),
                                  ),
                                ),
                                DataCell(
                                  field(
                                    r,
                                    r.classCode,
                                    (v) => r.classCode = v,
                                    RegExp(r'^[A-Z]{2}\d{4,6}$'),
                                  ),
                                ),
                                DataCell(
                                  field(
                                    r,
                                    r.subjectCode,
                                    (v) => r.subjectCode = v,
                                    RegExp(r'^[A-Z]{2,4}\d{3}$'),
                                  ),
                                ),
                                DataCell(
                                  field(r, r.room, (v) => r.room = v, null),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 160,
                                    child: Tooltip(
                                      message: r.raw,
                                      child: Text(
                                        r.raw,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: reviewed,
                    onChanged: busy || result != null
                        ? null
                        : (v) => setState(() => reviewed = v!),
                    title: const Text(
                      'Tôi đã kiểm tra học kỳ, ngày, lớp, môn, phòng và slot.',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy
              ? null
              : () => Navigator.pop(context, result == null ? null : monday),
          child: Text(result == null ? 'Đóng' : 'Hoàn tất'),
        ),
        if (read != null && result == null)
          FilledButton(
            onPressed: busy || !reviewed ? null : save,
            child: const Text('Nhập lịch đã kiểm tra'),
          ),
      ],
    ),
  );
  Widget field(
    ScheduleDraft row,
    String value,
    ValueChanged<String> change,
    RegExp? pattern,
  ) => SizedBox(
    width: 110,
    child: TextFormField(
      initialValue: value,
      enabled: !busy && result == null,
      maxLength: pattern == null ? 80 : 12,
      decoration: const InputDecoration(counterText: ''),
      onChanged: (v) {
        change(v);
        if (reviewed) setState(() => reviewed = false);
      },
      validator: (v) => !row.selected
          ? null
          : v == null ||
                v.trim().isEmpty ||
                (pattern != null && !pattern.hasMatch(v.trim().toUpperCase()))
          ? 'Kiểm tra lại'
          : null,
    ),
  );
}
