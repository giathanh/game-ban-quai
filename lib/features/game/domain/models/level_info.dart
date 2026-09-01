/// Menu-facing metadata for one level. The heavy [LevelData] is loaded lazily
/// from [tmxAsset] only when the player actually starts the level.
class LevelInfo {
  const LevelInfo({
    required this.id,
    required this.tmxAsset,
    required this.title,
    required this.tagline,
  });

  /// Stable id, also used as the progress key. Never reorder existing ids.
  final String id;

  /// Asset path of the Tiled map, e.g. `assets/levels/level_02.tmx`.
  final String tmxAsset;

  final String title;

  /// One-line pitch shown on the level card.
  final String tagline;
}
