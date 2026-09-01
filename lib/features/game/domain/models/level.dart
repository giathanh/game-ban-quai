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
  int get totalEnemies => groups.fold(0, (sum, group) => sum + group.count);
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

/// Visual + behavioural family a tower belongs to. Drives which artwork the
/// [Tower] paints and which projectile it fires.
enum TowerKind {
  /// Cheap, fast, single-target crossbow.
  arrow,

  /// Slow, heavy shot that also damages everything around the point of impact.
  cannon,

  /// Long-range bolt that sets its target on fire for damage over time.
  flamingArrow,
}

/// Static stats for a tower type.
class TowerStats {
  const TowerStats({
    required this.kind,
    required this.name,
    required this.description,
    required this.cost,
    required this.rangeCells,
    required this.fireRate,
    required this.damage,
    required this.projectileSpeed,
    this.splashRadiusCells = 0,
    this.splashDamageFactor = 0.5,
    this.burnDps = 0,
    this.burnDuration = 0,
  });

  final TowerKind kind;
  final String name;

  /// One-line pitch shown in the build menu.
  final String description;
  final int cost;

  /// Range measured in grid cells.
  final double rangeCells;

  /// Shots per second.
  final double fireRate;

  /// Direct hit damage.
  final double damage;

  /// Projectile travel speed in pixels per second.
  final double projectileSpeed;

  /// Radius (in grid cells) of the area hit on impact. 0 means single target.
  final double splashRadiusCells;

  /// Fraction of [damage] dealt to enemies caught in the splash (not the
  /// primary target, who always takes the full hit).
  final double splashDamageFactor;

  /// Damage per second applied by the burn left on a hit target. 0 means no
  /// burn.
  final double burnDps;

  /// How long (seconds) the burn lasts. Re-hitting refreshes rather than stacks.
  final double burnDuration;

  bool get hasSplash => splashRadiusCells > 0;
  bool get hasBurn => burnDps > 0 && burnDuration > 0;

  /// Returns a copy with the given fields overridden. Used by the upgrade
  /// resolver to build a buffed [TowerStats] without mutating the `const`
  /// catalog entry.
  TowerStats copyWith({
    TowerKind? kind,
    String? name,
    String? description,
    int? cost,
    double? rangeCells,
    double? fireRate,
    double? damage,
    double? projectileSpeed,
    double? splashRadiusCells,
    double? splashDamageFactor,
    double? burnDps,
    double? burnDuration,
  }) {
    return TowerStats(
      kind: kind ?? this.kind,
      name: name ?? this.name,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      rangeCells: rangeCells ?? this.rangeCells,
      fireRate: fireRate ?? this.fireRate,
      damage: damage ?? this.damage,
      projectileSpeed: projectileSpeed ?? this.projectileSpeed,
      splashRadiusCells: splashRadiusCells ?? this.splashRadiusCells,
      splashDamageFactor: splashDamageFactor ?? this.splashDamageFactor,
      burnDps: burnDps ?? this.burnDps,
      burnDuration: burnDuration ?? this.burnDuration,
    );
  }
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
    required this.towers,
    this.backgroundAsset = 'game/level_01_background.png',
  });

  final String name;

  /// Path (relative to `assets/images/`) of the diorama drawn under the field.
  /// Falls back to a gradient when the asset is missing or in logic-only tests.
  final String backgroundAsset;

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

  /// Tower types the player may build on this level, in menu order.
  final List<TowerStats> towers;

  double get width => gridCols * cellSize;
  double get height => gridRows * cellSize;

  /// Converts a cell coordinate to the pixel centre of that cell.
  Vector2 cellToPixel(Vector2 cell) =>
      Vector2((cell.x + 0.5) * cellSize, (cell.y + 0.5) * cellSize);

  /// Path waypoints resolved to pixel coordinates.
  List<Vector2> pathPixels() =>
      pathCells.map(cellToPixel).toList(growable: false);
}
