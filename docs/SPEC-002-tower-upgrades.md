# SPEC-002 — Tower upgrades / skill points

Author: game-lead · Status: ready for implementation · Target: Web (preview), Android, iOS
Depends on: SPEC-001 (shipped), the 30-level campaign (`kLevelCatalog`), `ProgressStore`.

## Goal

> "Thêm tính năng nâng cấp tháp sau mỗi màn như nâng cấp phạm vi, độ sát thương,
> thời gian chờ."

Clearing a level grants **điểm nâng cấp** (upgrade points). The player spends them
**outside of a round**, on a dedicated **Nâng cấp** screen reached from the main menu
and from level select. Purchases are **global** (they buff every tower the player
builds, in every level) and **persistent** across app restarts.

Three axes, exactly as requested:

| Axis (id)  | Vietnamese label     | Effect                        |
| ---------- | -------------------- | ----------------------------- |
| `range`    | Phạm vi              | + tower range                 |
| `damage`   | Sát thương           | + direct-hit damage           |
| `reload`   | Thời gian chờ        | − reload time (faster firing) |

## Non-goals (explicitly out of scope)

- **Per-tower in-round upgrades** (tap a placed tower → pay gold → level it up). Different
  feature, different economy. The build/sell menu keeps its current two states.
- **Per-tower-kind tracks** (a separate range track for cannon vs arrow). The data model is
  built to allow it later — see "Key model decision" — but v1 ships 3 account-wide tracks.
- New tower kinds, new upgrade axes (splash radius, burn, projectile speed, gold income).
- Respec / refund of spent points. Only a full `reset()` for debug + tests.
- Upgraded-tower VFX (auras, tier pips on the sprite). HUD/build-menu numbers only.
- Retuning `tool/generate_levels.dart`. See "Balance finding" — this is a real problem, but
  it is SPEC-003, not this spec.

## Key model decision — account-wide now, per-kind-ready

Upgrade levels are stored keyed by a **string track id** of the form `<scope>.<axis>`.
v1 only ever writes `all.range`, `all.damage`, `all.reload`. A future spec can introduce
`cannon.damage` without a storage migration, because the reader ignores unknown keys and
the resolver falls back to `all.*` when a kind-specific track is absent.

Rationale for account-wide in v1: 3 kinds × 3 axes = 9 tracks would split the point budget
three ways, make every early purchase feel weightless, and needs a screen that does not fit
one portrait page. 3 tracks × 5 tiers = 15 nodes reads at a glance.

## Points economy

### Income

Points are awarded by **award tokens**, one per (level, reason). A token can be claimed
**at most once, ever** — replaying a cleared level pays nothing, so there is no grind loop.

| Token                    | When                                              | Points                       |
| ------------------------ | ------------------------------------------------- | ---------------------------- |
| `<levelId>:clear`        | First time the level is won                       | `2 + (levelIndex ~/ 5)`      |
| `<levelId>:flawless`     | Won with `lives == level.startingLives` (no leak) | `1`                          |

`levelId` is the stable `LevelInfo.id` (`level_07`), **not** the index — indices shift if
levels are ever reordered, ids are contractually stable (see `level_catalog.dart`).

Clear payouts by band: levels 1–5 → 2, 6–10 → 3, 11–15 → 4, 16–20 → 5, 21–25 → 6, 26–30 → 7.

- **Total from clears across all 30 levels: 135 points.**
- **Plus flawless: up to 165 points.**

The flawless token is claimable independently of the clear token, so a player who scraped
through level 7 at 2 lives can come back later, replay it cleanly, and collect the missing
+1 (but not a second clear payout).

### Costs

Five tiers per axis, escalating:

| Tier | Cost | Cumulative |
| ---- | ---- | ---------- |
| 1    | 3    | 3          |
| 2    | 5    | 8          |
| 3    | 9    | 17         |
| 4    | 14   | 31         |
| 5    | 22   | 53         |

**53 per axis · 159 to max all three.**

