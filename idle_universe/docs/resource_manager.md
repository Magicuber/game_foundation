# Resource Manager

[Back to Project Documentation](./README.md)

## Overview

`ResourceManager` owns resource query, spending, production, and research progress.

**File:** [`src/core/managers/resource_manager.gd`](../src/core/managers/resource_manager.gd)

## Resources

- **Dust**: primary currency
- **Orbs**: special currency stored on `GameState`
- **Elements**: all element amounts are resources
- **Research Points**: planet upgrade currency

## Core jobs

### Query

- `get_resource_name(resource_id)`
- `get_resource_amount(resource_id)`
- `get_research_points()`
- `get_research_progress_ratio()`
- `get_research_progress_display()`

### Affordability

- `can_afford_resource(resource_id, cost)`
- `can_afford_cost_entries(cost_entries)`

### Spend / gain

- `add_resource(resource_id, amount)`
- `spend_resource(resource_id, amount)`
- `spend_cost_entries_atomic(cost_entries)`
- `produce_resource(resource_id, amount)`
- `apply_research_progress(rp_amount)`

## Resource name rules

- `dust` -> `Dust`
- element ID -> element name from `ElementState`
- unknown ID -> raw ID text

## Cost entries

Cost arrays may mix:
- element costs
- dust costs
- orb costs

Example:

```gdscript
[
  {"resource_id": "dust", "cost": DigitMaster.new(1000)},
  {"resource_id": "orbs", "is_orb_requirement": true, "required_amount": 25}
]
```

## Atomic spend

`spend_cost_entries_atomic()` is important. It:
1. checks all costs first
2. totals same resource IDs
3. deducts orbs
4. deducts resources
5. restores previous values if anything fails

This prevents partial payment bugs.

## Production

`produce_resource()` does more than add value:
- dust gets dust gain multiplier
- element production unlocks show-in-counter flag
- element production also feeds blessing mass

## Research progress

Research uses fractional progress:
- `research_progress` stores fractional remainder
- whole points go into `research_points`
- if production is huge, infinite-safe path adds directly

## Related docs

- [Game Mechanics](./game_mechanics.md)
- [Planets](./planets.md)
- [Oblations](./oblations.md)
- [Project Index](./project_index.md)
- [Back to docs index](./README.md)