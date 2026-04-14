# Reset Manager

[Back to Project Documentation](./README.md)

## Overview

`ResetManager` resets run-scoped data while keeping long-term progress.

**File:** [`src/core/managers/reset_manager.gd`](../src/core/managers/reset_manager.gd)

## Reset types

### `reset_run_state()`
Soft reset for prestige/run restart.

Resets:
- dust
- current element
- unlock tracking fields
- player level
- global multiplier
- tick count
- played time
- smash counters
- research points/progress
- best planet levels this run
- moon upgrade purchases

Then it calls subsystem reset helpers:
- `_reset_elements_to_defaults()`
- `_reset_upgrades_to_defaults()`
- `_reset_planets_to_owned_defaults()`

It also picks fallback current planet.

### `reset_planets_to_owned_defaults()`
Restores each planet to default state, but keeps ownership flags.

## Design intent

This manager separates:
- **run state**: temporary progression inside current run
- **persistent state**: things like owned planets, blessings, prestige unlocks, orbs

That split makes prestige safe and predictable.

## Related docs

- [Prestige Manager](./prestige_manager.md)
- [State Classes](./state_classes.md)
- [Game Mechanics](./game_mechanics.md)
- [Back to docs index](./README.md)