import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({
    required this.label,
    required this.onPressed,
    required this.icon,
    this.primary = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final bool primary;

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
        label: Text(label),
      ),
    );
  }
}
