import 'dart:math' as math;

import 'package:ban_heo/features/game/data/levels/level_catalog.dart';
import 'package:ban_heo/features/game/data/levels/tmx_level_loader.dart';
import 'package:ban_heo/features/game/domain/models/level.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/load_level.dart';

const _minimalTmx = '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" orientation="orthogonal" width="10" height="8" tilewidth="48" tileheight="48" infinite="0">
 <properties>
  <property name="startingLives" type="int" value="15"/>
  <property name="startingGold" type="int" value="90"/>
  <property name="timeBetweenWaves" type="float" value="2.5"/>
  <property name="towers" value="arrow,cannon"/>
  <property name="enemyHp" type="float" value="25"/>
  <property name="enemySpeed" type="float" value="55"/>
  <property name="enemyGold" type="int" value="6"/>
  <property name="enemyLives" type="int" value="1"/>
  <property name="waves" value="3@0.5;4@0.4+2@0.9"/>
 </properties>
 <objectgroup id="1" name="path">
  <object id="1" x="0" y="0">
   <polyline points="-24,120 120,120 120,360"/>
  </object>
 </objectgroup>
 <objectgroup id="2" name="buildspots">
  <object id="2" x="120" y="216"><point/></object>
 </objectgroup>
</map>
''';

void main() {
  test('parses grid, path, spots and properties from a .tmx', () {
    final level = parseTmxLevel(_minimalTmx, fallbackName: 'minimal');

    expect(level.cellSize, 48);
    expect(level.gridCols, 10);
    expect(level.gridRows, 8);
    expect(level.startingLives, 15);
    expect(level.startingGold, 90);
    expect(level.timeBetweenWaves, 2.5);
    expect(level.towers.map((t) => t.name), ['Tháp Bắn Tên', 'Tháp Đại Bác']);
    expect(level.enemy.maxHp, 25);
    expect(level.enemy.speed, 55);

    // pixel (px/48 - 0.5): (-24,120) -> (-1, 2)
    expect(level.pathCells.first.x, closeTo(-1, 1e-9));
    expect(level.pathCells.first.y, closeTo(2, 1e-9));
    expect(level.pathCells.length, 3);
    expect(level.buildSpotCells.single.x, closeTo(2, 1e-9));
    expect(level.buildSpotCells.single.y, closeTo(4, 1e-9));

    // waves: "3@0.5;4@0.4+2@0.9"
    expect(level.waves.length, 2);
    expect(level.waves[0].totalEnemies, 3);
    expect(level.waves[1].groups.length, 2);
    expect(level.waves[1].totalEnemies, 6);
  });

  test('throws a helpful error when the path layer is missing', () {
    final broken = _minimalTmx.replaceAll('name="path"', 'name="nope"');
    expect(
      () => parseTmxLevel(broken, fallbackName: 'broken'),
      throwsA(isA<FormatException>()),
    );
  });

  test('throws on an unknown tower id', () {
    final broken = _minimalTmx.replaceAll('arrow,cannon', 'arrow,dragon');
    expect(
      () => parseTmxLevel(broken, fallbackName: 'broken'),
      throwsA(isA<FormatException>()),
    );
  });

  test('throws on a malformed wave spec', () {
    final broken = _minimalTmx.replaceAll('3@0.5;4@0.4+2@0.9', '3@0.5;oops');
    expect(
      () => parseTmxLevel(broken, fallbackName: 'broken'),
      throwsA(isA<FormatException>()),
    );
  });

  test('every catalog .tmx parses into a runnable, well-formed level', () {
    for (final info in kLevelCatalog) {
      final LevelData level = loadLevelFromFile(info.tmxAsset);
      expect(level.pathCells.length, greaterThanOrEqualTo(2), reason: info.id);
      expect(level.buildSpotCells.length, greaterThanOrEqualTo(4),
          reason: info.id);
      expect(level.waves, isNotEmpty, reason: info.id);
      expect(level.towers, isNotEmpty, reason: info.id);
      expect(level.startingLives, greaterThan(0), reason: info.id);
      expect(level.enemy.maxHp, greaterThan(0), reason: info.id);

      // Build spots must be inside the grid and clear of the river, else towers
      // render on top of the path / off-screen.
      for (final spot in level.buildSpotCells) {
        expect(
          spot.x >= 0 &&
              spot.x <= level.gridCols - 1 &&
              spot.y >= 0 &&
              spot.y <= level.gridRows - 1,
          isTrue,
          reason: '${info.id}: build spot $spot outside grid',
        );
        expect(
          _minCellsToPath(spot, level.pathCells),
          greaterThan(0.6),
          reason: '${info.id}: build spot $spot sits on the river',
        );
      }
    }
  });
}

/// Shortest distance (in cells) from [p] to any segment of the polyline [path].
double _minCellsToPath(Vector2 p, List<Vector2> path) {
  var best = double.infinity;
  for (var i = 0; i < path.length - 1; i++) {
    final a = path[i];
    final b = path[i + 1];
    final ab = b - a;
    final lenSq = ab.length2;
    final t = lenSq == 0
        ? 0.0
        : (((p - a).dot(ab)) / lenSq).clamp(0.0, 1.0).toDouble();
    final proj = a + ab * t;
    best = math.min(best, (p - proj).length);
  }
  return best;
}
