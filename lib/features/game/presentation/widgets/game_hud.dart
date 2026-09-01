import 'package:flutter/material.dart';

import '../../engine/ban_heo_game.dart';

class GameHud extends StatelessWidget {
  const GameHud({required this.game, required this.onPause, super.key});

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
              _Stat(Icons.favorite, '${game.lives.value}', Colors.redAccent),
              const SizedBox(width: 16),
              _Stat(Icons.savings, '${game.economy.gold}', Colors.amberAccent),
              const SizedBox(width: 16),
              _Stat(
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
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
