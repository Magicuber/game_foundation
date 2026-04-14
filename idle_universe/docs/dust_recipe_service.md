# Dust Recipe Service

## Overview

The `DustRecipeService` calculates Dust rewards from converting elements. It handles element selection, quantity scaling, and complex formulas involving diversity, stability, and tier quality bonuses.

**File:** [`src/services/dust_recipe_service.gd`](../src/services/dust_recipe_service.gd)

## Purpose

When players "obliterate" (convert) elements to Dust, this service:
1. Tracks which elements are selected and in what quantities
2. Calculates Dust payout based on complex formulas
3. Considers element diversity, atomic weights, and stability
4. Applies upgrade multipliers (Elemental Resonance)

## Selection System

### Selection Steps

Players choose how much of each element to convert via stepped percentages:

```gdscript
const SELECTION_STEPS := [0.0, 0.10, 0.25, 0.50, 1.0]
// None, 10%, 25%, 50%, 100% of owned amount
```

### Selection State

```gdscript
var _selection_indices: Dictionary = {}
// Key: element_id (String)
// Value: step index (0-4)

// Example:
{
    "ele_H": 4,    // 100% of Hydrogen
    "ele_He": 2,   // 25% of Helium
    "ele_Li": 0    // Not selected (or cleared)
}
```

### Cycling Selection

```gdscript
func cycle_selection(element_id: String) -> void:
    var next_index := (get_selection_index(element_id) + 1) % SELECTION_STEPS.size()
    if next_index == 0:
        _selection_indices.erase(element_id)  // Clear selection
    else:
        _selection_indices[element_id] = next_index
    invalidate()  // Mark cache dirty

func cycle_all_unlocked_selections(game_state: GameState) -> void:
    // Cycle ALL unlocked elements simultaneously
    // Useful for "select all" functionality
```

### Getting Selection Amounts

```gdscript
func get_selection_fraction(element_id: String) -> float:
    var index := clampi(get_selection_index(element_id), 0, SELECTION_STEPS.size() - 1)
    return SELECTION_STEPS[index]
    // Returns: 0.0, 0.10, 0.25, 0.50, or 1.0

// Example calculation for Hydrogen:
// Owned: 1.5e20, Selection: index 2 (25%)
// Selected amount: 1.5e20 × 0.25 = 3.75e19
```

## Dust Calculation Formula

The payout uses a sophisticated formula with multiple components:

```
Dust = base_scalar × quantity^quantity_exponent × diversity^diversity_exponent × avg_quality × resonance_bonus

Where:
- base_scalar = 0.024
- quantity_exponent = 0.90
- diversity_exponent = 0.55
- quality = hybrid of stability and tier scores
```

### Constants

```gdscript
const BASE_SCALAR := 0.024           // Overall dust payout tuning
const QUANTITY_EXPONENT := 0.90      // Diminishing returns on bulk
const DIVERSITY_EXPONENT := 0.55     // Reward for mixing elements
const STABILITY_WEIGHT := 0.65       // Stability vs tier importance
const TIER_WEIGHT := 0.35            // Tier score weight
```

### Stability Scores

Elements have intrinsic stability values (based on nuclear physics approximations):

```gdscript
const STABILITY_BY_INDEX := {
    1: 0.000,   // Hydrogen (unstable, decays)
    2: 0.804,   // Helium (stable)
    3: 0.637,   // Lithium
    4: 0.734,   // Beryllium
    5: 0.787,   // Boron
    6: 0.873,   // Carbon
    7: 0.850,   // Nitrogen
    8: 0.907,   // Oxygen
    9: 0.884,   // Fluorine
    10: 0.913,  // Neon
}

func _get_stability_score(element_index: int) -> float:
    if STABILITY_BY_INDEX.has(element_index):
        return STABILITY_BY_INDEX[element_index]
    
    // Fallback formula for elements 11-118
    var tier_ratio := sqrt(clampf(element_index / 118.0, 0.0, 1.0))
    return clampf(0.45 + (0.45 × tier_ratio), 0.0, 1.0)
```

**Stability ranges:** 0.0 (unstable) to ~1.0 (very stable)

### Tier Score

How advanced the element is relative to current progress:

```gdscript
func _get_hybrid_quality(game_state, element_id, highest_unlocked_index) -> float:
    var element := game_state.get_element_state(element_id)
    var atomic_number := element.index
    
    // Tier: how far along this element is (0.0 = early, 1.0 = max unlocked)
    var tier_score := sqrt(clampf(atomic_number / highest_unlocked_index, 0.0, 1.0))
    
    // Stability: inherent property
    var stability_score := _get_stability_score(atomic_number)
    
    // Hybrid: weighted combination
    return clampf(
        (STABILITY_WEIGHT × stability_score) + (TIER_WEIGHT × tier_score),
        0.0, 
        1.0
    )
```

**Example calculation:**
- Element: Oxygen (atomic number 8)
- Highest unlocked: Neon (10)
- Tier score: sqrt(8/10) = 0.89
- Stability score: 0.907
- Hybrid quality: 0.65×0.907 + 0.35×0.89 = 0.90

### Full Calculation Steps

```gdscript
func _ensure_cache(game_state, upgrades_system) -> void:
    if not _cache_dirty:
        return
    
    // Step 1: Collect selected elements
    _cached_selected_amounts.clear()
    _cached_selected_element_ids.clear()
    
    for element_id in _selection_indices.keys():
        var fraction := get_selection_fraction(element_id)
        var owned_amount: DigitMaster = game_state.get_resource_amount(element_id)
        var selected_amount := owned_amount.multiply_scalar(fraction)
        
        _cached_selected_amounts[element_id] = selected_amount
        _cached_selected_element_ids.append(element_id)
    
    _cached_selected_element_ids.sort()
    
    if _cached_selected_amounts.is_empty():
        _cached_preview = DigitMaster.zero()
        _cache_dirty = false
        return
    
    // Step 2: Calculate total quantity
    var total_quantity := DigitMaster.zero()
    var max_exponent := -999999  // For scaling
    
    for amount in _cached_selected_amounts.values():
        total_quantity = total_quantity.add(amount)
        max_exponent = maxi(max_exponent, amount.exponent)
    
    // Step 3: Calculate average quality
    var highest_unlocked := _get_highest_unlocked_atomic_number(game_state)
    var scaled_quantity_sum := 0.0
    var weighted_quality_sum := 0.0
    
    for element_id in _cached_selected_element_ids:
        var amount: DigitMaster = _cached_selected_amounts[element_id]
        
        // Scale quantity relative to largest for precision
        var scaled_qty := amount.mantissa × pow(10, amount.exponent - max_exponent)
        scaled_quantity_sum += scaled_qty
        
        var quality := _get_hybrid_quality(game_state, element_id, highest_unlocked)
        weighted_quality_sum += scaled_qty × quality
    
    var avg_quality := weighted_quality_sum / scaled_quantity_sum
    
    // Step 4: Apply formulas
    var diversity_count := _cached_selected_amounts.size()
    
    // quantity^0.9 × diversity^0.55
    var raw_dust := total_quantity.power(QUANTITY_EXPONENT)
    raw_dust = raw_dust.multiply_scalar(pow(diversity_count, DIVERSITY_EXPONENT))
    
    // Apply base scalar and quality
    raw_dust = raw_dust.multiply_scalar(BASE_SCALAR × avg_quality)
    
    // Step 5: Apply upgrade multipliers
    var resonance_bonus := upgrades_system.get_dust_recipe_bonus_multiplier(
        game_state, 
        _cached_selected_element_ids
    )
    raw_dust = raw_dust.multiply_scalar(resonance_bonus)
    
    // Step 6: Sanity cap (can't exceed total quantity obliterated)
    if raw_dust.compare(total_quantity) > 0:
        _cached_preview = total_quantity
    else:
        _cached_preview = raw_dust
    
    _cache_dirty = false
```

## Resonance Bonus

From the **Elemental Resonance** upgrade:

```gdscript
func get_dust_recipe_bonus_multiplier(game_state, selected_element_ids) -> float:
    var bonus := 1.0  // Base
    
    for upgrade_id in game_state.get_upgrade_ids():
        var upgrade := game_state.get_upgrade_state(upgrade_id)
        if upgrade.effect_type != "dust_resonance_sequence":
            continue
        
        // Count how many selected elements are in the resonance chain
        var matched_count := 0
        var max_resonant_index := upgrade.sequence_start_index + upgrade.current_level - 1
        
        for element_id in selected_element_ids:
            var element := game_state.get_element_state(element_id)
            if element.index >= upgrade.sequence_start_index 
               and element.index <= max_resonant_index:
                matched_count += 1
        
        // +4% per matched element per upgrade level
        bonus += matched_count × upgrade.effect_amount  // effect_amount = 0.04
    
    return bonus
```

