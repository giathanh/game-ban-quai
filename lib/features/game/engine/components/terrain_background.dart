import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../domain/models/level.dart';

/// Full-field scenery for Level 1: a grassy valley of rolling hills ringed by a
/// mountain range, with trees scattered across the slopes. Purely decorative and
/// drawn beneath the river, build pads and units. Every random choice is
/// resolved once in [onLoad] so the scene never flickers between frames.
class TerrainBackground extends PositionComponent {
  TerrainBackground({required this.level, required List<Vector2> pathPixels})
    : _path = pathPixels,
      super(priority: -20);

  final LevelData level;
  final List<Vector2> _path;

  final List<_Hill> _hills = <_Hill>[];
  final List<_Mountain> _mountains = <_Mountain>[];
  final List<_Tree> _trees = <_Tree>[];

  late final Paint _grassPaint;
  final Paint _hillPaint = Paint();
  final Paint _hillShadowPaint = Paint()..color = const Color(0x140A2A10);
  final Paint _rockPaint = Paint()..color = const Color(0xFF8A8274);
  final Paint _rockShadePaint = Paint()..color = const Color(0xFF5F594E);
  final Paint _rockFootPaint = Paint()..color = const Color(0x223B3226);
  final Paint _snowPaint = Paint()..color = const Color(0xFFF3F4F2);
  final Paint _treeShadowPaint = Paint()..color = const Color(0x1F000000);
  final Paint _treeBasePaint = Paint();
  final Paint _treeHiPaint = Paint();

  @override
  Future<void> onLoad() async {
    size = Vector2(level.width, level.height);
    final w = level.width;
    final h = level.height;

    _grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF6FB25C), Color(0xFF4C9040)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rng = math.Random(20260901);

    // --- Rolling hills: big soft blobs in alternating grass shades. ----------
    const hillShades = <Color>[
      Color(0xFF77B863),
      Color(0xFF5FA34D),
      Color(0xFF539A43),
      Color(0xFF69B156),
    ];
    final hillCount = 7 + rng.nextInt(3);
    for (var i = 0; i < hillCount; i++) {
      final c = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
      final rx = h * (0.20 + rng.nextDouble() * 0.28);
      final ry = rx * (0.55 + rng.nextDouble() * 0.35);
      _hills.add(
        _Hill(
          blob: _blob(c, rx, ry, rng),
          color: hillShades[rng.nextInt(hillShades.length)],
        ),
      );
    }

    // --- Mountain ranges: a ridge along the top, a spur in a bottom corner. --
    _mountains.addAll(
      _ridge(
        baseY: h * 0.05,
        from: -w * 0.05,
        to: w * 1.05,
        peaks: 7,
        minH: h * 0.11,
        maxH: h * 0.21,
        rng: rng,
      ),
    );
    _mountains.addAll(
      _ridge(
        baseY: h * 0.95,
        from: w * 0.58,
        to: w * 1.12,
        peaks: 3,
        minH: h * 0.12,
        maxH: h * 0.22,
        rng: rng,
      ),
    );

