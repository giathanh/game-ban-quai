import 'package:flutter/material.dart';

/// One row in the level picker. Tapping is disabled (and the card dimmed) when
/// [onTap] is null / [locked] is true.
class LevelCard extends StatelessWidget {
  const LevelCard({
    required this.number,
    required this.title,
    required this.tagline,
    required this.locked,
    required this.cleared,
    required this.onTap,
    super.key,
  });

  final int number;
  final String title;
  final String tagline;
  final bool locked;
  final bool cleared;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = locked ? const Color(0xFF20402C) : const Color(0xFFF8F1D8);
    final textColor =
        locked ? Colors.white38 : const Color(0xFF164F3B);

    return Opacity(
      opacity: locked ? 0.75 : 1,
      child: Material(
        color: base,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                _Badge(number: number, locked: locked, cleared: cleared),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        locked ? 'Qua màn trước để mở khoá' : tagline,
                        style: TextStyle(
                          color: locked
                              ? Colors.white38
                              : const Color(0xFF5B6F57),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  locked
                      ? Icons.lock_rounded
                      : (cleared
                          ? Icons.replay_rounded
                          : Icons.play_arrow_rounded),
                  color: locked ? Colors.white38 : const Color(0xFF2B9B78),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.number,
    required this.locked,
    required this.cleared,
  });

  final int number;
  final bool locked;
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    final color = locked
        ? const Color(0xFF3A5B45)
        : (cleared ? const Color(0xFF2B9B78) : const Color(0xFFFF8B4B));
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: cleared && !locked
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
          : Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}
