import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A cheerful, hand-drawn-style backdrop for the main menu: a sunny sky with
/// drifting clouds, rolling hills, two cute castle towers and a parade of
/// pig-monsters bobbing along the path. Everything animates gently off a single
/// looping [animationValue] in `[0, 1)`.
class MenuBackgroundPainter extends CustomPainter {
  MenuBackgroundPainter(this.animationValue, this.color);

  final double animationValue;

  /// Kept for API compatibility with the menu screen; the scene uses its own
  /// storybook palette.
  final Color color;

  // ---- palette -------------------------------------------------------------
  static const _skyTop = Color(0xFFBEE9FF);
  static const _skyBottom = Color(0xFFFFF3D6);
  static const _hillBack = Color(0xFF9BDE7F);
  static const _hillMid = Color(0xFF77CB63);
  static const _hillFront = Color(0xFF54B24A);
  static const _ground = Color(0xFF3E9B3E);
  static const _path = Color(0xFFF6E1B0);
  static const _pathEdge = Color(0xFFE4C888);
  static const _stone = Color(0xFFCDBBA0);
  static const _stoneShade = Color(0xFFB39E80);
  static const _roof = Color(0xFFEC6A5C);
  static const _roofShade = Color(0xFFCE5648);
  static const _pig = Color(0xFFF7A8C4);
  static const _pigSnout = Color(0xFFEC8FB0);
  static const _pigLine = Color(0xFF9B4A6E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final t = animationValue;

    // ---- sky --------------------------------------------------------------
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyBottom],
        ).createShader(Offset.zero & size),
    );

    _sun(canvas, Offset(w * 0.84, h * 0.16), h * 0.07, t);

    // ---- drifting clouds ------------------------------------------------
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
    for (var i = 0; i < 5; i++) {
      final speed = 0.4 + i * 0.12;
      final phase = (t * speed + i * 0.27) % 1.0;
      final x = (w + 220) * phase - 110;
      final y = h * (0.10 + (i * 0.09) % 0.34);
      final s = 0.7 + (i % 3) * 0.28;
      _cloud(canvas, Offset(x, y), 34 * s, cloudPaint);
    }

    // ---- hills ----------------------------------------------------------
    _hill(canvas, size, h * 0.60, 26, 0.9, _hillBack);
    _hill(canvas, size, h * 0.70, 34, 1.6, _hillMid);
    _hill(canvas, size, h * 0.82, 30, 2.4, _hillFront);
    canvas.drawRect(
      Rect.fromLTRB(0, h * 0.82, w, h),
      Paint()..color = _ground,
    );

    // ---- winding path -------------------------------------------------
    _pathRibbon(canvas, size);

    // ---- towers -----------------------------------------------------
    _tower(canvas, Offset(w * 0.20, h * 0.70), h * 0.20, t, flagLeft: false);
    _tower(canvas, Offset(w * 0.78, h * 0.66), h * 0.16, t + 0.5, flagLeft: true);

    // ---- pig-monster parade --------------------------------------------
    const pigs = <_PigSlot>[
      _PigSlot(0.09, 0.87, 0.44, hat: _PigHat.horns),
      _PigSlot(0.30, 0.83, 0.34, hat: _PigHat.helmet),
      _PigSlot(0.50, 0.88, 0.29, hat: _PigHat.none),
      _PigSlot(0.67, 0.84, 0.25, hat: _PigHat.horns),
      _PigSlot(0.86, 0.87, 0.22, hat: _PigHat.none),
    ];
    for (var i = 0; i < pigs.length; i++) {
      final p = pigs[i];
      final bob = math.sin(t * math.pi * 2 * 2 + i * 1.3) * p.size * h * 0.05;
      _pigMonster(
        canvas,
        Offset(w * p.x, h * p.y + bob),
        p.size * h * 0.12,
        p.hat,
        i.isEven,
      );
    }

    // ---- floating hearts ---------------------------------------------
    final heartPaint = Paint()..color = const Color(0xFFFF8FB3);
    for (var i = 0; i < 6; i++) {
      final phase = (t * (0.6 + i * 0.05) + i / 6) % 1.0;
      final x = w * ((i * 0.173 + 0.08) % 1.0) + math.sin(phase * math.pi * 3) * 12;
      final y = h * (0.9 - phase * 0.7);
      heartPaint.color = const Color(0xFFFF8FB3)
          .withValues(alpha: (1 - phase).clamp(0.0, 1.0) * 0.5);
      _heart(canvas, Offset(x, y), 6 + (i % 3) * 2.0, heartPaint);
    }
  }

  // ------------------------------------------------------------------------

  void _sun(Canvas canvas, Offset c, double r, double t) {
    canvas.drawCircle(c, r * 1.9, Paint()..color = const Color(0x33FFE9A8));
    canvas.drawCircle(c, r * 1.4, Paint()..color = const Color(0x44FFE9A8));
    final ray = Paint()
      ..color = const Color(0xFFFFD873)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2 + t * math.pi * 2 * 0.1;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r * 1.35,
        c + Offset(math.cos(a), math.sin(a)) * r * 1.75,
        ray,
      );
    }
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFDD77));
  }

  void _cloud(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawCircle(c, r, p);
    canvas.drawCircle(c + Offset(r * 0.9, r * 0.2), r * 0.78, p);
    canvas.drawCircle(c + Offset(-r * 0.9, r * 0.25), r * 0.7, p);
    canvas.drawCircle(c + Offset(r * 0.1, -r * 0.5), r * 0.6, p);
    canvas.drawRect(
      Rect.fromLTWH(c.dx - r * 1.7, c.dy, r * 3.4, r + 2),
      p,
    );
  }

  void _hill(
    Canvas canvas,
    Size size,
    double baseY,
    double amp,
    double freq,
    Color color,
  ) {
    final path = Path()..moveTo(0, size.height);
    path.lineTo(0, baseY);
    const steps = 24;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final y = baseY - math.sin(i / steps * math.pi * freq + freq) * amp;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _pathRibbon(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ribbon = Path()
      ..moveTo(w * 0.30, h)
      ..cubicTo(w * 0.32, h * 0.9, w * 0.05, h * 0.88, w * 0.10, h * 0.80)
      ..cubicTo(w * 0.16, h * 0.72, w * 0.62, h * 0.78, w * 0.72, h * 0.70)
      ..cubicTo(w * 0.82, h * 0.63, w * 0.72, h * 0.60, w * 0.86, h * 0.58)
      ..lineTo(w * 0.98, h * 0.62)
      ..lineTo(w * 0.90, h * 0.70)
      ..cubicTo(w * 0.78, h * 0.74, w * 0.40, h * 0.86, w * 0.30, h * 0.92)
      ..cubicTo(w * 0.26, h * 0.95, w * 0.44, h, w * 0.52, h)
      ..close();
    canvas.drawPath(
      ribbon,
      Paint()
        ..color = _pathEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(ribbon, Paint()..color = _path);
  }

  void _tower(
    Canvas canvas,
    Offset base,
    double height,
    double t, {
    required bool flagLeft,
  }) {
    final wdt = height * 0.52;
    final bodyTop = base.dy - height;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(base.dx - wdt / 2, bodyTop, wdt, height),
      topLeft: Radius.circular(wdt * 0.18),
      topRight: Radius.circular(wdt * 0.18),
    );
    canvas.drawRRect(body, Paint()..color = _stone);
    // shaded right half
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTWH(base.dx, bodyTop, wdt, height),
      Paint()..color = _stoneShade.withValues(alpha: 0.5),
    );
    // brick lines
    final brick = Paint()
      ..color = _stoneShade
      ..strokeWidth = 1.5;
    for (var i = 1; i < 5; i++) {
      final y = bodyTop + height * i / 5;
      canvas.drawLine(Offset(base.dx - wdt / 2, y), Offset(base.dx + wdt / 2, y), brick);
    }
    canvas.restore();

    // crenellations
    final merlon = Paint()..color = _stone;
    for (var i = 0; i < 3; i++) {
      final mx = base.dx - wdt / 2 + wdt * i / 3;
      canvas.drawRect(
        Rect.fromLTWH(mx + wdt * 0.04, bodyTop - wdt * 0.22, wdt * 0.24, wdt * 0.26),
        merlon,
      );
    }

    // conical roof
    final roofH = wdt * 0.9;
    final roofBaseY = bodyTop - wdt * 0.16;
    final roof = Path()
      ..moveTo(base.dx - wdt * 0.62, roofBaseY)
      ..lineTo(base.dx + wdt * 0.62, roofBaseY)
      ..lineTo(base.dx, roofBaseY - roofH)
      ..close();
    canvas.drawPath(roof, Paint()..color = _roof);
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, roofBaseY)
        ..lineTo(base.dx + wdt * 0.62, roofBaseY)
        ..lineTo(base.dx, roofBaseY - roofH)
        ..close(),
      Paint()..color = _roofShade,
    );

    // flag
    final poleTop = roofBaseY - roofH - wdt * 0.5;
    canvas.drawLine(
      Offset(base.dx, roofBaseY - roofH),
      Offset(base.dx, poleTop),
      Paint()
        ..color = const Color(0xFF6B5B47)
        ..strokeWidth = 2,
    );
    final wave = math.sin(t * math.pi * 2 * 2) * wdt * 0.08;
    final dir = flagLeft ? -1.0 : 1.0;
    final flag = Path()
      ..moveTo(base.dx, poleTop)
      ..lineTo(base.dx + dir * wdt * 0.5, poleTop + wdt * 0.1 + wave)
      ..lineTo(base.dx, poleTop + wdt * 0.34)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFFC24B));

    // arched window with a warm glow
    final winW = wdt * 0.34;
    final winRect = Rect.fromLTWH(
      base.dx - winW / 2,
      bodyTop + height * 0.34,
      winW,
      height * 0.30,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        winRect,
        topLeft: Radius.circular(winW / 2),
        topRight: Radius.circular(winW / 2),
      ),
      Paint()..color = const Color(0xFF5B3A2A),
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        winRect.deflate(2),
        topLeft: Radius.circular(winW / 2),
        topRight: Radius.circular(winW / 2),
      ),
      Paint()..color = const Color(0xFFFFD98A),
    );
  }

  void _pigMonster(
    Canvas canvas,
    Offset c,
    double r,
    _PigHat hat,
    bool faceRight,
  ) {
    final line = Paint()
      ..color = _pigLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, r * 0.09);
    final fill = Paint()..color = _pig;
    final dir = faceRight ? 1.0 : -1.0;

    // shadow
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(0, r * 1.15), width: r * 2.1, height: r * 0.5),
      Paint()..color = const Color(0x22000000),
    );

    // trotters
    for (final s in const [-0.5, 0.5]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: c + Offset(r * s, r * 0.95),
            width: r * 0.42,
            height: r * 0.5,
          ),
          Radius.circular(r * 0.15),
        ),
        fill,
      );
    }

    // ears
    for (final s in const [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(c.dx + s * r * 0.55, c.dy - r * 0.55)
        ..lineTo(c.dx + s * r * 1.0, c.dy - r * 1.15)
        ..lineTo(c.dx + s * r * 0.15, c.dy - r * 0.95)
        ..close();
      canvas.drawPath(ear, fill);
      canvas.drawPath(ear, line);
    }

    // horns (monster flavour, still cute)
    if (hat == _PigHat.horns) {
      final horn = Paint()..color = const Color(0xFFF3E7D0);
      for (final s in const [-1.0, 1.0]) {
        final p = Path()
          ..moveTo(c.dx + s * r * 0.7, c.dy - r * 0.9)
          ..quadraticBezierTo(
            c.dx + s * r * 1.25,
            c.dy - r * 1.5,
            c.dx + s * r * 0.95,
            c.dy - r * 1.75,
          )
          ..quadraticBezierTo(
            c.dx + s * r * 0.7,
            c.dy - r * 1.35,
            c.dx + s * r * 0.45,
            c.dy - r * 1.0,
          )
          ..close();
        canvas.drawPath(p, horn);
        canvas.drawPath(p, line);
      }
    }

    // body
    canvas.drawCircle(c, r, fill);
    canvas.drawCircle(c, r, line);

    // helmet
    if (hat == _PigHat.helmet) {
      final helm = Rect.fromCenter(center: c + Offset(0, -r * 0.35), width: r * 2.05, height: r * 1.6);
      canvas.drawArc(helm, math.pi, math.pi, true, Paint()..color = const Color(0xFF8C98A6));
      canvas.drawArc(helm, math.pi, math.pi, true, line);
      canvas.drawRect(
        Rect.fromCenter(center: c + Offset(0, -r * 0.35), width: r * 2.05, height: r * 0.26),
        Paint()..color = const Color(0xFF6B7683),
      );
    }

    // cheeks
    final cheek = Paint()..color = const Color(0x33E0578A);
    canvas.drawCircle(c + Offset(-r * 0.62, r * 0.15), r * 0.22, cheek);
    canvas.drawCircle(c + Offset(r * 0.62, r * 0.15), r * 0.22, cheek);

    // snout
    final snout = Offset(c.dx + dir * r * 0.1, c.dy + r * 0.25);
    canvas.drawOval(
      Rect.fromCenter(center: snout, width: r * 0.95, height: r * 0.7),
      Paint()..color = _pigSnout,
    );
    canvas.drawOval(
      Rect.fromCenter(center: snout, width: r * 0.95, height: r * 0.7),
      line,
    );
    for (final s in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: snout + Offset(s * r * 0.2, 0),
          width: r * 0.14,
          height: r * 0.24,
        ),
        Paint()..color = _pigLine,
      );
    }

    // eyes (happy arcs) + tiny fang
    final eyeY = c.dy - r * 0.15;
    for (final s in const [-1.0, 1.0]) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(c.dx + s * r * 0.38, eyeY), width: r * 0.34, height: r * 0.34),
        math.pi,
        math.pi,
        false,
        line,
      );
    }
    final fang = Path()
      ..moveTo(c.dx - r * 0.12, c.dy + r * 0.62)
      ..lineTo(c.dx - r * 0.02, c.dy + r * 0.62)
      ..lineTo(c.dx - r * 0.07, c.dy + r * 0.8)
      ..close();
    canvas.drawPath(fang, Paint()..color = Colors.white);
    canvas.drawPath(fang, line);
  }

  void _heart(Canvas canvas, Offset c, double s, Paint p) {
    final path = Path()
      ..moveTo(c.dx, c.dy + s * 0.9)
      ..cubicTo(c.dx - s * 1.6, c.dy - s * 0.5, c.dx - s * 0.5, c.dy - s * 1.3, c.dx, c.dy - s * 0.4)
      ..cubicTo(c.dx + s * 0.5, c.dy - s * 1.3, c.dx + s * 1.6, c.dy - s * 0.5, c.dx, c.dy + s * 0.9)
      ..close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant MenuBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color;
}

enum _PigHat { none, horns, helmet }

class _PigSlot {
  const _PigSlot(this.x, this.y, this.size, {required this.hat});

  final double x;
  final double y;
  final double size;
  final _PigHat hat;
}
