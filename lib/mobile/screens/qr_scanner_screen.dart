import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/student_attendance.dart';
import '../services/mobile_auth_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({
    super.key,
    required this.authService,
    this.onAttendanceSuccess,
  });

  final MobileAuthService authService;
  final VoidCallback? onAttendanceSuccess;

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _scannerController;
  late final AnimationController _animController;
  late final Animation<double> _scanAnimation;

  bool _isProcessing = false;
  bool _isFlashOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  String? _extractToken(String raw) {
    final trimmed = raw.trim();
    if (RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(trimmed)) {
      return trimmed;
    }
    try {
      final uri = Uri.parse(trimmed);
      if (uri.fragment.isNotEmpty) {
        final fragParams = Uri.splitQueryString(uri.fragment);
        if (fragParams.containsKey('token')) return fragParams['token'];
      }
      if (uri.queryParameters.containsKey('token')) {
        return uri.queryParameters['token'];
      }
    } catch (_) {}
    return null;
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawVal = barcodes.first.rawValue;
    if (rawVal == null || rawVal.isEmpty) return;

    final token = _extractToken(rawVal);
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã QR không hợp lệ cho điểm danh FPT.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    await _processCheckIn(token);
  }

  Future<void> _processCheckIn(String token) async {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final res = await widget.authService.apiService.checkIn(token);
      final attendance = StudentAttendance.fromJson(res);

      if (mounted) {
        widget.onAttendanceSuccess?.call();
        await _showResultModal(
          success: true,
          title: 'Điểm danh thành công!',
          message:
              'Đã ghi nhận có mặt cho sinh viên ${attendance.studentName ?? widget.authService.currentUser?.fullName ?? ""}.',
          attendance: attendance,
        );
      }
    } catch (e) {
      if (mounted) {
        await _showResultModal(
          success: false,
          title: 'Điểm danh thất bại',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showResultModal({
    required bool success,
    required String title,
    required String message,
    StudentAttendance? attendance,
  }) async {
    const fptOrange = Color(0xFFF37021);
    const ink = Color(0xFF3A504E);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: success ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_circle_rounded : Icons.highlight_off_rounded,
                color: success ? const Color(0xFF137333) : const Color(0xFFC5221F),
                size: 54,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: success ? ink : const Color(0xFFC5221F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            if (attendance != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _infoRow('Mã sinh viên', attendance.studentCode ?? 'Chưa cập nhật'),
                    const Divider(height: 16),
                    _infoRow('Buổi học #', '${attendance.sessionId ?? "N/A"}'),
                    if (attendance.room != null && attendance.room!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _infoRow('Phòng học', attendance.room!),
                    ],
                    if (attendance.className != null && attendance.className!.isNotEmpty) ...[
                      const Divider(height: 16),
                      _infoRow('Lớp học', attendance.className!),
                    ],
                    const Divider(height: 16),
                    _infoRow(
                      'Thời gian',
                      attendance.checkInTime != null
                          ? '${attendance.checkInTime!.hour.toString().padLeft(2, "0")}:${attendance.checkInTime!.minute.toString().padLeft(2, "0")} - ${attendance.checkInTime!.day}/${attendance.checkInTime!.month}/${attendance.checkInTime!.year}'
                          : 'Vừa xong',
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: success ? fptOrange : ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(success ? 'Hoàn tất' : 'Thử lại'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF3A504E)),
        ),
      ],
    );
  }

  void _showManualInputDialog() {
    final tokenController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nhập mã điểm danh thủ công', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nếu không thể quét camera, bạn có thể dán liên kết hoặc mã token 32 ký tự:',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: tokenController,
              decoration: const InputDecoration(
                labelText: 'Mã QR Token hoặc Đường dẫn',
                hintText: 'Nhập hoặc dán tại đây',
                prefixIcon: Icon(Icons.qr_code_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF37021)),
            onPressed: () {
              final raw = tokenController.text.trim();
              final token = _extractToken(raw) ?? raw;
              if (token.isNotEmpty) {
                Navigator.pop(ctx);
                _processCheckIn(token);
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const fptOrange = Color(0xFFF37021);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetected,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_rounded, color: Colors.white70, size: 54),
                      const SizedBox(height: 16),
                      Text(
                        'Không thể truy cập máy ảnh: ${error.errorCode}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: fptOrange),
                        onPressed: _showManualInputDialog,
                        icon: const Icon(Icons.keyboard_alt_outlined),
                        label: const Text('Nhập mã thủ công'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Viewfinder Overlay
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scanSize = constraints.maxWidth * 0.72;
                return Container(
                  width: scanSize,
                  height: scanSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Scanner Line Animation
                      AnimatedBuilder(
                        animation: _scanAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: scanSize * _scanAnimation.value,
                            left: 12,
                            right: 12,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    fptOrange,
                                    Colors.white,
                                    fptOrange,
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: fptOrange.withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Corner indicators
                      _corner(top: 0, left: 0),
                      _corner(top: 0, right: 0),
                      _corner(bottom: 0, left: 0),
                      _corner(bottom: 0, right: 0),
                    ],
                  ),
                );
              },
            ),
          ),

          // Processing Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: fptOrange),
                    SizedBox(height: 16),
                    Text(
                      'Đang xác thực điểm danh...',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Header Instruction
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 16, left: 20, right: 20),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: fptOrange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Hướng camera vào mã QR của giảng viên',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Controls Bar (Flash, Flip, Manual input)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlButton(
                      icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      label: 'Đèn flash',
                      isActive: _isFlashOn,
                      onTap: () async {
                        await _scannerController.toggleTorch();
                        setState(() => _isFlashOn = !_isFlashOn);
                      },
                    ),
                    _controlButton(
                      icon: Icons.keyboard_alt_outlined,
                      label: 'Nhập mã',
                      isActive: false,
                      onTap: _showManualInputDialog,
                    ),
                    _controlButton(
                      icon: Icons.flip_camera_ios_rounded,
                      label: 'Lật camera',
                      isActive: false,
                      onTap: () async {
                        await _scannerController.switchCamera();
                        setState(() {
                          _cameraFacing = _cameraFacing == CameraFacing.back
                              ? CameraFacing.front
                              : CameraFacing.back;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner({double? top, double? bottom, double? left, double? right}) {
    const fptOrange = Color(0xFFF37021);
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? const BorderSide(color: fptOrange, width: 4) : BorderSide.none,
            bottom: bottom != null ? const BorderSide(color: fptOrange, width: 4) : BorderSide.none,
            left: left != null ? const BorderSide(color: fptOrange, width: 4) : BorderSide.none,
            right: right != null ? const BorderSide(color: fptOrange, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: top != null && left != null ? const Radius.circular(20) : Radius.zero,
            topRight: top != null && right != null ? const Radius.circular(20) : Radius.zero,
            bottomLeft: bottom != null && left != null ? const Radius.circular(20) : Radius.zero,
            bottomRight: bottom != null && right != null ? const Radius.circular(20) : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFF37021)
                  : Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
