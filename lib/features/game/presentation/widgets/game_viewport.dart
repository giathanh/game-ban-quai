import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps the HUD stationary while the playfield zooms and tilts in perspective.
class GameViewport extends StatefulWidget {
  const GameViewport({required this.child, super.key});

  final Widget child;

  @override
  State<GameViewport> createState() => _GameViewportState();
}

class _GameViewportState extends State<GameViewport>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..addListener(_animate);
  Matrix4 _from = Matrix4.identity();
  Matrix4 _to = Matrix4.identity();
  Size _size = Size.zero;

  void _animate() {
    _transform.value = Matrix4Tween(
      begin: _from,
      end: _to,
    ).transform(Curves.easeOutCubic.transform(_animation.value));
  }

  void _zoom(double target) {
    final scale = target.clamp(1.0, 2.5);
    final center = _size.center(Offset.zero);
    final scene = _transform.toScene(center);
    final x = (center.dx - scene.dx * scale).clamp(
      _size.width * (1 - scale),
      0.0,
    );
    final y = (center.dy - scene.dy * scale).clamp(
      _size.height * (1 - scale),
      0.0,
    );
    _from = _transform.value.clone();
    _to = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, x)
      ..setEntry(1, 3, y);
    _animation.forward(from: 0);
  }

  @override
  void dispose() {
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (_size != size) {
          _animation.stop();
          _size = size;
          _transform.value = Matrix4.identity();
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              transformationController: _transform,
              minScale: 1,
              onInteractionStart: (_) => _animation.stop(),
              child: AnimatedBuilder(
                animation: _transform,
                child: widget.child,
                builder: (context, child) {
                  final depth =
                      ((_transform.value.getMaxScaleOnAxis() - 1) / 1.5).clamp(
                        0.0,
                        1.0,
                      );
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.35 / math.max(size.height, 1))
                      ..rotateX(-0.12 * depth),
                    child: child,
                  );
                },
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: _transform,
                  builder: (context, _) {
                    final scale = _transform.value.getMaxScaleOnAxis();
                    return Material(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Thu nhỏ',
                            color: Colors.white,
                            onPressed: scale > 1.001
                                ? () => _zoom(scale - 0.3)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          TextButton(
                            onPressed: () => _zoom(1),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text('${scale.toStringAsFixed(1)}×'),
                          ),
                          IconButton(
                            tooltip: 'Phóng to',
                            color: Colors.white,
                            onPressed: scale < 2.499
                                ? () => _zoom(scale + 0.3)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
