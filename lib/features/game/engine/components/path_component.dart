import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Draws the enemy path as a river: muddy banks, a sandy shore, layered water
/// and a scrolling scatter of foam flecks so the current reads as flowing.
/// Enemy movement uses the same waypoint list directly — this is decoration.
class PathComponent extends PositionComponent {
  PathComponent({required this.waypoints, required this.laneWidth})
    : super(priority: -10);

  final List<Vector2> waypoints;

  /// Width of the open water. Banks and shore are drawn wider than this.
  final double laneWidth;

  late final Path _path;
  late final PathMetric _metric;
  late final double _length;

  double _t = 0;
  final List<_Foam> _foam = <_Foam>[];

  late final Paint _bankPaint;
  late final Paint _shorePaint;
  late final Paint _waterDeepPaint;
  late final Paint _waterPaint;
  late final Paint _shimmerPaint;
  final Paint _foamPaint = Paint()..color = const Color(0x3DFFFFFF);

  Paint _river(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  Future<void> onLoad() async {
    _bankPaint = _river(const Color(0xFF6E5A34), laneWidth + 22);
    _shorePaint = _river(const Color(0xFFCBB577), laneWidth + 12);
    _waterDeepPaint = _river(const Color(0xFF276390), laneWidth + 2);
    _waterPaint = _river(const Color(0xFF3E8FC4), laneWidth * 0.80);
    _shimmerPaint = _river(const Color(0x3BCFEBFF), laneWidth * 0.30);

    _path = Path()..moveTo(waypoints.first.x, waypoints.first.y);
    for (var i = 1; i < waypoints.length; i++) {
      _path.lineTo(waypoints[i].x, waypoints[i].y);
    }
    _metric = _path.computeMetrics().first;
    _length = _metric.length;

    final rng = math.Random(7);
    for (var i = 0; i < 18; i++) {
      _foam.add(
        _Foam(
          start: rng.nextDouble() * _length,
          speed: 12 + rng.nextDouble() * 12,
          lateral: (rng.nextDouble() * 2 - 1) * 0.62,
          size: 1.4 + rng.nextDouble() * 2.6,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPath(_path, _bankPaint);
    canvas.drawPath(_path, _shorePaint);
    canvas.drawPath(_path, _waterDeepPaint);
    canvas.drawPath(_path, _waterPaint);
    canvas.drawPath(_path, _shimmerPaint);

    for (final f in _foam) {
      final tan = _metric.getTangentForOffset((f.start + _t * f.speed) % _length);
      if (tan == null) continue;
      final p = tan.position;
      final off = f.lateral * laneWidth * 0.5;
      canvas.drawCircle(
        Offset(p.dx - tan.vector.dy * off, p.dy + tan.vector.dx * off),
        f.size,
        _foamPaint,
      );
    }
  }
}

class _Foam {
  _Foam({
    required this.start,
    required this.speed,
    required this.lateral,
    required this.size,
  });

  /// Offset along the river at t=0, in pixels.
  final double start;

  /// Downstream drift in pixels per second.
  final double speed;

  /// Position across the river, -1..1.
  final double lateral;
  final double size;
}
