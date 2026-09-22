import 'package:flutter/material.dart';

/// Editorial campus entrance, with a compact layout for smaller windows.
class CampusLogin extends StatelessWidget {
  const CampusLogin({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        if (constraints.maxWidth >= 1000)
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/images/fpt_bg.jpg', fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xA611302D), Color(0xF511302D)],
                        ),
                      ),
                    ),
                    for (final size in [340.0, 240.0])
                      Positioned(
                        right: 90 - size / 2,
                        top: 270 - size / 2,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0x55DCEAA5)),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(42),
                      child: LayoutBuilder(
                        builder: (context, c) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.blur_on_rounded,
                                  color: Color(0xFFDCEAA5),
                                  size: 30,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'CAMPUS / STUDIO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'Có mặt.\nKết nối.\nTiến xa.',
                              style: TextStyle(
                                color: const Color(0xFFF8F6EE),
                                fontSize: c.maxHeight < 550 ? 48 : 70,
                                height: 1.08,
                                letterSpacing: -3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Mỗi buổi học, một kết nối mới.',
                              style: TextStyle(
                                color: Color(0xFFDCEAA5),
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 36),
                            const Divider(color: Color(0x44FFFFFF)),
                            const SizedBox(height: 16),
                            const Text(
                              'FPT UNIVERSITY    /    ATTENDANCE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(flex: 5, child: child),
      ],
    ),
  );
}