Budget shape this produces:

- After level 5 (10 pts): tier 1 on all three axes, or tier 1+2 on one. Visible immediately.
- After level 10 (25 pts): ~tier 3 on a favourite axis plus tier 1 elsewhere.
- After level 20 (70 pts): one axis maxed, or tier 3 across the board.
- After level 30, clears only (135 pts): **two axes maxed and tier 3 of the third — 12 short
  of maxing everything.** Real build choices, no "everything by level 22".
- A 100%-flawless run (165 pts) maxes all three with 6 to spare, and only at the very end.

### Balance — effect magnitudes

Effects are linear in tier and applied multiplicatively to the catalog base stats.

| Axis     | Per tier          | At tier 5                     |
| -------- | ----------------- | ----------------------------- |
| `range`  | `+8%` range       | `×1.40` range (`×1.96` area)  |
| `damage` | `+12%` damage     | `×1.60` damage                |
| `reload` | `−6%` reload time | `×0.70` reload → `×1.43` rate |

Fully maxed: **DPS ×2.29**, range ×1.40. Because a longer range means more towers cover any
given stretch of the river, effective throughput at a choke point lands around **×3**.

Worked example, `arrow` (base: 2.8 cells, 12 dmg, 1.6/s = 19.2 dps):
maxed → 3.92 cells, 19.2 dmg, 2.29/s = **43.9 dps**.

### Balance finding (report to the user, do not fix here)

I costed the late campaign while tuning this. **Level 30 looks unwinnable even with every
upgrade maxed**, and that is a pre-existing curve bug, not something upgrades should paper
over. Rough numbers from `tool/generate_levels.dart` at level 30: enemy HP 735, 18 waves,
~445 pigs → ~327,000 HP to remove, against 9 build spots × ~28 effective dps × ~200 s of
round time ≈ 50,000 damage (≈115,000 with upgrades maxed, plus cannon splash). Still ~3×
short.

Therefore this spec deliberately **does not** inflate upgrade magnitudes to compensate. The
target for these numbers is: *maxed upgrades make level N feel roughly like level N−8 does
today.* The curve itself (the `(l-1)² × 0.5` HP term and the 18-wave finales) should be
retuned in a follow-up spec against the new upgraded-tower baseline.

## Data model

`lib/features/upgrades/domain/upgrade_catalog.dart`

```dart
enum UpgradeAxis { range, damage, reload }   // id: 'range' | 'damage' | 'reload'

/// Static description of one purchasable track (label, blurb, icon, per-tier
/// effect step, cost table). One entry per axis in `kUpgradeCatalog`.
class UpgradeTrack { ... }

const int kMaxTier = 5;
const List<int> kTierCosts = [3, 5, 9, 14, 22];   // index = tier - 1
```

`lib/features/upgrades/domain/upgrade_levels.dart`

```dart
/// Immutable snapshot of purchased tiers. Value type: `==`, `hashCode`,
/// `copyWith`, `UpgradeLevels.none` (all zero).
class UpgradeLevels {
  const UpgradeLevels({this.range = 0, this.damage = 0, this.reload = 0});
  final int range, damage, reload;      // each 0..kMaxTier
  int tierOf(UpgradeAxis axis);
  bool get isEmpty;                      // all three are 0 → HUD chip hidden
  int get pointsSpent;                   // sum of kTierCosts prefixes
}
```

`lib/features/upgrades/domain/upgrade_math.dart` — **pure, no I/O, no Flutter imports**

```dart
double rangeMultiplier(int tier);        // 1 + 0.08 * tier
double damageMultiplier(int tier);       // 1 + 0.12 * tier
double reloadMultiplier(int tier);       // 1 - 0.06 * tier

/// Base catalog stats + purchased tiers → the stats a Tower is actually built
/// with. `cost` is NOT scaled (sell refund and build price stay authored).
TowerStats applyUpgrades(TowerStats base, UpgradeLevels levels);

int costOfTier(int tier);                // 0 for tier <= 0 or > kMaxTier
int costToReach(int tier);               // cumulative
```

