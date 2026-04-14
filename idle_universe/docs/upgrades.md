# Upgrades Documentation

## Overview

Upgrades provide permanent bonuses and automation that enhance the core gameplay loop. They unlock progressively and use various currencies with different cost scaling modes.

**Key Files:**
- [`src/core/managers/upgrade_manager.gd`](../src/core/managers/upgrade_manager.gd) - Upgrade logic
- [`src/core/state/upgrade_state.gd`](../src/core/state/upgrade_state.gd) - Upgrade state class
- [`src/data/upgrades.json`](../src/data/upgrades.json) - Upgrade definitions

## Upgrade Structure

```gdscript
class_name UpgradeState

var id: String                      # Unique identifier
var name: String                    # Display name
var description: String             # Tooltip description
var currency_id: String             # Primary currency (element ID or "dust")
var secondary_currency_id: String   # Secondary currency (optional)
var tier: int                      # Unlock tier/era
var required_era_index: int         # Minimum era requirement

var base_cost: float               # Starting cost
var cost_mode: String              # Cost scaling algorithm
var cost_scaling: float             # Scaling multiplier
var cost_step: float               # Linear step amount

var max_level: int                 # Maximum upgrade level
var current_level: int             # Current owned level
var current_cost: DigitMaster        # Cost for next level
var secondary_current_cost: DigitMaster  # Secondary cost

var effect_type: String            # What this upgrade does
var effect_amount: float           # Base effect value
var sequence_start_index: int       # For sequence-based upgrades
var sequence_requires_unlock: bool  # Whether sequence needs unlock
```

## Cost Modes

### 1. Additive Power Mode (`additive_power`)

Cost increases exponentially with level:

```gdscript
# Formula: cost = base_cost × (scaling ^ level)
current_cost = base_cost × pow(cost_scaling, current_level)
```

**Used by:** Most standard upgrades

### 2. Element Sequence Linear Mode (`element_sequence_linear`)

Cost steps up based on element index in sequence:

```gdscript
# Formula: cost = base_cost + (step × current_level)
current_cost = base_cost + (cost_step × current_level)
```

**Used by:** Elemental Resonance upgrade

## Effect Types

| Effect Type | Description | Affected Upgrades |
|-------------|-----------|-------------------|
| `auto_smash` | Auto-smashes selected element | particle_smasher |
| `auto_smash_speed_bonus` | Reduces auto-smash cooldown | smasher_bearings |
| `critical_auto_smash` | Chance for bonus auto-smash protons | critical_smasher_chance, critical_smasher_chance_2 |
| `critical_spawn_bonus` | Increases critical smash output | critical_payload |
| `fission_split` | Chance to split into two atoms | fission_1, fission_2 |
| `bonus_element_output` | Chance for extra element copies | resonant_yield |
| `manual_bonus_output` | Chance for extra manual smash output | double_hit |
| `dust_resonance_sequence` | +X% dust per resonant element | elemental_resonance |

## Available Upgrades

### Tier 1 (Atomic Era)

| ID | Name | Currency | Max Level | Effect |
|----|------|----------|-----------|--------|
| `particle_smasher` | Particle Smasher | ele_H | 60 | Auto-smash selected element |
| `critical_smasher_chance` | Critical Smasher Chance | ele_H | 20 | Chance for bonus auto-smash protons |
| `elemental_resonance` | Elemental Resonance | ele_H | 118 | +4% dust payout per resonant element |
| `fission_1` | Fission | ele_He | 25 | Chance to split production |
| `resonant_yield` | Resonant Yield | ele_Li | 20 | Chance for extra element copies |
| `double_hit` | Double Hit | ele_Li | 20 | Chance for extra manual smash output |
| `critical_routing` | Critical Routing | ele_B | 20 | Critical smashes more frequent |
| `smasher_bearings` | Smasher Bearings | ele_N | 25 | Auto-smash resolves faster |
| `critical_payload` | Critical Payload | ele_O | 15 | Critical smashes create more output |
| `fission_calibration` | Fission Calibration | ele_F | 20 | Fission triggers more often |

### Tier 2 (Planetary Era)

