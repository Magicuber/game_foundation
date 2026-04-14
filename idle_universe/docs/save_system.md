# Save System

## Overview

The save system provides persistent storage of game state between sessions. It converts the entire `GameState` object into a JSON-serializable dictionary format.

**Key Files:**
- [`src/core/save/game_state_serializer.gd`](../src/core/save/game_state_serializer.gd) - Serialization logic
- [`src/bootstrap/save_manager.gd`](../src/bootstrap/save_manager.gd) - Save/Load operations

## Save Architecture

```
┌─────────────────────────────────────────┐
│           GameState                     │
│  (All game data and state)             │
└─────────────────────────────────────────┘
                    │
                    │ to_save_dict()
                    ▼
┌─────────────────────────────────────────┐
│      GameStateSerializer                │
│  (Converts to dictionary)              │
└─────────────────────────────────────────┘
                    │
                    │ JSON.stringify()
                    ▼
┌─────────────────────────────────────────┐
│         JSON File                       │
│  (user://save_file.json)                │
└─────────────────────────────────────────┘
```

## Save Format

The save file is a JSON dictionary containing:

```json
{
    "version": 7,
    "orbs": 0,
    "dust": {"mantissa": 1.23, "exponent": 15},
    "elements": {
        "ele_H": {
            "unlocked": true,
            "amount": {"mantissa": 5.67, "exponent": 12}
        }
    },
    "upgrades": {
        "particle_smasher": {
            "level": 10,
            "current_cost": {"mantissa": 1.0, "exponent": 20}
        }
    },
    "planets": {
        "planet_a": {
            "level": 5,
            "xp": {"mantissa": 1.0, "exponent": 8},
            "workers": {"mantissa": 3.0, "exponent": 0}
        }
    },
    "blessings": {
        "blessing_critical_chance": {
            "level": 3
        }
    },
    "current_element_id": "ele_H",
    "current_planet_id": "planet_a",
    "research_points": {"mantissa": 0.5, "exponent": 6},
    "completed_milestones": ["planet_a_5"],
    "total_played_seconds": 3600,
    "tick_count": 1000
}
```

## Serialization Process

### Saving

```gdscript
# game_state.gd
func to_save_dict() -> Dictionary:
    return serializer.to_save_dict(self)

# game_state_serializer.gd
func to_save_dict(state: GameState) -> Dictionary:
    var save_data := {
        "version": GameState.SAVE_VERSION,
        "orbs": state.orbs,
        "dust": state.dust.to_save_data(),
        "elements": _serialize_elements(state.elements),
        "upgrades": _serialize_upgrades(state.upgrades),
        "planets": _serialize_planets(state.planets),
        "blessings": _serialize_blessings(state.blessings),
        "current_element_id": state.current_element_id,
        "current_planet_id": state.current_planet_id,
        "research_points": state.research_points.to_save_data(),
        "completed_milestones": state.completed_milestones,
        "total_played_seconds": state.total_played_seconds,
        "tick_count": state.tick_count
    }
    return save_data
```

### Loading

```gdscript
# save_manager.gd
func load_into_state(state: GameState) -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return  # No save file exists
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var json_string = file.get_as_text()
    var parsed = JSON.parse_string(json_string)
    
    if parsed is Dictionary:
        state.apply_save_dict(parsed)

# game_state.gd
func apply_save_dict(save_data: Dictionary) -> void:
    serializer.apply_save_dict(self, save_data)

# game_state_serializer.gd
func apply_save_dict(state: GameState, save_data: Dictionary) -> void:
    # Apply saved data to state
    # Handle version migration if needed
    _apply_element_states(state, save_data.get("elements", {}))
    _apply_upgrade_states(state, save_data.get("upgrades", {}))
    _apply_planet_states(state, save_data.get("planets", {}))
    # ... etc
```

## Save Versioning

The save system includes version tracking for backward compatibility:

```gdscript
const SAVE_VERSION := 7
```

### Version Migration

When loading an older save:
1. Check the `version` field
2. Apply migrations sequentially
3. Update to current version

