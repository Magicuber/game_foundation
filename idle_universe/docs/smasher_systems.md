# Smasher Systems

## Overview

The core gameplay mechanic of Idle Universe involves "smashing" elements to generate new elements. This system includes manual and auto-smashing, critical hits, fission splitting, and elemental variants.

**Key Files:**
- [`src/systems/element_system.gd`](../src/systems/element_system.gd) - Smash logic
- [`src/systems/upgrades_system.gd`](../src/systems/upgrades_system.gd) - Upgrade effects

## Smashing Types

### Manual Smash

Player-initiated via button click:

```gdscript
# From element_system.gd
func manual_smash(game_state: GameState, upgrades_system: UpgradesSystem) -> Dictionary:
    var result := _build_smash_result(
        game_state, 
        upgrades_system, 
        game_state.current_element_id, 
        false  # is_auto = false
    )
    _apply_smash_result(game_state, result, false)
    game_state.total_manual_smashes += 1
    return result
```

### Auto Smash

Automatically triggered by tick system:

```gdscript
# From element_system.gd
func resolve_auto_smash(game_state: GameState, upgrades_system: UpgradesSystem, 
                        element_id: String) -> Dictionary:
    var result := preview_auto_smash(game_state, upgrades_system, element_id)
    apply_deferred_auto_smash_result(game_state, result)
    game_state.total_auto_smashes += 1
    return result

func preview_auto_smash(game_state: GameState, upgrades_system: UpgradesSystem, 
                       element_id: String) -> Dictionary:
    return _build_smash_result(game_state, upgrades_system, element_id, true)
```

## Smash Result Structure

```gdscript
{
    "source_element_id": "ele_H",           # Element being smashed
    "produced_resource_ids": ["ele_He"],   # All resources generated
    "produced_resource_id": "ele_He",     # Primary output
    "bonus_resource_ids": ["ele_He"],      # Extra from crits/bonuses
    "resource_counts": {"ele_He": 2},      # Final tallies
    "was_fission": false,                    # Did fission trigger?
    "variant": "normal",                     # Visual variant
    "rolled_variants": [],                   # All variants rolled
    "base_reward_multiplier": 1              # Combined variant multiplier
}
```

## Smasher Variants

Smashing can roll special variants that increase output:

### Variant Types

| Variant | Base Multiplier | Display Priority |
|---------|-----------------|------------------|
| Normal | 1× | Lowest |
| Foil | 2× | Medium |
| Holographic | 5× | High |
| Polychrome | 10× | Highest |

### Variant Constants

```gdscript
const VARIANT_NORMAL := "normal"
const VARIANT_FOIL := "foil"
const VARIANT_HOLOGRAPHIC := "holographic"
const VARIANT_POLYCHROME := "polychrome"

const VARIANT_BASE_REWARD_MULTIPLIERS := {
    VARIANT_NORMAL: 1,
    VARIANT_FOIL: 2,
    VARIANT_HOLOGRAPHIC: 5,
    VARIANT_POLYCHROME: 10
}

const VARIANT_PRIORITY_ORDER := [
    VARIANT_POLYCHROME,
    VARIANT_HOLOGRAPHIC,
    VARIANT_FOIL
]
```

### Rolling Variants

```gdscript
func _roll_smasher_variants(game_state: GameState) -> Array[String]:
    var rolled: Array[String] = []

    if _roll_percent_chance(game_state.get_foil_spawn_chance_percent()):
        rolled.append(VARIANT_FOIL)

    if _roll_percent_chance(game_state.get_holographic_spawn_chance_percent()):
        rolled.append(VARIANT_HOLOGRAPHIC)

    if _roll_percent_chance(game_state.get_polychrome_spawn_chance_percent()):
        rolled.append(VARIANT_POLYCHROME)

    return rolled
```

### Variant Chance Sources

Variant chances come from **blessings:**

```gdscript
# From game_state via blessing_manager
func get_foil_spawn_chance_percent() -> float:
    return blessing_manager.get_blessing_effect_total("foil_spawn")

func get_holographic_spawn_chance_percent() -> float:
    return blessing_manager.get_blessing_effect_total("holographic_spawn")

func get_polychrome_spawn_chance_percent() -> float:
    return blessing_manager.get_blessing_effect_total("polychrome_spawn")
```