`applyUpgrades` returns a **new** `TowerStats` with `rangeCells`, `damage`, and
`fireRate` scaled (`fireRate / reloadMultiplier(tier)`), everything else copied verbatim.
It must not mutate its input; the catalog is `const`.

Add `TowerStats.copyWith({...})` to `lib/features/game/domain/models/level.dart` so
`applyUpgrades` is a one-liner and future axes are cheap.

## `UpgradeStore` API

`lib/features/upgrades/data/upgrade_store.dart` — same thin-static-class-over-
`shared_preferences` style as `ProgressStore`.

**The point balance is derived, not stored.** `balance = earnedFromClaimedAwards −
UpgradeLevels.pointsSpent`. Two stored facts only, so the balance can never drift out of
sync with what was actually bought/awarded, and a corrupted write self-heals.

Keys (all under the `banheo.upgrades.` namespace):

- `banheo.upgrades.awards` — `StringList` of claimed tokens (`level_07:clear`).
- `banheo.upgrades.tiers`  — `StringList` of `"<trackId>=<tier>"` (`all.damage=3`).
  Unknown track ids are ignored on read, so forward-compatible with per-kind tracks.

```dart
class UpgradeStore {
  UpgradeStore._();

  /// Purchased tiers. Defaults to `UpgradeLevels.none`.
  static Future<UpgradeLevels> levels();

  /// Unspent points: everything earned minus everything spent. Never negative.
  static Future<int> points();

  /// Both of the above in one prefs round-trip (what the screens actually use).
  static Future<UpgradeState> load();     // record: (levels, points, earned, spent)

  /// Claims the clear (and optionally flawless) award for [levelId]. Idempotent:
  /// re-claiming an already-claimed token grants 0. Returns the points actually
  /// granted by THIS call, so the win dialog can show "+3 điểm nâng cấp".
  static Future<int> awardForClear({
    required String levelId,
    required int levelIndex,
    required bool flawless,
  });

  /// Buys the next tier of [axis]. Returns false (and writes nothing) when the
  /// track is already at [kMaxTier] or the balance is short.
  static Future<bool> buy(UpgradeAxis axis);

  /// Wipes awards + tiers. Debug menu / tests.
  static Future<void> reset();
}
```

`awardForClear` computes the clear payout itself from `levelIndex` (`2 + levelIndex ~/ 5`) —
callers never pass a point value, so the formula has exactly one home.

## Effective-stats resolution (how the buffs reach a `Tower`)

The engine stays dumb: **`Tower` is unchanged**. It keeps receiving a `TowerStats` and
keeps reading `stats.rangeCells` / `stats.damage` / `stats.fireRate` verbatim.

Resolution happens once, at build time:

1. `BanHeoGame` gains a constructor field
   `UpgradeLevels upgrades = UpgradeLevels.none` (defaulted, so every existing test and
   `testWithGame` factory compiles untouched).
2. `BanHeoGame.buildTower(spot, stats)` charges `stats.cost` (unmodified) and then
   constructs `Tower(stats: applyUpgrades(stats, upgrades), ...)`.
3. `LevelLoaderScreen` loads the level `.tmx` **and** `UpgradeStore.load()` in the same
   `FutureBuilder`, and passes `upgrades` down through `GameScreen` → `BanHeoGame`.
   Reading per round is correct: upgrades can only change from the menu, never mid-round.
4. `sellTower` already refunds from `tower.stats.cost`, which `applyUpgrades` leaves alone —
   no change needed, but the test plan pins it.

`LevelData` and `tmx_level_loader.dart` are **not** touched. Level data stays the pure
authored artifact; upgrades are a player-state overlay applied on top.

## Screens

### `UpgradeScreen` — `lib/features/upgrades/presentation/screens/upgrade_screen.dart`

