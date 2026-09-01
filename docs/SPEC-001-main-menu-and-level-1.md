# SPEC-001 — Main menu + Level 1 (preview vertical slice)

Author: game-lead · Status: in progress · Target: Web (preview), Android, iOS

## Goal
A previewable slice: launch → **Main Menu** → tap Play → **Level 1** plays a full
tower-defense round to win or lose, then returns to the menu.

## Stack & decisions
- Flutter + **Flame** (`flame: ^1.x`). Add to `pubspec.yaml`, `fvm flutter pub get`.
- State: plain Flame components + `ValueNotifier`/`ChangeNotifier` for HUD; no extra
  state-management package yet.
- Rendering: **placeholder shapes only** (circles/rects/`TextComponent`). No image assets.
- Fixed logical play-field (e.g. 20×12 grid of 48px cells = 960×576), scaled to fit
  the screen with a Flame `World` + `CameraComponent` (`FixedResolutionViewport`).

## Folder layout
```
lib/
  main.dart              # thin: runApp(BanHeoApp())
  app.dart               # MaterialApp, routes, theme
  screens/
    main_menu_screen.dart
    game_screen.dart     # hosts GameWidget + HUD overlay + pause/result dialogs
  game/
    ban_heo_game.dart    # FlameGame subclass, owns level lifecycle
    components/
      enemy.dart         # marching pig/monster along the path
      tower.dart         # placed defense, acquires + shoots targets
      projectile.dart
      path_component.dart # draws the path
      build_spot.dart    # tappable buildable tile
    systems/
      wave_spawner.dart  # reads WaveData, spawns enemies over time
      economy.dart       # gold: earn on kill, spend on build
  data/
    level.dart           # LevelData, WaveData, SpawnGroup models
    levels/
      level_01.dart      # declarative Level 1 definition
test/
  economy_test.dart
  wave_spawner_test.dart
```

## Main Menu (`main_menu_screen.dart`)
- Title "BẮN HEO", subtitle "Thủ tháp - bắn quái".
- Buttons: **Chơi** (→ Level 1), **Hướng dẫn** (dialog with 3 lines of rules),
  **Thoát** (only on non-web; hidden on web).
- Simple animated background acceptable (parallax rects / drifting circles), optional.

## Level 1 gameplay
- **Map:** single fixed path from left edge to right edge (poly-line through the grid).
  Enemies that reach the end cost the player 1 life.
- **Lives:** 20. **Starting gold:** 100.
- **Build:** tap an empty build spot → menu with 1 tower type for this slice:
  - *Pigshooter* — cost 50, range 2.5 cells, fire rate 1/s, damage 10, projectile speed 300px/s.
  - Towers can be sold for 60% refund (optional for this slice).
- **Enemies:** one type — *Heo* (pig): hp 30, speed 60px/s, gold on kill 8, 1 life on leak.
- **Waves (Level 1):** 5 waves, 3s between waves, "Bắt đầu wave" button to pull the next
  wave early (bonus gold optional).
  1. 5 pigs, 0.8s apart
  2. 8 pigs, 0.7s apart
  3. 12 pigs, 0.6s apart
  4. 10 pigs, 0.4s apart
  5. 15 pigs, 0.35s apart
- **HUD:** lives, gold, wave X/5, next-wave button, pause button.
- **Win:** all 5 waves cleared with lives > 0 → result dialog "Thắng!" → menu.
- **Lose:** lives reach 0 → result dialog "Thua" → menu. Replaying resets all state.

## Acceptance criteria
1. `fvm flutter run -d chrome` boots to the main menu.
2. Play → Level 1 renders path, build spots, HUD.
3. Building a Pigshooter deducts 50 gold; it auto-targets and kills pigs; kills add gold.
4. Leaked pigs reduce lives; lives 0 → lose dialog → menu.
5. Clearing wave 5 → win dialog → menu.
6. Returning to a level starts fully fresh (gold/lives/waves/towers reset).
7. `fvm flutter analyze` clean; `fvm flutter test` green.
8. Works with mouse (web) and touch (mobile) — use Flame tap events, not raw pointer.

## Out of scope (later specs)
Multiple tower types, multiple levels, level-select screen, upgrades, persistence,
sound, real art, settings, monetization.
