import 'package:ban_heo/features/upgrades/presentation/screens/upgrade_screen.dart';
import 'package:ban_heo/features/upgrades/presentation/widgets/upgrade_track_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: UpgradeScreen()));
  await tester.pump(); // kick the load future
  await tester.pump(const Duration(milliseconds: 50)); // let setState land
}

Iterable<FilledButton> _buyButtons(WidgetTester tester) => tester
    .widgetList<FilledButton>(find.byType(FilledButton))
    .where((b) => (b.child is Text) && ((b.child! as Text).data ?? '').isNotEmpty)
    .where(
      (b) =>
          ((b.child! as Text).data!).startsWith('Nâng cấp') ||
          (b.child! as Text).data == 'Đã tối đa',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('with no points every buy button is disabled', (tester) async {
    await _pump(tester);

    final buttons = _buyButtons(tester).toList();
    expect(buttons, hasLength(3));
    for (final b in buttons) {
      expect(b.onPressed, isNull);
    }
    expect(find.text('Điểm nâng cấp: 0'), findsOneWidget);
  });

  testWidgets('with 3 points the range track can be bought', (tester) async {
    // level index 5 clears for a payout of 3.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'banheo.upgrades.awards': <String>['level_06:clear'],
    });
    await _pump(tester);

    expect(find.text('Điểm nâng cấp: 3'), findsOneWidget);

    final rangeCard = find.ancestor(
      of: find.text('Phạm vi'),
      matching: find.byType(UpgradeTrackCard),
    );
    final buyButton = find.descendant(
      of: rangeCard,
      matching: find.widgetWithText(FilledButton, 'Nâng cấp · 3 điểm'),
    );
    expect(tester.widget<FilledButton>(buyButton).onPressed, isNotNull);

    await tester.tap(buyButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Điểm nâng cấp: 0'), findsOneWidget);
    expect(find.text('Hiện tại: +8% phạm vi'), findsOneWidget);
  });

  testWidgets('a maxed track shows "Đã tối đa" and is disabled', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'banheo.upgrades.awards': <String>[
        for (var i = 1; i <= 30; i++)
          'level_${i.toString().padLeft(2, '0')}:clear',
      ],
      'banheo.upgrades.tiers': <String>['all.damage=5'],
    });
    await _pump(tester);

    final damageCard = find.ancestor(
      of: find.text('Sát thương'),
      matching: find.byType(UpgradeTrackCard),
    );
    final maxedButton = find.descendant(
      of: damageCard,
      matching: find.widgetWithText(FilledButton, 'Đã tối đa'),
    );
    expect(maxedButton, findsOneWidget);
    expect(tester.widget<FilledButton>(maxedButton).onPressed, isNull);
  });
}
