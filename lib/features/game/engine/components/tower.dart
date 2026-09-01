import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/level.dart';
import '../ban_heo_game.dart';
import 'enemy.dart';
import 'projectile.dart';

/// A placed defense. Every [update] it aims at the enemy furthest along the
/// path within range, and — once its cooldown clears — fires a [Projectile].
/// The artwork it paints is chosen by [TowerStats.kind].
class Tower extends PositionComponent with HasGameReference<BanHeoGame> {
  Tower({required super.position, required this.stats, required this.cellSize})
    : super(size: Vector2.all(cellSize * 0.72), anchor: Anchor.center);

  final TowerStats stats;
  final double cellSize;

  double get rangePixels => stats.rangeCells * cellSize;

  double _cooldown = 0;

  /// Direction the weapon points, in radians. Follows the current target.
  double _aimAngle = 0;

  /// 1 right after a shot, decaying to 0 — drives recoil and muzzle flash.
  double _recoil = 0;
  double _time = 0;

  // --- palette -------------------------------------------------------------
  final Paint _rangeFill = Paint()..color = const Color(0x14004D40);
  final Paint _rangeStroke = Paint()
    ..color = const Color(0x66004D40)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _shadowPaint = Paint()..color = const Color(0x33000000);

  @override
  void update(double dt) {
    _time += dt;
    if (_recoil > 0) {
      _recoil = math.max(0, _recoil - dt * 6);
    }
    if (_cooldown > 0) {
      _cooldown -= dt;
    }

    final target = _acquireTarget();
    if (target != null) {
      final dx = target.position.x - position.x;
      final dy = target.position.y - position.y;
      _aimAngle = math.atan2(dy, dx);
      if (_cooldown <= 0) {
        _fire(target);
        _cooldown = 1 / stats.fireRate;
        _recoil = 1;
      }
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
        kind: stats.kind,
        splashRadius: stats.splashRadiusCells * cellSize,
        splashDamageFactor: stats.splashDamageFactor,
        burnDps: stats.burnDps,
        burnDuration: stats.burnDuration,
      ),
    );
  }

  // --- rendering ----------------------------------------------------------

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    final center = Offset(r, r);

    final selected = game.selectedSpot.value?.tower == this;
    if (selected) {
      canvas.drawCircle(center, rangePixels, _rangeFill);
      canvas.drawCircle(center, rangePixels, _rangeStroke);
    }

    canvas.drawOval(
      Rect.fromCenter(center: center + const Offset(0, 2), width: size.x, height: size.y * 0.7),
      _shadowPaint,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    switch (stats.kind) {
      case TowerKind.arrow:
        _renderArrowTower(canvas, r);
      case TowerKind.cannon:
        _renderCannonTower(canvas, r);
      case TowerKind.flamingArrow:
        _renderFlamingArrowTower(canvas, r);
    }
    canvas.restore();
  }

  void _stoneBase(Canvas canvas, double r, Color face, Color rim, {bool battlements = false}) {
    final rimPaint = Paint()..color = rim;
    final facePaint = Paint()..color = face;
    if (battlements) {
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(math.cos(a) * r * 0.92, math.sin(a) * r * 0.92),
            width: r * 0.34,
            height: r * 0.34,
          ),
          rimPaint,
        );
      }
    }
    canvas.drawCircle(Offset.zero, r * 0.92, rimPaint);
    canvas.drawCircle(Offset.zero, r * 0.74, facePaint);
  }

  /// Cheap wooden crossbow on a pale stone footing.
  void _renderArrowTower(Canvas canvas, double r) {
    _stoneBase(canvas, r, const Color(0xFFBCA987), const Color(0xFF8D7B5B));

    canvas.save();
    canvas.rotate(_aimAngle);
    canvas.translate(-_recoil * r * 0.18, 0);

    final woodPaint = Paint()
      ..color = const Color(0xFF6D4C29)
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;
    // Bow limbs (a shallow arc across the aim axis).
    final bow = Path()
      ..moveTo(r * 0.15, -r * 0.85)
      ..quadraticBezierTo(r * 0.72, 0, r * 0.15, r * 0.85);
    canvas.drawPath(bow, Paint()
      ..color = const Color(0xFF7C5836)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.2
      ..strokeCap = StrokeCap.round);
    // String.
    canvas.drawLine(
      Offset(r * 0.15, -r * 0.8),
      Offset(r * 0.15, r * 0.8),
      Paint()
        ..color = const Color(0xFFE8E0CF)
        ..strokeWidth = 1.5,
    );
    // Stock.
    canvas.drawLine(Offset(-r * 0.7, 0), Offset(r * 0.55, 0), woodPaint);
    // Loaded bolt.
    canvas.drawLine(
      Offset(-r * 0.2, 0),
      Offset(r * 0.95, 0),
      Paint()
        ..color = const Color(0xFF3E2723)
        ..strokeWidth = r * 0.1
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(r * 1.05, 0)
        ..lineTo(r * 0.78, -r * 0.16)
        ..lineTo(r * 0.78, r * 0.16)
        ..close(),
      Paint()..color = const Color(0xFFCFD8DC),
    );
    canvas.restore();
  }

  /// Heavy iron cannon on a dark battlemented turret.
  void _renderCannonTower(Canvas canvas, double r) {
    _stoneBase(canvas, r, const Color(0xFF9E8677), const Color(0xFF6D584C),
        battlements: true);

    canvas.save();
    canvas.rotate(_aimAngle);
    final back = -_recoil * r * 0.3;
    canvas.translate(back, 0);

    final barrel = RRect.fromRectAndRadius(
      Rect.fromLTWH(-r * 0.35, -r * 0.32, r * 1.35, r * 0.64),
      Radius.circular(r * 0.18),
    );
    canvas.drawRRect(barrel, Paint()..color = const Color(0xFF37474F));
    canvas.drawRRect(barrel, Paint()
      ..color = const Color(0xFF1C262B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    // Muzzle ring + bore.
    canvas.drawCircle(Offset(r * 1.0, 0), r * 0.34, Paint()..color = const Color(0xFF455A64));
    canvas.drawCircle(Offset(r * 1.0, 0), r * 0.19, Paint()..color = const Color(0xFF10171A));
    // Breech cap.
    canvas.drawCircle(Offset(-r * 0.35, 0), r * 0.34, Paint()..color = const Color(0xFF2E3B42));

    if (_recoil > 0.25) {
      final f = _recoil;
      canvas.drawPath(
        Path()
          ..moveTo(r * 1.15, 0)
          ..lineTo(r * 1.15 + r * 0.9 * f, -r * 0.36 * f)
          ..lineTo(r * 1.15 + r * 1.3 * f, 0)
          ..lineTo(r * 1.15 + r * 0.9 * f, r * 0.36 * f)
          ..close(),
        Paint()..color = Color.lerp(const Color(0xFFFFF3E0), const Color(0x00FF7043), 1 - f)!,
      );
    }
    canvas.restore();
  }

  /// Ornate ballista wreathed in fire on a scorched dark plinth.
  void _renderFlamingArrowTower(Canvas canvas, double r) {
    _stoneBase(canvas, r, const Color(0xFF5B4636), const Color(0xFF37271C));
    // Glowing embers around the rim.
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 + _time * 0.6;
      final glow = 0.6 + 0.4 * math.sin(_time * 5 + i);
      canvas.drawCircle(
        Offset(math.cos(a) * r * 0.62, math.sin(a) * r * 0.62),
        r * 0.1,
        Paint()..color = const Color(0xFFFF7043).withValues(alpha: glow),
      );
    }

    canvas.save();
    canvas.rotate(_aimAngle);
    canvas.translate(-_recoil * r * 0.16, 0);

    // Dark metal-bound limbs.
    canvas.drawPath(
      Path()
        ..moveTo(r * 0.1, -r * 0.9)
        ..quadraticBezierTo(r * 0.8, 0, r * 0.1, r * 0.9),
      Paint()
        ..color = const Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.22
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(Offset(-r * 0.75, 0), Offset(r * 0.5, 0),
        Paint()
          ..color = const Color(0xFF3E2723)
          ..strokeWidth = r * 0.24
          ..strokeCap = StrokeCap.round);

    // Bolt shaft.
    canvas.drawLine(
      Offset(-r * 0.2, 0),
      Offset(r * 0.85, 0),
      Paint()
        ..color = const Color(0xFF2E1B12)
        ..strokeWidth = r * 0.1
        ..strokeCap = StrokeCap.round,
    );
    // Flaming head.
    final flick = 1 + 0.3 * math.sin(_time * 22);
    canvas.drawPath(
      Path()
        ..moveTo(r * 1.5 * flick, 0)
        ..quadraticBezierTo(r * 0.9, -r * 0.5 * flick, r * 0.7, 0)
        ..quadraticBezierTo(r * 0.9, r * 0.5 * flick, r * 1.5 * flick, 0),
      Paint()..color = const Color(0xFFFF7043),
    );
    canvas.drawPath(
      Path()
        ..moveTo(r * 1.15 * flick, 0)
        ..quadraticBezierTo(r * 0.95, -r * 0.24 * flick, r * 0.82, 0)
        ..quadraticBezierTo(r * 0.95, r * 0.24 * flick, r * 1.15 * flick, 0),
      Paint()..color = const Color(0xFFFFE082),
    );
    canvas.restore();
  }
}
