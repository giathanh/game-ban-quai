import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/levels/level_01.dart';
import 'game_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat();

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  void _play() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(level: level01),
      ),
    );
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hướng dẫn'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Chạm vào ô trống để xây tháp Pigshooter (50 vàng).'),
            SizedBox(height: 8),
            Text('2. Tháp tự bắn heo trong tầm; hạ heo để nhận vàng.'),
            SizedBox(height: 8),
            Text('3. Heo thoát qua bên phải sẽ trừ mạng. Hết mạng là thua.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _quit() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bg,
              builder: (context, _) => CustomPaint(
                painter: _DriftPainter(_bg.value, scheme.primary),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BẮN HEO',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thủ tháp - bắn quái',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 40),
                  _MenuButton(label: 'Chơi', onPressed: _play, primary: true),
                  const SizedBox(height: 14),
                  _MenuButton(label: 'Hướng dẫn', onPressed: _showHelp),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 14),
                    _MenuButton(label: 'Thoát', onPressed: _quit),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size(220, 52),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
    return primary
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.tonal(
            onPressed: onPressed, style: style, child: Text(label));
  }
}

class _DriftPainter extends CustomPainter {
  _DriftPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF12321A),
    );
    final paint = Paint()..color = color.withValues(alpha: 0.12);
    for (var i = 0; i < 14; i++) {
      final phase = (t + i / 14) % 1.0;
      final x = (size.width + 160) * phase - 80;
      final y = size.height * ((i * 0.137) % 1.0);
      final r = 24.0 + (i % 5) * 12.0;
      canvas.drawCircle(Offset(x, y + 20 * math.sin(phase * math.pi * 2)), r,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DriftPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}
