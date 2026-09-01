import '../../game/domain/models/level.dart';
import 'upgrade_catalog.dart';
import 'upgrade_levels.dart';

/// Pure upgrade maths: multipliers, cost-table helpers and the base-stats →
/// built-stats resolver. No Flutter, no I/O, no mutation — safe to call from
/// anywhere, including plain unit tests.

/// Range multiplier at [tier]: `+8%` per tier (`×1.40` at tier 5).
double rangeMultiplier(int tier) => 1 + 0.08 * tier.clamp(0, kMaxTier);

/// Damage multiplier at [tier]: `+12%` per tier (`×1.60` at tier 5).
double damageMultiplier(int tier) => 1 + 0.12 * tier.clamp(0, kMaxTier);

/// Reload-time multiplier at [tier]: `−6%` per tier (`×0.70` at tier 5). A
/// tower's fire rate is divided by this, so tier 5 fires `×1.43` as fast.
double reloadMultiplier(int tier) => 1 - 0.06 * tier.clamp(0, kMaxTier);

/// Base catalog stats + purchased tiers → the stats a [Tower] is actually built
/// with. Returns a **new** [TowerStats]; never mutates [base]. `cost` is copied
/// verbatim so the build price and the 60% sell refund stay authored.
TowerStats applyUpgrades(TowerStats base, UpgradeLevels levels) {
  if (levels.isEmpty) return base;
  return base.copyWith(
    rangeCells: base.rangeCells * rangeMultiplier(levels.range),
    damage: base.damage * damageMultiplier(levels.damage),
    fireRate: base.fireRate / reloadMultiplier(levels.reload),
  );
}

/// Cost of buying [tier]. 0 for `tier <= 0` or `tier > kMaxTier`.
int costOfTier(int tier) {
  if (tier <= 0 || tier > kMaxTier) return 0;
  return kTierCosts[tier - 1];
}

/// Cumulative cost of owning [tier] (0 for non-positive, capped at [kMaxTier]).
int costToReach(int tier) {
  final capped = tier.clamp(0, kMaxTier);
  var sum = 0;
  for (var i = 0; i < capped; i++) {
    sum += kTierCosts[i];
  }
  return sum;
}
