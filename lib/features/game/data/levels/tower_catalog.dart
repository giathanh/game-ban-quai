import '../../domain/models/level.dart';

/// Every tower the game knows about, keyed by a short id used in level files
/// (the `towers` map property of a `.tmx`, e.g. `arrow,cannon,flamingArrow`).
///
/// Levels pick a subset from here instead of re-declaring stats, so balancing a
/// tower is a one-line change that every level inherits.
const Map<String, TowerStats> kTowerCatalog = <String, TowerStats>{
  'arrow': TowerStats(
    kind: TowerKind.arrow,
    name: 'Tháp Bắn Tên',
    description: 'Bắn nhanh, một mục tiêu. Rẻ và ổn định.',
    cost: 50,
    rangeCells: 2.8,
    fireRate: 1.6,
    damage: 12,
    projectileSpeed: 440,
  ),
  'cannon': TowerStats(
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
  'flamingArrow': TowerStats(
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
};

/// Resolves a comma-separated id list (`'arrow, cannon'`) to tower stats, in the
/// order given. Unknown ids throw so a typo in a level file fails loudly.
List<TowerStats> towersFromIds(String csv) {
  final ids = csv
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);
  if (ids.isEmpty) {
    throw const FormatException('level lists no towers (empty `towers` property)');
  }
  return ids.map((id) {
    final stats = kTowerCatalog[id];
    if (stats == null) {
      throw FormatException(
        'unknown tower id "$id" — valid ids: ${kTowerCatalog.keys.join(', ')}',
      );
    }
    return stats;
  }).toList(growable: false);
}
