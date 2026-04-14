# Development Notes

[Back to Project Documentation](./README.md)

## Why this exists

Repo history shows the game grew in waves. Each wave solved one hard problem:
- make core idle loop work
- stop `GameLoader` from becoming a monolith
- separate UI refresh from gameplay logic
- add long-term progression systems
- harden save/load and test coverage
- keep unfinished content visible but safely gated

This note captures the main decisions, why they happened, what changed, and how they were built.

## Decision timeline

| When | Decision | Why | How |
|------|----------|-----|-----|
| 2026-03-24 | Start Godot foundation and `DigitMaster` | Idle scaling needed numbers beyond float range early | Built game in Godot, added big-number support before content ballooned |
| 2026-03-24 | Add element chain | Core loop needs a simple, readable progression spine | Data-driven periodic table with element-to-element production |
| 2026-03-26 | Add first menus and upgrade UI | Need player-facing loop beyond raw state | Built top-level menus and upgrade cards in `GameLoader` |
| 2026-03-27 to 2026-03-28 | Add world/planet layer and dust generation | Game needed second progression axis, not just elements | Added world view toggle, Planet A state, and dust conversion math |
| 2026-03-31 | Add upgrades system | Automation and long-term growth need upgrade economy | Introduced `UpgradesSystem` with cost scaling and effect summaries |
| 2026-04-03 | Split UI out of `GameLoader` | Loader was turning into a giant god object | Moved behavior into controllers: HUD, menu, era, world, element menu, upgrade panel |
| 2026-04-03 | Add typed state classes | Dict-heavy state was hard to reason about and easy to break | Replaced ad-hoc dict use with `ElementState`, `PlanetState`, `UpgradeState`, later `BlessingState` |
| 2026-04-03 | Extract dust recipe + icon cache services | Dust mode and sprite slicing were reusable logic, not loader concerns | Moved selection math to `DustRecipeService` and atlas slicing to `GameIconCache` |
| 2026-04-07 | Add blessings | Need passive meta progression and rare reward layer | Added rarity tables, blessing mass gain, and blessing opening lifecycle |
| 2026-04-09 | Add prestige layer | Run resets needed explicit milestone and reward structure | Added milestone definitions, prestige points, and prestige panel/controller |
| 2026-04-10 | Split loader into router + refresh coordinator + setup helper | UI refresh and action routing were becoming unmaintainable inside one scene script | Extracted `GameActionRouter`, `GameUiRefreshCoordinator`, `GameLoaderSetupHelper`, `UiStateController` |
| 2026-04-10 | Harden saves and add backup rotation | Player progress needs protection from partial writes | Save temp file, verify it, rotate primary to backup, quarantine invalid saves |
| 2026-04-10 | Cap tick processing | Idle games must not spiral after lag spikes | Tick accumulator processes limited ticks per frame |
| 2026-04-10 | Add regression tests | Refactors were touching too many systems at once | Added smoke tests for saves, blessings, prestige, fission, atomic cost entries, and core loop |
| 2026-04-11 | Audit loader cleanup for dead imports | Refactor follow-up wanted to prune unused preloads, but inspection showed `UIMetrics` still in use and no stale imports left to remove | Scanned `game_loader.gd`, confirmed `class_name` scripts and textures were still referenced, and left file unchanged |
| 2026-04-14 | Document architecture | Codebase crossed threshold where external docs mattered | Added docs tree and cross-linked all major systems |

## Why key architecture choices were made

### 1. `GameLoader` stayed as scene root, not game logic home

`GameLoader` owns UI nodes and orchestration, but actual rules moved outward.
Reason: UI wiring in Godot is noisy. Keeping it in one place makes scene setup simpler, but gameplay logic must not stay there or the file becomes impossible to maintain.

### 2. Managers use weak refs back to `GameState`

Reason: `GameState` owns managers, managers need to read/write state, and direct strong references create circular ownership headaches.
How: `weakref(owner)` and `game_state` getter on each manager.

### 3. Dirty flags drive UI refresh

Reason: refreshing all panels every frame is wasteful and made the loader huge.
How: UI state tracks bitflags; refresh coordinator calls only panels touched by current change.

### 4. Dust mode is separate from normal element selection

Reason: converting elements to Dust is a different user intent than picking current smash target.
How: `dust_mode_active` changes tile overlay, selection cycle, preview math, and button labels.

### 5. Placeholder content is kept in data, not hidden in code

Reason: future content should be visible to the structure and safe to gate without breaking UI.
How: placeholder blessings, planets, moon upgrades, and prestige entries carry `placeholder` flags.

### 6. Save system uses verify-then-rotate

Reason: save corruption is expensive in idle games because progress accumulates over long time.
How: write `.tmp`, read it back, then promote and keep `.bak` as fallback.

## Session-driven observations

From session logs, a few implementation directions were explicit:
- World view had to stay playable while zoomed out, but atom view should own manual smash visuals.
- Planets menu was introduced before full planet content existed, so placeholder panels were the correct bridge.
- Dust conversion needed a visible selection preview, not a hidden batch operation.
- Blessings needed a rollout path before all blessings existed, so placeholder blessing rows were valid.
- Prestige work had to preserve old saves, so migration logic was prioritized alongside new features.
- Loader cleanup should stop at verified usage, not guesswork; the dead-import pass found no real removals beyond already-extracted helpers.
- Docs-first work stayed read-only on code. Later session history was used to explain decisions, not to change implementation.

## Related docs

- [Architecture](./architecture.md)
- [Bootstrap Systems](./bootstrap_systems.md)
- [Game Mechanics](./game_mechanics.md)
- [Change Log](./change_log.md)
- [Back to docs index](./README.md)