# Change Log

[Back to Project Documentation](./README.md)

## Scope

This log covers repo history from first idle_universe commit through latest documented commit.
Source basis: git history in this repo, oldest to newest.

---

## 2026-03-24 — Project birth and core foundation

### `a895850` — Started Godot version
- First Godot project scaffold.
- Established repo as Godot-based game rather than loose asset dump.
- Set baseline for later scene and script structure.

### `2935a44` — added framework for godot version
- Added initial Godot project layout and runtime wiring.
- Started shaping core scene / project config structure.
- Foundation for future gameplay systems.

### `1b28c67` — added sprites and big number support
- Added first sprite assets.
- Introduced `DigitMaster`/large-number path so game can scale past normal float limits.
- Early sign of idle-game math needs.

### `e95dabf` — added elements
- Added element progression data and early periodic-table loop.
- Core idle mechanic formed: elements unlock, produce next element, feed growth.
- Began game-specific content data.

### `ba6a517` — added plugin
- Enabled addon/plugin integration.
- Project started supporting external tooling and editor extensions.

---

## 2026-03-25 — Cleanup

### `c530a5a` — removed addons
- Removed addon layer from early build.
- Likely temporary simplification while core gameplay stabilized.

---

## 2026-03-26 — UI system begins

### `dc2238c` — updated ui
- Introduced first major UI pass.
- Began shaping main layout and on-screen presentation.

### `0d6f3cd` — updated font, upgrade menu, and upgrade list
- Added JetBrains Mono font for clearer numeric display.
- Added upgrade menu/list presentation.
- Expanded `GameLoader` and upgrade system wiring.
- Upgrades became a real gameplay layer, not just data.

### `19a831f` — added element menu
- Added dedicated element menu.
- Added `ElementMenuTile` UI component.
- Element grid became interactive instead of purely data-driven.

### `4b16efb` — added Era menu
- Added era menu UI.
- Expanded `GameState` for era/progression unlock handling.
- Added era art and planet art assets.
- Began long-term progression gating.

### `d0d0cce` — added world page, shop and planet menus, and dust generation
- Added world view and world/planet menu entry points.
- Added shop UI shell.
- Added dust generation path.
- Added `DigitMaster` improvements for large-number handling.
- Planetary gameplay path started to emerge.

### `45753d5` — added upgrades
- Added substantial upgrade content and upgrade backlog notes.
- Added second-tier upgrade scaffolding.
- Expanded `UpgradesSystem` and `ElementSystem` behavior.
- Upgrade economy became a major progression layer.

### `5448622` — added planet updates
- Added `planets.json` and planet progression content.
- Expanded `GameLoader` and `GameState` for planet-level updates.
- Planet system became first-class gameplay.

### `70abcac` — mstr sprite sheet
- Added master sprite sheet art source.
- Prepared larger content pipeline for element/variant visuals.

---

## 2026-04-03 — Refactor wave: UI refresh, typed state, controller split

### `d500a0f` — updated UI Refresh mechanics
- Reworked refresh flow for better UI update handling.
- Expanded loader logic and UI coordination.
- Updated `UpgradesSystem` and element tile UI for new refresh model.

### `053e2cc` — broke out functions from game loader
- Extracted `AtomEffectsController` from giant loader file.
- Added `DustRecipeService` and `GameIconCache` services.
- Major step toward separation of concerns.

### `2b45468` — updated view and scene tree
- Added `UIMetrics` constants layer.
- Refined scene tree and layout sizes.
- Improved menu/upgrade/UI sizing consistency.

### `63c8dfc` — moved out world controls out of gamer loader
- Extracted `WorldViewController` from `GameLoader`.
- Continued move toward controller-based UI architecture.

### `1941820` — moved hud and menu controls out of game loader
- Extracted `HudController` and `MenuController`.
- Reduced loader responsibility.
- Menu and HUD logic became reusable controller layers.

### `5f4c7b0` — moved submenu control out of game loader
- Extracted `ElementMenuController` and `UpgradesPanelController`.
- Pushed submenus into dedicated controller scripts.

### `ac698fc` — moved era out of game loader
- Extracted `EraPanelController`.
- Era UI got dedicated handling.

### `f9574e5` — updated to a typed state system
- Added typed `ElementState`, `PlanetState`, and `UpgradeState` classes.
- Reworked `GameState` toward typed collections.
- Tightened systems and UI around typed data.
- Major architecture upgrade.

### `522a495` — error fixed
- Small targeted fix in element menu controller.
- Debug/stability patch.

### `1cb6a12` — updated text sizes and added debug options
- Adjusted typography sizing.
- Added debug controls to UI.
- Improved usability and testing tools.

### `945620a` — text size changes
- Further refined UI text sizing.
- Polished element tile layout.

---

## 2026-04-05 — Element menu fix

### `0c4ccd1` — fixed elements menu
- Refined element menu behavior and button logic.
- Continued polish on tile selection and upgrade presentation.

---

## 2026-04-06 — Menu expansion and profile icon