### Display Variant

The displayed variant is the highest priority one rolled:

```gdscript
func _get_display_variant(rolled_variants: Array[String]) -> String:
    for variant in VARIANT_PRIORITY_ORDER:  # Poly > Holo > Foil
        if rolled_variants.has(variant):
            return variant
    return VARIANT_NORMAL
```

### Combined Multiplier

When multiple variants roll, multipliers multiply:

```gdscript
func _get_combined_reward_multiplier(rolled_variants: Array[String]) -> int:
    var multiplier := 1
    for variant in rolled_variants:
        multiplier *= VARIANT_BASE_REWARD_MULTIPLIERS[variant]
    return multiplier

# Examples:
# Foil only: 2×
# Foil + Holographic: 2 × 5 = 10×
# All three: 2 × 5 × 10 = 100×
```

## Critical Hits

### Auto Critical System

Particle Smasher critical hits spawn additional elements:

```gdscript
# From upgrades_system.gd
func get_auto_smash_spawn_count(game_state: GameState) -> int:
    var crit_chance := get_global_critical_smash_chance_percent(game_state)

    # Each 100% grants +1 base spawn
    var spawn_count := 1 + int(floor(crit_chance / 100.0))

    # Remainder % chance for extra
    var remainder := fmod(crit_chance, 100.0)
    if rng.randf() * 100.0 < remainder:
        spawn_count += 1

    return spawn_count
```

### Critical Chance Sources

| Source | Effect Type | Stacking |
|--------|-------------|----------|
| `critical_smasher_chance` upgrade | `critical_auto_smash` | Additive |
| `critical_smasher_chance_2` upgrade | `critical_auto_smash` | Additive |
| Blessings | `critical_auto_smash` | Additive |

```gdscript
func get_global_critical_smash_chance_percent(game_state: GameState) -> float:
    _ensure_aggregate_cache(game_state)

    # From upgrades
    var upgrade_crit := _cached_global_critical_smash_chance_percent

    # From blessings
    var blessing_crit := game_state.get_blessing_critical_smasher_bonus_percent()

    return upgrade_crit + blessing_crit
```

### Critical Payload (Bonus Output)

Critical auto-smashes can grant 3× output:

```gdscript
func should_trigger_critical_payload(game_state: GameState) -> bool:
    var chance := get_critical_payload_chance_percent(game_state)
    if chance <= 0.0:
        return false
    return rng.randf() * 100.0 < chance

# If triggered:
# Instead of 1 copy, get 3 copies of output element
```

Source: `critical_payload` upgrade (`EFFECT_CRITICAL_PAYLOAD_BONUS`)

### Manual Critical (Double Hit)

Manual smashes can trigger double output:

```gdscript
func should_trigger_manual_double_hit(game_state: GameState) -> bool:
    var chance := minf(1.0, get_manual_double_hit_chance(game_state))
    if chance <= 0.0:
        return false
    return rng.randf() < chance

# Source: double_hit upgrade (EFFECT_MANUAL_BONUS_OUTPUT)
```

### Resonant Yield (Bonus Elements)

Both manual and auto smashes can yield extra copies:

```gdscript
func should_trigger_resonant_yield(game_state: GameState) -> bool:
    var chance := minf(1.0, get_resonant_yield_chance(game_state))
    if chance <= 0.0:
        return false
    return rng.randf() < chance

# Source: resonant_yield upgrade (EFFECT_BONUS_ELEMENT_OUTPUT)
```

## Fission System

### Fission Mechanics

Fission splits production into two lower elements:

```gdscript
const FISSION_PART_COUNT := 2

func _build_smash_result(...) -> Dictionary:
    var produced_resource_ids: Array[String] = [produced_resource]
    var was_fission := false

    # Check if fission triggers
    if upgrades_system.should_trigger_fission(game_state):
        var fission_results := _roll_fission_split(game_state, produced_resource)
        if not fission_results.is_empty():
            produced_resource_ids = fission_results
            was_fission = true

            # Overflow fission grants extra base copies
            var overflow_count := upgrades_system.get_fission_overflow_base_copy_count(game_state)
            for _i in range(overflow_count):
                produced_resource_ids.append(produced_resource)
```

### Fission Split Logic

Finds two unlocked elements whose atomic numbers sum to the target:

