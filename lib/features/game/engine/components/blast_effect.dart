import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A short-lived expanding shockwave drawn where a cannon shell lands. Purely
/// cosmetic — the splash damage is resolved by the [Projectile] itself.
class BlastEffect extends PositionComponent {
  BlastEffect({required super.position, required this.radius})
    : super(anchor: Anchor.center, priority: 50);

  /// Final radius of the ring, in pixels (matches the tower's splash radius).
  final double radius;

  static const double _duration = 0.32;
  double _elapsed = 0;

  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / _duration).clamp(0.0, 1.0);
    final r = radius * (0.35 + 0.65 * t);
    final fade = (1 - t).clamp(0.0, 1.0);
    _fillPaint.color = Color.lerp(
      const Color(0xFFFFE082),
      const Color(0x00FF7043),
      t,
    )!.withValues(alpha: 0.5 * fade);
    _ringPaint.color = const Color(0xFFFF7043).withValues(alpha: fade);
    canvas.drawCircle(Offset.zero, r, _fillPaint);
    canvas.drawCircle(Offset.zero, r, _ringPaint);
  }
}
