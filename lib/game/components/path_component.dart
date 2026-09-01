import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Draws the enemy path as a thick poly-line. Purely decorative — enemy
/// movement uses the same waypoint list directly.
class PathComponent extends PositionComponent {
  PathComponent({required this.waypoints, required this.laneWidth})
      : super(priority: -10);

  final List<Vector2> waypoints;
  final double laneWidth;

  late final Path _path;
  late final Paint _lanePaint;
  late final Paint _edgePaint;

  @override
  Future<void> onLoad() async {
    _lanePaint = Paint()
      ..color = const Color(0xFF6D4C41)
      ..style = PaintingStyle.stroke
      ..strokeWidth = laneWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _edgePaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = laneWidth + 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _path = Path()..moveTo(waypoints.first.x, waypoints.first.y);
    for (var i = 1; i < waypoints.length; i++) {
      _path.lineTo(waypoints[i].x, waypoints[i].y);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPath(_path, _edgePaint);
    canvas.drawPath(_path, _lanePaint);
  }
}
