import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/level.dart';
import '../ban_heo_game.dart';

/// The soft 3D toy-diorama scenery drawn beneath the river and all gameplay.
class TerrainBackground extends PositionComponent
    with HasGameReference<BanHeoGame> {
  TerrainBackground({required this.level}) : super(priority: -20);

  final LevelData level;
  Sprite? _sprite;

  late final Paint _fallbackPaint;

  @override
  void onLoad() {
    super.onLoad();
    size = Vector2(level.width, level.height);
    _fallbackPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF91D743), Color(0xFF54AA38)],
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    _loadSprite();
  }

  Future<void> _loadSprite() async {
    // Flame's logic-only tests intentionally run without Flutter's asset
    // binding, so they keep the lightweight gradient fallback.
    try {
      if (WidgetsBinding.instance.rootElement == null) return;
    } catch (_) {
      return;
    }
    try {
      _sprite = Sprite(await game.images.load(level.backgroundAsset));
    } catch (_) {
      // Keep the fallback visible if an asset cannot be decoded.
    }
  }

  @override
  void render(Canvas canvas) {
    final sprite = _sprite;
    if (sprite == null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _fallbackPaint);
      return;
    }
    sprite.render(canvas, size: size);
  }
}
