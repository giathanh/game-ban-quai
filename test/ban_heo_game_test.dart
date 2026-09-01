import 'package:ban_heo/data/level.dart';
import 'package:ban_heo/game/ban_heo_game.dart';
import 'package:ban_heo/game/components/enemy.dart';
import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

const _pigshooter = TowerStats(
  name: 'Pigshooter',
  cost: 50,
  rangeCells: 2.5,
  fireRate: 1,
  damage: 10,
  projectileSpeed: 300,
);

/// A long straight lane so test pigs take a long time to leak, plus knobs for
/// the pieces each test cares about.
LevelData _level({
  required int startingLives,
  required List<WaveData> waves,
  double enemySpeed = 4,
  double timeBetweenWaves = 0.1,
  List<Vector2>? pathCells,
}) {
  return LevelData(
    name: 'Test',
    cellSize: 32,
    gridCols: 40,
    gridRows: 10,
    startingLives: startingLives,
    startingGold: 100,
    timeBetweenWaves: timeBetweenWaves,
    pathCells: pathCells ?? <Vector2>[Vector2(-1, 5), Vector2(40, 5)],
    buildSpotCells: <Vector2>[Vector2(3, 3)],
    waves: waves,
    enemy: EnemyStats(
      maxHp: 10,
      speed: enemySpeed,
      goldOnKill: 7,
      livesOnLeak: 1,
    ),
    pigshooter: _pigshooter,
  );
}

GameResult? result;

BanHeoGame _makeGame(LevelData level) =>
    BanHeoGame(level: level, onGameOver: (r) => result = r);

/// Advances the game one frame, yielding to the microtask queue afterwards so
/// that queued components (whose `onLoad` is async) actually finish mounting.
Future<void> _tick(BanHeoGame game, [double dt = 1 / 60]) async {
  game.update(dt);
  await null;
  await null;
}

/// Steps the game frame by frame until [predicate] holds or the budget runs out.
Future<void> _tickUntil(
  BanHeoGame game,
  bool Function() predicate, {
  int maxFrames = 2400,
}) async {
  var frames = 0;
  while (!predicate() && frames < maxFrames) {
    await _tick(game);
    frames++;
  }
  expect(
    predicate(),
    isTrue,
    reason: 'condition never became true within $maxFrames frames',
  );
}

Future<void> _killEveryPig(BanHeoGame game) async {
  for (final pig in game.world.children.query<Enemy>().toList()) {
    pig.takeDamage(pig.stats.maxHp);
  }
  await _tick(game, 0);
}

void main() {
  setUp(() => result = null);

  testWithGame<BanHeoGame>(
    'killing a pig credits goldOnKill',
    () => _makeGame(
      _level(
        startingLives: 50,
        waves: const [
          WaveData([SpawnGroup(count: 3, interval: 0.4)]),
        ],
      ),
    ),
    (game) async {
      await _tickUntil(
        game,
        () => game.world.children.query<Enemy>().isNotEmpty,
      );

      final goldBefore = game.economy.gold;
      final pig = game.world.children.query<Enemy>().first;
      pig.takeDamage(pig.stats.maxHp);
      await _tick(game, 0);

      expect(game.economy.gold, goldBefore + game.level.enemy.goldOnKill);
    },
  );

  testWithGame<BanHeoGame>(
    'a leaked pig costs livesOnLeak lives',
    () => _makeGame(
      _level(
        startingLives: 5,
        enemySpeed: 500,
        pathCells: <Vector2>[Vector2(0, 2), Vector2(1, 2)],
        waves: const [
          WaveData([SpawnGroup(count: 1, interval: 0.1)]),
        ],
      ),
    ),
    (game) async {
      const livesBefore = 5;
      expect(game.lives.value, livesBefore);
      await _tickUntil(game, () => game.lives.value != livesBefore);
      expect(game.lives.value, livesBefore - game.level.enemy.livesOnLeak);
    },
  );

  testWithGame<BanHeoGame>(
    'dropping to 0 lives ends the round as a loss',
    () => _makeGame(
      _level(
        startingLives: 1,
        enemySpeed: 500,
        pathCells: <Vector2>[Vector2(0, 2), Vector2(1, 2)],
        waves: const [
          WaveData([SpawnGroup(count: 2, interval: 0.1)]),
        ],
      ),
    ),
    (game) async {
      await _tickUntil(game, () => result != null);
      expect(result, GameResult.lost);
      expect(game.lives.value, 0);
    },
  );

  testWithGame<BanHeoGame>(
    'spawning every wave then clearing every pig wins the round',
    () => _makeGame(
      _level(
        startingLives: 100,
        waves: const [
          WaveData([SpawnGroup(count: 2, interval: 0.2)]),
          WaveData([SpawnGroup(count: 2, interval: 0.2)]),
        ],
      ),
    ),
    (game) async {
      await _tickUntil(game, () => game.allWavesSpawned);
      // Let any pig still queued for mount settle, then remove them all.
      await _tick(game);
      await _tick(game);
      await _killEveryPig(game);
      expect(game.aliveEnemyCount, 0);

      await _tick(game);
      expect(result, GameResult.won);
    },
  );

  testWithGame<BanHeoGame>(
    'does not declare a win while the last pig is still pending mount (B3)',
    () => _makeGame(
      _level(
        startingLives: 100,
        enemySpeed: 3,
        timeBetweenWaves: 0.01,
        waves: const [
          WaveData([SpawnGroup(count: 2, interval: 0.0)]),
        ],
      ),
    ),
    (game) async {
      // Step raw frames (no microtask yield) so the pigs stay un-mounted: they
      // are handed to world.add() on the very tick allWavesSpawned flips true.
      var frames = 0;
      while (!game.allWavesSpawned && frames < 600) {
        game.update(1 / 60);
        frames++;
      }
      expect(game.allWavesSpawned, isTrue);

      // The component query cannot see the just-added pigs yet...
      expect(game.world.children.query<Enemy>(), isEmpty);
      expect(game.aliveEnemyCount, greaterThan(0));
      // ...so the win check must count them via the alive counter, not the
      // query. Pre-fix this reported a premature win here.
      expect(result, isNull);

      // They mount on subsequent ticks and the round still resolves normally.
      await _tickUntil(
        game,
        () => game.world.children.query<Enemy>().isNotEmpty,
      );
      await _killEveryPig(game);
      await _tick(game);
      expect(result, GameResult.won);
    },
  );
}
