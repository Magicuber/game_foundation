# State Classes

## Overview

State classes hold data for individual game entities. They are simple data containers with serialization support, separate from the logic in managers.

**Location:** [`src/core/state/`](../src/core/state/)

## Architecture Pattern

```
┌──────────────────────────────────────────┐
│           GameState                      │
│  (Holds collections of states)          │
└──────────────┬───────────────────────────┘
               │
    ┌──────────┼──────────┬──────────────┐
    │          │          │              │
    ▼          ▼          ▼              ▼
┌────────┐ ┌─────────┐ ┌──────────┐ ┌────────┐
│Element │ │ Upgrade │ │ Planet   │ │Blessing│
│State   │ │ State   │ │ State    │ │ State  │
└────────┘ └─────────┘ └──────────┘ └────────┘
    │          │          │              │
    └──────────┴──────────┴──────────────┘
                         │
                         ▼
              ┌──────────────────┐
              │  to_save_dict()  │
              │apply_save_dict() │
              └──────────────────┘
```

## Common Interface

All state classes implement:

| Method | Purpose |
|--------|---------|
| `from_content(dict)` | Factory method from JSON data |
| `to_save_dict()` | Serialize for save files |
| `apply_save_dict(dict)` | Deserialize from save |
| `to_view_dict()` | Format for UI display |
| `reset_to_default()` | Soft reset values |

## ElementState

**File:** [`src/core/state/element_state.gd`](../src/core/state/element_state.gd)

Represents a periodic table element's current status.

### Properties

```gdscript
var id: String                    // "ele_H"
var name: String                  // Display name: "H"
var index: int                    // Atomic number (1-118)
var unlocked: bool                // Can player use this?
var default_unlocked: bool        // For reset

// Costs and amounts
var cost: DigitMaster             // Unlock cost
var amount: DigitMaster            // Current owned amount
var default_amount: DigitMaster   // Starting amount

// Production
var produces: String              // ID of next element in chain
var show_in_counter: bool         // Visible in UI counter?
```

### Factory Pattern

```gdscript
static func from_content(raw: Dictionary, fallback_index: int) -> ElementState:
    var state := ElementState.new()
    state.id = str(raw.get("id", ""))
    state.name = str(raw.get("name", state.id))
    state.index = int(raw.get("index", fallback_index))
    state.unlocked = bool(raw.get("unlocked", false))
    state.default_unlocked = state.unlocked  // Remember default
    
    // Convert to DigitMaster
    state.cost = DigitMaster.from_variant(raw.get("cost", 0))
    state.amount = DigitMaster.from_variant(raw.get("amt", 0))
    state.default_amount = state.amount.clone()
    
    state.produces = str(raw.get("produces", ""))
    state.show_in_counter = bool(raw.get("show_in_counter", false))
    state.default_show_in_counter = state.show_in_counter
    
    return state
```

### Save Format

```gdscript
func to_save_dict() -> Dictionary:
    return {
        "unlocked": unlocked,
        "show_in_counter": show_in_counter,
        "amount": amount.to_save_data()
    }

func apply_save_dict(save_data: Dictionary) -> void:
    unlocked = bool(save_data.get("unlocked", unlocked))
    show_in_counter = bool(save_data.get("show_in_counter", show_in_counter))
    amount = DigitMaster.from_variant(save_data.get("amount", amount))
```

### Reset Behavior

```gdscript
func reset_to_default() -> void:
    unlocked = default_unlocked
    show_in_counter = default_show_in_counter
    amount = default_amount.clone()
```

## UpgradeState

**File:** [`src/core/state/upgrade_state.gd`](../src/core/state/upgrade_state.gd)

Represents an upgrade's current level and costs.

### Properties

```gdscript
// Identity
var id: String
var name: String
var description: String
var tier: int                    // UI grouping

// Requirements
var required_era_index: int       // Minimum era to purchase

// Currencies
var currency_id: String           // Primary currency (element or "dust")
var base_cost: DigitMaster
var current_cost: DigitMaster     // Cost for next level

var secondary_currency_id: String // Optional
var secondary_base_cost: DigitMaster
var secondary_current_cost: DigitMaster

// Cost scaling
var cost_mode: String             // "additive_power" or "element_sequence_linear"
var cost_scaling: float           // Multiplier per level
var cost_step: float              // For linear mode

// Levels
var max_level: int
var current_level: int
var default_current_level: int

// Effects
var effect_type: String           // What this upgrade does
var effect_amount: float          // Base value

// Element sequence specifics
var sequence_start_index: int     // Starting element index
var sequence_requires_unlock: bool // Must elements be unlocked?
```

### Factory Pattern

