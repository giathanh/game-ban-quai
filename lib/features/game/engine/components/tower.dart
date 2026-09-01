import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/level.dart';
import '../ban_heo_game.dart';
import 'enemy.dart';
import 'projectile.dart';

/// A placed defense rendered with a soft 3D sprite.
class Tower extends PositionComponent with HasGameReference<BanHeoGame> {
  Tower({required super.position, required this.stats, required this.cellSize})
    : super(size: Vector2.all(cellSize * 1.06), anchor: Anchor.center);

  final TowerStats stats;
  final double cellSize;

  double get rangePixels => stats.rangeCells * cellSize;

  Sprite? _sprite;
  double _cooldown = 0;
  double _aimAngle = 0;
  double _recoil = 0;
  double _time = 0;

  final Paint _rangeFill = Paint()..color = const Color(0x1837B899);
  final Paint _rangeStroke = Paint()
    ..color = const Color(0xAAE4FFF4)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.7;
  final Paint _shadowPaint = Paint()..color = const Color(0x3D173620);

  @override
  void onLoad() {
    super.onLoad();
    final asset = switch (stats.kind) {
      TowerKind.arrow => 'game/tower_arrow.png',
      TowerKind.cannon => 'game/tower_cannon.png',
      TowerKind.flamingArrow => 'game/tower_flaming_arrow.png',
    };
    _loadSprite(asset);
  }

  Future<void> _loadSprite(String asset) async {
    try {
      if (WidgetsBinding.instance.rootElement == null) return;
    } catch (_) {
      return;
    }
    try {
      _sprite = Sprite(await game.images.load(asset));
    } catch (_) {
      // Logic-only Flame tests do not initialize Flutter's asset binding.
    }
  }

  @override
  void update(double dt) {
    _time += dt;
    _recoil = math.max(0, _recoil - dt * 6);
    if (_cooldown > 0) _cooldown -= dt;

    final target = _acquireTarget();
    if (target == null) return;

    _aimAngle = math.atan2(
      target.position.y - position.y,
      target.position.x - position.x,
    );
    if (_cooldown <= 0) {
      _fire(target);
      _cooldown = 1 / stats.fireRate;
      _recoil = 1;
    }
  }

  Enemy? _acquireTarget() {
    Enemy? best;
    var bestProgress = -1.0;
    for (final enemy in game.world.children.query<Enemy>()) {
      if (enemy.isRemoving ||
          enemy.position.distanceTo(position) > rangePixels) {
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
        kind: stats.kind,
        splashRadius: stats.splashRadiusCells * cellSize,
        splashDamageFactor: stats.splashDamageFactor,
        burnDps: stats.burnDps,
        burnDuration: stats.burnDuration,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    if (game.selectedSpot.value?.tower == this) {
      canvas.drawCircle(center, rangePixels, _rangeFill);
      canvas.drawCircle(center, rangePixels, _rangeStroke);
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, size.y * 0.29),
        width: size.x * 0.66,
        height: size.y * 0.20,
      ),
      _shadowPaint,
    );

    final bob = math.sin(_time * 2.2) * size.y * 0.012;
    final squash = 1 - _recoil * 0.045;
    canvas.save();
    canvas.translate(center.dx, center.dy + bob);
    canvas.scale(1 / squash, squash);
    canvas.translate(-center.dx, -center.dy);
    final sprite = _sprite;
    if (sprite != null) {
      sprite.render(canvas, size: size);
    } else {
      canvas.drawCircle(
        center,
        size.x * 0.28,
        Paint()..color = const Color(0xFFD9C8A6),
      );
    }
    canvas.restore();

    if (_recoil > 0.24) _renderMuzzleFlash(canvas, center);
  }

  void _renderMuzzleFlash(Canvas canvas, Offset center) {
    final distance = size.x * 0.43;
    final tip =
        center + Offset(math.cos(_aimAngle), math.sin(_aimAngle)) * distance;
    final radius = size.x * (0.07 + _recoil * 0.06);
    canvas.drawCircle(
      tip,
      radius * 1.7,
      Paint()..color = const Color(0x55FF8A30),
    );
    canvas.drawCircle(
      tip,
      radius,
      Paint()
        ..color = stats.kind == TowerKind.flamingArrow
            ? const Color(0xFFFF9D2E)
            : const Color(0xFFFFE3A1),
    );
  }
}
