import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../upgrades/data/upgrade_store.dart';
import '../../../upgrades/domain/upgrade_levels.dart';
import '../../data/progress_store.dart';
import '../../domain/models/level.dart';
import '../../engine/ban_heo_game.dart';
import '../widgets/build_menu.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_viewport.dart';
import '../widgets/pause_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    required this.level,
    this.levelIndex,
    this.levelId,
    this.upgrades = UpgradeLevels.none,
    this.onReplay,
    this.onNext,
    super.key,
  }) : assert(
         (levelId == null) == (levelIndex == null),
         'levelId and levelIndex must be supplied together (campaign context) '
         'or both omitted (standalone / test)',
       );

  final LevelData level;

  /// Position of this level in the campaign catalog, or null when launched
  /// outside it (e.g. a test). Drives progress saving.
  final int? levelIndex;

  /// Stable catalog id (`level_07`), or null outside the campaign. Drives the
  /// upgrade-point award on a first clear.
  final String? levelId;

  /// Global tower buffs to apply this round.
  final UpgradeLevels upgrades;

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
    upgrades: widget.upgrades,
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

  Future<void> _onGameOver(GameResult result) async {
    if (_resultShown) {
      return;
    }
    _resultShown = true;

    final won = result == GameResult.won;

    if (won && widget.levelIndex != null) {
      // Fire-and-forget: the picker re-reads progress when we pop back to it.
      unawaited(ProgressStore.markCompleted(widget.levelIndex!));
    }

    var award = AwardResult.none;
    if (won && widget.levelId != null) {
      try {
        award = await UpgradeStore.awardForClear(
          levelId: widget.levelId!,
          levelIndex: widget.levelIndex ?? 0,
          flawless: _game.lives.value == widget.level.startingLives,
        );
      } catch (_) {
        // A prefs failure (blocked storage / private browsing on web) must
        // never gate the result dialog — the player just gets no points.
        award = AwardResult.none;
      }
    }

    if (!mounted) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final showNext = won && widget.onNext != null;
      final buffer = StringBuffer(
        won
            ? 'Bạn đã chặn hết ${widget.level.waves.length} đợt heo. Giỏi lắm!'
            : 'Đàn heo đã tràn qua. Thử lại nhé!',
      );
      if (award.points > 0) {
        buffer.write('\n\n+${award.points} điểm nâng cấp!');
        if (award.flawlessGranted) {
          buffer.write('\nKhông rò con nào — thưởng thêm 1 điểm!');
        }
      }
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(won ? 'Thắng!' : 'Thua'),
          content: Text(buffer.toString()),
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GameViewport(
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: widget.level.width,
                  height: widget.level.height,
                  child: GameWidget(game: _game),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: GameHud(game: _game, onPause: _togglePause),
            ),
          ),
          SafeArea(child: BuildMenu(game: _game)),
          if (_paused) PauseOverlay(onResume: _togglePause),
        ],
      ),
    );
  }
}
