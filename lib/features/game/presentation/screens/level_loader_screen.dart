import 'package:flutter/material.dart';

import '../../../../core/platform/orientation_lock.dart';
import '../../data/levels/level_catalog.dart';
import '../../domain/models/level.dart';
import 'game_screen.dart';

/// Owns a whole play session: it loads the `.tmx` for the current level, hands
/// off to [GameScreen], and handles "retry" / "next level" by swapping the
/// level in place (no route juggling). It is the single route that stays mounted
/// for the duration of play, so it is also the right place to hold the
/// landscape orientation lock.
class LevelLoaderScreen extends StatefulWidget {
  const LevelLoaderScreen({required this.levelIndex, super.key});

  final int levelIndex;

  @override
  State<LevelLoaderScreen> createState() => _LevelLoaderScreenState();
}

class _LevelLoaderScreenState extends State<LevelLoaderScreen> {
  late int _index = widget.levelIndex;

  /// Bumped on every (re)load so [GameScreen]'s state is rebuilt from scratch.
  int _attempt = 0;
  late Future<LevelData> _future = loadCatalogLevel(_index);

  @override
  void initState() {
    super.initState();
    OrientationLock.landscape();
  }

  @override
  void dispose() {
    OrientationLock.portrait();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _attempt++;
      _future = loadCatalogLevel(_index);
    });
  }

  void _goToNextLevel() {
    if (!hasLevelAt(_index + 1)) {
      return;
    }
    setState(() {
      _index++;
      _attempt++;
      _future = loadCatalogLevel(_index);
    });
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
          return _LoadError(error: snapshot.error, onRetry: _reload);
        }
        return GameScreen(
          key: ValueKey<String>('${_index}_$_attempt'),
          level: snapshot.data!,
          levelIndex: _index,
          onReplay: _reload,
          onNext: hasLevelAt(_index + 1) ? _goToNextLevel : null,
        );
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: onRetry,
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
}
