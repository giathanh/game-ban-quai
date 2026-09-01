import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/level.dart';
import '../ban_heo_game.dart';

/// A cute pig monster rowing a boat along the river path.
class Enemy extends PositionComponent with HasGameReference<BanHeoGame> {
  Enemy({
    required this.stats,
    required this.pathPixels,
    required double cellSize,
  }) : super(size: Vector2.all(cellSize * 0.92), anchor: Anchor.center);

  final EnemyStats stats;
  final List<Vector2> pathPixels;

  Sprite? _sprite;
  late double _hp;
  int _segment = 0;
  bool _resolved = false;
  double _angle = 0;
  double _time = 0;
  double pathProgress = 0;
  double _burnRemaining = 0;
  double _burnDps = 0;
  double _flameTime = 0;

  bool get isBurning => _burnRemaining > 0;
  double get hpFraction => (_hp / stats.maxHp).clamp(0, 1).toDouble();

  final Vector2 _step = Vector2.zero();
  final Paint _wakePaint = Paint()
    ..color = const Color(0x8AFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  final Paint _hpBackPaint = Paint()..color = const Color(0xCC41251C);
  final Paint _hpFrontPaint = Paint()..color = const Color(0xFF72D572);
  final Paint _flamePaint = Paint()..color = const Color(0xE6FF7043);
  final Paint _flameCorePaint = Paint()..color = const Color(0xF2FFD54F);

  @override
  void onLoad() {
    super.onLoad();
    _hp = stats.maxHp;
    position.setFrom(pathPixels.first);
    if (pathPixels.length > 1) {
      final d = pathPixels[1] - pathPixels.first;
      _angle = math.atan2(d.y, d.x);
    }
    _loadSprite();
  }

  Future<void> _loadSprite() async {
    try {
      if (WidgetsBinding.instance.rootElement == null) return;
    } catch (_) {
      return;
    }
    try {
      _sprite = Sprite(await game.images.load('game/pig_boat.png'));
    } catch (_) {
      // Logic-only Flame tests do not initialize Flutter's asset binding.
    }
  }

  @override
  void update(double dt) {
    if (_resolved) return;
    _time += dt;

    if (_burnRemaining > 0) {
      final burnTick = math.min(_burnRemaining, dt);
      _burnRemaining -= burnTick;
      _flameTime += dt;
      takeDamage(_burnDps * burnTick);
      if (_resolved) return;
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
    if (distance > 0.0001) _angle = math.atan2(_step.y, _step.x);
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

  void applyBurn(double dps, double duration) {
    if (_resolved) return;
    _burnDps = math.max(_burnDps, dps);
    _burnRemaining = math.max(_burnRemaining, duration);
  }

  void takeDamage(double amount) {
    if (_resolved) return;
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
    final bob = math.sin(_time * 5) * size.y * 0.025;

    canvas.save();
    canvas.translate(r, r + bob);
    canvas.rotate(_angle);
    canvas.drawLine(
      Offset(-r * 0.55, -r * 0.18),
      Offset(-r * 1.05, -r * 0.36),
      _wakePaint,
    );
    canvas.drawLine(
      Offset(-r * 0.55, r * 0.18),
      Offset(-r * 1.05, r * 0.36),
      _wakePaint,
    );
    canvas.translate(-r, -r);
    final sprite = _sprite;
    if (sprite != null) {
      sprite.render(canvas, size: size);
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(r, r),
          width: size.x * 0.8,
          height: size.y * 0.5,
        ),
        Paint()..color = const Color(0xFFF5A0BA),
      );
    }
    canvas.restore();

    if (isBurning) _renderBurn(canvas, r);
    _renderHpBar(canvas);
  }

  void _renderBurn(Canvas canvas, double r) {
    for (var i = 0; i < 3; i++) {
      final flick = math.sin(_flameTime * 9 + i * 2.1);
      final fx = r + (i - 1) * r * 0.38;
      final fy = r * 0.75 + flick * r * 0.06;
      final h = r * (0.72 + 0.22 * flick.abs());
      canvas.drawPath(
        Path()
          ..moveTo(fx, fy)
          ..quadraticBezierTo(fx - r * 0.22, fy - h * 0.5, fx, fy - h)
          ..quadraticBezierTo(fx + r * 0.22, fy - h * 0.5, fx, fy),
        _flamePaint,
      );
      canvas.drawCircle(Offset(fx, fy - h * 0.28), r * 0.10, _flameCorePaint);
    }
  }

  void _renderHpBar(Canvas canvas) {
    final barWidth = size.x * 0.78;
    const barHeight = 4.0;
    final left = (size.x - barWidth) / 2;
    const top = -7.0;
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, barWidth, barHeight),
      const Radius.circular(3),
    );
    canvas.drawRRect(background, _hpBackPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth * hpFraction, barHeight),
        const Radius.circular(3),
      ),
      _hpFrontPaint,
    );
  }
}