### `8a2292f` — added new menus, and started to format blessings menu
- Added more menu panels and menu routing.
- Started blessings menu layout work.
- Added generated profile icon asset.
- Expanded `HudController` and `MenuController` logic.

---

## 2026-04-07 — Blessings system lands

### `396b77a` — added blessings
- Added full blessing content set and rarity-varying variant art.
- Added `BlessingState` and `BlessingsPanelController`.
- Blessing effects became a major progression layer.
- Added tier-2 upgrade art.

### `96cd890` — added menus and updated blessings
- Refined menu system around blessings.
- Updated blessing behavior and element/upgrade interactions.
- Blessings began integrating with core progression and smashes.

---

## 2026-04-09 — Export pipeline, prestige, planet menu, fission tuning

### `a44205f` — added export options
- Added `export_presets.cfg`.
- Project became export-ready.
- Minor config update to support build/export flow.

### `d0900dd` — added prestige system
- Added prestige milestones and prestige controllers.
- Added Planet B controllers and supporting save/progression state.
- Introduced prestige smoke test.
- Prestige became long-term meta progression.

### `13d47c6` — built out planet menu
- Added `planet_menu.json`.
- Expanded planets panel significantly.
- Added richer planet tree/menu UX.
- Reworked world/planet presentation and supporting metrics.

### `4c7c9d4` — updated element spawning and fission calc
- Refined atom smash / fission logic.
- Added fission pair selection test.
- Cleaned older docs/assets from root and tightened element spawning math.
- Massive internal refactor for smash output logic.

---

## 2026-04-10 — Stability, performance, modularization

### `d3dc024` — updated world page
- Fine-tuned world view behavior.
- Adjusted state updates and tick interaction in world mode.

### `d48dc97` — optimizations
- Improved save robustness.
- Added batch UI refresh support.
- Expanded blessing-panel and world-view test coverage.
- Added `BlessingCatalogRow` UI component.
- Bigger performance and polish pass.

### `4a0542a` — added planet B sprite, cleaned up tick queuing, and streamlined the action queue
- Added Planet B art assets.
- Simplified action queue processing.
- Cleaned tick logic and icon caching.
- Added atomic cost-entry test coverage.

### `5261e31` — UI batch, tick cap, DigitMaster cleanup.
- Refined loader batching and tick cap behavior.
- Cleaned large-number usage in state code.
- Continued stability/efficiency improvements.

### `16646bf` — Harden saves, batch UI refresh, cap ticks, clean blessing lifecycle
- Strengthened save handling.
- Added blessing lifecycle smoke test.
- Improved `BlessingState` lifecycle and cache behavior.
- Reduced corruption risk and UI churn.

### `48aa8c7` — Split progression + break RefCounted cycles
- Massive architecture refactor.
- Split `GameState` behavior into manager classes:
  - `BlessingManager`
  - `PlanetManager`
  - `PrestigeManager`
  - `ProgressionManager`
  - `ResourceManager`
  - `GameStateSerializer`
  - `AutosaveService`
  - `GameBootstrap`
  - `UiStateController`
- Broke ref-counted cycles for safer object ownership.
- Biggest structural change in repo history.

### `ed57668` — Extract loader UI router + cleanup dead helpers
- Extracted `GameActionRouter`.
- Added `GameLoaderSetupHelper`.
- Added `GameUiRefreshCoordinator`.
- Added `ResetManager` and expanded `UpgradeManager`.
- Loader became orchestration shell rather than monolith.

### `5843659` — added uids
- Added missing `.uid` files for new scripts.
- Project resource identity became stable across editor operations.

---

## 2026-04-14 — Prestige rework and docs overhaul

### `45b00fa` — reworked prestige system and added documentation
- Reworked prestige flow and related state handling.
- Added docs/readme set across project.
- Introduced first full external documentation pass.
- Added test suite, state docs, bootstrap docs, and system docs.
- This commit marks start of current documentation era.

---

## High-level evolution

### Phase 1: Foundation
- Godot project scaffold
- Big-number support
- Element chain setup
- Basic art/assets

### Phase 2: UI and upgrade layer
- Element menu
- Upgrade menu
- Era menu
- World/planet/shop shell

### Phase 3: System depth
- Typed state classes
- Blessings
- Prestige
- Planets and planet menu
- Fission and variant smashes

### Phase 4: Architecture cleanup
- Controller split
- Service extraction
- Manager extraction
- Save hardening
- Dirty-flag UI refresh
- Tick cap / action queue cleanup

### Phase 5: Documentation and stabilization
- Full docs tree
- README coverage by directory
- System-specific deep dives
- Regression tests and smoke tests

---

## Notes

- Old root docs like `dust_scaling_comparison.md` and `elements_section_upgrade_backlog.md` were later removed from root during cleanup.
- `assests/` folder name is intentional in repo history, even though misspelled.
- Historical commit messages are sometimes terse, so this changelog uses code diff context to describe impact.

## Back to docs

- [Docs index](./README.md)
- [Project Index](./project_index.md)