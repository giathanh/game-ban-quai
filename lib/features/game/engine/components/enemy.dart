import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/level.dart';
import '../ban_heo_game.dart';

/// A pig (Heo) rowing a boat down the river. Reaching the end costs the player
/// lives; dropping to 0 hp pays out gold. The boat turns to face the direction
/// of travel; the hp bar stays upright above it.
class Enemy extends PositionComponent with HasGameReference<BanHeoGame> {
  Enemy({
    required this.stats,
    required this.pathPixels,
    required double cellSize,
  }) : super(size: Vector2.all(cellSize * 0.62), anchor: Anchor.center);

  final EnemyStats stats;
  final List<Vector2> pathPixels;

  late double _hp;
  int _segment = 0;
  bool _resolved = false;

  /// Heading in radians; 0 points along +x. Updated as the boat moves.
  double _angle = 0;

  /// Distance travelled along the path in pixels — used by towers to target the
  /// enemy that is furthest along.
  double pathProgress = 0;

  /// Remaining burn time in seconds and its damage-per-second. Applied by
  /// flaming-arrow towers; re-hitting refreshes rather than stacks.
  double _burnRemaining = 0;
  double _burnDps = 0;
  double _flameTime = 0;

  bool get isBurning => _burnRemaining > 0;

  final Paint _hullPaint = Paint()..color = const Color(0xFF7B4A24);
  final Paint _hullInnerPaint = Paint()..color = const Color(0xFFB9895B);
  final Paint _hullOutlinePaint = Paint()
    ..color = const Color(0xFF46290F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _plankPaint = Paint()
    ..color = const Color(0x5546290F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _paddlePaint = Paint()
    ..color = const Color(0xFF5D3A1A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  final Paint _wakePaint = Paint()
    ..color = const Color(0x40FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final Paint _bodyPaint = Paint()..color = const Color(0xFFF48FB1);
  final Paint _snoutPaint = Paint()..color = const Color(0xFFE47DA0);
  final Paint _outlinePaint = Paint()
    ..color = const Color(0xFF880E4F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _hpBackPaint = Paint()..color = const Color(0xFF4E342E);
  final Paint _hpFrontPaint = Paint()..color = const Color(0xFF66BB6A);
  final Paint _flamePaint = Paint()..color = const Color(0xE6FF7043);
  final Paint _flameCorePaint = Paint()..color = const Color(0xF2FFD54F);

  final Vector2 _step = Vector2.zero();

  double get hpFraction => (_hp / stats.maxHp).clamp(0, 1).toDouble();

  @override
  Future<void> onLoad() async {
    _hp = stats.maxHp;
    position.setFrom(pathPixels.first);
    if (pathPixels.length > 1) {
      final d = pathPixels[1] - pathPixels.first;
      _angle = math.atan2(d.y, d.x);
    }
  }

  @override
  void update(double dt) {
    if (_resolved) {
      return;
    }

    if (_burnRemaining > 0) {
      final burnTick = math.min(_burnRemaining, dt);
      _burnRemaining -= burnTick;
      _flameTime += dt;
      takeDamage(_burnDps * burnTick);
      if (_resolved) {
        return;
      }
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
    if (distance > 0.0001) {
      _angle = math.atan2(_step.y, _step.x);
    }
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

  /// Sets the pig on fire: [dps] damage per second for [duration] seconds.
  /// Overlapping burns take the stronger dps and the longer remaining time.
  void applyBurn(double dps, double duration) {
    if (_resolved) {
      return;
    }
    _burnDps = math.max(_burnDps, dps);
    _burnRemaining = math.max(_burnRemaining, duration);
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

    canvas.save();
    canvas.translate(r, r);
    canvas.rotate(_angle);
    _renderBoat(canvas, r);
    canvas.restore();

    if (isBurning) {
      _renderBurn(canvas, r);
    }
    _renderHpBar(canvas);
  }

  /// Flame tongues licking up off a burning pig. Drawn upright (not rotated with
  /// the boat) and flickering on [_flameTime].
  void _renderBurn(Canvas canvas, double r) {
    for (var i = 0; i < 3; i++) {
      final flick = math.sin(_flameTime * 9 + i * 2.1);
      final fx = r + (i - 1) * r * 0.5;
      final fy = r - r * 0.1 + flick * r * 0.08;
      final h = r * (0.9 + 0.3 * flick.abs());
      canvas.drawPath(
        Path()
          ..moveTo(fx, fy)
          ..quadraticBezierTo(fx - r * 0.3, fy - h * 0.5, fx, fy - h)
          ..quadraticBezierTo(fx + r * 0.3, fy - h * 0.5, fx, fy),
        _flamePaint,
      );
      final coreH = h * 0.55;
      canvas.drawPath(
        Path()
          ..moveTo(fx, fy)
          ..quadraticBezierTo(fx - r * 0.14, fy - coreH * 0.5, fx, fy - coreH)
          ..quadraticBezierTo(fx + r * 0.14, fy - coreH * 0.5, fx, fy),
        _flameCorePaint,
      );
    }
  }

  void _renderBoat(Canvas canvas, double r) {
    final hx = r * 1.75; // half length (bow at +x)
    final hy = r * 0.98; // half beam

    // Wake trailing behind the stern.
    canvas.drawLine(Offset(-hx, -hy * 0.2), Offset(-hx * 1.9, -hy * 1.3), _wakePaint);
    canvas.drawLine(Offset(-hx, hy * 0.2), Offset(-hx * 1.9, hy * 1.3), _wakePaint);

    // Hull: pointed bow, rounded stern.
    final hull = Path()
      ..moveTo(hx, 0)
      ..quadraticBezierTo(hx * 0.35, -hy, -hx * 0.72, -hy)
      ..quadraticBezierTo(-hx * 1.06, -hy * 0.5, -hx * 1.06, 0)
      ..quadraticBezierTo(-hx * 1.06, hy * 0.5, -hx * 0.72, hy)
      ..quadraticBezierTo(hx * 0.35, hy, hx, 0)
      ..close();
    canvas.drawPath(hull, _hullPaint);
    canvas.drawPath(hull, _hullOutlinePaint);

    // Inner well.
    final well = Path()
      ..moveTo(hx * 0.72, 0)
      ..quadraticBezierTo(hx * 0.2, -hy * 0.66, -hx * 0.62, -hy * 0.66)
      ..quadraticBezierTo(-hx * 0.86, -hy * 0.33, -hx * 0.86, 0)
      ..quadraticBezierTo(-hx * 0.86, hy * 0.33, -hx * 0.62, hy * 0.66)
      ..quadraticBezierTo(hx * 0.2, hy * 0.66, hx * 0.72, 0)
      ..close();
    canvas.drawPath(well, _hullInnerPaint);
    canvas.drawLine(Offset(-hx * 0.2, -hy * 0.6), Offset(-hx * 0.2, hy * 0.6), _plankPaint);

    // Paddle over the port side.
    canvas.drawLine(Offset(hx * 0.05, hy * 0.2), Offset(-hx * 0.35, hy * 1.5), _paddlePaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-hx * 0.35, hy * 1.5), width: r * 0.5, height: r * 0.85),
      _paddlePaint..style = PaintingStyle.fill,
    );
    _paddlePaint.style = PaintingStyle.stroke;

    // Pig sitting amidships.
    final pigR = r * 0.72;
    final pig = Offset(-hx * 0.05, 0);
    canvas.drawCircle(pig, pigR, _bodyPaint);
    canvas.drawCircle(pig, pigR, _outlinePaint);
    // Ears.
    for (final s in const [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(pig.dx - pigR * 0.15, pig.dy + s * pigR * 0.55)
        ..lineTo(pig.dx - pigR * 0.75, pig.dy + s * pigR * 0.5)
        ..lineTo(pig.dx - pigR * 0.35, pig.dy + s * pigR * 1.0)
        ..close();
      canvas.drawPath(ear, _bodyPaint);
      canvas.drawPath(ear, _outlinePaint);
    }
    // Snout facing the bow.
    canvas.drawCircle(Offset(pig.dx + pigR * 0.55, pig.dy), pigR * 0.42, _snoutPaint);
    canvas.drawCircle(Offset(pig.dx + pigR * 0.55, pig.dy), pigR * 0.42, _outlinePaint);
  }

  void _renderHpBar(Canvas canvas) {
    final barWidth = size.x;
    const barHeight = 4.0;
    const barTop = -barHeight - 3;
    canvas.drawRect(Rect.fromLTWH(0, barTop, barWidth, barHeight), _hpBackPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, barTop, barWidth * hpFraction, barHeight),
      _hpFrontPaint,
    );
  }
}