```gdscript
func _roll_fission_split(game_state: GameState, produced_resource_id: String) -> Array[String]:
    var produced_element := game_state.get_element_state(produced_resource_id)
    var target_weight := produced_element.index  # Atomic number

    if target_weight <= 1:
        return []  # Can't split Hydrogen or lower

    var candidate_splits: Array[Dictionary] = []

    # Try all combinations: left + right = target
    var max_left := int(floor(float(target_weight - 1) / 2.0))
    for left_index in range(1, max_left + 1):
        var right_index := target_weight - left_index
        if left_index >= right_index:
            continue

        var left_elem := game_state.get_element_state_by_index(left_index)
        var right_elem := game_state.get_element_state_by_index(right_index)

        # Both must exist and be unlocked
        if left_elem == null or right_elem == null:
            continue
        if not left_elem.unlocked or not right_elem.unlocked:
            continue

        candidate_splits.append({"left_id": left_elem.id, "right_id": right_elem.id})

    if candidate_splits.is_empty():
        return []

    # Pick random valid split
    var split := candidate_splits[rng.randi_range(0, candidate_splits.size() - 1)]
    return [split.left_id, split.right_id]
```

### Fission Chance Sources

| Upgrade | Effect Type | Base Effect |
|---------|-------------|-------------|
| `fission_1` | `fission_split` | 1.0% per level |
| `fission_2` | `fission_split` | 1.0% per level |
| Blessings | `fission_split` | Varies |

```gdscript
func get_fission_chance_percent(game_state: GameState) -> float:
    _ensure_aggregate_cache(game_state)
    var upgrade_fission := _cached_fission_chance_percent
    var blessing_fission := game_state.get_blessing_fission_bonus_percent()
    return maxf(0.0, upgrade_fission + blessing_fission)
```

### Fission Overflow

When fission chance exceeds 100%:

```gdscript
func get_fission_overflow_base_copy_count(game_state: GameState) -> int:
    # Chance beyond 100% grants extra copies
    var overflow_chance := get_fission_chance_percent(game_state) - 100.0
    if overflow_chance <= 0.0:
        return 0

    # Each 100% overflow = +1 guaranteed extra base copy
    var copy_count := int(floor(overflow_chance / 100.0))
    var remainder := fmod(overflow_chance, 100.0)
    if rng.randf() * 100.0 < remainder:
        copy_count += 1

    return copy_count
```

**Example:**
- Fission chance: 250%
- Base fission produces 2 elements
- Overflow: 150% → +1 guaranteed extra base copy
- Total: 2 fission products + 1 base element = 3 elements

## Complete Smash Flow

```
1. Player clicks smash button OR auto-smash triggers
        ↓
2. _build_smash_result():
   a. Get source element's "produces" target
   b. Check fission → if yes, split target into 2 elements
   c. Get overflow copies
        ↓
3. Apply variant multipliers to all outputs
        ↓
4. Check critical payload (auto) / double hit (manual)
   → Add bonus copies
        ↓
5. Check resonant yield → Add bonus copies
        ↓
6. _apply_smash_result():
   → Produce all elements to game state
   → Increment manual/auto smash counters
        ↓
7. Return result for UI display/animation
```

## Upgrade Effects Summary

| Upgrade | Effect on Smashing |
|---------|-------------------|
| `particle_smasher` | Enables auto-smash, faster rate per level |
| `critical_smasher_chance` | +2% global crit chance per level |
| `critical_smasher_chance_2` | +2% global crit chance per level |
| `fission_1` | +1% fission chance per level |
| `fission_2` | +1% fission chance per level |
| `resonant_yield` | +1% bonus element chance per level |
| `double_hit` | +1% manual double hit chance per level |
| `smasher_bearings` | -4% auto-smash interval per level |
| `critical_payload` | +1% chance for 3× output per level |
| `critical_routing` | +1% global crit chance per level |
| `fission_calibration` | +0.75% fission chance per level |

## Related Documentation

- [Upgrades](./upgrades.md) - Detailed upgrade information
- [Tick System](./tick_system.md) - Auto-smash timing
- [Element System](./elements.md) - Element progression
- [Blessings](./blessings.md) - Variant chances from blessings
- [Game Mechanics](./game_mechanics.md) - Core loop