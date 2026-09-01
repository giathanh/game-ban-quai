import 'package:shared_preferences/shared_preferences.dart';

import '../../game/data/levels/level_catalog.dart';
import '../domain/upgrade_catalog.dart';
import '../domain/upgrade_levels.dart';
import '../domain/upgrade_math.dart';

/// Snapshot returned by [UpgradeStore.load] — everything the screens render in
/// one prefs round-trip. [points] is derived (`earned - spent`), never stored.
class UpgradeState {
  const UpgradeState({
    required this.levels,
    required this.points,
    required this.earned,
    required this.spent,
  });

  final UpgradeLevels levels;
  final int points;
  final int earned;
  final int spent;
}

/// Outcome of [UpgradeStore.awardForClear]. [points] is what THIS call granted
/// (0 on a replay); [flawlessGranted] is true only when the flawless token fired
/// on this call, so the win dialog can show the extra "no leak" line.
class AwardResult {
  const AwardResult({required this.points, required this.flawlessGranted});

  static const AwardResult none =
      AwardResult(points: 0, flawlessGranted: false);

  final int points;
  final bool flawlessGranted;
}

/// Prefs-backed store for global tower upgrades. Same thin static-class style as
/// `ProgressStore`. Two keys only; the point balance is always recomputed from
/// them so it cannot drift.
class UpgradeStore {
  UpgradeStore._();

  /// Claimed award tokens with the granted points baked in:
  /// `"<levelId>:clear=<payout>"` / `"<levelId>:flawless=1"`. Legacy tokens
  /// without `=` are still read (payout is then recomputed from the catalog).
  static const String _awardsKey = 'banheo.upgrades.awards';

  /// Purchased tiers: `"<trackId>=<tier>"`, e.g. `"all.damage=3"`. Entries whose
  /// track id we do not understand are preserved verbatim (forward compat).
  static const String _tiersKey = 'banheo.upgrades.tiers';

  /// Clear payout for a level at [levelIndex]: `2 + levelIndex ~/ 5`.
  static int clearPayout(int levelIndex) => 2 + levelIndex ~/ 5;

  // --- reads ---------------------------------------------------------------

  static Future<UpgradeLevels> levels() async {
    final prefs = await SharedPreferences.getInstance();
    return _parseTiers(prefs.getStringList(_tiersKey)).levels;
  }

  static Future<int> points() async {
    final prefs = await SharedPreferences.getInstance();
    return _pointsFrom(prefs);
  }

  static Future<UpgradeState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final levels = _parseTiers(prefs.getStringList(_tiersKey)).levels;
    final earned = _earnedFrom(prefs.getStringList(_awardsKey));
    final spent = levels.pointsSpent;
    return UpgradeState(
      levels: levels,
      points: (earned - spent).clamp(0, 1 << 30),
      earned: earned,
      spent: spent,
    );
  }

  // --- writes ------------------------------------------------------------

  static Future<AwardResult> awardForClear({
    required String levelId,
    required int levelIndex,
    required bool flawless,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final awards = <String>[...?prefs.getStringList(_awardsKey)];

    var granted = 0;
    var flawlessGranted = false;

    if (!_hasAward(awards, '$levelId:clear')) {
      final payout = clearPayout(levelIndex);
      awards.add('$levelId:clear=$payout');
      granted += payout;
    }

    if (flawless && !_hasAward(awards, '$levelId:flawless')) {
      awards.add('$levelId:flawless=1');
      granted += 1;
      flawlessGranted = true;
    }

    if (granted > 0) {
      await prefs.setStringList(_awardsKey, awards);
    }
    return AwardResult(points: granted, flawlessGranted: flawlessGranted);
  }

  /// Buys the next tier of [axis]. Returns false and writes nothing when the
  /// track is maxed or the balance is short.
  static Future<bool> buy(UpgradeAxis axis) async {
    final prefs = await SharedPreferences.getInstance();
    final tiers = _parseTiers(prefs.getStringList(_tiersKey));
    final current = tiers.levels.tierOf(axis);
    if (current >= kMaxTier) return false;

    final price = costOfTier(current + 1);
    if (_pointsFrom(prefs) < price) return false;

    final next = tiers.levels.withTier(axis, current + 1);
    await prefs.setStringList(_tiersKey, <String>[
      ..._serializeTiers(next),
      ...tiers.unknown, // keep forward-compat entries we did not author
    ]);
    return true;
  }

  /// Wipes both keys. Debug menu / tests only.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_awardsKey);
    await prefs.remove(_tiersKey);
  }

  // --- helpers ---------------------------------------------------------

  static int _pointsFrom(SharedPreferences prefs) {
    final levels = _parseTiers(prefs.getStringList(_tiersKey)).levels;
    final earned = _earnedFrom(prefs.getStringList(_awardsKey));
    final balance = earned - levels.pointsSpent;
    return balance < 0 ? 0 : balance;
  }

  static bool _hasAward(List<String> awards, String base) =>
      awards.any((t) => t == base || t.startsWith('$base='));

  static int _earnedFrom(List<String>? raw) {
    if (raw == null) return 0;
    var earned = 0;
    for (final token in raw) {
      final eq = token.indexOf('=');
      if (eq >= 0) {
        // Payout baked into the token — trust it, so a later catalog
        // reorder/delete cannot retroactively revalue a claimed award.
        final value = int.tryParse(token.substring(eq + 1).trim());
        if (value != null && value > 0) earned += value;
        continue;
      }
      // Legacy token without a baked-in payout: recompute it.
      final colon = token.lastIndexOf(':');
      if (colon <= 0) continue;
      final id = token.substring(0, colon);
      final reason = token.substring(colon + 1);
      final index = kLevelCatalog.indexWhere((l) => l.id == id);
      if (index < 0) continue;
      if (reason == 'flawless') {
        earned += 1;
      } else if (reason == 'clear') {
        earned += clearPayout(index);
      }
    }
    return earned;
  }

  /// Parsed tier state plus any entries whose track id we did not recognise
  /// (kept so a future per-kind track survives a v1 [buy]).
  static _Tiers _parseTiers(List<String>? raw) {
    if (raw == null) return const _Tiers(UpgradeLevels.none, <String>[]);
    var levels = UpgradeLevels.none;
    final unknown = <String>[];
    for (final entry in raw) {
      final eq = entry.indexOf('=');
      if (eq <= 0) {
        unknown.add(entry);
        continue;
      }
      final trackId = entry.substring(0, eq).trim();
      final tier = int.tryParse(entry.substring(eq + 1).trim());
      // v1 scope is always `all.`; anything else is a forward-compat track we
      // do not understand yet — preserve it rather than drop or throw.
      final axis =
          trackId.startsWith('all.') ? UpgradeAxis.fromId(trackId.substring(4)) : null;
      if (tier == null || axis == null) {
        unknown.add(entry);
        continue;
      }
      levels = levels.withTier(axis, tier.clamp(0, kMaxTier));
    }
    return _Tiers(levels, unknown);
  }

  static List<String> _serializeTiers(UpgradeLevels levels) {
    return <String>[
      for (final axis in UpgradeAxis.values)
        if (levels.tierOf(axis) > 0) 'all.${axis.id}=${levels.tierOf(axis)}',
    ];
  }
}

class _Tiers {
  const _Tiers(this.levels, this.unknown);

  final UpgradeLevels levels;
  final List<String> unknown;
}
