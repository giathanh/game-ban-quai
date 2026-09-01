import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../data/level.dart';
import '../game/ban_heo_game.dart';
import '../game/components/build_spot.dart';
import '../game/systems/economy.dart';

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
              child: _Hud(game: _game, onPause: _togglePause),
            ),
            _BuildMenu(game: _game),
            if (_paused) _PauseOverlay(onResume: _togglePause),
          ],
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.game, required this.onPause});

  final BanHeoGame game;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        game.lives,
        game.wave,
        game.economy,
        game.nextWaveCountdown,
        game.canStartNextWave,
      ]),
      builder: (context, _) {
        final countdown = game.nextWaveCountdown.value;
        final canStart = game.canStartNextWave.value;
        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _stat(Icons.favorite, '${game.lives.value}', Colors.redAccent),
              const SizedBox(width: 16),
              _stat(Icons.savings, '${game.economy.gold}', Colors.amberAccent),
              const SizedBox(width: 16),
              _stat(
                Icons.waves,
                game.wave.value == 0
                    ? 'Chuẩn bị'
                    : 'Wave ${game.wave.value}/${game.level.waves.length}',
                Colors.lightBlueAccent,
              ),
              const Spacer(),
              FilledButton.tonal(
                onPressed: canStart ? game.callNextWaveEarly : null,
                child: Text(
                  canStart && countdown > 0
                      ? 'Bắt đầu wave (${countdown.ceil()}s)'
                      : 'Bắt đầu wave',
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: onPause,
                icon: const Icon(Icons.pause),
                tooltip: 'Tạm dừng',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _BuildMenu extends StatelessWidget {
  const _BuildMenu({required this.game});

  final BanHeoGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BuildSpot?>(
      valueListenable: game.selectedSpot,
      builder: (context, spot, _) {
        if (spot == null) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: game.economy,
            builder: (context, _) {
              final tower = game.level.pigshooter;
              final occupied = spot.isOccupied;
              final canAfford = game.economy.canAfford(tower.cost);
              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            occupied ? 'Tháp Pigshooter' : 'Xây tháp',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: game.closeSpotMenu,
                            icon: const Icon(Icons.close),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (!occupied)
                        FilledButton.icon(
                          onPressed: canAfford
                              ? () => game.buildPigshooter(spot)
                              : null,
                          icon: const Icon(Icons.gps_fixed),
                          label: Text(
                            'Pigshooter — ${tower.cost} vàng'
                            '${canAfford ? '' : ' (thiếu vàng)'}',
                          ),
                        )
                      else
                        FilledButton.tonalIcon(
                          onPressed: () => game.sellTower(spot),
                          icon: const Icon(Icons.sell),
                          label: Text(
                            'Bán (+${Economy.refundValue(tower.cost)} vàng)',
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tạm dừng',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onResume, child: const Text('Tiếp tục')),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Về menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
