import 'package:ban_heo/features/game/engine/systems/economy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts with the configured amount of gold', () {
    final economy = Economy(startingGold: 100);
    expect(economy.gold, 100);
  });

  test('trySpend deducts and returns true when affordable', () {
    final economy = Economy(startingGold: 100);
    expect(economy.trySpend(50), isTrue);
    expect(economy.gold, 50);
  });

  test('trySpend is a no-op and returns false when too expensive', () {
    final economy = Economy(startingGold: 40);
    expect(economy.trySpend(50), isFalse);
    expect(economy.gold, 40);
  });

  test('canAfford reflects the current balance', () {
    final economy = Economy(startingGold: 50);
    expect(economy.canAfford(50), isTrue);
    expect(economy.canAfford(51), isFalse);
  });

  test('earn adds gold and ignores non-positive amounts', () {
    final economy = Economy(startingGold: 0);
    economy.earn(8);
    economy.earn(0);
    economy.earn(-5);
    expect(economy.gold, 8);
  });

  test('notifies listeners only when the balance actually changes', () {
    final economy = Economy(startingGold: 100);
    var notifications = 0;
    economy.addListener(() => notifications++);

    economy.earn(8); // +1
    economy.trySpend(10); // +1
    economy.trySpend(9999); // rejected, no notification
    economy.earn(0); // ignored, no notification

    expect(notifications, 2);
    expect(economy.gold, 98);
  });

  test('refundValue is 60% of the original cost, floored', () {
    expect(Economy.refundValue(50), 30);
    expect(Economy.refundValue(75), 45);
    expect(Economy.refundValue(10), 6);
  });

  test('kill/build cycle from the Level 1 numbers stays consistent', () {
    final economy = Economy(startingGold: 100);
    expect(economy.trySpend(50), isTrue); // build a Pigshooter
    expect(economy.gold, 50);
    for (var i = 0; i < 5; i++) {
      economy.earn(8); // 5 pig kills
    }
    expect(economy.gold, 90);
    expect(economy.trySpend(50), isTrue); // second Pigshooter
    expect(economy.gold, 40);
    expect(economy.trySpend(50), isFalse); // cannot afford a third
  });
}
