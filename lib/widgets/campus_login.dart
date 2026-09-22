import 'package:flutter/material.dart';
import 'dart:ui';

/// Full-screen glassmorphism campus entrance layout.
class CampusLogin extends StatelessWidget {
  const CampusLogin({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;
      return Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset('assets/images/fpt_bg.jpg', fit: BoxFit.cover),
          
          // Overlay Gradient
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0x990A1A18), Color(0xCC05100E)],
              ),
            ),
          ),
          
          // Decorative Circles
          if (isWide)
            for (final size in [440.0, 300.0])
              Positioned(
                left: constraints.maxWidth * 0.15 - size / 2,
                top: constraints.maxHeight * 0.4 - size / 2,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x22DCEAA5), width: 1.5),
                  ),
                ),
              ),

          // Left Side Text (Only on Wide Screens)
          if (isWide)
            Positioned(
              left: constraints.maxWidth * 0.1,
              top: 0,
              bottom: 0,
              child: Center(
                child: SizedBox(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.blur_on_rounded,
                            color: Color(0xFFDCEAA5),
                            size: 32,
                          ),
                          SizedBox(width: 14),
                          Text(
                            'CAMPUS / STUDIO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      Text(
                        'Có mặt.\nKết nối.\nTiến xa.',
                        style: TextStyle(
                          color: const Color(0xFFF8F6EE),
                          fontSize: constraints.maxHeight < 650 ? 54 : 76,
                          height: 1.05,
                          letterSpacing: -3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Không gian điểm danh hiện đại\nvà mượt mà dành riêng cho FPT University.',
                        style: TextStyle(
                          color: Color(0xFFDCEAA5),
                          fontSize: 18,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      const Divider(color: Color(0x44FFFFFF)),
                      const SizedBox(height: 16),
                      const Text(
                        'FPT UNIVERSITY    /    ATTENDANCE',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Right Side Login Form
          Positioned(
            right: isWide ? constraints.maxWidth * 0.1 : 0,
            left: isWide ? null : 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: child,
              ),
            ),
          ),
        ],
      );
    },
  );
}
