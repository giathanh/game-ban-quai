/// Identifiers and static tables for the three account-wide upgrade tracks.
///
/// Pure data — no Flutter, no I/O — so the engine, the store and the widgets can
/// all share it without dragging bindings into logic-only tests. Track ids are
/// of the form `<scope>.<axis>`; v1 only ever writes the `all.*` scope, but the
/// reader is written so a future `cannon.damage` needs no storage migration.
library;

/// The three upgrade axes. [id] is the stable string used inside persisted track
/// ids (`all.range`) and must never change.
enum UpgradeAxis {
  range('range'),
  damage('damage'),
  reload('reload');

  const UpgradeAxis(this.id);

  final String id;

  /// The axis whose [id] matches, or null for an unknown string (forward
  /// compatibility: unknown persisted tracks are ignored, not fatal).
  static UpgradeAxis? fromId(String id) {
    for (final axis in UpgradeAxis.values) {
      if (axis.id == id) return axis;
    }
    return null;
  }
}

/// Highest tier a single track can reach.
const int kMaxTier = 5;

/// Point cost of each tier. `kTierCosts[t - 1]` is the price of buying tier `t`.
const List<int> kTierCosts = <int>[3, 5, 9, 14, 22];

/// Static, user-facing description of one purchasable track.
class UpgradeTrack {
  const UpgradeTrack({
    required this.axis,
    required this.label,
    required this.blurb,
    required this.unit,
    required this.percentPerTier,
  });

  final UpgradeAxis axis;

  /// Vietnamese track name, e.g. `Phạm vi`.
  final String label;

  /// One-line pitch shown under the label.
  final String blurb;

  /// Short noun used in the effect readout, e.g. `phạm vi`.
  final String unit;

  /// Signed percentage step per tier: `+8`, `+12` or `-6`.
  final int percentPerTier;

  /// Cumulative signed percentage effect at [tier] (tier 0 → 0).
  int percentAt(int tier) => percentPerTier * tier.clamp(0, kMaxTier);
}

/// One entry per axis, in screen order.
const List<UpgradeTrack> kUpgradeCatalog = <UpgradeTrack>[
  UpgradeTrack(
    axis: UpgradeAxis.range,
    label: 'Phạm vi',
    blurb: 'Tháp bắn xa hơn, phủ được nhiều khúc sông hơn.',
    unit: 'phạm vi',
    percentPerTier: 8,
  ),
  UpgradeTrack(
    axis: UpgradeAxis.damage,
    label: 'Sát thương',
    blurb: 'Mỗi phát bắn đau hơn, hạ heo nhanh hơn.',
    unit: 'sát thương',
    percentPerTier: 12,
  ),
  UpgradeTrack(
    axis: UpgradeAxis.reload,
    label: 'Thời gian chờ',
    blurb: 'Giảm thời gian nạp đạn, tháp bắn dồn dập hơn.',
    unit: 'thời gian chờ',
    percentPerTier: -6,
  ),
];

/// The catalog entry for [axis].
UpgradeTrack trackFor(UpgradeAxis axis) =>
    kUpgradeCatalog.firstWhere((t) => t.axis == axis);