**Example:**
- Elemental Resonance level 5 (resonates H, He, Li, Be, B)
- Selected elements: H, O, Ne
- H matches (index 1) → +4%
- O doesn't match (index 8 > 5)
- Ne doesn't match (index 10 > 5)
- Total bonus: 1.04× base dust

## API Reference

### Selection Management

```gdscript
func get_selection_step_count() -> int
// Returns: 5 (number of percentage steps)

func get_selection_index(element_id: String) -> int
// Returns: 0-4 (current selection step for element)

func cycle_selection(element_id: String) -> void
// Advance to next selection step (wraps to 0)

func cycle_all_unlocked_selections(game_state: GameState) -> void
// Cycle all unlocked elements simultaneously

func clear_selection() -> void
// Reset all selections to 0

func invalidate() -> void
// Mark cache dirty (force recalculation)
```

### Calculation Results

```gdscript
func get_selected_amounts(game_state, upgrades_system) -> Dictionary
// Returns: { element_id: DigitMaster(amount), ... }

func get_selected_element_ids(game_state, upgrades_system) -> Array[String]
// Returns: Sorted list of selected element IDs

func get_preview(game_state, upgrades_system) -> DigitMaster
// Returns: Predicted dust payout (cached)
```

## Usage Flow

```
1. UI displays elements with selection buttons
        ↓
2. Player clicks element button
        ↓
3. Controller calls: dust_recipe_service.cycle_selection(element_id)
        ↓
4. UI calls: dust_recipe_service.get_preview(game_state, upgrades_system)
   (Triggers recalculation due to dirty cache)
        ↓
5. UI displays updated preview amount
        ↓
6. Player clicks "Obliterate" button
        ↓
7. Controller:
   - Gets amounts: get_selected_amounts()
   - Deducts elements from game_state
   - Adds preview dust to game_state
   - Calls clear_selection()
```

## Caching

Calculations are expensive. The service caches results:

```gdscript
var _cache_dirty := true
var _cached_selected_amounts: Dictionary
var _cached_selected_element_ids: Array[String]
var _cached_preview: DigitMaster

// Cache invalidated when:
// - cycle_selection() called
// - clear_selection() called
// - invalidate() called externally

// Cache refreshed when:
// - get_preview() called while dirty
// - get_selected_amounts() called while dirty
// - get_selected_element_ids() called while dirty
```

## Integration with Controllers

From `element_menu_controller.gd`:

```gdscript
func refresh(game_state, upgrades_system, dust_recipe_service, dust_mode_active, ...):
    // In dust mode, show selection UI on element tiles
    for element_id in _element_menu_tiles.keys():
        var tile := _element_menu_tiles[element_id]
        var dust_fraction := 0.0
        if dust_mode_active:
            dust_fraction = dust_recipe_service.get_selection_fraction(element_id)
        tile.refresh(game_state.current_element_id, dust_fraction)
    
    // Show preview amount
    if dust_mode_active:
        var preview := dust_recipe_service.get_preview(game_state, upgrades_system)
        _info_label.text = "Predicted Dust: %s" % preview.big_to_short_string()
```

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| No elements selected | Preview = 0 |
| Single element selected | Diversity = 1, no diversity bonus |
| All same element | Minimal diversity bonus (1^0.55 = 1) |
| Dust > total quantity | Capped to quantity (sanity check) |
| Very large quantities | Uses scaled calculations for precision |
| Element no longer owned | Skipped during recalculation |

## Formula Rationale

**Quantity^0.9 (diminishing returns):**
- Prevents linear scaling from being too powerful
- 10× quantity = ~7.9× dust (not 10×)
- Encourages frequent conversions vs hoarding

**Diversity^0.55 (reward mixing):**
- 2 elements = 1.46× multiplier
- 5 elements = 2.08× multiplier
- 10 elements = 2.85× multiplier
- Diminishing returns prevent forcing all elements

**Hybrid quality (0.65 stability + 0.35 tier):**
- Early game: stability matters more
- Late game: tier score matters more
- Reflects real element value (rare elements worth more)

## Related Documentation

- [Oblations](./oblations.md) - High-level oblation system
- [Upgrades](./upgrades.md) - Elemental Resonance upgrade
- [Controllers](./controllers.md) - UI integration
- [Data Format](./data_format.md) - Recipe JSON structure