Portrait, scrollable, styled like `MainMenuScreen`/`LevelSelectScreen`: translucent
storybook panel (`0xFFF8F1D8` at 94%, radius 34, cream border, layered shadow) over the
menu background. All copy in Vietnamese.

- AppBar `NÂNG CẤP THÁP` (`0xFF164F3B`, white, w900, letterSpacing 1.5) to match level select.
- **Balance header**: big `Điểm nâng cấp: N`, subtitle
  `Thắng màn mới để nhận thêm điểm. Chơi lại màn cũ không cộng điểm.`
- **Three `UpgradeTrackCard`s** (`presentation/widgets/upgrade_track_card.dart`), one per
  axis, each showing:
  - icon + label (`Phạm vi` / `Sát thương` / `Thời gian chờ`) and a one-line blurb;
  - 5 tier pips, filled up to the purchased tier;
  - current total effect (`+24% phạm vi`) and the next tier's delta (`→ +32%`);
  - a `FilledButton` `Nâng cấp · N điểm`, disabled (with reason text `Chưa đủ điểm` /
    `Đã tối đa`) when unaffordable or maxed.
- Tapping buy calls `UpgradeStore.buy(axis)` then reloads state via `setState`. Optimistic
  UI is not worth it here; the prefs write is sub-millisecond.
- Bottom: a small `Đặt lại` text button **only in debug** (`kDebugMode`), confirm dialog,
  calls `UpgradeStore.reset()`.

The screen makes **no** `OrientationLock` calls — it inherits the menus' portrait state, and
`LevelLoaderScreen` remains the only owner of the landscape lock.

### Navigation entry points

1. **`MainMenuScreen`** — a new `MenuButton` `NÂNG CẤP` (`Icons.upgrade_rounded`) between
   `BẮT ĐẦU` and `HƯỚNG DẪN`. It shows the unspent balance as a trailing badge when > 0, so
   the player notices unspent points from the title screen. Requires `MenuButton` to accept
   an optional `String? badge` (additive, defaulted — no other call site changes).
2. **`LevelSelectScreen`** — an AppBar action: an `IconButton`/chip showing
   `Icons.upgrade_rounded` + the balance, pushing the same screen. This is the important one:
   it is where the player lands right after a win. Refresh the balance in the existing
   `_refresh()` (extend it to also read `UpgradeStore.points()`), and `await` the push so the
   balance updates on pop, exactly like `_openLevel` already does.

### Win dialog — `GameScreen`

- `GameScreen` gains a `String? levelId` param, supplied by `LevelLoaderScreen` from
  `kLevelCatalog[_index].id`. `levelIndex` stays (it drives `ProgressStore`).
- `_onGameOver` becomes `Future<void>`: on a win with a non-null `levelId`, `await
  UpgradeStore.awardForClear(levelId: ..., levelIndex: ..., flawless: game.lives.value ==
  level.startingLives)` before showing the dialog, and append to the win text:
  - `+N điểm nâng cấp!` (and `Không rò con nào — thưởng thêm 1 điểm!` when the flawless
    token was granted by this call);
  - nothing at all when `N == 0` (a replay).
- The `ProgressStore.markCompleted` call stays fire-and-forget as it is today.
- Guard the existing `if (!mounted) return;` after the new `await`.

### In-round visibility (HUD + build menu)

Yes — the player should see the buff they paid for while playing.

- **`GameHud`**: when `game.upgrades.isEmpty == false`, render one compact chip after the
  wave stat: `⌖ +24%  ⚔ +36%  ⏱ −18%` (omit zeroed axes). Static — it does not change during
  a round, so it must not be wired into the merged `Listenable` (that would cost rebuilds
  for nothing).
- **`BuildMenu` `_TowerOption`**: show the effective range/fire numbers, with the buffed
  figures tinted green and the base struck through / shown in parentheses when a buff is
  active. Compute via `applyUpgrades(tower, game.upgrades)`.
- No tower sprite/VFX change in v1.

## File-by-file change list

