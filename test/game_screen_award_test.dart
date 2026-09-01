import 'package:ban_heo/features/game/domain/models/level.dart';
import 'package:ban_heo/features/game/presentation/screens/game_screen.dart';
import 'package:ban_heo/features/upgrades/data/upgrade_store.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A one-pig level that resolves in a fraction of a second: the pig sprints off
/// the short path (a "leak"). With [livesOnLeak] 0 the round is won flawless;
/// with 1 it is won with a life lost (not flawless), as long as [startingLives]
/// is >= 2.
LevelData _quickWin({required int startingLives, required int livesOnLeak}) =>
    LevelData(
      name: 'QW',
      cellSize: 32,
      gridCols: 8,
      gridRows: 6,
      startingLives: startingLives,
      startingGold: 0,
      timeBetweenWaves: 0.01,
      pathCells: <Vector2>[Vector2(0, 2), Vector2(1, 2)],
      buildSpotCells: <Vector2>[Vector2(3, 3)],
      waves: const <WaveData>[
        WaveData([SpawnGroup(count: 1, interval: 0.1)]),
      ],
      enemy: EnemyStats(
        maxHp: 10,
        speed: 600,
        goldOnKill: 0,
        livesOnLeak: livesOnLeak,
      ),
      towers: const <TowerStats>[
        TowerStats(
          kind: TowerKind.arrow,
          name: 'a',
          description: 'd',
          cost: 10,
          rangeCells: 2,
          fireRate: 1,
          damage: 5,
          projectileSpeed: 100,
        ),
      ],
    );

Future<void> _pumpUntilWin(WidgetTester tester) async {
  for (var i = 0; i < 200 && find.text('Thắng!').evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 32));
  }
  expect(find.text('Thắng!'), findsOneWidget);
}

Future<void> _pumpGame(
  WidgetTester tester, {
  required LevelData level,
  required String levelId,
  required int levelIndex,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(
        key: ValueKey<String>('$levelId-${DateTime.now().microsecondsSinceEpoch}'),
        level: level,
        levelId: levelId,
        levelIndex: levelIndex,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('first campaign win shows the +N line and banks the points', (
    tester,
  ) async {
    await _pumpGame(
      tester,
      level: _quickWin(startingLives: 3, livesOnLeak: 1),
      levelId: 'level_01',
      levelIndex: 0,
    );
    await _pumpUntilWin(tester);

    expect(find.textContaining('+2 điểm nâng cấp!'), findsOneWidget);
    expect(find.textContaining('Không rò con nào'), findsNothing);
    expect(await UpgradeStore.points(), 2);
  });

  testWidgets('winning the same level again shows no point line', (tester) async {
    await UpgradeStore.awardForClear(
      levelId: 'level_01',
      levelIndex: 0,
      flawless: false,
    );

    await _pumpGame(
      tester,
      level: _quickWin(startingLives: 3, livesOnLeak: 1),
      levelId: 'level_01',
      levelIndex: 0,
    );
    await _pumpUntilWin(tester);

    expect(find.textContaining('điểm nâng cấp'), findsNothing);
    expect(await UpgradeStore.points(), 2);
  });

  testWidgets('a flawless win adds the bonus line exactly once', (tester) async {
    await _pumpGame(
      tester,
      level: _quickWin(startingLives: 3, livesOnLeak: 0),
      levelId: 'level_02',
      levelIndex: 1,
    );
    await _pumpUntilWin(tester);

    expect(find.textContaining('+3 điểm nâng cấp!'), findsOneWidget);
    expect(find.textContaining('Không rò con nào — thưởng thêm 1 điểm!'),
        findsOneWidget);
    expect(await UpgradeStore.points(), 3);
  });
}
