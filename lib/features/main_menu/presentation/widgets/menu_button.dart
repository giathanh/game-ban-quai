import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size(220, 52),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
    return primary
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton.tonal(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          );
  }
}
