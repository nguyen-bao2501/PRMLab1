import 'dart:math' as math;

import 'package:flutter/material.dart';

const studioInk = Color(0xFF3A504E);
const studioLime = Color(0xFFD69E2E);
const studioPaper = Color(0xFFE8F0ED);

class StudioHero extends StatelessWidget {
  const StudioHero({super.key, required this.onOpen, required this.onImport});
  final VoidCallback? onOpen, onImport;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: studioInk,
      borderRadius: BorderRadius.circular(26),
    ),
    child: LayoutBuilder(
      builder: (context, c) => Stack(
        children: [
          if (c.maxWidth > 650)
            const Positioned(
              right: -20,
              top: -12,
              bottom: -12,
              width: 300,
              child: CustomPaint(painter: CampusOrbitPainter()),
            ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KHÔNG GIAN CHO NHỮNG KẾT NỐI',
                        style: TextStyle(
                          color: studioLime,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 21),
                      Text(
                        'Lớp học sẵn sàng.\nBạn cũng vậy.',
                        style: TextStyle(
                          fontSize: c.maxWidth > 650 ? 38 : 29,
                          letterSpacing: -1.2,
                          color: studioPaper,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Mở buổi học. Chia sẻ QR. Đón những kết nối mới.',
                        style: TextStyle(
                          color: Color(0xFFCEDBC8),
                          fontSize: 13,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: onOpen,
                            style: FilledButton.styleFrom(
                              backgroundColor: studioLime,
                              foregroundColor: studioInk,
                            ),
                            icon: const Icon(Icons.north_east, size: 17),
                            label: const Text('Đến lớp học của tôi'),
                          ),
                          TextButton.icon(
                            onPressed: onImport,
                            style: TextButton.styleFrom(
                              foregroundColor: studioPaper,
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Nhập lớp từ Sheet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (c.maxWidth > 650) const SizedBox(width: 225),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CampusOrbitPainter extends CustomPainter {
  const CampusOrbitPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF52705A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (final angle in [-.55, .55]) {
      canvas.save();
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 275, height: 165),
        paint,
      );
      canvas.restore();
    }
    canvas.rotate(-.14);
    final ticket = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-70, -94, 140, 188),
      const Radius.circular(16),
    );
    canvas.drawRRect(ticket, Paint()..color = studioLime);
    canvas.drawLine(
      const Offset(-51, 48),
      const Offset(51, 48),
      Paint()..color = studioInk.withValues(alpha: .3),
    );
    final mark = Path()
      ..moveTo(-28, -10)
      ..lineTo(-5, 13)
      ..lineTo(32, -28);
    canvas.drawPath(
      mark,
      Paint()
        ..color = studioInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var x = -45; x < 48; x += 7) {
      canvas.drawLine(
        Offset(x.toDouble(), 62),
        Offset(x.toDouble(), 76),
        Paint()
          ..color = studioInk
          ..strokeWidth = x.isEven ? 2 : 3,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CampusOrbitPainter oldDelegate) => false;
}

class AttendanceRing extends StatelessWidget {
  const AttendanceRing({super.key, required this.present, required this.total});
  final int present, total;
  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (present / total).clamp(0.0, 1.0);
    return Semantics(
      label: '$present trên $total sinh viên đã điểm danh',
      child: SizedBox(
        width: 170,
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(child: CustomPaint(painter: _RingPainter(ratio))),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(ratio * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: studioInk,
                    letterSpacing: -2,
                  ),
                ),
                const Text(
                  'ĐÃ ĐIỂM DANH',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.3,
                    color: studioInk,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.ratio);
  final double ratio;
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      bounds.deflate(9),
      -math.pi / 2,
      math.pi * 2,
      false,
      paint..color = const Color(0xFFE9EDDF),
    );
    if (ratio > 0) {
      canvas.drawArc(
        bounds.deflate(9),
        -math.pi / 2,
        math.pi * 2 * ratio,
        false,
        paint..color = studioInk,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => ratio != oldDelegate.ratio;
}
