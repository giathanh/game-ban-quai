import 'package:flutter/material.dart';

import '../../../upgrades/domain/upgrade_catalog.dart';
import '../../../upgrades/domain/upgrade_levels.dart';
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
          child: Row(
            children: [
              // The stat cluster scrolls horizontally so it can never push the
              // wave / pause controls off-screen on a small landscape phone
              // (e.g. 568x320), with or without the upgrade chip.
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Stat(
                        Icons.favorite,
                        '${game.lives.value}',
                        Colors.redAccent,
                      ),
                      const SizedBox(width: 16),
                      _Stat(
                        Icons.savings,
                        '${game.economy.gold}',
                        Colors.amberAccent,
                      ),
                      const SizedBox(width: 16),
                      _Stat(
                        Icons.waves,
                        game.wave.value == 0
                            ? 'Chuẩn bị'
                            : 'Wave ${game.wave.value}/'
                                  '${game.level.waves.length}',
                        Colors.lightBlueAccent,
                      ),
                      if (!game.upgrades.isEmpty) ...[
                        const SizedBox(width: 12),
                        _UpgradeChip(levels: game.upgrades),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
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

/// Static readout of the active global upgrades. Not wired into the HUD's
/// merged [Listenable] — the values cannot change during a round.
class _UpgradeChip extends StatelessWidget {
  const _UpgradeChip({required this.levels});

  final UpgradeLevels levels;

  @override
  Widget build(BuildContext context) {
    final parts = <(IconData, String)>[
      if (levels.range > 0)
        (
          Icons.my_location,
          '+${trackFor(UpgradeAxis.range).percentAt(levels.range)}%',
        ),
      if (levels.damage > 0)
        (
          Icons.bolt,
          '+${trackFor(UpgradeAxis.damage).percentAt(levels.damage)}%',
        ),
      if (levels.reload > 0)
        (
          Icons.timer_outlined,
          '${trackFor(UpgradeAxis.reload).percentAt(levels.reload)}%',
        ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x3355E0A8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x8855E0A8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, part) in parts.indexed) ...[
            if (index > 0) const SizedBox(width: 8),
            Icon(part.$1, color: const Color(0xFFB8F5DC), size: 15),
            const SizedBox(width: 2),
            Text(
              part.$2,
              softWrap: false,
              style: const TextStyle(
                color: Color(0xFFDDFBEE),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
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
            shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
          ),
        ),
      ],
    );
  }
}
