import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/sheet_class_importer.dart';

class ImportClassesDialog extends StatefulWidget {
  const ImportClassesDialog({super.key, required this.api});
  final ApiService api;
  @override
  State<ImportClassesDialog> createState() => _ImportClassesDialogState();
}

class _ImportClassesDialogState extends State<ImportClassesDialog> {
  final source = TextEditingController(
    text: 'https://docs.google.com/spreadsheets/d/1Uewi8TJPsTFedaeVz8IybvB2HbeHIfDFB-R9o2s9LyI/edit',
  );
  final semester = TextEditingController();
  List<Json> tabs = [];
  final selected = <int>{};
  final subjects = <TextEditingController>[];
  List<SheetImportResult>? results;
  String? error, loadedId;
  String progress = '';
  bool busy = false, changed = false;
  int completed = 0;

  @override
  void dispose() {
    source.dispose();
    semester.dispose();
    for (final c in subjects) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
      results = null;
    });
    try {
      final id = SheetClassImporter.spreadsheetId(source.text);
      final list = await widget.api.sheetTabs(id);
      if (!mounted) return;
      for (final c in subjects) {
        c.dispose();
      }
      subjects.clear();
      selected.clear();
      tabs = list;
      loadedId = id;
      for (var i = 0; i < list.length; i++) {
        final subject = list[i]['subjectCode']?.toString() ?? '';
        subjects.add(TextEditingController(text: subject));
        if (subject.isNotEmpty) selected.add(i);
      }
      if (list.isEmpty) error = 'File Google Sheet không có tab nào.';
    } catch (e) {
      if (mounted)
        error = e is ApiException
            ? e.message
            : 'Không tải được danh sách tab. Vui lòng thử lại.';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> import() async {
    if (selected.isEmpty) return;
    final indices = selected.toList()..sort();
    if (indices.any((i) => subjects[i].text.trim().isEmpty)) {
      setState(
        () => error = 'Điền mã môn cho tất cả tab đã chọn, hoặc bỏ chọn tab không phải lớp học.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
      results = null;
      completed = 0;
    });
    try {
      changed = true;
      final data = await SheetClassImporter(widget.api).importTabs(
        spreadsheetId: loadedId!,
        semester: semester.text.trim(),
        tabs: indices
            .map(
              (i) => {
                ...tabs[i],
                'subjectCode': subjects[i].text.trim().toUpperCase(),
              },
            )
            .toList(),
        onProgress: (count, tab) {
          if (mounted)
            setState(() {
              completed = count;
              progress = tab;
            });
        },
      );
      if (mounted) setState(() => results = data);
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is ApiException ? e.message : 'Quá trình nhập bị gián đoạn. Có thể thử lại; lớp đã tạo sẽ được sử dụng lại.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.sizeOf(context).height - 64,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.table_chart_outlined, color: fptOrange),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Nhập tất cả lớp từ Google Sheet',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: busy
                        ? null
                        : () => Navigator.pop(context, changed),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Mỗi tab tạo một lớp theo tên tab và nhập danh sách sinh viên.\nCác lớp đã liên kết đúng tab sẽ được cập nhật, không tạo lại.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: source,
                enabled: !busy && loadedId == null,
                decoration: const InputDecoration(
                  labelText: 'Đường dẫn hoặc ID Google Sheet',
                ),
              ),
              const SizedBox(height: 12),
              if (loadedId == null)
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: busy ? null : load,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(
                      busy
                          ? 'Đang đọc danh sách tab…'
                          : 'Lấy tất cả lớp từ Sheet',
                    ),
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (loadedId != null && results == null) ...[
                TextField(
                  controller: semester,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Học kỳ cho lớp mới (không bắt buộc)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: tabs.isNotEmpty && selected.length == tabs.length,
                      onChanged: busy
                          ? null
                          : (v) => setState(() {
                              selected.clear();
                              if (v == true)
                                selected.addAll(
                                  List.generate(tabs.length, (i) => i),
                                );
                            }),
                    ),
                    Expanded(
                      child: Text(
                        'Chọn tất cả • ${selected.length}/${tabs.length} tab',
                      ),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              loadedId = null;
                              tabs = [];
                              selected.clear();
                            }),
                      child: const Text('Đổi file'),
                    ),
                  ],
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: tabs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Checkbox(
                            value: selected.contains(i),
                            onChanged: busy
                                ? null
                                : (v) => setState(() {
                                    if (v == true) {
                                      selected.add(i);
                                    } else {
                                      selected.remove(i);
                                    }
                                  }),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tabs[i]['sheetName']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tabs[i]['classCode'] == null
                                      ? 'Chưa nhận diện mã lớp • kiểm tra tab trước khi chọn'
                                      : 'Lớp ${tabs[i]['classCode']}',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 135,
                            child: TextField(
                              controller: subjects[i],
                              enabled: !busy,
                              decoration: const InputDecoration(
                                labelText: 'Mã môn',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (busy) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: selected.isEmpty
                        ? null
                        : completed / selected.length,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đang nhập $completed/${selected.length}: $progress',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: busy || selected.isEmpty ? null : import,
                    icon: const Icon(Icons.playlist_add_check),
                    label: Text(
                      busy
                          ? 'Đang nhập…'
                          : 'Nhập ${selected.length} lớp đã chọn',
                    ),
                  ),
                ),
              ],
              if (results != null) ...[
                Text(
                  '${results!.where((r) => r.success).length}/${results!.length} tab nhập thành công',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: results!.length,
                    itemBuilder: (context, i) {
                      final r = results![i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          r.success
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: r.success ? Colors.green : Colors.red,
                        ),
                        title: Text(r.tab),
                        subtitle: Text(
                          r.error ??
                              '${r.imported} sinh viên mới • ${r.skipped} dòng đã có/bỏ qua',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (results!.any((r) => !r.success))
                      TextButton(
                        onPressed: () => setState(() {
                          final failed = results!
                              .where((r) => !r.success)
                              .map((r) => r.tab)
                              .toSet();
                          selected.clear();
                          for (var i = 0; i < tabs.length; i++) {
                            if (failed.contains(tabs[i]['sheetName']))
                              selected.add(i);
                          }
                          results = null;
                        }),
                        child: const Text('Thử lại các tab lỗi'),
                      ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xem danh sách lớp'),
                    ),
                  ],
                ),
              ],
              if (busy && loadedId == null)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
