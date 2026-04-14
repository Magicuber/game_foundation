# GameState Serializer

[Back to Project Documentation](./README.md)

## Overview

`GameStateSerializer` converts whole game state to/from save dictionary.

**File:** [`src/core/save/game_state_serializer.gd`](../src/core/save/game_state_serializer.gd)

## Save shape

Serializer writes:
- global scalar fields
- digit fields as `DigitMaster` save dicts
- element / upgrade / blessing / planet maps
- milestone / unlock arrays
- prestige and oblation state

## Save flow

### `to_save_dict(state)`
Builds dictionary from current live state.

### `apply_save_dict(state, save_data)`
Restores dictionary into live state.

## Ordering

Load order matters:
1. scalar state
2. collections and flags
3. element states
4. upgrade states
5. blessing states
6. planet states
7. refresh progression state

That order keeps derived state valid after load.

## Version handling

`save_version` drives compatibility.
Current serializer contains legacy branch logic for versions before 7:
- default planet unlock fix for Planetary Era
- some oblation claim migrations from older prestige-node names

## Element / upgrade / planet handling

Each sub-state is restored by its own `apply_save_dict()` method.
This keeps serializer thin and avoids duplicated logic.

## Blessing handling

Blessing save is a bit special:
- saved by level only
- cache invalidated after restore
- unopened count repaired if older save lacks field

## Planet handling

Planet save restores each planet and recomputes XP requirement from saved level.
That avoids stale requirement data.

## Related docs

- [Save Manager](./save_manager.md)
- [State Classes](./state_classes.md)
- [DigitMaster](./digitmaster.md)
- [Back to docs index](./README.md)