# Prestige Manager

[Back to Project Documentation](./README.md)

## Overview

`PrestigeManager` handles milestone-based prestige progression, prestige points, and prestige node claims.

**File:** [`src/core/managers/prestige_manager.gd`](../src/core/managers/prestige_manager.gd)

## Model

Prestige has two parts:
- **Milestones**: run goals like `Planet A Lv. 5`
- **Nodes**: claimable persistent rewards bought with prestige points

Game data lives in:
- `GameState.PRESTIGE_MILESTONES`
- `GameState.PRESTIGE_NODES`

## Milestone flow

1. manager finds next pending milestone
2. UI shows progress text
3. when condition met, `can_prestige()` becomes true
4. `perform_prestige()` marks milestone complete and grants points
5. `next_milestone_id` advances
6. run reset happens

## Conditions

Current implemented milestone kind:
- `planet_level`

It checks `best_planet_levels_this_run[planet_id] >= required_level`

## Prestige preview

`get_prestige_preview()` returns:
- can prestige
- current milestone
- reward points
- next node
- can claim node
- reset summary text

## Prestige points

- `prestige_points_total`: lifetime total
- `prestige_points_unspent`: available to spend

`claim_next_prestige_node()` spends 1 point and marks node claimed.

## Dust bonus

`get_prestige_dust_multiplier()` scans claimed nodes and adds multipliers from nodes with:
- `effect_type == "dust_multiplier"`

## Reset interaction

`perform_prestige()` calls `GameState._reset_run_state()` after reward grant.
That means prestige is a controlled run reset, not a full save wipe.

## Legacy sync

`sync_legacy_prestige_count_from_nodes()` preserves older node-count style prestige by mapping visible element sections into `prestige_count`.

## Related docs

- [Planets](./planets.md)
- [Reset Manager](./reset_manager.md)
- [Game Mechanics](./game_mechanics.md)
- [Project Index](./project_index.md)
- [Back to docs index](./README.md)