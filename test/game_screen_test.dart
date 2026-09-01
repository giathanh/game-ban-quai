import 'package:ban_heo/features/game/data/levels/level_catalog.dart';
import 'package:ban_heo/features/game/engine/ban_heo_game.dart';
import 'package:ban_heo/features/game/presentation/screens/game_screen.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/load_level.dart';

void main() {
  // Smoke-test a spread of the campaign (all 3 handcrafted + generated samples
  // across the difficulty curve). `tmx_level_loader_test` parses every catalog
  // entry; this just proves the parsed geometry actually runs in the engine.
  final sample = <int>{0, 1, 2, 3, kLevelCatalog.length ~/ 2, kLevelCatalog.length - 1};
  for (final index in sample) {
    final info = kLevelCatalog[index];
    testWidgets('GameScreen runs "${info.id}" without throwing', (tester) async {
      final level = loadLevelFromFile(info.tmxAsset);
      await tester.pumpWidget(MaterialApp(home: GameScreen(level: level)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(GameWidget<BanHeoGame>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'GameScreen lays the GameWidget out at a non-zero size and does not throw',
    (tester) async {
      final level = loadLevelFromFile('assets/levels/level_01.tmx');
      await tester.pumpWidget(MaterialApp(home: GameScreen(level: level)));
      // A couple of frames so the HUD/overlay widgets build (this is where the
      // pre-load LateInitializationError used to fire) without pumpAndSettle,
      // which would spin forever on the game loop ticker.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final gameWidget = find.byType(GameWidget<BanHeoGame>);
      expect(gameWidget, findsOneWidget);

      final size = tester.getSize(gameWidget);
      expect(
        size.width,
        greaterThan(0),
        reason: 'Stack must not collapse to 0',
      );
      expect(
        size.height,
        greaterThan(0),
        reason: 'Stack must not collapse to 0',
      );

      expect(tester.takeException(), isNull);
    },
  );
}
