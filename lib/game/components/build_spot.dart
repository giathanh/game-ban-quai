import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../ban_heo_game.dart';
import 'tower.dart';

/// A tappable buildable tile. Tapping opens the build/sell menu via the game.
class BuildSpot extends PositionComponent
    with TapCallbacks, HasGameReference<BanHeoGame> {
  BuildSpot({required super.position, required double cellSize})
      : super(
          size: Vector2.all(cellSize * 0.82),
          anchor: Anchor.center,
          priority: -5,
        );

  Tower? tower;

  bool get isOccupied => tower != null;

  final Paint _fillPaint = Paint()..color = const Color(0x33FFFFFF);
  final Paint _borderPaint = Paint()
    ..color = const Color(0x99FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void onTapDown(TapDownEvent event) {
    if (game.isInteractionLocked) {
      return;
    }
    game.selectedSpot.value = this;
  }

  @override
  void render(Canvas canvas) {
    if (isOccupied) {
      return;
    }
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, _fillPaint);
    canvas.drawRRect(rect, _borderPaint);
  }
}