```gdscript
func apply_save_dict(state: GameState, save_data: Dictionary) -> void:
    var version = save_data.get("version", 0)
    
    if version < 1:
        # Migrate from version 0 to 1
        _migrate_v0_to_v1(save_data)
    
    if version < 2:
        # Migrate from version 1 to 2
        _migrate_v1_to_v2(save_data)
    
    # ... continue until current version
    
    # Apply final data
    _apply_current_version(state, save_data)
```

## DigitMaster Serialization

**File:** [`src/core/DigitMaster.gd`](../src/core/DigitMaster.gd)

Custom numbers are serialized as dictionaries:

```gdscript
# Saving
func to_save_data() -> Dictionary:
    return {
        "mantissa": mantissa,
        "exponent": exponent,
        "is_infinite": is_infinite
    }

# Loading
static func from_variant(value: Variant) -> DigitMaster:
    match typeof(value):
        TYPE_DICTIONARY:
            var dict: Dictionary = value
            if bool(dict.get("is_infinite", false)):
                return DigitMaster.infinity()
            return DigitMaster.new(
                float(dict.get("mantissa", 0.0)),
                int(dict.get("exponent", 0))
            )
```

## State Class Serialization

Each state class implements `to_save_dict()` and `apply_save_dict()`:

```gdscript
# planet_state.gd
func to_save_dict() -> Dictionary:
    return {
        "level": level,
        "xp": xp.to_save_data(),
        "workers": workers.to_save_data()
    }

func apply_save_dict(save_data: Dictionary) -> void:
    level = int(save_data.get("level", 1))
    xp = DigitMaster.from_variant(save_data.get("xp", 0))
    workers = DigitMaster.from_variant(save_data.get("workers", 0))
```

## Blessings Save Integration

Blessings are handled specially during loading:

```gdscript
# game_state.gd
func apply_save_dict(save_data: Dictionary) -> void:
    # Rebuild blessing system from data
    var blessing_data = save_data.get("blessings", {})
    blessing_manager.apply_saved_blessing_levels(blessing_data)

# blessing_manager.gd
func apply_saved_blessing_levels(saved_blessings: Dictionary) -> void:
    for blessing_id_variant in saved_blessings.keys():
        var blessing_id = str(blessing_id_variant)
        var blessing = get_blessing_state(blessing_id)
        if blessing == null:
            continue
        var blessing_save: Dictionary = saved_blessings[blessing_id]
        blessing.apply_save_dict(blessing_save)
```

## Save File Location

The save file is stored in Godot's user directory:

```gdscript
const SAVE_PATH := "user://save_file.json"
```

On desktop platforms, this is typically:
- Windows: `%APPDATA%/Godot/app_userdata/Idle_Universe/save_file.json`
- macOS: `~/Library/Application Support/Godot/app_userdata/Idle_Universe/save_file.json`
- Linux: `~/.local/share/godot/app_userdata/Idle_Universe/save_file.json`

## Auto-Save

**File:** [`src/bootstrap/autosave_service.gd`](../src/bootstrap/autosave_service.gd)

The game auto-saves at regular intervals:

```gdscript
# Check in tick_system or game loop
if tick_count - last_save_tick >= SAVE_INTERVAL:
    SaveManager.save_from_state(game_state)
    last_save_tick = tick_count
```

## Save Data Integrity

The save system includes defensive programming:

1. **Missing fields** - Defaults are applied
2. **Corrupted data** - Validation checks
3. **Type mismatches** - Type conversion with fallbacks
4. **Partial saves** - Graceful degradation

## Save Optimization

The save system minimizes data size by:
- Only saving non-default values
- Using efficient number encoding (DigitMaster)
- Excluding runtime-cached data
- Excluding UI state

## Manual Save Operations

The save manager provides manual operations:

```gdscript
# save_manager.gd
static func save_from_state(state: GameState) -> void:
    var save_data = state.to_save_dict()
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))

static func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
```

## Related Documentation

- [Architecture](./architecture.md) - System overview
- [Game Mechanics](./game_mechanics.md) - What data is saved
- [GameState Serializer](./game_state_serializer.md) - Save dict conversion
- [Save Manager](./save_manager.md) - File operations and recovery
- [Data Format](./data_format.md) - JSON structure definitions