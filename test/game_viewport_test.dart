import 'package:ban_heo/features/game/presentation/widgets/game_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('zoom buttons animate, preserve taps and reset the view', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameViewport(
            child: Center(
              child: GestureDetector(
                onTap: () => taps++,
                child: const SizedBox(
                  key: Key('target'),
                  width: 60,
                  height: 60,
                  child: ColoredBox(color: Colors.green),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Phóng to'));
    await tester.pumpAndSettle();
    expect(find.text('1.3×'), findsOneWidget);
    await tester.tap(find.byKey(const Key('target')));
    expect(taps, 1);
    await tester.tap(find.text('1.3×'));
    await tester.pumpAndSettle();
    expect(find.text('1.0×'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two fingers zoom and drag without triggering a tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameViewport(
            child: GestureDetector(
              onTap: () => taps++,
              child: const ColoredBox(color: Colors.green),
            ),
          ),
        ),
      ),
    );
    final first = await tester.startGesture(const Offset(300, 250), pointer: 1);
    final second = await tester.startGesture(
      const Offset(500, 250),
      pointer: 2,
    );
    await first.moveTo(const Offset(220, 270));
    await second.moveTo(const Offset(580, 270));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });
}
