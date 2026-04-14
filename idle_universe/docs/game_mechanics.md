# Game Mechanics

## Overview

Idle Universe is an idle game with multiple interconnected progression systems. Players:
1. Smash elements to generate more elements
2. Collect Dust through oblations
3. Use Dust to buy upgrades
4. Purchase and level up planets
5. Earn Research Points for moon upgrades
6. Unlock blessings for passive bonuses
7. Progress through game eras

## Core Loop

```
Smash Elements → Collect Elements → Convert to Dust
                                         ↓
                    Research ← Planets ← Dust
                        ↓
                  Moon Upgrades → Era Progression
```

## Element System

**Files:**
- [`src/core/managers/progression_manager.gd`](../src/core/managers/progression_manager.gd)
- [`src/core/state/element_state.gd`](../src/core/state/element_state.gd)
- [`src/data/elements.json`](../src/data/elements.json)

### How It Works

Elements progress through the periodic table. Each element:
- Has an index (1-118 for real elements, plus special elements)
- Produces the next element in the chain
- Can be unlocked with Dust

```gdscript
class_name ElementState

var id: String          # e.g., "ele_H"
var name: String        # e.g., "H"
var index: int         # Priority/progression order
var unlocked: bool     # Whether player has access
var amount: DigitMaster # Current amount owned
var cost: DigitMaster   # Unlock cost
var produces: String    # ID of element this produces
```

### Element Chain Example

```
ele_P (Protons) → ele_H (Hydrogen) → ele_He (Helium) → ... → ele_Og (Oganesson) → Dust
```

### Element Sections

Elements are grouped into sections that determine visibility:
- Section 1: Indexes 1-10
- Section 2: Indexes 11-30
- Section 3: Indexes 31-54
- Section 4: Indexes 55-86
- Section 5: Indexes 87-118

See also: [Elements Documentation](./elements.md)

## Upgrade System

**Files:**
- [`src/core/managers/upgrade_manager.gd`](../src/core/managers/upgrade_manager.gd)
- [`src/data/upgrades.json`](../src/data/upgrades.json)

### Upgrade Types

| Upgrade | Effect | Currency |
|---------|--------|----------|
| `particle_smasher` | Auto-smash selected element | ele_H |
| `critical_smasher_chance` | Chance to spawn extra protons | ele_H |
| `fission_1` | Split production into two atoms | ele_He |
| `resonant_yield` | Chance for extra output | ele_Li |
| `double_hit` | Chance for extra manual smash | ele_Li |
| `elemental_resonance` | Dust recipe payouts per resonant element | ele_H |

### Cost Modes

- `additive_power` - Linear cost scaling with power formula
- `element_sequence_linear` - Costs increase by fixed step per level

## Planet System

**Files:**
- [`src/core/managers/planet_manager.gd`](../src/core/managers/planet_manager.gd)
- [`src/core/state/planet_state.gd`](../src/core/state/planet_state.gd)
- [`src/data/planets.json`](../src/data/planets.json)

### Planet Properties

```gdscript
class_name PlanetState

var id: String
var name: String
var unlocked: bool
var level: int
var xp: DigitMaster           # Current XP
var xp_to_next_level: DigitMaster
var workers: DigitMaster
var max_level: int

# Costs
var purchase_cost_dust: DigitMaster
var purchase_cost_orbs: int
```

### Planet Workers

- Workers produce XP (allocated to planet leveling) or Research Points
- Worker allocation ratio determines split:
  - 0% - All workers produce Research Points
  - 100% - All workers produce planet XP
  - Values in between split production

### XP Calculation

Planet XP requirements use exponential scaling:

```gdscript
func calculate_planet_xp_requirement(level: int) -> DigitMaster:
    if level <= 1:
        return DigitMaster.new(1500.0)  # LEVEL_TWO_REQUIREMENT
    
    var growth_steps := 23.0  # 25 levels - 2 (start at level 2)
    var growth_ratio := pow(10M / 1.5K, 1/23)
    requirement = 1500 * pow(growth_ratio, level - 1)
```

See also: [Planets Documentation](./planets.md)

## Blessing System

**Files:**
- [`src/core/managers/blessing_manager.gd`](../src/core/managers/blessing_manager.gd)
- [`src/core/state/blessing_state.gd`](../src/core/state/blessing_state.gd)
- [`src/data/blessings.json`](../src/data/blessings.json)

### Blessing Types