    // --- Trees: kept clear of the river and the build pads. -----------------
    final pads = level.buildSpotCells
        .map(level.cellToPixel)
        .map((v) => Offset(v.x, v.y))
        .toList(growable: false);
    var attempts = 0;
    while (_trees.length < 48 && attempts < 800) {
      attempts++;
      final p = Offset(rng.nextDouble() * w, rng.nextDouble() * h);
      if (p.dy < h * 0.13) continue; // behind the top ridge
      if (_distToPath(p) < level.cellSize * 0.95) continue;
      if (pads.any((pad) => (pad - p).distance < level.cellSize * 0.9)) {
        continue;
      }
      _trees.add(
        _Tree(
          center: p,
          radius: level.cellSize * (0.32 + rng.nextDouble() * 0.30),
          tint: rng.nextDouble(),
        ),
      );
    }
    // Paint far trees first so nearer ones overlap them.
    _trees.sort((a, b) => a.center.dy.compareTo(b.center.dy));
  }

  // --- Geometry helpers ------------------------------------------------------

  /// A smooth closed blob around [c], roughly [rx]×[ry], with jittered lobes.
  Path _blob(Offset c, double rx, double ry, math.Random rng) {
    const n = 14;
    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        () {
          final a = i / n * math.pi * 2;
          final j = 0.78 + rng.nextDouble() * 0.42;
          return Offset(
            c.dx + math.cos(a) * rx * j,
            c.dy + math.sin(a) * ry * j,
          );
        }(),
    ];
    final path = Path();
    final start = (pts[n - 1] + pts[0]) / 2;
    path.moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final cur = pts[i];
      final mid = (cur + pts[(i + 1) % n]) / 2;
      path.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
    }
    return path..close();
  }

  List<_Mountain> _ridge({
    required double baseY,
    required double from,
    required double to,
    required int peaks,
    required double minH,
    required double maxH,
    required math.Random rng,
  }) {
    final step = (to - from) / peaks;
    return <_Mountain>[
      for (var i = 0; i < peaks; i++)
        () {
          final cx = from + step * (i + 0.5) + (rng.nextDouble() - 0.5) * step;
          final ph = minH + rng.nextDouble() * (maxH - minH);
          return _Mountain(
            apex: Offset(cx, baseY - ph),
            baseY: baseY,
            half: step * (0.72 + rng.nextDouble() * 0.5),
            snowFrac: 0.24 + rng.nextDouble() * 0.14,
          );
        }(),
    ];
  }

  double _distToPath(Offset p) {
    var best = double.infinity;
    for (var i = 0; i < _path.length - 1; i++) {
      best = math.min(best, _distToSeg(p, _path[i], _path[i + 1]));
    }
    return best;
  }

  double _distToSeg(Offset p, Vector2 a, Vector2 b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    var t = len2 == 0 ? 0.0 : ((p.dx - a.x) * dx + (p.dy - a.y) * dy) / len2;
    t = t.clamp(0.0, 1.0);
    return (Offset(a.x + t * dx, a.y + t * dy) - p).distance;
  }

  // --- Render --------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _grassPaint);

    for (final hill in _hills) {
      canvas.save();
      canvas.translate(0, 8);
      canvas.drawPath(hill.blob, _hillShadowPaint);
      canvas.restore();
      _hillPaint.color = hill.color;
      canvas.drawPath(hill.blob, _hillPaint);
    }

    for (final m in _mountains) {
      final rise = m.baseY - m.apex.dy;
      final body = Path()
        ..moveTo(m.apex.dx - m.half, m.baseY)
        ..lineTo(m.apex.dx, m.apex.dy)
        ..lineTo(m.apex.dx + m.half, m.baseY)
        ..close();
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(m.apex.dx, m.baseY),
          width: m.half * 2.1,
          height: rise * 0.22,
        ),
        _rockFootPaint,
      );
      canvas.drawPath(body, _rockPaint);
      canvas.drawPath(
        Path()
          ..moveTo(m.apex.dx, m.apex.dy)
          ..lineTo(m.apex.dx + m.half, m.baseY)
          ..lineTo(m.apex.dx, m.baseY)
          ..close(),
        _rockShadePaint,
      );
      final sy = m.apex.dy + rise * m.snowFrac;
      final sHalf = m.half * m.snowFrac;
      canvas.drawPath(
        Path()
          ..moveTo(m.apex.dx - sHalf, sy)
          ..lineTo(m.apex.dx - sHalf * 0.25, sy - rise * 0.06)
          ..lineTo(m.apex.dx, m.apex.dy)
          ..lineTo(m.apex.dx + sHalf * 0.35, sy - rise * 0.05)
          ..lineTo(m.apex.dx + sHalf, sy)
          ..lineTo(m.apex.dx + sHalf * 0.4, sy + rise * 0.03)
          ..lineTo(m.apex.dx - sHalf * 0.3, sy + rise * 0.04)
          ..close(),
        _snowPaint,
      );
    }

    for (final t in _trees) {
      canvas.drawOval(
        Rect.fromCenter(
          center: t.center.translate(t.radius * 0.35, t.radius * 0.45),
          width: t.radius * 2.2,
          height: t.radius * 1.1,
        ),
        _treeShadowPaint,
      );
      _treeBasePaint.color = Color.lerp(
        const Color(0xFF2E6B2C),
        const Color(0xFF3C8637),
        t.tint,
      )!;
      _treeHiPaint.color = Color.lerp(
        const Color(0xFF4C9C41),
        const Color(0xFF6BB85B),
        t.tint,
      )!;
      canvas.drawCircle(t.center, t.radius, _treeBasePaint);
      canvas.drawCircle(
        t.center.translate(-t.radius * 0.28, -t.radius * 0.30),
        t.radius * 0.62,
        _treeHiPaint,
      );
    }
  }
}

class _Hill {
  _Hill({required this.blob, required this.color});

  final Path blob;
  final Color color;
}

class _Mountain {
  _Mountain({
    required this.apex,
    required this.baseY,
    required this.half,
    required this.snowFrac,
  });

  final Offset apex;
  final double baseY;
  final double half;
  final double snowFrac;
}

class _Tree {
  _Tree({required this.center, required this.radius, required this.tint});

  final Offset center;
  final double radius;

  /// 0..1 blend between the darker and lighter canopy tints.
  final double tint;
}
