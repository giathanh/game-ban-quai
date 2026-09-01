import 'package:ban_heo/features/game/domain/models/level.dart';
import 'package:ban_heo/features/game/engine/ban_heo_game.dart';
import 'package:ban_heo/features/game/engine/components/enemy.dart';
import 'package:ban_heo/features/game/engine/components/projectile.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

LevelData _level() => LevelData(
  name: 'Test',
  cellSize: 32,
  gridCols: 40,
  gridRows: 10,
  startingLives: 100,
  startingGold: 500,
  timeBetweenWaves: 0.05,
  pathCells: <Vector2>[Vector2(-1, 5), Vector2(40, 5)],
  buildSpotCells: <Vector2>[Vector2(3, 3)],
  waves: const <WaveData>[
    WaveData([SpawnGroup(count: 3, interval: 0.05)]),
  ],
  enemy: const EnemyStats(
    maxHp: 40,
    speed: 2,
    goldOnKill: 5,
    livesOnLeak: 1,
  ),
  towers: const <TowerStats>[
    TowerStats(
      kind: TowerKind.flamingArrow,
      name: 'Fire',
      description: 't',
      cost: 10,
      rangeCells: 3,
      fireRate: 1,
      damage: 5,
      projectileSpeed: 400,
      burnDps: 10,
      burnDuration: 2,
    ),
  ],
);

BanHeoGame _game() => BanHeoGame(level: _level(), onGameOver: (_) {});

Future<void> _tick(BanHeoGame game, [double dt = 1 / 60]) async {
  game.update(dt);
  await null;
  await null;
}

Future<void> _tickUntil(BanHeoGame game, bool Function() done, {int max = 1200}) async {
  var f = 0;
  while (!done() && f < max) {
    await _tick(game);
    f++;
  }
  expect(done(), isTrue, reason: 'condition not met in $max frames');
}

void main() {
  testWithGame<BanHeoGame>('applyBurn keeps damaging a pig after the hit', _game, (
    game,
  ) async {
    await _tickUntil(game, () => game.world.children.query<Enemy>().isNotEmpty);
    final pig = game.world.children.query<Enemy>().first;

    pig.applyBurn(10, 2);
    expect(pig.isBurning, isTrue);
    final before = pig.hpFraction;

    // One second of burn ≈ 10 dmg on a 40 hp pig => ~0.25 of the bar.
    for (var i = 0; i < 60; i++) {
      await _tick(game);
    }

    expect(pig.hpFraction, lessThan(before));
    expect(pig.hpFraction, closeTo(before - 0.25, 0.08));
  });

  testWithGame<BanHeoGame>('cannon splash damages a bystander pig, not just the target', () {
    return BanHeoGame(
      level: LevelData(
        name: 'Splash',
        cellSize: 32,
        gridCols: 40,
        gridRows: 10,
        startingLives: 100,
        startingGold: 100,
        timeBetweenWaves: 0.05,
        pathCells: <Vector2>[Vector2(-1, 5), Vector2(40, 5)],
        buildSpotCells: <Vector2>[Vector2(3, 3)],
        waves: const <WaveData>[
          WaveData([SpawnGroup(count: 2, interval: 0.0)]),
        ],
        enemy: const EnemyStats(
          maxHp: 100,
          speed: 1,
          goldOnKill: 5,
          livesOnLeak: 1,
        ),
        towers: const <TowerStats>[
          TowerStats(
            kind: TowerKind.cannon,
            name: 'Boom',
            description: 't',
            cost: 10,
            rangeCells: 3,
            fireRate: 1,
            damage: 30,
            projectileSpeed: 10000,
            splashRadiusCells: 3,
          ),
        ],
      ),
      onGameOver: (_) {},
    );
  }, (game) async {
    await _tickUntil(
      game,
      () => game.world.children.query<Enemy>().length >= 2,
    );
    final pigs = game.world.children.query<Enemy>().toList();
    final target = pigs.first;
    final bystander = pigs[1];
    // Park the bystander right next to the target so it is inside the blast.
    bystander.position.setFrom(target.position + Vector2(20, 0));

    game.world.add(
      Projectile(
        position: target.position.clone(),
        target: target,
        speed: 10000,
        damage: 30,
        kind: TowerKind.cannon,
        splashRadius: 96,
      ),
    );
    for (var i = 0; i < 5; i++) {
      await _tick(game);
    }

    expect(target.hpFraction, lessThan(1), reason: 'direct hit');
    expect(bystander.hpFraction, lessThan(1), reason: 'caught in the splash');
    // Bystander took the reduced splash hit, not the full one.
    expect(bystander.hpFraction, greaterThan(target.hpFraction));
  });
}