Blessings have rarities that determine roll chances:
- Uncommon (most common)
- Rare
- Legendary
- Exotic
- Exalted
- Divine (rarest)

### Effect Types

| Effect | Description |
|--------|-------------|
| `critical_smasher_chance` | Chance for bonus critical protons |
| `fission_split` | Chance for atomic fission |
| `crystal_spawn` | Increases crystal spawn rates |
| `bonus_element_output` | Chance for additional element copies |

### Blessing Generation

1. Generating elements adds mass to blessing progress
2. Each element index contributes: `mass += amount × element_index`
3. When progress reaches cost threshold, a new blessing counter increments
4. Players open blessings to roll random ones

```gdscript
# Cost formula (quadratic)
cost = 10x² + 400x + 1600
# where x = blessing_count
```

See also: [Blessings Documentation](./blessings.md)

## Oblation System

**Files:**
- [`src/core/managers/oblation_manager.gd`](../src/core/managers/oblation_manager.gd)
- [`src/data/oblations.json`](../src/data/oblations.json)

### How It Works

Oblations provide recipes to convert elements into Dust:
- Recipes require specific element combinations (slots)
- Completing recipes grants Dust
- Research Points provide multipliers to Dust output
- Elemental Resonance upgrade increases payout per resonant element

### Slot System

Recipes have slots that accept:
- Specific element IDs
- Element categories (by index)
- "any unlocked" elements

### Multipliers

- **Base Dust** - From recipe base value
- **Research Bonus** - Multiplied by research points formula
- **Resonance Bonus** - +4% per resonant element (with upgrade)
- **Oblation Effects** - From active oblation bonuses

See also: [Oblations Documentation](./oblations.md)

## Era System

**Files:**
- [`src/core/managers/progression_manager.gd`](../src/core/managers/progression_manager.gd)

### Era Progression

| Era | Index | Unlock Condition |
|-----|-------|------------------|
| Atomic Era | 0 | Starting era |
| Planetary Era | 1 | Unlock element ele_Ne (Neon) |
| Solar Era | 2 | Coming soon |
| Space Era | 3 | Coming soon |
| (Future) | 4 | Coming soon |

### Era Effects

Unlocking a new era:
1. Opens new content (planets, upgrades, etc.)
2. May enable planet purchase in planetary era
3. Unlocks new upgrade tiers requiring both elements and dust

## Tick System

**File:** [`src/core/tick_system.gd`](../src/core/tick_system.gd)

The tick system processes time-based operations:
1. Updates planet production (workers → XP/Research)
2. Increments tick counter
3. Accumulates total played time
4. Triggers auto-save at intervals

## Resource Management

### Resources

| Resource | Purpose |
|----------|---------|
| **Elements** | Raw materials, used for oblations, unlock progression |
| **Dust** | Primary currency for upgrades, planet workers |
| **Orbs** | Secondary currency for planet purchases |
| **Research Points** | Currency for moon upgrades |

### Resource Operations

```gdscript
# Querying
get_resource_amount(resource_id: String) -> DigitMaster
can_afford_resource(resource_id: String, cost: DigitMaster) -> bool

# Modifying
add_resource(resource_id: String, amount: DigitMaster) -> void
spend_resource(resource_id: String, amount: DigitMaster) -> bool

# Production
produce_resource(resource_id: String, amount: DigitMaster) -> void
```

## Critical Hits System

Upgrades can provide chances for critical hits:
- `critical_smasher_chance` - Auto-smashes have chance for bonus
- `critical_routing` - Increases critical hit frequency
- `critical_payload` - Increases bonus output from critical hits
- Blessing effects stack with upgrade effects

## Fission System

The `fission_split` effect gives chance for production splitting:
- When triggered, one element production becomes two atoms
- Sum of resulting atoms' weights equals original weight
- Both resulting elements must be unlocked

## Related Documentation

- [Architecture](./architecture.md) - System design
- [Bootstrap Systems](./bootstrap_systems.md) - Loader, routing, dirty refresh
- [Resource Manager](./resource_manager.md) - Resource flow
- [Prestige Manager](./prestige_manager.md) - Prestige path
- [Reset Manager](./reset_manager.md) - Run reset behavior
- [Elements](./elements.md) - Element progression details
- [Upgrades](./upgrades.md) - Upgrade documentation
- [Planets](./planets.md) - Planet mechanics
- [Blessings](./blessings.md) - Blessing system
- [Oblations](./oblations.md) - Dust recipes
- [Save System](./save_system.md) - Persistence