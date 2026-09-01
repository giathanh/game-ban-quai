import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/level.dart';
import '../ban_heo_game.dart';
import 'blast_effect.dart';
import 'enemy.dart';

/// A homing shot fired by a [Tower]. Removes itself on hit or when its target
/// disappears. On impact it deals its damage, optionally splashes an area and
/// optionally sets the target on fire — driven by the firing tower's
/// [TowerStats].
class Projectile extends PositionComponent with HasGameReference<BanHeoGame> {
  Projectile({
    required super.position,
    required this.target,
    required this.speed,
    required this.damage,
    this.kind = TowerKind.arrow,
    this.splashRadius = 0,
    this.splashDamageFactor = 0.5,
    this.burnDps = 0,
    this.burnDuration = 0,
  }) : super(size: Vector2.all(10), anchor: Anchor.center);

  final Enemy target;
  final double speed;
  final double damage;
  final TowerKind kind;

  /// Splash radius in pixels. 0 means single target.
  final double splashRadius;
  final double splashDamageFactor;
  final double burnDps;
  final double burnDuration;

  static final Paint _arrowShaftPaint = Paint()
    ..color = const Color(0xFF5D4037)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  static final Paint _arrowHeadPaint = Paint()..color = const Color(0xFFCFD8DC);
  static final Paint _fletchPaint = Paint()..color = const Color(0xFFECEFF1);
  static final Paint _ballPaint = Paint()..color = const Color(0xFF263238);
  static final Paint _ballShinePaint = Paint()..color = const Color(0xFF546E7A);
  static final Paint _smokePaint = Paint()..color = const Color(0x55B0BEC5);
  static final Paint _firePaint = Paint()..color = const Color(0xFFFF7043);
  static final Paint _fireCorePaint = Paint()..color = const Color(0xFFFFE082);

  final Vector2 _dir = Vector2.zero();
  double _angle = 0;
  double _t = 0;

  @override
  void update(double dt) {
    if (!target.isMounted || target.isRemoving) {
      removeFromParent();
      return;
    }
    _t += dt;

    _dir
      ..setFrom(target.position)
      ..sub(position);
    final distance = _dir.length;
    if (distance > 0.0001) {
      _angle = math.atan2(_dir.y, _dir.x);
    }
    final travel = speed * dt;

    if (distance <= travel || distance < 4) {
      _impact();
      return;
    }

    _dir.scale(travel / distance);
    position.add(_dir);
  }

  void _impact() {
    target.takeDamage(damage);
    if (burnDuration > 0) {
      target.applyBurn(burnDps, burnDuration);
    }

    if (splashRadius > 0) {
      for (final enemy in game.world.children.query<Enemy>()) {
        if (identical(enemy, target) ||
            enemy.isRemoving ||
            !enemy.isMounted) {
          continue;
        }
        if (enemy.position.distanceTo(position) <= splashRadius) {
          enemy.takeDamage(damage * splashDamageFactor);
        }
      }
      game.world.add(
        BlastEffect(position: position.clone(), radius: splashRadius),
      );
    }

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_angle);
    switch (kind) {
      case TowerKind.arrow:
        _renderArrow(canvas, fiery: false);
      case TowerKind.flamingArrow:
        _renderArrow(canvas, fiery: true);
      case TowerKind.cannon:
        _renderCannonball(canvas);
    }
    canvas.restore();
  }

  void _renderArrow(Canvas canvas, {required bool fiery}) {
    const len = 9.0;
    if (fiery) {
      final flick = 1 + 0.25 * math.sin(_t * 30);
      canvas.drawPath(
        Path()
          ..moveTo(len * 0.4, 0)
          ..quadraticBezierTo(-len * 0.6, -4 * flick, -len * 1.9 * flick, 0)
          ..quadraticBezierTo(-len * 0.6, 4 * flick, len * 0.4, 0),
        _firePaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(len * 0.2, 0)
          ..quadraticBezierTo(-len * 0.3, -2 * flick, -len * 1.0 * flick, 0)
          ..quadraticBezierTo(-len * 0.3, 2 * flick, len * 0.2, 0),
        _fireCorePaint,
      );
    }
    canvas.drawLine(const Offset(-len, 0), const Offset(len * 0.6, 0),
        _arrowShaftPaint);
    canvas.drawPath(
      Path()
        ..moveTo(len, 0)
        ..lineTo(len * 0.35, -3.2)
        ..lineTo(len * 0.35, 3.2)
        ..close(),
      _arrowHeadPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-len, 0)
        ..lineTo(-len * 1.5, -3)
        ..lineTo(-len * 0.7, 0)
        ..lineTo(-len * 1.5, 3)
        ..close(),
      _fletchPaint,
    );
  }

  void _renderCannonball(Canvas canvas) {
    canvas.drawCircle(Offset(-8 - 2 * math.sin(_t * 20), 0), 3, _smokePaint);
    canvas.drawCircle(const Offset(-5, 0), 2.2, _smokePaint);
    canvas.drawCircle(Offset.zero, 5, _ballPaint);
    canvas.drawCircle(const Offset(-1.4, -1.4), 1.6, _ballShinePaint);
  }
}
