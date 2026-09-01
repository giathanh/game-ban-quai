import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'enemy.dart';

/// A homing pellet fired by a [Tower]. Removes itself on hit or when its target
/// disappears.
class Projectile extends PositionComponent {
  Projectile({
    required super.position,
    required this.target,
    required this.speed,
    required this.damage,
  }) : super(size: Vector2.all(8), anchor: Anchor.center);

  final Enemy target;
  final double speed;
  final double damage;

  final Paint _paint = Paint()..color = const Color(0xFFFFF176);
  final Vector2 _dir = Vector2.zero();

  @override
  void update(double dt) {
    if (!target.isMounted || target.isRemoving) {
      removeFromParent();
      return;
    }

    _dir
      ..setFrom(target.position)
      ..sub(position);
    final distance = _dir.length;
    final travel = speed * dt;

    if (distance <= travel || distance < 4) {
      target.takeDamage(damage);
      removeFromParent();
      return;
    }

    _dir.scale(travel / distance);
    position.add(_dir);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, _paint);
  }
}
