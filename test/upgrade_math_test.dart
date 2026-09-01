import 'package:ban_heo/features/game/data/levels/tower_catalog.dart';
import 'package:ban_heo/features/game/domain/models/level.dart';
import 'package:ban_heo/features/upgrades/domain/upgrade_catalog.dart';
import 'package:ban_heo/features/upgrades/domain/upgrade_levels.dart';
import 'package:ban_heo/features/upgrades/domain/upgrade_math.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = TowerStats(
  kind: TowerKind.arrow,
  name: 'Tháp Bắn Tên',
  description: 'test blurb',
  cost: 50,
  rangeCells: 2.8,
  fireRate: 1.6,
  damage: 12,
  projectileSpeed: 440,
);

const _maxed = UpgradeLevels(range: 5, damage: 5, reload: 5);

void main() {
  group('multipliers', () {
    test('range: 0 -> 1, 5 -> 1.40', () {
      expect(rangeMultiplier(0), closeTo(1, 1e-9));
      expect(rangeMultiplier(5), closeTo(1.40, 1e-9));
    });

    test('damage: 5 -> 1.60', () {
      expect(damageMultiplier(0), closeTo(1, 1e-9));
      expect(damageMultiplier(5), closeTo(1.60, 1e-9));
    });

    test('reload: 5 -> 0.70', () {
      expect(reloadMultiplier(0), closeTo(1, 1e-9));
      expect(reloadMultiplier(5), closeTo(0.70, 1e-9));
    });
  });

  test('applyUpgrades(base, none) equals base on every field', () {
    final r = applyUpgrades(_base, UpgradeLevels.none);
    expect(r.kind, _base.kind);
    expect(r.name, _base.name);
    expect(r.description, _base.description);
    expect(r.cost, _base.cost);
    expect(r.rangeCells, _base.rangeCells);
    expect(r.fireRate, _base.fireRate);
    expect(r.damage, _base.damage);
    expect(r.projectileSpeed, _base.projectileSpeed);
    expect(r.splashRadiusCells, _base.splashRadiusCells);
    expect(r.splashDamageFactor, _base.splashDamageFactor);
    expect(r.burnDps, _base.burnDps);
    expect(r.burnDuration, _base.burnDuration);
  });

  test('maxed arrow: range 3.92, damage 19.2, fireRate 2.286, cost still 50', () {
    final r = applyUpgrades(_base, _maxed);
    expect(r.rangeCells, closeTo(3.92, 1e-6));
    expect(r.damage, closeTo(19.2, 1e-6));
    expect(r.fireRate, closeTo(2.2857, 1e-3));
    expect(r.cost, 50);
  });

  test('applyUpgrades does not mutate its argument', () {
    applyUpgrades(_base, _maxed);
    expect(_base.rangeCells, 2.8);
    expect(_base.damage, 12);
    expect(_base.fireRate, 1.6);
    expect(_base.cost, 50);
  });

  test('non-scaled fields pass through untouched', () {
    final cannon = kTowerCatalog['cannon']!;
    final flame = kTowerCatalog['flamingArrow']!;
    final rc = applyUpgrades(cannon, _maxed);
    final rf = applyUpgrades(flame, _maxed);

    expect(rc.splashRadiusCells, cannon.splashRadiusCells);
    expect(rc.splashDamageFactor, cannon.splashDamageFactor);
    expect(rc.projectileSpeed, cannon.projectileSpeed);
    expect(rc.kind, cannon.kind);
    expect(rc.name, cannon.name);
    expect(rc.description, cannon.description);

    expect(rf.burnDps, flame.burnDps);
    expect(rf.burnDuration, flame.burnDuration);
    expect(rf.projectileSpeed, flame.projectileSpeed);
  });

  test('every catalog tower survives max upgrades with sane stats', () {
    for (final tower in kTowerCatalog.values) {
      final r = applyUpgrades(tower, _maxed);
      for (final v in <double>[r.rangeCells, r.damage, r.fireRate]) {
        expect(v.isFinite, isTrue);
        expect(v, greaterThan(0));
      }
      expect(r.rangeCells, greaterThan(tower.rangeCells));
      expect(r.damage, greaterThan(tower.damage));
      expect(r.fireRate, greaterThan(tower.fireRate));
    }
  });

  test('cost table', () {
    expect(kTierCosts.length, kMaxTier);
    expect(costOfTier(0), 0);
    expect(costOfTier(1), 3);
    expect(costOfTier(5), 22);
    expect(costOfTier(6), 0);
    expect(costToReach(0), 0);
    expect(costToReach(2), 8);
    expect(costToReach(5), 53);
    expect(costToReach(99), 53);
  });
}
