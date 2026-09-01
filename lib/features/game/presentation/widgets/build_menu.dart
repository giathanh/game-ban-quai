import 'package:flutter/material.dart';

import '../../domain/models/level.dart';
import '../../engine/ban_heo_game.dart';
import '../../engine/components/build_spot.dart';
import '../../engine/systems/economy.dart';

class BuildMenu extends StatelessWidget {
  const BuildMenu({required this.game, super.key});

  final BanHeoGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<BuildSpot?>(
      valueListenable: game.selectedSpot,
      builder: (context, spot, _) {
        if (spot == null) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: game.economy,
            builder: (context, _) {
              return Card(
                margin: const EdgeInsets.all(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: spot.isOccupied
                        ? _OccupiedView(game: game, spot: spot)
                        : _BuildView(game: game, spot: spot),
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

class _BuildView extends StatelessWidget {
  const _BuildView({required this.game, required this.spot});

  final BanHeoGame game;
  final BuildSpot spot;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: 'Chọn tháp để xây', onClose: game.closeSpotMenu),
        const SizedBox(height: 4),
        for (final tower in game.level.towers) ...[
          _TowerOption(
            tower: tower,
            canAfford: game.economy.canAfford(tower.cost),
            onBuild: () => game.buildTower(spot, tower),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _TowerOption extends StatelessWidget {
  const _TowerOption({
    required this.tower,
    required this.canAfford,
    required this.onBuild,
  });

  final TowerStats tower;
  final bool canAfford;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: canAfford ? onBuild : null,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: canAfford ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            children: [
              _TowerBadge(kind: tower.kind),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tower.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      tower.description,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.savings, size: 15, color: Color(0xFFB8860B)),
                      const SizedBox(width: 3),
                      Text(
                        '${tower.cost}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (!canAfford)
                    const Text(
                      'thiếu vàng',
                      style: TextStyle(fontSize: 11, color: Colors.redAccent),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OccupiedView extends StatelessWidget {
  const _OccupiedView({required this.game, required this.spot});

  final BanHeoGame game;
  final BuildSpot spot;

  @override
  Widget build(BuildContext context) {
    final stats = spot.tower!.stats;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(title: stats.name, onClose: game.closeSpotMenu),
        const SizedBox(height: 4),
        Row(
          children: [
            _TowerBadge(kind: stats.kind),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                stats.description,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () => game.sellTower(spot),
          icon: const Icon(Icons.sell),
          label: Text('Bán (+${Economy.refundValue(stats.cost)} vàng)'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// A small square swatch that echoes each tower's in-game silhouette so the
/// menu reads at a glance.
class _TowerBadge extends StatelessWidget {
  const _TowerBadge({required this.kind});

  final TowerKind kind;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (kind) {
      TowerKind.arrow => (Icons.arrow_right_alt, const Color(0xFF6D4C29)),
      TowerKind.cannon => (Icons.adjust, const Color(0xFF37474F)),
      TowerKind.flamingArrow => (
        Icons.local_fire_department,
        const Color(0xFFFF7043),
      ),
    };
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
