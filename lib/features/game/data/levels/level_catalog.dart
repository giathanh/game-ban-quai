import '../../domain/models/level.dart';
import '../../domain/models/level_info.dart';
import 'tmx_level_loader.dart';

/// The ordered list of levels. **To add a level: author `assets/levels/level_NN.tmx`
/// in Tiled and append one entry here.** Nothing else in the codebase changes.
///
/// Order is progression order; ids must stay stable (they key saved progress).
const List<LevelInfo> kLevelCatalog = <LevelInfo>[
  LevelInfo(
    id: 'level_01',
    tmxAsset: 'assets/levels/level_01.tmx',
    title: 'Màn 1 — Khúc sông đầu',
    tagline: 'Đàn heo đầu tiên mò tới. Làm quen với ba loại tháp.',
  ),
  LevelInfo(
    id: 'level_02',
    tmxAsset: 'assets/levels/level_02.tmx',
    title: 'Màn 2 — Ngã ba sông',
    tagline: 'Dòng chảy dài hơn, heo khoẻ hơn và tới dồn dập hơn.',
  ),
  LevelInfo(
    id: 'level_03',
    tmxAsset: 'assets/levels/level_03.tmx',
    title: 'Màn 3 — Cửa biển',
    tagline: 'Bảy đợt heo thép. Giữ vàng cho tháp Tên Lửa.',
  ),
];

int get levelCount => kLevelCatalog.length;

bool hasLevelAt(int index) => index >= 0 && index < kLevelCatalog.length;

/// Loads the runnable [LevelData] for the catalog entry at [index].
Future<LevelData> loadCatalogLevel(int index) {
  final info = kLevelCatalog[index];
  return loadTmxLevel(info.tmxAsset);
}
