import 'package:ban_heo/features/game/domain/models/level.dart';
import 'package:ban_heo/features/game/engine/ban_heo_game.dart';
import 'package:ban_heo/features/game/presentation/widgets/game_hud.dart';
import 'package:ban_heo/features/upgrades/domain/upgrade_levels.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LevelData _level() => LevelData(
  name: 'T',
  cellSize: 32,
  gridCols: 20,
  gridRows: 10,
  startingLives: 20,
  startingGold: 120,
  timeBetweenWaves: 1,
  pathCells: <Vector2>[Vector2(-1, 5), Vector2(20, 5)],
  buildSpotCells: <Vector2>[Vector2(3, 3)],
  waves: const <WaveData>[
    WaveData([SpawnGroup(count: 1, interval: 1)]),
  ],
  enemy: const EnemyStats(maxHp: 10, speed: 2, goldOnKill: 1, livesOnLeak: 1),
  towers: const <TowerStats>[
    TowerStats(
      kind: TowerKind.arrow,
      name: 'a',
      description: 'd',
      cost: 10,
      rangeCells: 2,
      fireRate: 1,
      damage: 5,
      projectileSpeed: 100,
    ),
  ],
);

void main() {
  for (final size in const <Size>[Size(800, 360), Size(568, 320)]) {
    testWidgets('GameHud does not overflow at $size with maxed upgrades', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final game = BanHeoGame(
        level: _level(),
        onGameOver: (_) {},
        upgrades: const UpgradeLevels(range: 5, damage: 5, reload: 5),
      );
      addTearDown(game.disposeResources);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: GameHud(game: game, onPause: () {}),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
