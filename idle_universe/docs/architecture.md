# System Architecture

## Overview

Idle Universe follows a **Manager-based Architecture** with **Dependency Injection**. The core `GameState` class holds all game data and logic managers, while specialized manager classes handle specific game mechanics.

## Architecture Layers

```
┌─────────────────────────────────────┐
│           UI Layer                  │
│  (Scenes, Controllers, Views)      │
├─────────────────────────────────────┤
│        Game Systems Layer           │
│  (TickSystem, Cross-cutting logic) │
├─────────────────────────────────────┤
│         Manager Layer               │
│  (Planet, Blessing, Upgrade, etc) │
├─────────────────────────────────────┤
│          State Layer                │
│  (ElementState, PlanetState, etc)   │
├─────────────────────────────────────┤
│          Data Layer                 │
│  (JSON Data Files, Save System)     │
└─────────────────────────────────────┘
```

## Core Components

### GameState (Central Hub)

**File:** [`src/core/game_state.gd`](../src/core/game_state.gd)

`GameState` is the central orchestrator that:
- Contains all game data (elements, planets, upgrades, blessings)
- Holds references to all manager instances
- Provides public API for game operations
- Coordinates between different game systems

```gdscript
class_name GameState

# Managers
var blessing_manager
var resource_manager
var milestone_manager
var oblation_manager
var planet_manager
var progression_manager
var upgrade_manager
var reset_manager
var serializer

# Game Data
var elements: Dictionary
var planets: Dictionary
var upgrades: Dictionary
var blessings: Dictionary
var current_element_id: String
var current_planet_id: String
var research_points: DigitMaster
var dust: DigitMaster
```

### Manager Pattern

Each manager specializes in one aspect of gameplay:

| Manager | Responsibility | Key API |
|---------|---------------|---------|
| `PlanetManager` | Planet purchase, ownership, production | `purchase_planet()`, `select_planet()`, `process_planet_production()` |
| `BlessingManager` | Blessing generation, effects | `roll_random_blessing_id()`, `award_random_blessing()` |
| `UpgradeManager` | Upgrade purchases, levels | `get_upgrade_state()`, `set_upgrade_level()` |
| `ProgressionManager` | Element unlock progression | `unlock_next_element()`, `select_element()` |
| `ResourceManager` | Resources (dust, orbs) | `add_resource()`, `can_afford_resource()` |
| `MilestoneManager` | Milestone tracking | `get_next_milestone()`, `refresh_milestones()` |
| `OblationManager` | Oblation recipes | `get_oblation_preview()`, `confirm_oblation()` |

### Relationship Structure

Managers use **Weak References** to avoid circular dependencies:

```gdscript
class_name PlanetManager

var _game_state_ref: WeakRef = null
var game_state:
    get:
        return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
    _game_state_ref = weakref(owner) if owner != null else null
```

## Initialization Flow

```
bootstrap/game_bootstrap.gd
        │
        ├── Load JSON data files
        │
        ├── Create GameState instance
        │
        ├── Initialize managers with GameState reference
        │   ├── blessing_manager = BlessingManager.new(self)
        │   ├── planet_manager = PlanetManager.new(self)
        │   └── ...
        │
        ├── Load data into managers
        │
        └── Return initialized GameState
```

## Data Flow

### Reading Game State
1. UI/Controller calls `GameState.get_planet_entries()`
2. `GameState` delegates to `planet_manager.get_planet_entries()`
3. `PlanetManager` queries internal state and returns formatted data
4. `GameState` returns data to caller

### Modifying Game State
1. UI/Controller calls `GameState.purchase_planet("planet_b")`
2. `GameState` delegates to `planet_manager.purchase_planet("planet_b")`
3. `PlanetManager` checks requirements (can afford?)
4. If valid, `PlanetManager` updates `game_state.planet_owned_flags`
5. `GameState` may trigger side effects (refresh progression)

## Save System Architecture

**Key Files:**
- [`src/core/save/game_state_serializer.gd`](../src/core/save/game_state_serializer.gd)
- [`src/bootstrap/save_manager.gd`](../src/bootstrap/save_manager.gd)

The save system converts the entire `GameState` to a serializable dictionary:

```gdscript
# Serialization path:
GameState -> GameStateSerializer -> Dictionary -> JSON File

# Deserialization path:
JSON File -> Dictionary -> apply_save_dict() -> GameState
```

## State Classes

Individual state classes hold data for specific entities:

- `ElementState` - [`src/core/state/element_state.gd`](../src/core/state/)
- `PlanetState` - [`src/core/state/planet_state.gd`](../src/core/state/)
- `UpgradeState` - [`src/core/state/upgrade_state.gd`](../src/core/state/)
- `BlessingState` - [`src/core/state/blessing_state.gd`](../src/core/state/)

Each state class:
1. Provides static `from_content()` factory method
2. Holds properties specific to that entity type
3. May include helper methods for calculations
4. Is serializable via `to_save_dict()` / `apply_save_dict()`

## Number System

**File:** [`src/core/DigitMaster.gd`](../src/core/DigitMaster.gd)

The game uses a custom number class `DigitMaster` for arbitrarily large values:

```gdscript
# Stores numbers as: mantissa × 10^exponent
# Example: 1.5e308

func _init(mantissa: float, exponent: int, is_infinite: bool = false):
    # Handles very large numbers efficiently
```

Key features:
- Custom arithmetic operations
- Scientific notation formatting
- Infinity support
- Serialization support

## Design Patterns Used

1. **Dependency Injection** - Managers receive GameState reference
2. **Facade Pattern** - GameState provides unified API
3. **Factory Pattern** - State classes use `from_content()` factories
4. **Observer Pattern** - UI refreshes based on state changes
5. **Strategy Pattern** - Different effect types use different strategies

## Benefits

- **Separation of Concerns** - Each manager handles one system
- **Testability** - Managers can be unit tested in isolation
- **Modularity** - Easy to add new game mechanics
- **Maintainability** - Clear organization of code
- **Scalability** - Supports adding new managers and features

## Related Documentation

- [Game Mechanics](./game_mechanics.md) - How systems work together
- [Bootstrap Systems](./bootstrap_systems.md) - Loader, router, UI refresh
- [Resource Manager](./resource_manager.md) - Resource spending and production
- [Prestige Manager](./prestige_manager.md) - Prestige flow
- [Reset Manager](./reset_manager.md) - Run reset behavior
- [Save System](./save_system.md) - Persistence details
- [Data Format](./data_format.md) - JSON structure