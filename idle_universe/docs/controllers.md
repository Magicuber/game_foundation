# UI Controllers

[Back to Project Documentation](./README.md)

## Overview

Controllers bridge `GameState` and UI. They build view models, connect button signals, and refresh visible panels.

**Location:** [`src/controllers/`](../src/controllers/)

## How controllers fit

- `GameLoader` owns controller instances
- `GameUiRefreshCoordinator` calls refresh methods
- controllers emit signals for user actions
- `GameActionRouter` handles those signals and changes state

## Shared pattern

Most controllers follow this shape:

1. `configure(...)` injects UI nodes and helper services
2. `refresh(game_state, ...)` updates labels/buttons/icons
3. button signals emit action requests
4. parent layer routes requests back into game logic

## Controller index

### `AtomEffectsController`
Controls atom smash presentation.

Responsibilities:
- spawn hit/fuse effects
- queue pending auto-smash results
- clear visual particles when leaving atom view

Used by:
- `GameLoader`
- `GameActionRouter.on_manual_smash_resolved()`
- `GameActionRouter.on_auto_smash_requested()`

### `BlessingsPanelController`
Controls blessings UI.

Responsibilities:
- show blessing progress
- show discovered/unopened counts
- refresh blessing catalog rows
- open blessings on request

### `ElementMenuController`
Controls element list and dust mode.

Responsibilities:
- build element section grid
- show unlock/next section status
- manage dust selection mode
- emit element press and dust actions

See also: [Smasher Systems](./smasher_systems.md) and [Dust Recipe Service](./dust_recipe_service.md)

### `EraPanelController`
Controls era progress panel.

Responsibilities:
- show current era
- show next era requirement list
- enable unlock button when eligible

### `HudController`
Controls top bar and bottom navigation.

Responsibilities:
- render orbs/dust counters
- show player level
- update prev/next/zoom/menu/shop buttons
- reflect current view mode and menu state

### `MenuController`
Controls main overlay menu.

Responsibilities:
- show/hide menu panels
- switch active menu content
- update main menu button availability
- style shared overlay and background

### `OblationsPanelController`
Controls oblation recipe panel.

Responsibilities:
- list recipes
- show slot options and previews
- emit confirm action for recipe result

### `PlanetsPanelController`
Controls planet menu and world/planet details.

Responsibilities:
- show owned and purchasable planets
- show current planet info
- handle planet unlock/purchase requests
- handle moon upgrade requests
- play unlock animations

### `PrestigePanelController`
Controls prestige/milestone UI.

Responsibilities:
- show milestone list
- show prestige preview
- show prestige points and node claims
- handle increment/decrement debug controls

### `UpgradesPanelController`
Controls upgrade shop.

Responsibilities:
- build upgrade button list
- show cost, level, effect text
- emit purchase request

### `WorldViewController`
Controls world-view stage.

Responsibilities:
- show active planet/world art
- update worker button and allocation slider
- display world progress and navigation state
- manage particles when switching views

## Important controller data flow

```text
UI node press
  -> controller emits signal
  -> GameLoader binds signal to router
  -> GameActionRouter mutates state or queues action
  -> UI dirty flags set
  -> GameUiRefreshCoordinator refreshes panels
```

## Deep dive examples

### Element menu + dust mode

- `ElementMenuController` displays elements in sections
- `GameActionRouter.on_make_dust_pressed()` turns dust mode on
- tile click cycles selection through `DustRecipeService`
- `on_dust_clear_all_pressed()` clears all selections

### Upgrade purchase

- `UpgradesPanelController` emits `purchase_requested(upgrade_id)`
- `GameLoader` forwards to `GameActionRouter.on_upgrade_purchase_requested()`
- router queues `purchase_upgrade` action
- `TickSystem` processes action
- `UpgradesSystem.purchase_upgrade()` performs cost/effect update

### Planet actions

- `PlanetsPanelController` emits unlock or moon upgrade requests
- router calls into `GameState` purchase methods
- refresh coordinator updates world + planets + stats

## Related docs

- [Architecture](./architecture.md)
- [Bootstrap Systems](./bootstrap_systems.md)
- [UI Components](./ui_components.md)
- [Project Index](./project_index.md)
- [Back to docs index](./README.md)