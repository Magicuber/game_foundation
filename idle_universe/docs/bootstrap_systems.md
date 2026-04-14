# Bootstrap Systems

[Back to Project Documentation](./README.md)

## Overview

Bootstrap layer wires game together. `GameLoader` is main scene controller. It builds state, owns UI nodes, and delegates user actions and refresh work to helper objects.

**Key files:**
- [`src/bootstrap/game_loader.gd`](../src/bootstrap/game_loader.gd)
- [`src/bootstrap/game_action_router.gd`](../src/bootstrap/game_action_router.gd)
- [`src/bootstrap/game_ui_refresh_coordinator.gd`](../src/bootstrap/game_ui_refresh_coordinator.gd)
- [`src/bootstrap/ui_state_controller.gd`](../src/bootstrap/ui_state_controller.gd)
- [`src/bootstrap/game_loader_setup_helper.gd`](../src/bootstrap/game_loader_setup_helper.gd)
- [`src/bootstrap/autosave_service.gd`](../src/bootstrap/autosave_service.gd)
- [`src/bootstrap/game_bootstrap.gd`](../src/bootstrap/game_bootstrap.gd)

## GameLoader

`GameLoader` is main scene root. It owns:
- all top-level UI nodes
- `GameState`
- `TickSystem`
- `ElementSystem`
- `UpgradesSystem`
- controller objects
- dirty flag refresh loop
- view/menu mode switching

### Startup flow

1. Build game state from JSON via `GameBootstrap`
2. Construct router/coordinator/helper objects
3. Wire signals from `TickSystem` and panel controllers
4. Configure UI controllers with scene nodes
5. Apply reference layout
6. Refresh UI once, then run normal loop

### Important state

- `menu_mode` = current menu panel
- `view_mode` = atom or world view
- `ui_dirty_flags` = pending refresh bits
- `dust_mode_active` = element menu dust conversion mode
- `debug_show_element_hitboxes` = debug overlay flag

## GameActionRouter

`GameActionRouter` handles user input events. It does not own UI; it routes actions into game state and refresh requests.

### Main jobs

- manual smash
- auto smash resolution
- navigation buttons
- menu open/close
- upgrade purchase requests
- planet purchase and moon upgrade requests
- oblation confirm requests
- era unlock requests
- debug actions like add dust/orbs

### Important pattern

Router decides whether action is:
- immediate state change
- queued tick action
- UI state mode switch

Example:
- smash button in atom view -> queue `manual_smash`
- prev/next in world view -> direct planet selection
- prev/next in atom view -> queue element selection

## GameUiRefreshCoordinator

Coordinator maps dirty flags to refresh functions.

### Why exists

UI updates are expensive. Instead of refreshing all panels every frame, loader marks dirty bits, then coordinator refreshes only needed panels.

### Dirty targets

- top bar
- selection UI
- navigation
- counters
- upgrades panel
- elements panel
- era panel
- stats panel
- shop panel
- planets panel
- prestige panel
- oblations panel
- blessings progress/catalog
- world view
- debug hitboxes

### Flow

1. action changes state
2. router calls `_mark_ui_dirty(flags)`
3. loader calls `ui_refresh_coordinator.refresh_ui(flags)`
4. controller flushes only matching panels

## UiStateController

Controller stores UI mode and dirty bits.

### Fields

- `menu_mode`
- `view_mode`
- `ui_dirty_flags`

### Helpers

- `set_menu_mode()`
- `set_view_mode()`
- `mark_ui_dirty()`
- `flush_dirty_ui()`
- flag composition helpers for resource, selection, menu, and view refresh sets

### Meaning

This is simple state holder. It does not know Godot nodes. It only knows mode integers and bitmasks.

## GameLoaderSetupHelper

Helper creates UI pieces at runtime.

### Current uses

- create `Reset Blessings` button
- create placeholder `Oblations`, `Factory`, and `Collider` menu panels/buttons
- style dynamic buttons

This keeps `GameLoader` from becoming even more huge.

## AutosaveService

Autosave layer checks tick count and writes save when interval passes.

### Behavior

- save every N ticks
- save on exit
- update `last_save_tick` on success

## Bootstrap data path

```text
JSON data -> GameBootstrap -> GameState -> systems/controllers -> UI
```

## Related docs

- [Architecture](./architecture.md)
- [Tick System](./tick_system.md)
- [Save Manager](./save_manager.md)
- [Project Index](./project_index.md)
- [Back to docs index](./README.md)