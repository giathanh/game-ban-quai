import 'package:flame/components.dart';

/// A contiguous burst of identical enemies inside a [WaveData].
class SpawnGroup {
  const SpawnGroup({required this.count, required this.interval});

  /// How many enemies this group releases.
  final int count;

  /// Seconds between each spawn inside the group.
  final double interval;
}

/// One wave: an ordered list of [SpawnGroup]s.
class WaveData {
  const WaveData(this.groups);

  final List<SpawnGroup> groups;

  /// Total enemies released by this wave.
  int get totalEnemies =>
      groups.fold(0, (sum, group) => sum + group.count);
}

/// Static stats for the single enemy type in this slice (Heo / pig).
class EnemyStats {
  const EnemyStats({
    required this.maxHp,
    required this.speed,
    required this.goldOnKill,
    required this.livesOnLeak,
  });

  final double maxHp;

  /// Pixels per second along the path.
  final double speed;
  final int goldOnKill;
  final int livesOnLeak;
}

/// Static stats for a tower type. This slice only ships the Pigshooter.
class TowerStats {
  const TowerStats({
    required this.name,
    required this.cost,
    required this.rangeCells,
    required this.fireRate,
    required this.damage,
    required this.projectileSpeed,
  });

  final String name;
  final int cost;

  /// Range measured in grid cells.
  final double rangeCells;

  /// Shots per second.
  final double fireRate;
  final double damage;

  /// Projectile travel speed in pixels per second.
  final double projectileSpeed;
}

/// Declarative definition of a level.
class LevelData {
  const LevelData({
    required this.name,
    required this.cellSize,
    required this.gridCols,
    required this.gridRows,
    required this.startingLives,
    required this.startingGold,
    required this.timeBetweenWaves,
    required this.pathCells,
    required this.buildSpotCells,
    required this.waves,
    required this.enemy,
    required this.pigshooter,
  });

  final String name;

  /// Side length of a single grid cell, in pixels.
  final double cellSize;
  final int gridCols;
  final int gridRows;
  final int startingLives;
  final int startingGold;

  /// Seconds the spawner waits between waves (and before wave 1).
  final double timeBetweenWaves;

  /// Path waypoints in cell coordinates. May start/end off-grid so enemies
  /// walk on and off screen.
  final List<Vector2> pathCells;

  /// Build spot centres in cell coordinates.
  final List<Vector2> buildSpotCells;

  final List<WaveData> waves;
  final EnemyStats enemy;
  final TowerStats pigshooter;

  double get width => gridCols * cellSize;
  double get height => gridRows * cellSize;

  /// Converts a cell coordinate to the pixel centre of that cell.
  Vector2 cellToPixel(Vector2 cell) =>
      Vector2((cell.x + 0.5) * cellSize, (cell.y + 0.5) * cellSize);

  /// Path waypoints resolved to pixel coordinates.
  List<Vector2> pathPixels() => pathCells.map(cellToPixel).toList(growable: false);
}
