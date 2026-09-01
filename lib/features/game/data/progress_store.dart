import 'package:shared_preferences/shared_preferences.dart';

/// Persists how far the player has unlocked. Levels unlock sequentially: level
/// index 0 is always playable; index `i > 0` unlocks once index `i - 1` is
/// cleared.
class ProgressStore {
  ProgressStore._();

  static const _key = 'banheo.progress.highestUnlockedIndex';

  /// Highest level index the player may enter (0 = only the first level).
  static Future<int> highestUnlockedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 0;
  }

  /// Records that [levelIndex] was cleared, unlocking the next level. No-op if
  /// the player had already progressed further.
  static Future<void> markCompleted(int levelIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked = prefs.getInt(_key) ?? 0;
    if (levelIndex + 1 > unlocked) {
      await prefs.setInt(_key, levelIndex + 1);
    }
  }

  /// Wipes progress (used by a debug menu / tests).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
