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

class _ImportScheduleImageDialogState extends State<ImportScheduleImageDialog> {
  final form = GlobalKey<FormState>();
  final semester = TextEditingController();
  ScheduleImageRead? read;
  DateTime? monday;
  bool busy = false, reviewed = false;
  String? error, result;
  @override
  void dispose() {
    semester.dispose();
    super.dispose();
  }

  String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
                    height: 200,
                    width: double.infinity,
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: Image.memory(read!.image, fit: BoxFit.contain),
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
                                reviewed = false;
                              });
                          },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      monday == null
                          ? 'Chọn thứ Hai đầu tuần'
                          : 'Ngày đầu tuần: ${date(monday!)}',
                    ),
                  ),
                  const Text(
                    'Lịch cũ được lưu ở trạng thái chưa điểm danh, không tự ghi nhận vắng. Chỉ nhập tuần đã chọn, không tự lặp cả học kỳ.',
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
