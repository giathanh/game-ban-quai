import 'package:flutter/material.dart';

import '../../../game/data/levels/level_catalog.dart';
import '../../../game/data/progress_store.dart';
import '../../../game/presentation/screens/level_loader_screen.dart';
import '../widgets/level_card.dart';

/// Scrollable list of every level in [kLevelCatalog]. Locked levels are shown
/// but disabled; clearing a level unlocks the next one (persisted via
/// [ProgressStore]).
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int _highestUnlocked = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final unlocked = await ProgressStore.highestUnlockedIndex();
    if (!mounted) {
      return;
    }
    setState(() {
      _highestUnlocked = unlocked;
      _loading = false;
    });
  }

  Future<void> _openLevel(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LevelLoaderScreen(levelIndex: index),
      ),
    );
    // The player may have cleared a level while away — re-read progress.
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12321A),
      appBar: AppBar(
        title: const Text('CHỌN MÀN'),
        backgroundColor: const Color(0xFF164F3B),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                itemCount: kLevelCatalog.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final info = kLevelCatalog[index];
                  final unlocked = index <= _highestUnlocked;
                  final cleared = index < _highestUnlocked;
                  return LevelCard(
                    number: index + 1,
                    title: info.title,
                    tagline: info.tagline,
                    locked: !unlocked,
                    cleared: cleared,
                    onTap: unlocked ? () => _openLevel(index) : null,
                  );
                },
              ),
            ),
    );
  }
}
