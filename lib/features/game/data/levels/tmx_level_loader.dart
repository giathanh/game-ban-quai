import 'package:flame/components.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tiled/tiled.dart';

import '../../domain/models/level.dart';
import 'tower_catalog.dart';

/// Loads a level authored in Tiled (`.tmx`) and turns it into a [LevelData] the
/// engine can run. Adding a level is therefore: draw a `.tmx`, drop it in
/// `assets/levels/`, list it in the level catalog. No engine code changes.
///
/// ## What the `.tmx` must contain
///
/// * Map size in tiles = grid size; `tilewidth` (== `tileheight`) = cell size.
/// * An object layer named `path` with a single polyline/polygon — the river.
///   Its first and last points may sit off the map so pigs walk on/off screen.
/// * An object layer named `buildspots` with point objects — tower slots.
/// * Map custom properties:
///   - `title`             (string)  shown in the level picker (optional)
///   - `background`        (string)  image path under `assets/images/` (optional)
///   - `startingLives`     (int)
///   - `startingGold`      (int)
///   - `timeBetweenWaves`  (float, seconds)
///   - `towers`            (string)  csv of ids from [kTowerCatalog]
///   - `enemyHp` / `enemySpeed` / `enemyGold` / `enemyLives`
///   - `waves`             (string)  see [_parseWaves]
Future<LevelData> loadTmxLevel(String assetPath) async {
  final xml = await rootBundle.loadString(assetPath);
  return parseTmxLevel(xml, fallbackName: _nameFromPath(assetPath));
}

/// Pure-Dart core of [loadTmxLevel]; takes the raw `.tmx` text so it can run in
/// unit tests without an asset bundle.
LevelData parseTmxLevel(String tmxXml, {required String fallbackName}) {
  final TiledMap map;
  try {
    map = TileMapParser.parseTmx(tmxXml);
  } on Exception catch (e) {
    throw FormatException('cannot parse .tmx for "$fallbackName": $e');
  }

  final props = map.properties;
  final cellSize = map.tileWidth.toDouble();
  if (cellSize <= 0) {
    throw FormatException('$fallbackName: map tilewidth must be > 0');
  }

  final pathObj = _objectLayer(map, 'path', fallbackName).objects.firstWhere(
    (o) => o.isPolyline || o.isPolygon,
    orElse: () => throw FormatException(
      '$fallbackName: the "path" layer needs a polyline (or polygon) object',
    ),
  );
  final rawPoints = pathObj.isPolyline ? pathObj.polyline : pathObj.polygon;
  final pathCells = rawPoints
      .map(
        (p) => _pixelToCell(pathObj.x + p.x, pathObj.y + p.y, cellSize),
      )
      .toList(growable: false);
  if (pathCells.length < 2) {
    throw FormatException('$fallbackName: the river needs at least 2 points');
  }

  final buildSpotCells = _objectLayer(map, 'buildspots', fallbackName)
      .objects
      .map((o) {
        // Point objects carry no size; rectangles/ellipses use their centre.
        final cx = o.x + (o.isPoint ? 0.0 : o.width / 2);
        final cy = o.y + (o.isPoint ? 0.0 : o.height / 2);
        return _pixelToCell(cx, cy, cellSize);
      })
      .toList(growable: false);

  return LevelData(
    name: _string(props, 'title') ?? fallbackName,
    cellSize: cellSize,
    gridCols: map.width,
    gridRows: map.height,
    startingLives: _int(props, 'startingLives', fallbackName),
    startingGold: _int(props, 'startingGold', fallbackName),
    timeBetweenWaves: _double(props, 'timeBetweenWaves', fallbackName),
    pathCells: pathCells,
    buildSpotCells: buildSpotCells,
    waves: _parseWaves(_requireString(props, 'waves', fallbackName), fallbackName),
    enemy: EnemyStats(
      maxHp: _double(props, 'enemyHp', fallbackName),
      speed: _double(props, 'enemySpeed', fallbackName),
      goldOnKill: _int(props, 'enemyGold', fallbackName),
      livesOnLeak: _int(props, 'enemyLives', fallbackName),
    ),
    towers: towersFromIds(_requireString(props, 'towers', fallbackName)),
    backgroundAsset:
        _string(props, 'background') ?? 'game/level_01_background.png',
  );
}

/// `"5@0.8;8@0.7;12@0.6+4@0.3"`
///
/// * `;` separates waves
/// * `+` separates spawn groups inside one wave
/// * each group is `count@interval` (interval in seconds between spawns)
List<WaveData> _parseWaves(String spec, String levelName) {
  final waves = spec
      .split(';')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map((waveSpec) {
        final groups = waveSpec.split('+').map((g) {
          final parts = g.trim().split('@');
          if (parts.length != 2) {
            throw FormatException(
              '$levelName: bad wave group "$g" — expected count@interval',
            );
          }
          final count = int.tryParse(parts[0].trim());
          final interval = double.tryParse(parts[1].trim());
          if (count == null || count <= 0 || interval == null || interval < 0) {
            throw FormatException(
              '$levelName: bad wave group "$g" — count must be a positive int, '
              'interval a non-negative number',
            );
          }
          return SpawnGroup(count: count, interval: interval);
        }).toList(growable: false);
        return WaveData(groups);
      })
      .toList(growable: false);
  if (waves.isEmpty) {
    throw FormatException('$levelName: `waves` property is empty');
  }
  return waves;
}

ObjectGroup _objectLayer(TiledMap map, String name, String levelName) {
  for (final layer in map.layers) {
    if (layer is ObjectGroup && layer.name == name) {
      return layer;
    }
  }
  throw FormatException('$levelName: missing object layer named "$name"');
}

Vector2 _pixelToCell(double px, double py, double cellSize) =>
    Vector2(px / cellSize - 0.5, py / cellSize - 0.5);

String _nameFromPath(String assetPath) {
  final file = assetPath.split('/').last;
  return file.endsWith('.tmx') ? file.substring(0, file.length - 4) : file;
}

// --- property readers: forgiving about int-vs-float authoring -----------------

String? _string(CustomProperties props, String name) {
  final v = props.getValue<String>(name);
  return (v == null || v.isEmpty) ? null : v;
}

String _requireString(CustomProperties props, String name, String levelName) {
  final v = _string(props, name);
  if (v == null) {
    throw FormatException('$levelName: missing string property "$name"');
  }
  return v;
}

double _double(CustomProperties props, String name, String levelName) {
  final n = props.getValue<double>(name) ??
      props.getValue<int>(name)?.toDouble() ??
      double.tryParse(props.getValue<String>(name) ?? '');
  if (n == null) {
    throw FormatException('$levelName: missing numeric property "$name"');
  }
  return n;
}

int _int(CustomProperties props, String name, String levelName) {
  final n = props.getValue<int>(name) ??
      props.getValue<double>(name)?.round() ??
      int.tryParse(props.getValue<String>(name) ?? '');
  if (n == null) {
    throw FormatException('$levelName: missing int property "$name"');
  }
  return n;
}
