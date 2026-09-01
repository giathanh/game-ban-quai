import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.primary = false,
    this.badge,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final bool primary;

  /// Optional trailing pill (e.g. the unspent upgrade-point count). Hidden when
  /// null.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? const Color(0xFFFF8B4B)
        : const Color(0xFF2D9A79);
    final shadow = primary ? const Color(0xFFB94D28) : const Color(0xFF17664F);
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(56),
      backgroundColor: background,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.42),
          width: 1.5,
        ),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 5))],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 24),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (badge != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: shadow,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
