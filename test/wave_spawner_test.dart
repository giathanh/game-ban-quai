import 'package:ban_heo/features/game/domain/models/level.dart';
import 'package:ban_heo/features/game/engine/systems/wave_spawner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/load_level.dart';

void _pump(WaveSpawner spawner, double seconds, {double dt = 1 / 60}) {
  var elapsed = 0.0;
  while (elapsed < seconds) {
    spawner.update(dt);
    elapsed += dt;
  }
}

void main() {
  test('waits timeBetweenWaves before releasing the first enemy', () {
    var spawned = 0;
    final spawner = WaveSpawner(
      waves: const [
        WaveData([SpawnGroup(count: 3, interval: 0.5)]),
      ],
      timeBetweenWaves: 1,
      onSpawnEnemy: () => spawned++,
    );

    _pump(spawner, 0.9);
    expect(spawned, 0, reason: 'countdown not finished yet');
    expect(spawner.currentWaveNumber, 0);

    _pump(spawner, 0.5); // now past 1s + a frame
    expect(spawned, greaterThanOrEqualTo(1));
    expect(spawner.currentWaveNumber, 1);
  });

  test('releases every enemy of every wave exactly once', () {
    var spawned = 0;
    final spawner = WaveSpawner(
      waves: const [
        WaveData([SpawnGroup(count: 3, interval: 0.3)]),
        WaveData([SpawnGroup(count: 4, interval: 0.3)]),
      ],
      timeBetweenWaves: 1,
      onSpawnEnemy: () => spawned++,
    );

    _pump(spawner, 30);

    expect(spawned, 7);
    expect(spawner.allWavesSpawned, isTrue);
    expect(spawner.currentWaveNumber, 2);
    expect(spawner.canCallNextWave, isFalse);
  });

  test('reports wave starts in order via onWaveStart', () {
    final starts = <int>[];
    final spawner = WaveSpawner(
      waves: const [
        WaveData([SpawnGroup(count: 1, interval: 0.2)]),
        WaveData([SpawnGroup(count: 1, interval: 0.2)]),
        WaveData([SpawnGroup(count: 1, interval: 0.2)]),
      ],
      timeBetweenWaves: 0.5,
      onSpawnEnemy: () {},
      onWaveStart: starts.add,
    );

    _pump(spawner, 20);
    expect(starts, [1, 2, 3]);
  });

  test('callNextWaveEarly skips the remaining countdown', () {
    var spawned = 0;
    final spawner = WaveSpawner(
      waves: const [
        WaveData([SpawnGroup(count: 2, interval: 0.2)]),
        WaveData([SpawnGroup(count: 2, interval: 0.2)]),
      ],
      timeBetweenWaves: 100, // effectively never auto-advances
      onSpawnEnemy: () => spawned++,
    );

    // Skip the long initial countdown and finish wave 1.
    spawner.callNextWaveEarly();
    _pump(spawner, 2);
    expect(spawner.currentWaveNumber, 1);
    expect(spawned, 2);
    expect(spawner.canCallNextWave, isTrue);

    // Without an early call wave 2 would wait ~100s.
    spawner.callNextWaveEarly();
    _pump(spawner, 2);
    expect(spawner.currentWaveNumber, 2);
    expect(spawned, 4);
    expect(spawner.allWavesSpawned, isTrue);
  });

  test('respects the spacing between enemies inside a wave', () {
    var spawned = 0;
    final spawner = WaveSpawner(
      waves: const [
        WaveData([SpawnGroup(count: 10, interval: 1.0)]),
      ],
      timeBetweenWaves: 0,
      onSpawnEnemy: () => spawned++,
    );

    _pump(spawner, 3.5); // ~t=3.5s into the wave
    // enemies at t=0,1,2,3 -> 4 spawned, not all 10.
    expect(spawned, inInclusiveRange(3, 5));
    expect(spawner.allWavesSpawned, isFalse);
  });

  test('drives the real Level 1 table to completion (50 pigs)', () {
    final level01 = loadLevelFromFile('assets/levels/level_01.tmx');
    var spawned = 0;
    final expected = level01.waves.fold<int>(
      0,
      (sum, wave) => sum + wave.totalEnemies,
    );
    expect(expected, 50);

    final spawner = WaveSpawner(
      waves: level01.waves,
      timeBetweenWaves: level01.timeBetweenWaves,
      onSpawnEnemy: () => spawned++,
    );

    _pump(spawner, 120);

    expect(spawned, 50);
    expect(spawner.allWavesSpawned, isTrue);
    expect(spawner.currentWaveNumber, level01.waves.length);
  });
}
