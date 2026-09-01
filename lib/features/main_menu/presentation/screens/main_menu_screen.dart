import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../game/data/levels/level_01.dart';
import '../../../game/presentation/screens/game_screen.dart';
import '../widgets/menu_background.dart';
import '../widgets/menu_button.dart';

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
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => GameScreen(level: level01)));
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
            Text(
              '1. Chạm vào ô trống để xây tháp: Bắn Tên (50), '
              'Đại Bác (75), Tên Lửa (100 vàng).',
            ),
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
                painter: MenuBackgroundPainter(_bg.value, scheme.primary),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3A1F).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BẮN HEO',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: Colors.white,
                      shadows: const [
                        Shadow(
                          color: Color(0xFF0C2410),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thủ tháp - bắn quái',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 40),
                  MenuButton(label: 'Chơi', onPressed: _play, primary: true),
                  const SizedBox(height: 14),
                  MenuButton(label: 'Hướng dẫn', onPressed: _showHelp),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 14),
                    MenuButton(label: 'Thoát', onPressed: _quit),
                  ],
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
