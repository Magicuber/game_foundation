# Planets Documentation

## Overview

The planetary system provides long-term progression and production bonuses. Players purchase planets using Dust and Orbs, then assign workers to generate XP (leveling up planets) or Research Points (unlocking moon upgrades).

**Key Files:**
- [`src/core/managers/planet_manager.gd`](../src/core/managers/planet_manager.gd) - Planet logic
- [`src/core/state/planet_state.gd`](../src/core/state/planet_state.gd) - Planet state class
- [`src/data/planets.json`](../src/data/planets.json) - Planet definitions
- [`src/data/planet_menu.json`](../src/data/planet_menu.json) - Planet menu configuration

## Planet Structure

```gdscript
class_name PlanetState

var id: String                # Unique identifier
var name: String              # Display name
var unlocked: bool            # Whether accessible

# Level and XP
var level: int               # Current level (1-max)
var xp: DigitMaster          # Current XP toward next level
var xp_to_next_level: DigitMaster  # XP required for next level
var max_level: int           # Level cap (e.g., 25 for Planet A)

# Workers
var workers: DigitMaster     # Number of workers assigned
var worker_allocation_to_xp: float  # 0.0-1.0 split for XP vs Research

# Costs
var purchase_cost_dust: DigitMaster  # Dust cost to purchase
var purchase_cost_orbs: int        # Orbs cost to purchase
```

## Planetary Era

### Unlock Requirements

To unlock Planetary Era (Era 1):
1. Must have unlocked element `ele_Ne` (Neon)
2. Planetary Era unlocks planet purchase

```gdscript
# game_state.gd
const PLANETARY_ERA_RESOURCE_IDS := ["ele_H", "ele_He", "ele_C", "ele_O", "ele_Ne"]
const PLANETARY_ERA_RESOURCE_COST := 10000.0
const PLANETARY_ERA_ORB_COST := 1000
const ERA_MENU_UNLOCK_ELEMENT_ID := "ele_Ne"
```

## Planet List

### Planet A (Default)

- **ID:** `planet_a`
- **Starting Status:** Purchase unlocked at Planetary Era
- **Max Level:** 25
- **XP Requirements:** Exponential scaling from 1.5K to 10M

### Planet B

- **ID:** `planet_b`
- **Unlock:** Milestone reward (Reach Planet A Level 5)
- **Purchase Cost:** Dust + Orbs

### Future Planets (placeholder)

- Planet C, D, E (placeholder for future content)
- Unlock via future milestone completion

## Worker System

### Worker Assignment

Workers generate either:
- **XP:** Levels up the planet (permanent bonuses)
- **Research Points:** Currency for moon upgrades

```gdscript
# Worker allocation: 0.0 = 100% Research, 1.0 = 100% XP
var XP_allocation_ratio: float  # Set via slider

# Production calculations
xp_generated = workers × delta_time × allocation_ratio × XP_multiplier
research_generated = workers × delta_time × (1 - allocation_ratio) × RP_per_production
```

### Worker Costs

Workers have exponential cost scaling:

```gdscript
# Formula: cost = base_cost × (ratio ^ worker_count)
# Rounded to nearest 25

func calculate_planet_worker_cost(planet: PlanetState) -> DigitMaster:
    var worker_count := planet.workers.to_float()
    var raw_cost := PLANET_WORKER_BASE_COST × pow(PLANET_WORKER_COST_RATIO, worker_count)
    var rounded_cost := ceil(raw_cost / 25.0) × 25.0
    return DigitMaster.new(rounded_cost)
```

**Constants:**
```gdscript
const PLANET_WORKER_BASE_COST := 1000.0
const PLANET_WORKER_COST_RATIO := 1.25
const PLANET_WORKER_COST_ROUND_TO := 25.0
```

## XP Progression

### XP Requirements

Planet XP requirements scale exponentially:

```gdscript
func calculate_planet_xp_requirement(level: int) -> DigitMaster:
    if level <= 1:
        return DigitMaster.new(PLANET_XP_LEVEL_TWO_REQUIREMENT)  # 1500
    
    # 23 growth steps (level 2 to 25)
    var growth_steps := float(PLANET_A_MAX_LEVEL - 2)  # 23.0
    
    # Calculate growth ratio to reach 10M from 1.5K
    var growth_ratio := pow(
        PLANET_XP_LEVEL_TWENTY_FIVE_REQUIREMENT / PLANET_XP_LEVEL_TWO_REQUIREMENT,
        1.0 / growth_steps
    )  # ≈ 1.34
    
    var requirement := PLANET_XP_LEVEL_TWO_REQUIREMENT × pow(growth_ratio, float(level - 1))
    return DigitMaster.new(round(requirement))
```

**Example progression:**
| Level | XP Requirement |
|-------|---------------|
| 2 | 1,500 |
| 5 | ~3,600 |
| 10 | ~12,000 |
| 15 | ~40,000 |
| 20 | ~135,000 |
| 25 | 10,000,000 |

### XP Application

