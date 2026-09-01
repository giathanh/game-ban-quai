import 'package:flutter/material.dart';

import '../../data/levels/level_catalog.dart';
import '../../domain/models/level.dart';
import 'game_screen.dart';

/// Loads the [LevelData] for a catalog index (the `.tmx` parse happens here) and
/// then hands off to [GameScreen]. Kept as its own route so "play", "retry" and
/// "next level" all funnel through the same loading + error path.
class LevelLoaderScreen extends StatefulWidget {
  const LevelLoaderScreen({required this.levelIndex, super.key});

  final int levelIndex;

  @override
  State<LevelLoaderScreen> createState() => _LevelLoaderScreenState();
}

class _LevelLoaderScreenState extends State<LevelLoaderScreen> {
  late Future<LevelData> _future = loadCatalogLevel(widget.levelIndex);

  void _retryLoad() {
    setState(() => _future = loadCatalogLevel(widget.levelIndex));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LevelData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF12321A),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF12321A),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_rounded,
                        color: Colors.white70, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Không nạp được màn này.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton(
                          onPressed: _retryLoad,
                          child: const Text('Thử lại'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Quay lại'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return GameScreen(
          level: snapshot.data!,
          levelIndex: widget.levelIndex,
        );
      },
    );
  }
}
