import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../data/progress_store.dart';
import '../../domain/models/level.dart';
import '../../engine/ban_heo_game.dart';
import '../widgets/build_menu.dart';
import '../widgets/game_hud.dart';
import '../widgets/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.level,
    this.levelIndex,
    this.onReplay,
    this.onNext,
    super.key,
  });

  final LevelData level;

  /// Position of this level in the campaign catalog, or null when launched
  /// outside it (e.g. a test). Drives progress saving.
  final int? levelIndex;

  /// Restart the current level. Null hides the retry action.
  final VoidCallback? onReplay;

  /// Advance to the next level. Null when there is none (last level / no
  /// campaign context) — the win dialog then offers "back to menu" instead.
  final VoidCallback? onNext;

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

    if (result == GameResult.won && widget.levelIndex != null) {
      // Fire-and-forget: the picker re-reads progress when we pop back to it.
      ProgressStore.markCompleted(widget.levelIndex!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final won = result == GameResult.won;
      final showNext = won && widget.onNext != null;
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
            if (widget.onReplay != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  widget.onReplay!();
                },
                child: const Text('Chơi lại'),
              ),
            if (showNext)
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  widget.onNext!();
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
