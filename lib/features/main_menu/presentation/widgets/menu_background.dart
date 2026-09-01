import 'dart:math' as math;

import 'package:flutter/material.dart';

class MenuBackgroundPainter extends CustomPainter {
  MenuBackgroundPainter(this.animationValue, this.color);

  final double animationValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF12321A),
    );
    final paint = Paint()..color = color.withValues(alpha: 0.12);
    for (var i = 0; i < 14; i++) {
      final phase = (animationValue + i / 14) % 1.0;
      final x = (size.width + 160) * phase - 80;
      final y = size.height * ((i * 0.137) % 1.0);
      final radius = 24.0 + (i % 5) * 12.0;
      canvas.drawCircle(
        Offset(x, y + 20 * math.sin(phase * math.pi * 2)),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MenuBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color;
}
