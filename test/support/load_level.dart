import 'dart:io';

import 'package:ban_heo/features/game/data/levels/tmx_level_loader.dart';
import 'package:ban_heo/features/game/domain/models/level.dart';

/// Reads a `.tmx` straight off disk and parses it, bypassing the asset bundle so
/// it works in plain (non-widget) tests. Paths are relative to the package root.
LevelData loadLevelFromFile(String path) {
  final xml = File(path).readAsStringSync();
  return parseTmxLevel(xml, fallbackName: path.split('/').last);
}
