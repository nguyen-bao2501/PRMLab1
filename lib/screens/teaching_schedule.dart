import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/attendance_store.dart';
import 'import_schedule_image_dialog.dart';

const slotStarts = [(7, 0), (9, 30), (12, 30), (15, 0), (17, 30), (20, 0)];
String lessonDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
DateTime? lessonStart(Json x) =>
    DateTime.tryParse('${x['startTime']}')?.toLocal();
int lessonSlot(Json x) {
  final d = lessonStart(x);
  if (d == null) return 0;
  final minutes = d.hour * 60 + d.minute;
  for (var i = slotStarts.length - 1; i >= 0; i--) {
    if (minutes >= slotStarts[i].$1 * 60 + slotStarts[i].$2) return i;
  }
  return 0;
}

String lessonStatus(Json x) => switch (x['status']) {
  'SCHEDULED' => 'Chưa điểm danh',
  'OPEN' => 'Đang điểm danh',
  'CLOSED' => 'Đã kết thúc',
  'CANCELLED' => 'Đã hủy',
  _ => 'Chưa rõ',
};
bool canOpenLesson(Json x, DateTime now) {
  final start = lessonStart(x);
  return x['status'] == 'SCHEDULED' &&
      start != null &&
      !now.isBefore(start) &&
      now.isBefore(start.add(const Duration(minutes: 135)));
}

class TeachingSchedule extends StatefulWidget {
  const TeachingSchedule({
    super.key,
    required this.store,
    required this.overview,
    required this.onLesson,
    required this.onCreateClass,
    required this.onSchedule,
  });
  final AttendanceStore store;
  final bool overview;
  final Future<void> Function(Json, Json) onLesson;
  final VoidCallback onCreateClass, onSchedule;
  @override
  State<TeachingSchedule> createState() => _TeachingScheduleState();
}

