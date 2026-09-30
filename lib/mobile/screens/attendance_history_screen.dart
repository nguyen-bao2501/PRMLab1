import 'package:flutter/material.dart';

import '../models/student_attendance.dart';
import '../services/mobile_auth_service.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({
    super.key,
    required this.authService,
  });

  final MobileAuthService authService;

  @override
  State<AttendanceHistoryScreen> createState() => AttendanceHistoryScreenState();
}

class AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<StudentAttendance> _attendances = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadAttendances();
  }

  Future<void> loadAttendances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await widget.authService.apiService.myAttendances();
      final list = res.map((e) => StudentAttendance.fromJson(e)).toList();
      // Sort newest first
      list.sort((a, b) {
        final aTime = a.checkInTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.checkInTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _attendances = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const fptOrange = Color(0xFFF37021);
    const ink = Color(0xFF3A504E);

    final presentCount = _attendances.where((a) => a.status.toUpperCase() == 'PRESENT').length;
    final lateCount = _attendances.where((a) => a.status.toUpperCase() == 'LATE').length;
    final absentCount = _attendances.where((a) => a.status.toUpperCase() == 'ABSENT').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          'Lịch sử Điểm danh',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: ink,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: loadAttendances,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: fptOrange,
        onRefresh: loadAttendances,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: fptOrange))
            : _errorMessage != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const SizedBox(height: 60),
                      Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ink,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: loadAttendances,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Thử lại'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // Stats Overview Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3A504E), Color(0xFF223533)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TỔNG QUAN THAM GIA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: Colors.white70,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: fptOrange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_attendances.length} buổi',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem('Có mặt', '$presentCount', const Color(0xFF68D391)),
                                Container(width: 1, height: 32, color: Colors.white24),
                                _statItem('Đi muộn', '$lateCount', const Color(0xFFF6E05E)),
                                Container(width: 1, height: 32, color: Colors.white24),
                                _statItem('Vắng mặt', '$absentCount', const Color(0xFFFC8181)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          const Icon(Icons.history_rounded, size: 20, color: ink),
                          const SizedBox(width: 8),
                          const Text(
                            'Chi tiết các buổi học',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_attendances.length} bản ghi',
                            style: const TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_attendances.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey.shade400),
                              const SizedBox(height: 14),
                              const Text(
                                'Bạn chưa có bản ghi điểm danh nào.',
                                style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Hãy chuyển sang tab Quét QR khi giảng viên mở buổi học.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.black38, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._attendances.map((item) => _buildAttendanceCard(item)),
                    ],
                  ),
      ),
    );
  }

  Widget _statItem(String title, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(StudentAttendance item) {
    const ink = Color(0xFF3A504E);
    final status = item.status.toUpperCase();

    Color badgeBg;
    Color badgeText;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'LATE':
        badgeBg = const Color(0xFFFEFCBF);
        badgeText = const Color(0xFF975A16);
        statusLabel = 'Đi muộn';
        statusIcon = Icons.access_time_rounded;
        break;
      case 'ABSENT':
        badgeBg = const Color(0xFFFED7D7);
        badgeText = const Color(0xFF9B2C2C);
        statusLabel = 'Vắng mặt';
        statusIcon = Icons.cancel_outlined;
        break;
      case 'PRESENT':
      default:
        badgeBg = const Color(0xFFC6F6D5);
        badgeText = const Color(0xFF22543D);
        statusLabel = 'Có mặt';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
    }

    final formattedDate = item.checkInTime != null
        ? '${item.checkInTime!.hour.toString().padLeft(2, "0")}:${item.checkInTime!.minute.toString().padLeft(2, "0")} • ${item.checkInTime!.day.toString().padLeft(2, "0")}/${item.checkInTime!.month.toString().padLeft(2, "0")}/${item.checkInTime!.year}'
        : 'Không rõ thời gian';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: const Color(0xFFEDF2F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: ink, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.className ?? (item.sessionId != null ? 'Buổi học #${item.sessionId}' : 'Lớp học'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ink,
                      ),
                    ),
                    if (item.subjectName != null && item.subjectName!.isNotEmpty)
                      Text(
                        item.subjectName!,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: badgeText),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.meeting_room_outlined, size: 14, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    item.room != null && item.room!.isNotEmpty ? 'Phòng ${item.room}' : 'Buổi #${item.sessionId ?? "N/A"}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_outlined, size: 14, color: Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          if (item.deviceInfo != null && item.deviceInfo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.smartphone_rounded, size: 14, color: Colors.black38),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Thiết bị: ${item.deviceInfo}',
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
