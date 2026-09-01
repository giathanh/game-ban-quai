import 'package:flutter/material.dart';

import '../../domain/upgrade_catalog.dart';
import '../../domain/upgrade_math.dart';

/// One row of the upgrade screen: a single axis, its pips, its current/next
/// effect and the buy button.
class UpgradeTrackCard extends StatelessWidget {
  const UpgradeTrackCard({
    required this.track,
    required this.tier,
    required this.points,
    required this.onBuy,
    this.busy = false,
    super.key,
  });

  final UpgradeTrack track;

  /// Tiers already purchased on this track (0..kMaxTier).
  final int tier;

  /// The player's current unspent balance.
  final int points;

  /// Called when the buy button is tapped. Never called when maxed / short.
  final VoidCallback onBuy;

  /// A purchase is in flight — disable the button to block a double-click.
  final bool busy;

  IconData get _icon => switch (track.axis) {
    UpgradeAxis.range => Icons.my_location,
    UpgradeAxis.damage => Icons.bolt,
    UpgradeAxis.reload => Icons.timer_outlined,
  };

  String _fmt(int percent) => percent >= 0 ? '+$percent%' : '$percent%';

  @override
  Widget build(BuildContext context) {
    final maxed = tier >= kMaxTier;
    final nextCost = costOfTier(tier + 1);
    final canAfford = !maxed && points >= nextCost;

    final String reason;
    if (maxed) {
      reason = 'Đã tối đa';
    } else if (!canAfford) {
      reason = 'Chưa đủ điểm';
    } else {
      reason = '';
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DBB0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B9B78).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icon, color: const Color(0xFF164F3B), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF164F3B),
                      ),
                    ),
                    Text(
                      track.blurb,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF5B6F57),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 1; i <= kMaxTier; i++) ...[
                if (i > 1) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: i <= tier
                          ? const Color(0xFF2B9B78)
                          : const Color(0xFF2B9B78).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Hiện tại: ${_fmt(track.percentAt(tier))} ${track.unit}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B4A38),
                ),
              ),
              if (!maxed)
                Text(
                  '  → ${_fmt(track.percentAt(tier + 1))}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B7A3D),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: (canAfford && !busy) ? onBuy : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9A79),
                    disabledBackgroundColor: const Color(0xFFBFC7B7),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: Text(
                    maxed ? 'Đã tối đa' : 'Nâng cấp · $nextCost điểm',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              if (reason.isNotEmpty && !maxed) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB23B3B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
