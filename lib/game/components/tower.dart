import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/level.dart';
import '../ban_heo_game.dart';
import 'enemy.dart';
import 'projectile.dart';

/// A placed defense. Every [update] it cools down, then acquires the enemy
/// furthest along the path within range and fires a [Projectile].
class Tower extends PositionComponent with HasGameReference<BanHeoGame> {
  Tower({
    required super.position,
    required this.stats,
    required this.cellSize,
  }) : super(
          size: Vector2.all(cellSize * 0.7),
          anchor: Anchor.center,
        );

  final TowerStats stats;
  final double cellSize;

  double get rangePixels => stats.rangeCells * cellSize;

  double _cooldown = 0;

  final Paint _bodyPaint = Paint()..color = const Color(0xFF4DB6AC);
  final Paint _outlinePaint = Paint()
    ..color = const Color(0xFF00695C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _rangePaint = Paint()
    ..color = const Color(0x1A00695C)
    ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    if (_cooldown > 0) {
      _cooldown -= dt;
    }
    if (_cooldown > 0) {
      return;
    }

    final target = _acquireTarget();
    if (target != null) {
      _fire(target);
      _cooldown = 1 / stats.fireRate;
    }
  }

  Enemy? _acquireTarget() {
    Enemy? best;
    var bestProgress = -1.0;
    for (final enemy in game.world.children.query<Enemy>()) {
      if (enemy.isRemoving) {
        continue;
      }
      if (enemy.position.distanceTo(position) > rangePixels) {
        continue;
      }
      if (enemy.pathProgress > bestProgress) {
        best = enemy;
        bestProgress = enemy.pathProgress;
      }
    }
    return best;
  }

  void _fire(Enemy target) {
    game.world.add(
      Projectile(
        position: position.clone(),
        target: target,
        speed: stats.projectileSpeed,
        damage: stats.damage,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final center = Offset(r, r);
    canvas.drawCircle(center, rangePixels, _rangePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      _bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(6),
      ),
      _outlinePaint,
    );
  }
}
