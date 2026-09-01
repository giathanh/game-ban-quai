import 'package:flutter/material.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.onResume, super.key});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tạm dừng',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: onResume, child: const Text('Tiếp tục')),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Về menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
