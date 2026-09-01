import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../domain/models/level.dart';
import '../../engine/ban_heo_game.dart';
import '../widgets/build_menu.dart';
import '../widgets/game_hud.dart';
import '../widgets/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({required this.level, super.key});

  final LevelData level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final BanHeoGame _game = BanHeoGame(
    level: widget.level,
    onGameOver: _onGameOver,
  );

  bool _paused = false;
  bool _resultShown = false;

  @override
  void dispose() {
    _game.disposeResources();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
  }

  void _onGameOver(GameResult result) {
    if (_resultShown) {
      return;
    }
    _resultShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(result == GameResult.won ? 'Thắng!' : 'Thua'),
          content: Text(
            result == GameResult.won
                ? 'Bạn đã chặn hết 5 wave heo. Giỏi lắm!'
                : 'Đàn heo đã tràn qua. Thử lại nhé!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(level: widget.level),
                  ),
                );
              },
              child: const Text('Chơi lại'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Về menu'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12321A),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: GameWidget(game: _game)),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: GameHud(game: _game, onPause: _togglePause),
            ),
            BuildMenu(game: _game),
            if (_paused) PauseOverlay(onResume: _togglePause),
          ],
        ),
      ),
    );
  }
}
