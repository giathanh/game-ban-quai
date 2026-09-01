import 'upgrade_catalog.dart';

/// Immutable snapshot of the tiers the player has purchased on each axis.
///
/// Value type: `==` / `hashCode` / `copyWith`, plus [UpgradeLevels.none] for the
/// zero state. Each field is clamped to `0..kMaxTier` by every producer.
class UpgradeLevels {
  const UpgradeLevels({this.range = 0, this.damage = 0, this.reload = 0});

  /// All tracks at tier 0.
  static const UpgradeLevels none = UpgradeLevels();

  final int range;
  final int damage;
  final int reload;

  int tierOf(UpgradeAxis axis) => switch (axis) {
    UpgradeAxis.range => range,
    UpgradeAxis.damage => damage,
    UpgradeAxis.reload => reload,
  };

  /// True when nothing has been bought — the HUD chip is then hidden.
  bool get isEmpty => range == 0 && damage == 0 && reload == 0;

  /// Points sunk into the current tiers (sum of the cost-table prefixes).
  int get pointsSpent =>
      _prefixCost(range) + _prefixCost(damage) + _prefixCost(reload);

  static int _prefixCost(int tier) {
    final capped = tier.clamp(0, kMaxTier);
    var sum = 0;
    for (var i = 0; i < capped; i++) {
      sum += kTierCosts[i];
    }
    return sum;
  }

  UpgradeLevels copyWith({int? range, int? damage, int? reload}) {
    return UpgradeLevels(
      range: range ?? this.range,
      damage: damage ?? this.damage,
      reload: reload ?? this.reload,
    );
  }

  /// A copy with [axis] set to [tier].
  UpgradeLevels withTier(UpgradeAxis axis, int tier) => switch (axis) {
    UpgradeAxis.range => copyWith(range: tier),
    UpgradeAxis.damage => copyWith(damage: tier),
    UpgradeAxis.reload => copyWith(reload: tier),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UpgradeLevels &&
            runtimeType == other.runtimeType &&
            range == other.range &&
            damage == other.damage &&
            reload == other.reload;
  }

  @override
  int get hashCode => Object.hash(range, damage, reload);

  @override
  String toString() =>
      'UpgradeLevels(range: $range, damage: $damage, reload: $reload)';
}