class _TeachingScheduleState extends State<TeachingSchedule> {
  List<Json> lessons = [];
  bool loading = false, autoSync = true;
  String? error, semester;
  DateTime? synced;
  late DateTime week;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    week = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    unawaited(load());
    timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (autoSync && !widget.store.busy) unawaited(load());
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (loading || widget.store.busy) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await widget.store.reload();
      if (!mounted) return;
      final rows = <Json>[];
      // Keep requests bounded for lecturers with many classes.
      for (final c in List<Json>.of(widget.store.classes)) {
        final sessions = await widget.store.api.sessions(c['id'] as int);
        rows.addAll(sessions.map((x) => {...x, '_class': c}));
      }
      rows.sort((a, b) => '${a['startTime']}'.compareTo('${b['startTime']}'));
      if (mounted)
        setState(() {
          lessons = rows;
          synced = DateTime.now();
        });
    } catch (e) {
      if (mounted)
        setState(
          () => error = e is ApiException
              ? e.message
              : 'Không tải được lịch dạy.',
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Json> get filtered => lessons
      .where(
        (x) =>
            semester == null || (x['_class'] as Json)['semester'] == semester,
      )
      .toList();
  Widget lessonCard(Json x, {bool fixedWidth = true, bool compact = false}) {
    final c = x['_class'] as Json;
    final d = lessonStart(x);
    final onTap = widget.store.busy
        ? null
        : () async {
            await widget.onLesson(c, x);
            if (mounted) await load();
          };

    Widget card = compact
        ? CompactLessonCardWidget(lesson: x, c: c, d: d, onTap: onTap)
        : LessonCardWidget(lesson: x, c: c, d: d, onTap: onTap);

    if (compact) return card;
    
    if (fixedWidth) {
      return SizedBox(width: 260, child: card);
    }
    return card;
  }

  Widget _buildActionButton({required IconData icon, required String label, VoidCallback? onPressed, bool primary = false}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: primary && onPressed != null
            ? const LinearGradient(colors: [Color(0xFFD69E2E), Color(0xFFC78C26)])
            : null,
        color: primary ? (onPressed == null ? const Color(0xFFF1F5F9) : null) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: primary ? null : Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: primary && onPressed != null
            ? const [BoxShadow(color: Color(0x33EA580C), blurRadius: 12, offset: Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: primary ? (onPressed == null ? const Color(0xFF94A3B8) : Colors.white) : const Color(0xFF475569)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primary ? (onPressed == null ? const Color(0xFF94A3B8) : Colors.white) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final terms =
        widget.store.classes
            .map((c) => c['semester']?.toString())
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final now = DateTime.now();
    final today = filtered.where((x) {
      final d = lessonStart(x);
      return d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF435A58), Color(0xFF2C3E3D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x332C3E3D),
                blurRadius: 20,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.overview ? 'Tổng quan giảng dạy' : 'Lịch dạy theo tuần',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tạo lớp theo học kỳ → nhập sinh viên → xếp lịch → điểm danh → xem thống kê.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  ],
                ),
              ),
              if (synced != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync, color: Color(0xFF94A3B8), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Cập nhật: ${synced!.hour}:${synced!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.add_circle,
                label: 'Tạo lớp học',
                onPressed: widget.store.busy ? null : widget.onCreateClass,
                primary: true,
              ),
              _buildActionButton(
                icon: Icons.event_available,
                label: 'Xếp lịch tiết học',
                onPressed: widget.store.busy || widget.store.classes.isEmpty ? null : widget.onSchedule,
              ),
              _buildActionButton(
                icon: Icons.document_scanner_outlined,
                label: 'Đọc lịch từ ảnh',
                onPressed: loading || widget.store.busy
                    ? null
                    : () async {
                        final imported = await showDialog<DateTime>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) =>
                              ImportScheduleImageDialog(api: widget.store.api),
                        );
                        if (imported != null && mounted) {
                          setState(() {
                            week = imported;
                            semester = null;
                          });
                          await load();
                        }
                      },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: terms.contains(semester) ? semester : null,
                    hint: const Text('Tất cả học kỳ', style: TextStyle(fontSize: 14)),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Tất cả học kỳ')),
                      ...terms.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                    ],
                    onChanged: (v) => setState(() => semester = v),
                  ),
                ),
              ),
              _buildActionButton(
                icon: Icons.sync,
                label: 'Đồng bộ',
                onPressed: loading ? null : load,
              ),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: autoSync,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (v) => setState(() => autoSync = v),
                    ),
                    const Text('Tự đồng bộ 30s', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 20),
        if (widget.overview) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              double safeWidth = constraints.maxWidth == double.infinity ? MediaQuery.of(context).size.width - 320 : constraints.maxWidth;
              if (safeWidth < 300) safeWidth = 300;
              int crossAxisCount = (safeWidth / 300).floor();
              if (crossAxisCount == 0) crossAxisCount = 1;
              double itemWidth = (safeWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

              final upcoming = filtered
                  .where(
                    (x) =>
                        x['status'] == 'SCHEDULED' &&
                        (lessonStart(x)?.isAfter(now) ?? false),
                  )
                  .take(6)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _buildStatCard(
                          title: 'Tổng số tiết hôm nay',
                          value: '${today.length}',
                          icon: Icons.calendar_today,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _buildStatCard(
                          title: 'Đang điểm danh',
                          value: '${today.where((x) => x['status'] == 'OPEN').length}',
                          icon: Icons.sensors,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (today.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Hôm nay chưa có lịch dạy. Chọn Xếp lịch tiết học để bắt đầu.',
                      ),
                    )
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: today.map((x) => SizedBox(width: itemWidth, child: lessonCard(x, fixedWidth: false))).toList(),
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Các tiết sắp tới',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: upcoming.map((x) => SizedBox(width: itemWidth, child: lessonCard(x, fixedWidth: false))).toList(),
                  ),
                ],
              );
            },
          ),
        ] else ...[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              IconButton(
                tooltip: 'Tuần trước',
                onPressed: () => setState(
                  () => week = week.subtract(const Duration(days: 7)),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${lessonDate(week)} – ${lessonDate(week.add(const Duration(days: 6)))}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                tooltip: 'Tuần sau',
                onPressed: () =>
                    setState(() => week = week.add(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_right),
              ),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: week,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null && mounted)
                    setState(
                      () => week = d.subtract(Duration(days: d.weekday - 1)),
                    );
                },
                child: const Text('Chọn tuần'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Table(
                      border: const TableBorder.symmetric(inside: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
                      columnWidths: const {0: FixedColumnWidth(110)},
                      defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5E6),
                      ),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          child: Text('Khung giờ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF173D35))),
                        ),
                        ...List.generate(
                          7,
                          (day) {
                            final date = week.add(Duration(days: day));
                            final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                            return Container(
                              color: isToday ? const Color(0xFF173D35) : Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day == 6 ? 'Chủ nhật' : 'Thứ ${day + 2}',
                                    style: TextStyle(
                                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w700, 
                                      fontSize: 15, 
                                      color: isToday ? const Color(0xFFDCEAA5) : const Color(0xFF173D35)
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lessonDate(date),
                                    style: TextStyle(
                                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600, 
                                      fontSize: 13, 
                                      color: isToday ? const Color(0xFFB4C77E) : const Color(0xFF2C5E51)
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    ...List.generate(
                      6,
                      (slot) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Slot ${slot + 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF475569))),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${slotStarts[slot].$1}:${slotStarts[slot].$2.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                          ...List.generate(7, (day) {
                            final date = week.add(Duration(days: day));
                            final items = filtered.where((x) {
                              final d = lessonStart(x);
                              return d != null &&
                                  d.year == date.year &&
                                  d.month == date.month &&
                                  d.day == date.day &&
                                  lessonSlot(x) == slot;
                            }).toList();
                            return ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 80),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: items.isNotEmpty ? Colors.white : const Color(0xFFF8FAFC),
                                child: Column(
                                  children: items.isEmpty
                                      ? const [SizedBox()]
                                      : items.map((x) => lessonCard(x, fixedWidth: false, compact: true)).toList(),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ],
);
  }
}

/// Only finalized attendance records participate in absence statistics.
List<Json> rankAbsences(List<Json> rows) {
  final students = <String, Json>{};
  for (final row in rows) {
    final key = '${row['studentId'] ?? row['email'] ?? row['studentCode']}';
    final entry = students.putIfAbsent(
      key,
      () => {...row, 'absences': 0, 'recorded': 0},
    );
    entry['recorded'] = (entry['recorded'] as int) + 1;
    if (row['status'] == 'ABSENT')
      entry['absences'] = (entry['absences'] as int) + 1;
  }
  return students.values.toList()
    ..sort((a, b) => (b['absences'] as int).compareTo(a['absences'] as int));
}

class ClassAttendanceSummary extends StatefulWidget {
  const ClassAttendanceSummary({super.key, required this.store});
  final AttendanceStore store;
  @override
  State<ClassAttendanceSummary> createState() => _ClassAttendanceSummaryState();
}

class _ClassAttendanceSummaryState extends State<ClassAttendanceSummary> {
  late Future<List<Json>> data;
  @override
  void initState() {
    super.initState();
    data = load();
  }

  Future<List<Json>> load() async {
    final rows = <Json>[];
    for (final x in widget.store.sessions.where(
      (x) => x['status'] == 'CLOSED',
    )) {
      rows.addAll(await widget.store.api.attendances(x['id'] as int));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Json>>(
    future: data,
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return TextButton(
          onPressed: () => setState(() => data = load()),
          child: const Text('Không tải được thống kê. Thử lại'),
        );
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final rows = snapshot.data!;
      final ranked = rankAbsences(rows);
      final absent = rows.where((x) => x['status'] == 'ABSENT').length;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng quan khóa học',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                rows.isEmpty
                    ? 'Chưa có dữ liệu điểm danh từ tiết đã kết thúc.'
                    : 'Tỷ lệ vắng: ${(100 * absent / rows.length).toStringAsFixed(1)}% · $absent/${rows.length} lượt điểm danh',
              ),
              const Text(
                'Chỉ tính tiết đã kết thúc; mỗi sinh viên tính trên số tiết có bản ghi điểm danh.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Sinh viên vắng nhiều nhất',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (ranked.every((x) => x['absences'] == 0))
                const Text('Chưa ghi nhận sinh viên vắng.'),
              ...ranked
                  .where((x) => x['absences'] > 0)
                  .take(5)
                  .map(
                    (x) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${x['studentName'] ?? x['email']}'),
                      subtitle: Text('${x['studentCode'] ?? ''}'),
                      trailing: Text(
                        '${x['absences']}/${x['recorded']} tiết · ${(100 * (x['absences'] as int) / (x['recorded'] as int)).toStringAsFixed(0)}%',
                      ),
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );
}

class LessonCardWidget extends StatefulWidget {
  const LessonCardWidget({super.key, required this.lesson, required this.c, required this.d, required this.onTap});
  final Json lesson;
  final Json c;
  final DateTime? d;
  final VoidCallback? onTap;

  @override
  State<LessonCardWidget> createState() => _LessonCardWidgetState();
}

class _LessonCardWidgetState extends State<LessonCardWidget> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final x = widget.lesson;
    final c = widget.c;
    final d = widget.d;
    final isOpen = x['status'] == 'OPEN';
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          transform: Matrix4.identity()..translate(0.0, hover ? -4.0 : 0.0),
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOpen ? const Color(0xFF86EFAC) : (hover ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isOpen ? const Color(0x2022C55E) : const Color(0x0A000000),
                blurRadius: hover ? 12 : 4,
                offset: Offset(0, hover ? 6 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${c['classCode']} · ${c['subjectCode']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOpen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sensors, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.room_outlined, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Phòng ${x['room'] ?? '—'}', 
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (d != null)
                Row(
                  children: [
                    const Icon(Icons.schedule_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${lessonDate(d)} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isOpen 
                      ? const Color(0xFF22C55E) 
                      : (canOpenLesson(x, DateTime.now()) ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  isOpen || canOpenLesson(x, DateTime.now()) ? 'ĐIỂM DANH' : 'XEM TIẾT HỌC',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: (isOpen || canOpenLesson(x, DateTime.now())) ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactLessonCardWidget extends StatefulWidget {
  const CompactLessonCardWidget({super.key, required this.lesson, required this.c, required this.d, required this.onTap});
  final Json lesson;
  final Json c;
  final DateTime? d;
  final VoidCallback? onTap;

  @override
  State<CompactLessonCardWidget> createState() => _CompactLessonCardWidgetState();
}

class _CompactLessonCardWidgetState extends State<CompactLessonCardWidget> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final x = widget.lesson;
    final c = widget.c;
    final isOpen = x['status'] == 'OPEN';
    
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOpen ? const Color(0xFFF0FDF4) : (hover ? const Color(0xFFF1F5E6) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOpen ? const Color(0xFF86EFAC) : (hover ? const Color(0xFF173D35) : const Color(0xFFE2E8F0)),
              width: 1.5,
            ),
            boxShadow: [
              if (hover)
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${c['classCode']} · ${c['subjectCode']}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                  if (isOpen)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.room_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'P.${x['room'] ?? '—'}', 
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