**New**

| Path                                                                  | What                                    |
| --------------------------------------------------------------------- | --------------------------------------- |
| `lib/features/upgrades/domain/upgrade_catalog.dart`                    | `UpgradeAxis`, `UpgradeTrack`, tables   |
| `lib/features/upgrades/domain/upgrade_levels.dart`                     | `UpgradeLevels` value type              |
| `lib/features/upgrades/domain/upgrade_math.dart`                       | multipliers, `applyUpgrades`, costs     |
| `lib/features/upgrades/data/upgrade_store.dart`                        | prefs-backed store                      |
| `lib/features/upgrades/presentation/screens/upgrade_screen.dart`       | the skill-tree screen                   |
| `lib/features/upgrades/presentation/widgets/upgrade_track_card.dart`   | one track row                           |
| `test/upgrade_store_test.dart`                                         | store behaviour                         |
| `test/upgrade_math_test.dart`                                          | pure math                               |
| `test/upgrade_screen_test.dart`                                        | widget test                             |

**Changed**

| Path                                                                    | Change                                                            |
| ----------------------------------------------------------------------- | ----------------------------------------------------------------- |
| `lib/features/game/domain/models/level.dart`                             | add `TowerStats.copyWith(...)`                                     |
| `lib/features/game/engine/ban_heo_game.dart`                             | `upgrades` field (defaulted); `buildTower` applies it              |
| `lib/features/game/presentation/screens/level_loader_screen.dart`        | load upgrades with the level; pass `upgrades` + `levelId` down     |
| `lib/features/game/presentation/screens/game_screen.dart`                | `upgrades` + `levelId` params; award points; win-dialog copy       |
| `lib/features/game/presentation/widgets/game_hud.dart`                   | bonus chip                                                         |
| `lib/features/game/presentation/widgets/build_menu.dart`                 | effective stats in `_TowerOption`                                  |
| `lib/features/main_menu/presentation/screens/main_menu_screen.dart`      | `NÂNG CẤP` button + balance badge                                  |
| `lib/features/main_menu/presentation/widgets/menu_button.dart`           | optional `badge` param                                             |
| `lib/features/level_select/presentation/screens/level_select_screen.dart`| AppBar upgrade action + balance in `_refresh()`                    |
| `test/tower_test.dart`                                                   | add the upgraded-tower case                                        |

No new packages. `shared_preferences` is already a dependency.

## Test plan

`test/upgrade_math_test.dart`
1. `rangeMultiplier(0) == 1`, `(5) == 1.40`; `damageMultiplier(5) == 1.60`;
   `reloadMultiplier(5) == 0.70` (use `closeTo`).
2. `applyUpgrades(base, none)` returns stats equal to base on all fields.
3. Maxed arrow → `rangeCells ≈ 3.92`, `damage ≈ 19.2`, `fireRate ≈ 2.286`, and
   **`cost` unchanged at 50** (sell-refund contract).
4. `applyUpgrades` does not mutate its argument (assert base fields after the call).
5. `splashRadiusCells`, `splashDamageFactor`, `burnDps`, `burnDuration`, `kind`, `name`,
   `description`, `projectileSpeed` pass through untouched.
6. Loop over `kTowerCatalog.values`: every entry survives max upgrades with finite,
   strictly-positive range/damage/fireRate. (Mirrors the existing catalog-loop tests.)
7. Cost table: `costToReach(5) == 53`; `kTierCosts.length == kMaxTier`.

