import 'package:flutter/foundation.dart';

/// Tracks the player's gold: earned on kills, spent on builds, refunded on sell.
///
/// Pure Dart + [ChangeNotifier] so the HUD can rebuild and the logic stays
/// unit-testable without a running game.
class Economy extends ChangeNotifier {
  Economy({required int startingGold}) : _gold = startingGold;

  int _gold;
  int get gold => _gold;

  /// True when [cost] can currently be paid.
  bool canAfford(int cost) => _gold >= cost;

  /// Adds [amount] gold. Ignores non-positive amounts.
  void earn(int amount) {
    if (amount <= 0) {
      return;
    }
    _gold += amount;
    notifyListeners();
  }

  /// Spends [cost] gold if affordable. Returns whether the spend happened.
  bool trySpend(int cost) {
    if (cost <= 0 || _gold < cost) {
      return false;
    }
    _gold -= cost;
    notifyListeners();
    return true;
  }

  /// Refund granted when selling something that cost [originalCost].
  static int refundValue(int originalCost) => (originalCost * 0.6).floor();
}
