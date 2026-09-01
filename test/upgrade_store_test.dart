import 'package:ban_heo/features/game/data/levels/level_catalog.dart';
import 'package:ban_heo/features/upgrades/data/upgrade_store.dart';
import 'package:ban_heo/features/upgrades/domain/upgrade_catalog.dart';
import 'package:ban_heo/features/upgrades/domain/upgrade_levels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _id(int index) => kLevelCatalog[index].id;

/// Awards the clear token for every level index, optionally flawless too.
Future<void> _awardAll({required bool flawless}) async {
  for (var i = 0; i < kLevelCatalog.length; i++) {
    await UpgradeStore.awardForClear(
      levelId: _id(i),
      levelIndex: i,
      flawless: flawless,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('fresh install is empty', () async {
    expect(await UpgradeStore.points(), 0);
    expect(await UpgradeStore.levels(), UpgradeLevels.none);
  });

  test('first clear grants the band payout', () async {
    final r = await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: false,
    );
    expect(r.points, 2);
    expect(await UpgradeStore.points(), 2);
  });

  test('re-claiming the same clear grants nothing', () async {
    await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: false,
    );
    final again = await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: false,
    );
    expect(again.points, 0);
    expect(await UpgradeStore.points(), 2);
  });

  test('flawless can be collected later, exactly once', () async {
    await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: false,
    );
    final late1 = await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: true,
    );
    expect(late1.points, 1);
    expect(late1.flawlessGranted, isTrue);

    final late2 = await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: true,
    );
    expect(late2.points, 0);
    expect(await UpgradeStore.points(), 3);
  });

  test('payout bands', () async {
    expect(
      (await UpgradeStore.awardForClear(
        levelId: _id(0),
        levelIndex: 0,
        flawless: false,
      ))
          .points,
      2,
    );
    expect(
      (await UpgradeStore.awardForClear(
        levelId: _id(5),
        levelIndex: 5,
        flawless: false,
      ))
          .points,
      3,
    );
    expect(
      (await UpgradeStore.awardForClear(
        levelId: _id(29),
        levelIndex: 29,
        flawless: false,
      ))
          .points,
      7,
    );
  });

  test('all clears = 135 points, plus flawless = 165', () async {
    await _awardAll(flawless: false);
    expect(await UpgradeStore.points(), 135);
    await _awardAll(flawless: true);
    expect(await UpgradeStore.points(), 165);
  });

  test('buy is rejected when short and writes nothing', () async {
    await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: false,
    ); // 2 points
    expect(await UpgradeStore.buy(UpgradeAxis.damage), isFalse);
    expect(await UpgradeStore.points(), 2);
    expect((await UpgradeStore.levels()).damage, 0);
  });

  test('buy succeeds with exact points', () async {
    await UpgradeStore.awardForClear(
      levelId: _id(5),
      levelIndex: 5,
      flawless: false,
    ); // 3 points
    expect(await UpgradeStore.buy(UpgradeAxis.damage), isTrue);
    expect(await UpgradeStore.points(), 0);
    expect((await UpgradeStore.levels()).damage, 1);
  });

  test('buying past the cap is rejected', () async {
    await _awardAll(flawless: true); // plenty
    for (var i = 0; i < kMaxTier; i++) {
      expect(await UpgradeStore.buy(UpgradeAxis.range), isTrue);
    }
    expect(await UpgradeStore.buy(UpgradeAxis.range), isFalse);
    expect((await UpgradeStore.levels()).range, kMaxTier);
  });

  test('balance is derived: earned 20, spent 8 -> 12', () async {
    for (final i in <int>[0, 5, 10, 15, 20]) {
      await UpgradeStore.awardForClear(
        levelId: _id(i),
        levelIndex: i,
        flawless: false,
      );
    }
    expect(await UpgradeStore.points(), 20);
    expect(await UpgradeStore.buy(UpgradeAxis.damage), isTrue); // -3
    expect(await UpgradeStore.buy(UpgradeAxis.damage), isTrue); // -5
    expect(await UpgradeStore.points(), 12);
    expect((await UpgradeStore.levels()).damage, 2);
  });

  test('reset clears both keys and reopens awards', () async {
    await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: false,
    );
    await UpgradeStore.reset();
    expect(await UpgradeStore.points(), 0);
    expect(await UpgradeStore.levels(), UpgradeLevels.none);

    final r = await UpgradeStore.awardForClear(
      levelId: _id(0),
      levelIndex: 0,
      flawless: false,
    );
    expect(r.points, 2);
  });

  test('unknown stored track id is ignored, not fatal', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'banheo.upgrades.tiers': <String>['bogus.thing=9', 'all.damage=2'],
    });
    final levels = await UpgradeStore.levels();
    expect(levels.damage, 2);
    expect(levels.range, 0);
  });

  test('a forward-compat track entry survives a v1 buy', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'banheo.upgrades.tiers': <String>['cannon.damage=2'],
    });
    await _awardAll(flawless: false); // plenty of points
    expect(await UpgradeStore.buy(UpgradeAxis.range), isTrue);

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('banheo.upgrades.tiers')!;
    expect(stored, contains('cannon.damage=2'));
    expect(stored, contains('all.range=1'));
  });

  test('claimed payout is not revalued when the catalog changes', () async {
    // Legacy-style claim would recompute from the (now shifted) index; a
    // baked-in token must keep its granted value.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'banheo.upgrades.awards': <String>['level_30:clear=7'],
    });
    expect(await UpgradeStore.points(), 7);
  });
}