`test/upgrade_store_test.dart` (`SharedPreferences.setMockInitialValues({})` in `setUp`)
1. Fresh install → `points() == 0`, `levels() == UpgradeLevels.none`.
2. `awardForClear(levelId: 'level_01', levelIndex: 0, flawless: false)` → returns 2, balance 2.
3. Calling it a second time returns **0** and the balance stays 2 (idempotent, no grind).
4. Clearing `level_01` non-flawless then flawless later grants the +1 exactly once.
5. Payout bands: index 0 → 2, index 5 → 3, index 29 → 7.
6. Awarding every level index 0..29 (clears only) → balance **135**; with flawless → **165**.
7. `buy(UpgradeAxis.damage)` with 2 points returns false and writes nothing.
8. With 3 points: `buy` returns true, `points() == 0`, `levels().damage == 1`.
9. Buying to `kMaxTier` then once more returns false and leaves the tier at 5.
10. Balance is derived: with awards worth 20 and two tiers bought (3+5), `points() == 12`.
11. `reset()` zeroes both keys; a previously claimed award becomes claimable again.
12. Unknown track id in the stored list (`bogus.thing=9`) is ignored, not thrown on.

`test/tower_test.dart` (added case)
13. Build a `BanHeoGame` with maxed `upgrades`, place a tower via `buildTower`, and assert
    the resulting `Tower.rangePixels` and `stats.damage` are the boosted values while
    `game.economy` was charged the **base** cost.
14. Same game, maxed vs none: the pig dies in strictly fewer frames.

`test/upgrade_screen_test.dart`
15. Pumps `UpgradeScreen` with mocked prefs at 0 points → all three buy buttons disabled.
16. With 3 points → `Phạm vi` buy enabled; tapping it rebuilds to `0` points and 1 filled pip.
17. Maxed track shows `Đã tối đa` and the button is disabled.

Existing suites (`ban_heo_game_test`, `game_screen_test`, `economy_test`,
`tmx_level_loader_test`, `wave_spawner_test`) must stay green **without edits** — that is
the check that the `upgrades` parameter was genuinely defaulted.

## Acceptance criteria

1. `fvm flutter analyze` clean; `fvm flutter test` green.
2. Main menu shows `NÂNG CẤP`; it opens the upgrade screen. Balance badge appears once the
   player has unspent points.
3. Level select shows the point balance in its AppBar and can open the same screen.
4. Winning a level for the first time shows `+N điểm nâng cấp!` in the win dialog and the
   balance is higher when the player returns to level select.
5. Winning the **same** level again shows no point line and grants nothing.
6. Winning with zero leaks grants the extra flawless point exactly once.
7. Buying a tier deducts the right cost, fills a pip, and updates the effect text.
8. After buying `Phạm vi`, entering any level and building a tower shows a **visibly larger**
   range circle when the tower is selected, and the HUD chip shows the active bonuses.
9. Upgrades survive an app restart (kill and relaunch, or hot restart on web).
10. Tower **cost** is unchanged by upgrades; sell refund is still 60% of the authored cost.
11. Debug-only `Đặt lại` wipes points and tiers; release builds do not show it.
12. Screen is usable at 360×640 portrait (scrolls, no overflow) and with mouse on web.

## Open questions (decide before or during review — none are blocking)

1. **Should `ProgressStore.reset()` also clear upgrades?** Leaning yes (one "xoá tiến trình"
   action), but that needs a debug entry point that does not exist yet. v1: keep them
   separate, `UpgradeStore.reset()` is only reachable from the debug button on the
   upgrade screen.
2. **Flawless = full lives, or ≥90% lives?** Locked as full lives for v1 because it is
   unambiguous to explain (`không rò con nào`), but it may be near-impossible on levels 25+
   until the curve retune lands. Revisit after SPEC-003.
3. **Per-kind tracks.** The storage format supports them. Worth a follow-up spec once the
   player has a reason to specialise (more tower kinds).
4. **Does the reload buff need a floor?** At `×0.70` the arrow tower fires 2.29/s; nothing in
   the projectile code caps rate. Fine today; if a future axis pushes past ~5/s, add a clamp
   in `applyUpgrades` rather than in `Tower`.
5. **Curve retune (SPEC-003).** See "Balance finding". Recommend re-running
   `tool/generate_levels.dart` with a softened HP ramp and shorter finales, benchmarked
   against the maxed-upgrade DPS baseline this spec establishes.
