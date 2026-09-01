import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../data/levels/level_catalog.dart';
import '../../data/progress_store.dart';
import '../../domain/models/level.dart';
import '../../engine/ban_heo_game.dart';
import '../widgets/build_menu.dart';
import '../widgets/game_hud.dart';
import '../widgets/pause_overlay.dart';
import 'level_loader_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({required this.level, this.levelIndex, super.key});

  final LevelData level;

  /// Position of this level in [kLevelCatalog], or null when the level was
  /// launched outside the campaign (e.g. a test). Drives progress saving and
  /// the "next level" button.
  final int? levelIndex;

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

  bool get _hasNextLevel =>
      widget.levelIndex != null && hasLevelAt(widget.levelIndex! + 1);

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

  void _replaceWithLevel(int index) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LevelLoaderScreen(levelIndex: index),
      ),
    );
  }

  void _onGameOver(GameResult result) {
    if (_resultShown) {
      return;
    }
    _resultShown = true;

    if (result == GameResult.won && widget.levelIndex != null) {
      // Fire-and-forget: the picker re-reads progress when we pop back to it.
      ProgressStore.markCompleted(widget.levelIndex!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final won = result == GameResult.won;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(won ? 'Thắng!' : 'Thua'),
          content: Text(
            won
                ? 'Bạn đã chặn hết ${widget.level.waves.length} đợt heo. Giỏi lắm!'
                : 'Đàn heo đã tràn qua. Thử lại nhé!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (widget.levelIndex != null) {
                  _replaceWithLevel(widget.levelIndex!);
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(
                        level: widget.level,
                        levelIndex: widget.levelIndex,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Chơi lại'),
            ),
            if (won && _hasNextLevel)
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _replaceWithLevel(widget.levelIndex! + 1);
                },
                child: const Text('Màn tiếp theo'),
              )
            else
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