```gdscript
static func from_content(raw: Dictionary) -> UpgradeState:
    var state := UpgradeState.new()
    var base_cost = DigitMaster.from_variant(raw.get("base_cost", 0))
    var sec_cost = DigitMaster.from_variant(raw.get("secondary_base_cost", 0))
    
    state.id = str(raw.get("id", ""))
    state.name = str(raw.get("name", state.id))
    state.description = str(raw.get("description", ""))
    state.tier = int(raw.get("tier", 1))
    state.required_era_index = int(raw.get("required_era_index", 0))
    
    state.currency_id = str(raw.get("currency_id", "dust"))
    state.base_cost = base_cost
    state.current_cost = base_cost.clone()  // Start at base
    
    state.secondary_currency_id = str(raw.get("secondary_currency_id", ""))
    state.secondary_base_cost = sec_cost
    state.secondary_current_cost = sec_cost.clone()
    
    state.cost_mode = str(raw.get("cost_mode", "additive_power"))
    state.cost_scaling = float(raw.get("cost_scaling", 1.0))
    state.cost_step = float(raw.get("cost_step", 0.0))
    
    state.max_level = int(raw.get("max_level", 1))
    state.current_level = int(raw.get("current_level", 0))
    state.default_current_level = state.current_level
    
    state.effect_type = str(raw.get("effect_type", ""))
    state.effect_amount = float(raw.get("effect_amount", 0.0))
    state.sequence_start_index = int(raw.get("sequence_start_index", 0))
    state.sequence_requires_unlock = bool(raw.get("sequence_requires_unlock", false))
    
    return state
```

### Save Format

```gdscript
func to_save_dict() -> Dictionary:
    return {
        "current_level": current_level,
        "current_cost": current_cost.to_save_data(),
        "secondary_current_cost": secondary_current_cost.to_save_data()
    }

func apply_save_dict(save_data: Dictionary) -> void:
    current_level = int(save_data.get("current_level", current_level))
    current_cost = DigitMaster.from_variant(
        save_data.get("current_cost", base_cost)
    )
    secondary_current_cost = DigitMaster.from_variant(
        save_data.get("secondary_current_cost", secondary_base_cost)
    )
```

### Reset

```gdscript
func reset_to_default() -> void:
    current_level = default_current_level
    current_cost = base_cost.clone()
    secondary_current_cost = secondary_base_cost.clone()
```

## PlanetState

**File:** [`src/core/state/planet_state.gd`](../src/core/state/planet_state.gd)

Represents a planet's level, XP, and worker status.

### Properties

```gdscript
// Identity
var id: String
var name: String
var unlocked: bool
var default_unlocked: bool

// Level and XP
var level: int
var default_level: int
var max_level: int
var xp: DigitMaster
var default_xp: DigitMaster
var xp_to_next_level: DigitMaster  // Computed, not saved directly

// Workers
var workers: DigitMaster
var default_workers: DigitMaster
var worker_allocation_to_xp: float  // 0.0-1.0
var default_worker_allocation_to_xp: float

// Costs
var purchase_cost_dust: DigitMaster
var purchase_cost_orbs: int
```

### Factory with XP Calculation

```gdscript
static func from_content(raw: Dictionary, xp_to_next: DigitMaster) -> PlanetState:
    var state := PlanetState.new()
    state.id = str(raw.get("id", ""))
    state.name = str(raw.get("name", state.id))
    
    state.unlocked = bool(raw.get("unlocked", false))
    state.default_unlocked = state.unlocked
    
    state.level = maxi(1, int(raw.get("level", 1)))
    state.default_level = state.level
    state.max_level = maxi(1, int(raw.get("max_level", 1)))
    
    state.workers = DigitMaster.from_variant(raw.get("workers", 0))
    state.default_workers = state.workers.clone()
    
    state.xp = DigitMaster.from_variant(raw.get("xp", 0))
    state.default_xp = state.xp.clone()
    
    state.xp_to_next_level = xp_to_next  // Passed from manager
    
    state.worker_allocation_to_xp = clampf(
        float(raw.get("worker_allocation_to_xp", 1.0)), 
        0.0, 
        1.0
    )
    state.default_worker_allocation_to_xp = state.worker_allocation_to_xp
    
    state.purchase_cost_dust = DigitMaster.from_variant(raw.get("purchase_cost_dust", 0))
    state.purchase_cost_orbs = maxi(0, int(raw.get("purchase_cost_orbs", 0)))
    
    return state
```

### Save Format

```gdscript
func to_save_dict() -> Dictionary:
    return {
        "unlocked": unlocked,
        "level": level,
        "workers": workers.to_save_data(),
        "xp": xp.to_save_data(),
        "worker_allocation_to_xp": worker_allocation_to_xp
    }

func apply_save_dict(save_data: Dictionary, xp_to_next: DigitMaster) -> void:
    unlocked = bool(save_data.get("unlocked", unlocked))
    level = maxi(1, int(save_data.get("level", level)))
    workers = DigitMaster.from_variant(save_data.get("workers", workers))
    xp = DigitMaster.from_variant(save_data.get("xp", xp))
    worker_allocation_to_xp = clampf(
        float(save_data.get("worker_allocation_to_xp", worker_allocation_to_xp)),
        0.0, 
        1.0
    )
    xp_to_next_level = xp_to_next  // Recalculated by manager
```

**Note:** `xp_to_next_level` is recalculated by `PlanetManager` on load, not stored in save.

### Reset

