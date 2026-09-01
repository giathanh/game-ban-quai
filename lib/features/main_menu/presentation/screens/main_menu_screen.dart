import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../level_select/presentation/screens/level_select_screen.dart';
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
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bg.dispose();
    super.dispose();
  }

  void _play() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LevelSelectScreen()),
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

  void _quit() => SystemNavigator.pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bg,
            builder: (context, child) =>
                Transform.scale(scale: 1.04 + _bg.value * 0.015, child: child),
            child: Image.asset(
              'assets/images/menu/menu_background.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.08),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x120B6A70), Color(0x361A4D32)],
                stops: [0.42, 1],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F1D8).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: const Color(0xFFFFF8DD),
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x55143F2A),
                          blurRadius: 28,
                          offset: Offset(0, 14),
                        ),
                        BoxShadow(
                          color: Color(0x667A5B2E),
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B9B78),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'THỦ THÁP • CHẶN HEO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'BẮN HEO',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                color: const Color(0xFF164F3B),
                                height: 0.95,
                                shadows: const [
                                  Shadow(
                                    color: Colors.white,
                                    offset: Offset(0, 3),
                                  ),
                                  Shadow(
                                    color: Color(0x40523420),
                                    blurRadius: 4,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dựng tháp xịn, bảo vệ dòng sông!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF5B6F57),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        MenuButton(
                          label: 'BẮT ĐẦU',
                          icon: Icons.play_arrow_rounded,
                          onPressed: _play,
                          primary: true,
                        ),
                        const SizedBox(height: 13),
                        MenuButton(
                          label: 'HƯỚNG DẪN',
                          icon: Icons.menu_book_rounded,
                          onPressed: _showHelp,
                        ),
                        if (!kIsWeb) ...[
                          const SizedBox(height: 13),
                          MenuButton(
                            label: 'THOÁT',
                            icon: Icons.logout_rounded,
                            onPressed: _quit,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
