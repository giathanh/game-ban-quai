import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../data/level.dart';
import '../ban_heo_game.dart';

/// A pig (Heo) marching along the path. Reaching the end costs the player lives;
/// dropping to 0 hp pays out gold.
class Enemy extends PositionComponent with HasGameReference<BanHeoGame> {
  Enemy({
    required this.stats,
    required this.pathPixels,
    required double cellSize,
  }) : super(
          size: Vector2.all(cellSize * 0.62),
          anchor: Anchor.center,
        );

  final EnemyStats stats;
  final List<Vector2> pathPixels;

  late double _hp;
  int _segment = 0;
  bool _resolved = false;

  /// Distance travelled along the path in pixels — used by towers to target the
  /// enemy that is furthest along.
  double pathProgress = 0;

  final Paint _bodyPaint = Paint()..color = const Color(0xFFF48FB1);
  final Paint _outlinePaint = Paint()
    ..color = const Color(0xFF880E4F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _hpBackPaint = Paint()..color = const Color(0xFF4E342E);
  final Paint _hpFrontPaint = Paint()..color = const Color(0xFF66BB6A);

  final Vector2 _step = Vector2.zero();

  double get hpFraction => (_hp / stats.maxHp).clamp(0, 1).toDouble();

  @override
  Future<void> onLoad() async {
    _hp = stats.maxHp;
    position.setFrom(pathPixels.first);
  }

  @override
  void update(double dt) {
    if (_resolved) {
      return;
    }
    if (_segment >= pathPixels.length - 1) {
      _leak();
      return;
    }

    final target = pathPixels[_segment + 1];
    _step
      ..setFrom(target)
      ..sub(position);
    final distance = _step.length;
    final move = stats.speed * dt;

    if (move >= distance) {
      position.setFrom(target);
      pathProgress += distance;
      _segment++;
    } else {
      _step.scale(move / distance);
      position.add(_step);
      pathProgress += move;
    }
  }

  /// Applies [amount] damage. Kills and pays out when hp runs out.
  void takeDamage(double amount) {
    if (_resolved) {
      return;
    }
    _hp -= amount;
    if (_hp <= 0) {
      _resolved = true;
      game.onEnemyKilled(this);
      removeFromParent();
    }
  }

  void _leak() {
    _resolved = true;
    game.onEnemyLeaked(this);
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final center = Offset(r, r);
    canvas.drawCircle(center, r, _bodyPaint);
    canvas.drawCircle(center, r, _outlinePaint);

    // Snout.
    canvas.drawCircle(center, r * 0.42, _outlinePaint);

    // HP bar above the pig.
    final barWidth = size.x;
    const barHeight = 4.0;
    const barTop = -barHeight - 3;
    canvas.drawRect(
      Rect.fromLTWH(0, barTop, barWidth, barHeight),
      _hpBackPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, barTop, barWidth * hpFraction, barHeight),
      _hpFrontPaint,
    );
  }
}