```gdscript
func apply_planet_xp(planet: PlanetState, xp_amount: DigitMaster) -> void:
    if level >= max_level:
        return
    
    var current_xp := planet.xp.add(xp_amount)
    var xp_to_next := planet.xp_to_next_level
    
    while level < max_level and current_xp.compare(xp_to_next) >= 0:
        current_xp = current_xp.subtract(xp_to_next)
        level += 1
        planet.level = level
        
        if level >= max_level:
            current_xp = DigitMaster.zero()
            break
        
        xp_to_next = calculate_planet_xp_requirement(level)
    
    planet.xp = current_xp
    planet.xp_to_next_level = xp_to_next
```

## Research Points

Research Points (RP) are earned from worker production and used for:
- Moon upgrades
- Permanent bonuses

### RP Generation

```gdscript
func process_planet_production(delta_seconds: float) -> Dictionary:
    var allocation_to_xp := clampf(planet.worker_allocation_to_xp, 0.0, 1.0)
    
    if allocation_to_xp < 1.0:
        var rp_amount := planet.workers.multiply_scalar(
            delta_seconds × (1.0 - allocation_to_xp) × RESEARCH_POINTS_PER_PRODUCTION
        )
        game_state._apply_research_progress(rp_amount)
```

**Constant:**
```gdscript
const RESEARCH_POINTS_PER_PRODUCTION := 0.001
```

## Milestones

Planet milestones track progression and unlock new planets:

```gdscript
# game_state.gd
const PRESTIGE_MILESTONES := [
    {
        "id": "planet_a_5",
        "title": "Planet A Lv. 5",
        "description": "Reach Planet A level 5.",
        "kind": "planet_level",
        "planet_id": "planet_a",
        "required_level": 5,
        "reward_points": 1,
        "unlock_planet_id": "planet_b"
    }
]
```

### Milestone Completion

When a planet reaches required level:
1. Milestone marked complete
2. Rewards granted (prestige points)
3. New content unlocked (next planet purchase)

## Planet Menu System

**File:** [`src/data/planet_menu.json`](../src/data/planet_menu.json)

The planet menu defines:
- Visual layout stages
- Node positions
- Visibility conditions
- Connections between planets/moons

### Menu Structure

```json
{
    "root": {"id": "root", "label": "Home"},
    "stages": [
        {
            "id": "solar_system_1",
            "stage_index": 1,
            "visible_planets": ["planet_a", "planet_b"],
            "visible_moons": ["moon_1", "moon_2"],
            "lines": [{"from_id": "root", "to_id": "planet_a"}]
        }
    ],
    "planets": {
        "planet_a": {"label": "Planet A", "tier": 1, "moon_ids": ["moon_1"]}
    },
    "moons": {
        "moon_1": {"label": "Moon 1", "parent_planet_id": "planet_a"}
    }
}
```

## Moon Upgrades

Moons provide upgrade slots activated by owning their parent planet:

```gdscript
func get_moon_upgrade_entries(moon_id: String) -> Array[Dictionary]:
    var moon_entry = game_state._planet_menu_moons.get(moon_id, {})
    var parent_owned := is_planet_owned(moon_entry.parent_planet_id)
    var purchased_ids := get_purchased_moon_upgrade_ids(moon_id)
    
    for upgrade in moon_entry.get("upgrades", []):
        var rp_cost = DigitMaster.from_variant(upgrade.rp_cost)
        var can_purchase := parent_owned and not purchased and 
                           research_points.compare(rp_cost) >= 0
```

## Multipliers

### XP Gain Multiplier

Oblation effects provide XP bonuses:

```gdscript
func get_planet_xp_gain_multiplier() -> float:
    return oblation_manager.get_planet_xp_gain_multiplier()
```

### Production Calculation

```gdscript
final_xp_per_second = workers × allocation_ratio × oblation_multiplier × blessing_effects
final_rp_per_second = workers × (1 - allocation_ratio) × RESEARCH_POINTS_PER_PRODUCTION
```

## Save/Load

Planet state persists:

```gdscript
// Save data structure
{
    "planets": {
        "planet_a": {
            "level": 5,
            "xp": {"mantissa": 1.23, "exponent": 8},
            "workers": {"mantissa": 3.0, "exponent": 0},
            "worker_allocation_to_xp": 0.7
        }
    },
    "current_planet_id": "planet_a",
    "moon_upgrade_purchases": {
        "moon_1": ["upgrade_1", "upgrade_2"]
    }
}
```

## Reset Behavior

On soft reset:
- Planet ownership preserved (planets stay owned)
- Levels reset to 1
- XP reset to 0
- Workers reset to 0
- Allocation reset to 1.0 (100% XP)

```gdscript
func _reset_planets_to_owned_defaults() -> void:
    for planet_id in planet_ids_in_order:
        var planet = get_planet_state(planet_id)
        if is_planet_owned(planet_id):
            # Reset progression but keep owned
            planet.level = 1
            planet.xp = DigitMaster.zero()
            planet.workers = DigitMaster.zero()
            planet.worker_allocation_to_xp = 1.0
```

## Related Documentation

- [Game Mechanics](./game_mechanics.md) - Core loop
- [Era System](./game_mechanics.md#era-system) - Era progression
- [Oblations](./oblations.md) - XP multipliers
- [Milestones](./game_mechanics.md) - Planet unlocks
- [Data Format](./data_format.md) - JSON structure