| ID | Name | Currency | Secondary | Max Level | Effect |
|----|------|----------|-----------|-----------|--------|
| `critical_smasher_chance_2` | Critical Smasher Chance II | ele_Na | dust | 20 | Chance for bonus auto-smash protons |
| `fission_2` | Fission II | ele_Mg | dust | 25 | Chance to split production |

## Era Requirements

Upgrades can require specific eras:

```json
{
    "id": "critical_smasher_chance_2",
    "tier": 2,
    "required_era_index": 1,
    ...
}
```

- `tier` - Visual grouping in UI
- `required_era_index` - Minimum era to purchase (1 = Planetary Era)

## Purchase Logic

### Can Afford Check

```gdscript
# upgrade_manager.gd (via game_state)
func can_afford_cost_entries(cost_entries: Array[Dictionary]) -> bool:
    for entry in cost_entries:
        var resource_id = entry.resource_id
        var required = entry.required_amount
        if not can_afford_resource(resource_id, required):
            return false
    return true
```

### Purchase Flow

```gdscript
# game_state.gd - upgrade-related methods
func set_upgrade_level(upgrade_id: String, level: int) -> void:
    upgrade_manager.set_upgrade_level(upgrade_id, level)

game_state.spend_cost_entries_atomic(cost_entries) -> bool
```

### Cost Recalculation

When upgrading, costs update:

```gdscript
# upgrade_state.gd
func advance_level() -> void:
    current_level += 1
    recalculate_cost()

func recalculate_cost() -> void:
    match cost_mode:
        "additive_power":
            current_cost = DigitMaster.new(base_cost * pow(cost_scaling, current_level))
        "element_sequence_linear":
            current_cost = DigitMaster.new(base_cost + cost_step * current_level)
```

## Effect Application

### Blessing Synergies

Blessing effects stack with upgrade effects:

```gdscript
# blessing_manager.gd
func get_blessing_critical_smasher_bonus_percent() -> float:
    return get_blessing_effect_total(BlessingState.EFFECT_CRITICAL_SMASHER_CHANCE)

func get_blessing_fission_bonus_percent() -> float:
    return get_blessing_effect_total(BlessingState.EFFECT_FISSION_CHANCE)
```

### Total Effect Calculation

```gdscript
# Total effect = (base_effect × upgrade_level) + blessing_effects
total_auto_smash_rate = base_rate × particle_smasher_level + blessing_effects
total_critical_chance = critical_upgrade_level × critical_upgrade_effect + blessing_critical_effects
```

## Save/Load

Upgrades persist through save/load:

```gdscript
# Serializing
var upgrade_data = {}
for upgrade_id in upgrade_ids_in_order:
    var upgrade = upgrades[upgrade_id]
    upgrade_data[upgrade_id] = {
        "level": upgrade.current_level,
        "cost": upgrade.current_cost.to_save_data()
    }

# Deserializing
func set_upgrade_level(upgrade_id: String, level: int) -> void:
    var upgrade = get_upgrade_state(upgrade_id)
    if upgrade:
        upgrade.current_level = level

game_state.set_upgrade_current_cost(upgrade_id, cost)
game_state.set_upgrade_secondary_current_cost(upgrade_id, secondary_cost)
```

## Reset Behavior

On soft reset (not prestige):

```gdscript
func reset_upgrades_to_defaults() -> void:
    for upgrade_id in game_state.upgrade_ids_in_order:
        var upgrade = get_upgrade_state(upgrade_id)
        if upgrade == null:
            continue
        upgrade.reset_to_default()

func reset_to_default() -> void:
    current_level = 0
    current_cost = DigitMaster.new(base_cost)
```

## Upgrade Visibility

Upgrades appear in UI based on:
1. Era requirements met
2. Currency element unlocked
3. Optional: Other conditions

```gdscript
# Check if upgrade should be visible
if upgrade.required_era_index <= game_state.unlocked_era_index:
    if game_state.has_element(upgrade.currency_id):
        show_upgrade = true
```

## Related Documentation

- [Game Mechanics](./game_mechanics.md) - How upgrades affect gameplay
- [Data Format](./data_format.md) - JSON structure details
- [Blessings](./blessings.md) - How blessings stack with upgrades
- [Elements](./elements.md) - Element unlock currency