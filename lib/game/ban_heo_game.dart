import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../data/level.dart';
import 'components/build_spot.dart';
import 'components/enemy.dart';
import 'components/path_component.dart';
import 'components/tower.dart';
import 'systems/economy.dart';
import 'systems/wave_spawner.dart';

/// Outcome of a finished round.
enum GameResult { won, lost }

/// Owns the Level 1 lifecycle: builds the field, runs the wave spawner, tracks
/// lives, and decides win/lose.
class BanHeoGame extends FlameGame {
  BanHeoGame({required this.level, required this.onGameOver})
    : economy = Economy(startingGold: level.startingGold),
      lives = ValueNotifier<int>(level.startingLives),
      _pathPixels = level.pathPixels(),
      super(
        camera: CameraComponent.withFixedResolution(
          width: level.width,
          height: level.height,
        ),
      );

  final LevelData level;

  /// Invoked exactly once when the round ends.
  final void Function(GameResult result) onGameOver;

  /// Construction-time state must not be `late`: Flutter overlays can read it
  /// during their first build pass, before Flame's asynchronous [onLoad].
  final Economy economy;
  final List<Vector2> _pathPixels;
  late final WaveSpawner _spawner;

  final ValueNotifier<int> lives;
  final ValueNotifier<int> wave = ValueNotifier<int>(0);
  final ValueNotifier<double> nextWaveCountdown = ValueNotifier<double>(0);
  final ValueNotifier<bool> canStartNextWave = ValueNotifier<bool>(false);

  /// Enemies handed to the world that have not yet resolved (been killed or
  /// leaked). Tracked explicitly: a just-spawned enemy is invisible to
  /// `world.children.query<Enemy>()` until the next lifecycle flush, so relying
  /// on that query for the win check races the spawner.
  int _alive = 0;
  bool _notifiersDisposed = false;

  /// The spot whose build/sell menu is open, or null. Driven by tap events and
  /// read by the Flutter HUD overlay.
  final ValueNotifier<BuildSpot?> selectedSpot = ValueNotifier<BuildSpot?>(
    null,
  );

  bool _ended = false;
  bool get isGameOver => _ended;

  bool get isInteractionLocked => _ended || paused;

  @override
  Color backgroundColor() => const Color(0xFF2E7D32);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;

    world.add(_GridBackground(level: level));
    world.add(
      PathComponent(waypoints: _pathPixels, laneWidth: level.cellSize * 0.7),
    );

    for (final cell in level.buildSpotCells) {
      world.add(
        BuildSpot(position: level.cellToPixel(cell), cellSize: level.cellSize),
      );
    }

    _spawner = WaveSpawner(
      waves: level.waves,
      timeBetweenWaves: level.timeBetweenWaves,
      onSpawnEnemy: _spawnEnemy,
      onWaveStart: (waveNumber) => wave.value = waveNumber,
    );
    world.add(_spawner);
  }

  /// True once every enemy of every wave has been handed to the world.
  bool get allWavesSpawned => _spawner.allWavesSpawned;

  /// Outstanding (unresolved) enemies — spawned but neither killed nor leaked.
  int get aliveEnemyCount => _alive;

  void _spawnEnemy() {
    _alive++;
    world.add(
      Enemy(
        stats: level.enemy,
        pathPixels: _pathPixels,
        cellSize: level.cellSize,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_ended) {
      return;
    }

    // Only touch the HUD notifiers when the value the HUD actually renders
    // changes: the countdown text shows whole seconds, so writing every frame
    // just forces 60fps rebuilds through the merged Listenable.
    final double rawCountdown = _spawner.timeUntilNextWave;
    if (rawCountdown.ceil() != nextWaveCountdown.value.ceil()) {
      nextWaveCountdown.value = rawCountdown;
    }
    final bool canStart = _spawner.canCallNextWave;
    if (canStart != canStartNextWave.value) {
      canStartNextWave.value = canStart;
    }

    if (lives.value <= 0) {
      _finish(GameResult.lost);
      return;
    }
    if (_spawner.allWavesSpawned && _alive == 0) {
      _finish(GameResult.won);
    }
  }

  // --- Events from components -------------------------------------------------

  void onEnemyKilled(Enemy enemy) {
    _alive--;
    if (_ended) {
      return;
    }
    economy.earn(enemy.stats.goldOnKill);
  }

  void onEnemyLeaked(Enemy enemy) {
    _alive--;
    if (_ended) {
      return;
    }
    lives.value = (lives.value - enemy.stats.livesOnLeak).clamp(0, 1 << 30);
  }

  // --- HUD / overlay API ----------------------------------------------------

  void callNextWaveEarly() {
    if (_ended) {
      return;
    }
    _spawner.callNextWaveEarly();
  }

  void closeSpotMenu() => selectedSpot.value = null;

  /// Attempts to build a Pigshooter on [spot]. Returns whether it succeeded.
  bool buildPigshooter(BuildSpot spot) {
    if (_ended || spot.isOccupied) {
      return false;
    }
    if (!economy.trySpend(level.pigshooter.cost)) {
      return false;
    }
    final tower = Tower(
      position: spot.position.clone(),
      stats: level.pigshooter,
      cellSize: level.cellSize,
    );
    spot.tower = tower;
    world.add(tower);
    selectedSpot.value = null;
    return true;
  }

  /// Sells the tower on [spot], refunding 60% of its cost.
  void sellTower(BuildSpot spot) {
    final tower = spot.tower;
    if (_ended || tower == null) {
      return;
    }
    economy.earn(Economy.refundValue(tower.stats.cost));
    tower.removeFromParent();
    spot.tower = null;
    selectedSpot.value = null;
  }

  void _finish(GameResult result) {
    _ended = true;
    pauseEngine();
    onGameOver(result);
  }

  /// Disposes every notifier/listenable this game owns. Idempotent: Flame calls
  /// [onRemove] when the [GameWidget] is torn down, and [_GameScreenState] also
  /// calls it defensively.
  void disposeResources() {
    if (_notifiersDisposed) {
      return;
    }
    _notifiersDisposed = true;
    economy.dispose();
    lives.dispose();
    wave.dispose();
    nextWaveCountdown.dispose();
    canStartNextWave.dispose();
    selectedSpot.dispose();
  }

  @override
  void onRemove() {
    disposeResources();
    super.onRemove();
  }
}

/// Faint grid lines so the play-field reads as a grid.
class _GridBackground extends PositionComponent {
  _GridBackground({required this.level}) : super(priority: -20);

  final LevelData level;

  final Paint _linePaint = Paint()
    ..color = const Color(0x22000000)
    ..strokeWidth = 1;

  @override
  void render(Canvas canvas) {
    for (var c = 0; c <= level.gridCols; c++) {
      final x = c * level.cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, level.height), _linePaint);
    }
    for (var r = 0; r <= level.gridRows; r++) {
      final y = r * level.cellSize;
      canvas.drawLine(Offset(0, y), Offset(level.width, y), _linePaint);
    }
  }
}
