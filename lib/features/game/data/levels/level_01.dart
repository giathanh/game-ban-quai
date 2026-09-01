import 'package:flame/components.dart';

import '../../domain/models/level.dart';

/// Level 1 — the preview vertical slice.
final LevelData level01 = LevelData(
  name: 'Level 1',
  cellSize: 48,
  gridCols: 20,
  gridRows: 12,
  startingLives: 20,
  startingGold: 100,
  timeBetweenWaves: 3,
  // Left edge to right edge, snaking through the grid. First and last points
  // sit off-grid so pigs march on and off screen.
  pathCells: <Vector2>[
    Vector2(-1, 2),
    Vector2(3, 2),
    Vector2(3, 9),
    Vector2(9, 9),
    Vector2(9, 3),
    Vector2(15, 3),
    Vector2(15, 9),
    Vector2(20, 9),
  ],
  buildSpotCells: <Vector2>[
    Vector2(2, 4),
    Vector2(5, 7),
    Vector2(6, 10),
    Vector2(8, 6),
    Vector2(11, 4),
    Vector2(12, 1),
    Vector2(14, 6),
    Vector2(17, 7),
    Vector2(13, 10),
  ],
  waves: const <WaveData>[
    WaveData(<SpawnGroup>[SpawnGroup(count: 5, interval: 0.8)]),
    WaveData(<SpawnGroup>[SpawnGroup(count: 8, interval: 0.7)]),
    WaveData(<SpawnGroup>[SpawnGroup(count: 12, interval: 0.6)]),
    WaveData(<SpawnGroup>[SpawnGroup(count: 10, interval: 0.4)]),
    WaveData(<SpawnGroup>[SpawnGroup(count: 15, interval: 0.35)]),
  ],
  enemy: const EnemyStats(maxHp: 30, speed: 60, goldOnKill: 8, livesOnLeak: 1),
  towers: const <TowerStats>[
    TowerStats(
      kind: TowerKind.arrow,
      name: 'Tháp Bắn Tên',
      description: 'Bắn nhanh, một mục tiêu. Rẻ và ổn định.',
      cost: 50,
      rangeCells: 2.8,
      fireRate: 1.6,
      damage: 12,
      projectileSpeed: 440,
    ),
    TowerStats(
      kind: TowerKind.cannon,
      name: 'Tháp Đại Bác',
      description: 'Đạn nổ nặng, gây sát thương diện rộng cho cả đàn heo.',
      cost: 75,
      rangeCells: 2.3,
      fireRate: 0.6,
      damage: 34,
      projectileSpeed: 240,
      splashRadiusCells: 1.2,
      splashDamageFactor: 0.55,
    ),
    TowerStats(
      kind: TowerKind.flamingArrow,
      name: 'Tháp Tên Lửa',
      description: 'Tầm xa nhất, mũi tên thiêu cháy mục tiêu theo thời gian.',
      cost: 100,
      rangeCells: 3.3,
      fireRate: 1.3,
      damage: 15,
      projectileSpeed: 460,
      burnDps: 9,
      burnDuration: 3,
    ),
  ],
);