```gdscript
func reset_to_default(xp_to_next: DigitMaster) -> void:
    unlocked = default_unlocked
    level = default_level
    workers = default_workers.clone()
    xp = default_xp.clone()
    worker_allocation_to_xp = default_worker_allocation_to_xp
    xp_to_next_level = xp_to_next
```

## BlessingState

**File:** [`src/core/state/blessing_state.gd`](../src/core/state/blessing_state.gd)

Represents a blessing's current level and discovered state.

### Properties

```gdscript
// Identity and display
var id: String
var name: String
var description: String
var rarity: String          // "Uncommon", "Rare", etc.

// State
var level: int              // 0 = undiscovered/undiscovered
var max_level: int          // Usually 1 or higher

// Effect
var effect_type: String
var effect_base: float        // Value per level
var effect_scaling: float     // Additional per level (if any)

// Content flag
var placeholder: bool       // Not yet implemented?

// Default values
var default_level: int
```

### Effect Calculation

```gdscript
func get_effect_value() -> float:
    if level <= 0:
        return 0.0
    // Simple linear scaling
    return level × effect_base
    // Or with scaling factor:
    // return level × effect_base + (level - 1) × effect_scaling
```

### Factory Pattern

```gdscript
static func from_content(raw: Dictionary) -> BlessingState:
    var state := BlessingState.new()
    state.id = str(raw.get("id", ""))
    state.name = str(raw.get("name", state.id))
    state.description = str(raw.get("description", ""))
    state.rarity = str(raw.get("rarity", "Uncommon"))
    
    state.level = int(raw.get("level", 0))
    state.default_level = state.level
    state.max_level = int(raw.get("max_level", 1))
    
    state.effect_type = str(raw.get("effect_type", ""))
    state.effect_base = float(raw.get("effect_base", 0.0))
    state.effect_scaling = float(raw.get("effect_scaling", 0.0))
    
    state.placeholder = bool(raw.get("placeholder", false))
    
    return state
```

### Save Format

```gdscript
func to_save_dict() -> Dictionary:
    return {
        "level": level
    }

func apply_save_dict(save_data: Dictionary) -> void:
    level = int(save_data.get("level", level))
```

**Note:** Blessings are compact in saves - only level needed.

### Reset

```gdscript
func reset_to_default() -> void:
    level = default_level  // Usually 0 (undiscovered)
```

## State Access Pattern

### In GameState

```gdscript
# Storage
var elements: Dictionary = {}        // Key: element_id, Value: ElementState
var upgrades: Dictionary = {}        // Key: upgrade_id, Value: UpgradeState
var planets: Dictionary = {}         // Key: planet_id, Value: PlanetState
var blessings: Dictionary = {}       // Key: blessing_id, Value: BlessingState

# Ordered access
var element_ids_in_order: Array[String] = []
var upgrade_ids_in_order: Array[String] = []
```

### Access via Managers

```gdscript
// PlanetManager example
func get_planet_state(planet_id: String) -> PlanetState:
    return game_state.planets.get(planet_id, null)

func get_planet_entries() -> Array[Dictionary]:
    var entries = []
    for planet_id in game_state.planet_ids_in_order:
        var planet = get_planet_state(planet_id)
        if planet == null:
            continue
        entries.append({
            "id": planet.id,
            "name": planet.name,
            "level": planet.level,
            "workers": planet.workers.clone()
            // ... etc
        })
    return entries
```

### Direct Access (Read Only)

```gdscript
// In UI/controllers (read-only preferred)
var upgrade = game_state.upgrades[upgrade_id]
if upgrade.current_level > 0:
    show_upgrade_effect(upgrade.effect_type, upgrade.get_effect_value())
```

## Serialization Chain

```
Save Flow:
GameState.to_save_dict()
    ├── elements: { id: element.to_save_dict(), ... }
    ├── upgrades: { id: upgrade.to_save_dict(), ... }
    ├── planets: { id: planet.to_save_dict(), ... }
    ├── blessings: { id: blessing.to_save_dict(), ... }
    └── ...

Load Flow:
GameState.apply_save_dict(save_data)
    GameStateSerializer.apply_save_dict(game_state, save_data)
        ├── For each element: element.apply_save_dict(saved_data)
        ├── For each upgrade: upgrade.apply_save_dict(saved_data)
        ├── For each planet: planet.apply_save_dict(saved_data, xp_to_next)
        └── For each blessing: blessing.apply_save_dict(saved_data)
```

## Design Principles

1. **Immutable defaults**: Store `default_*` copies for reset
2. **Cloning**: Return cloned `DigitMaster` values to prevent external mutation
3. **Validation**: Clamp values in apply (e.g., `level = maxi(1, level)`)
4. **Minimal saves**: Only save dynamic values, not static config
5. **Calculated fields**: Some values (like `xp_to_next`) are computed on load

## Related Documentation

- [Architecture](./architecture.md) - Manager relationship
- [Save System](./save_system.md) - Serialization details
- [Game Mechanics](./game_mechanics.md) - How states are used
- [Data Format](./data_format.md) - JSON source data