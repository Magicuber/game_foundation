# Oblations Documentation

## Overview

The oblation system converts elements into Dust (the primary currency). Players complete "recipes" that require specific element combinations, receiving Dust based on recipe base value, resonant elements, and multipliers.

**Key Files:**
- [`src/core/managers/oblation_manager.gd`](../src/core/managers/oblation_manager.gd) - Oblation logic
- [`src/data/oblations.json`](../src/data/oblations.json) - Recipe definitions

## Oblation Concepts

### Recipe
A recipe defines:
- Required element slots (specific or categorical)
- Base Dust value
- Multipliers and bonuses
- Unlock conditions

### Dust
Dust is the primary currency used for:
- Buying upgrades
- Purchasing planets
- Hiring planet workers

### Resonant Elements
When a recipe contains elements from the "resonance sequence" (elements unlocked in order), each resonant element adds a +4% Dust bonus per level of the `elemental_resonance` upgrade.

## Oblation Mechanics

### Dust Calculation

```
Final Dust = Base × Research Multiplier × Resonance Multiplier × Oblation Effects
```

Where:
- **Base** - Recipe's base dust value
- **Research Multiplier** - Increases with Research Points accumulated
- **Resonance Multiplier** - (1 + (0.04 × resonance_upgrade_level × resonant_element_count))
- **Oblation Effects** - Multipliers from other systems (oblation bonuses, etc.)

### Research Multiplier Formula

```gdscript
# Simplified example - actual formula may vary
research_multiplier = 1.0 + (research_points × research_effect_factor)
```

### Resonance Calculation

```gdscript
func calculate_dust_payout(recipe, inputs) -> DigitMaster:
    var base = recipe.base_dust
    
    # Count resonant elements
    var resonant_count = 0
    for element_id in inputs:
        if is_in_resonance_sequence(element_id):
            resonant_count += 1
    
    # Get resonance upgrade level
    var resonance_upgrade_level = get_upgrade_level("elemental_resonance")
    
    # Calculate multiplier
    var resonance_multiplier = 1.0 + (0.04 × resonance_upgrade_level × resonant_count)
    
    # Get research multiplier
    var research_multiplier = get_research_gain_multiplier()
    
    # Get oblation effects
    var oblation_multiplier = get_dust_gain_multiplier()
    
    # Final calculation
    var final = base × research_multiplier × resonance_multiplier × oblation_multiplier
    return DigitMaster.new(final)
```

## Recipe Structure

### Slot Types

| Slot Type | Description |
|-----------|-------------|
| `specific` | Requires exact element (e.g., only Hydrogen) |
| `category` | Requires element from category (e.g., any gas) |
| `any_unlocked` | Any unlocked element |
| `index_range` | Element within specific index range |

### JSON Recipe Format

```json
{
    "recipes": [
        {
            "id": "recipe_basic",
            "name": "Basic Conversion",
            "unlock_condition": "always",
            "slots": [
                {
                    "slot_id": "slot_1",
                    "type": "specific",
                    "element_id": "ele_H",
                    "required": true
                },
                {
                    "slot_id": "slot_2",
                    "type": "any_unlocked",
                    "required": false
                }
            ],
            "base_dust": 100
        }
    ]
}
```

## Manager API

### Getting Available Recipes

```gdscript
# oblation_manager.gd
func get_oblation_recipe_entries() -> Array[Dictionary]:
    var entries = []
    for recipe_id in oblation_recipe_ids_in_order:
        var recipe = _oblation_recipes_by_id[recipe_id]
        entries.append({
            "id": recipe.id,
            "name": recipe.name,
            "slots": get_slot_displays(recipe),
            "can_complete": can_complete_recipe(recipe),
            "preview_dust": calculate_preview(recipe, current_inputs)
        })
    return entries
```

### Getting Slot Options

```gdscript
func get_oblation_slot_options(recipe_id: String, slot_id: String) -> Array[Dictionary]:
    var recipe = _oblation_recipes_by_id[recipe_id]
    var slot = recipe.get_slot(slot_id)
    
    var options = []
    match slot.type:
        "specific":
            options.append({
                "element_id": slot.element_id,
                "name": get_element_name(slot.element_id),
                "available": has_element_amount(slot.element_id, 1)
            })
        "any_unlocked":
            for element_id in get_unlocked_element_ids():
                options.append({
                    "element_id": element_id,
                    "name": get_element_name(element_id),
                    "available": true
                })
    return options
```

### Preview Calculation

```gdscript
func get_oblation_preview(recipe_id: String, selected_inputs: Dictionary) -> Dictionary:
    var recipe = _oblation_recipes_by_id[recipe_id]
    
    # Validate all required slots filled
    if not has_all_required_slots_filled(recipe, selected_inputs):
        return {"valid": false, "reason": "missing_required_slots"}
    
    # Calculate dust
    var dust_amount = calculate_dust_payout(recipe, selected_inputs)
    var resonant_count = count_resonant_elements(selected_inputs)
    
    return {
        "valid": true,
        "dust_amount": dust_amount,
        "resonant_count": resonant_count,
        "resonance_bonus": 0.04 × get_upgrade_level("elemental_resonance") × resonant_count,
        "research_multiplier": get_research_gain_multiplier(),
        "base_dust": recipe.base_dust
    }
```

### Confirming an Oblation

```gdscript
func can_confirm_oblation(recipe_id: String, selected_inputs: Dictionary) -> bool:
    var recipe = _oblation_recipes_by_id[recipe_id]
    
    # Check all required slots have valid inputs
    for slot in recipe.slots:
        if not slot.required:
            continue
        if not selected_inputs.has(slot.slot_id):
            return false
        var element_id = selected_inputs[slot.slot_id]
        if not can_afford_spend(element_id, 1):
            return false
    return true

func confirm_oblation(recipe_id: String, selected_inputs: Dictionary) -> bool:
    if not can_confirm_oblation(recipe_id, selected_inputs):
        return false
    
    var recipe = _oblation_recipes_by_id[recipe_id]
    
    # Deduct elements
    for slot_id in selected_inputs.keys():
        var element_id = selected_inputs[slot_id]
        spend_resource(element_id, DigitMaster.one())
    
    # Calculate and award dust
    var dust_amount = calculate_dust_payout(recipe, selected_inputs)
    add_resource("dust", dust_amount)
    
    return true
```

## Multipliers and Effects

### Oblation Effects

Blessings and other systems can provide oblation multipliers:

```gdscript
func get_dust_gain_multiplier() -> float:
    # Base 1.0
    var multiplier = 1.0
    
    # Add blessing effects
    multiplier += blessing_manager.get_blessing_effect_total("dust_gain")
    
    # Add other effects (prestige, etc.)
    multiplier += get_prestige_dust_multiplier()
    
    return multiplier

func get_research_gain_multiplier() -> float:
    # Research points provide their own multiplier
    var multiplier = 1.0
    multiplier += blessing_manager.get_blessing_effect_total("research_gain")
    return multiplier
```

### Effect Application

When calculating final dust:

```gdscript
func calculate_final_dust(base: DigitMaster, inputs: Dictionary) -> DigitMaster:
    var dust = base.clone()
    
    # Apply research multiplier
    dust = dust.multiply_scalar(get_research_gain_multiplier())
    
    # Calculate resonance bonus
    var resonant_count = count_resonant_elements(inputs)
    var resonance_level = get_upgrade_level("elemental_resonance")
    var resonance_bonus = 1.0 + (0.04 × resonance_level × resonant_count)
    dust = dust.multiply_scalar(resonance_bonus)
    
    # Apply oblation effects (dust gain multiplier)
    dust = dust.multiply_scalar(get_dust_gain_multiplier())
    
    return dust
```

## Elemental Resonance Upgrade

**File:** [`src/data/upgrades.json`](../src/data/upgrades.json)

The `elemental_resonance` upgrade is key to oblation efficiency:

```json
{
    "id": "elemental_resonance",
    "name": "Elemental Resonance",
    "description": "Dust recipes gain +4% payout per resonant element included.",
    "currency_id": "ele_H",
    "cost_mode": "element_sequence_linear",
    "cost_step": 5000,
    "max_level": 118,
    "effect_type": "dust_resonance_sequence",
    "effect_amount": 0.04,
    "sequence_start_index": 1,
    "sequence_requires_unlock": true
}
```

### Resonance Sequence

Resonant elements follow the periodic table order:
- Start index: 1 (Hydrogen)
- Each level unlocks the next element as "resonant"
- All unlocked elements up to that index are considered resonant

**Example at resonance level 5:**
- Resonant elements: H, He, Li, Be, B
- Each resonant element in recipe adds +4% dust
- 3 resonant elements = +12% dust

## Claimed Recipes

Players can claim recipes (mark as completed for special rewards):

```gdscript
var oblation_claimed_recipe_ids: Array[String]

func is_recipe_claimed(recipe_id: String) -> bool:
    return oblation_claimed_recipe_ids.has(recipe_id)

func claim_recipe(recipe_id: String) -> bool:
    if is_recipe_claimed(recipe_id):
        return false
    if not has_completed_recipe(recipe_id):
        return false
    
    oblation_claimed_recipe_ids.append(recipe_id)
    # Award claim bonus
    return true
```

## Unlock Conditions

Recipes can have unlock conditions:

| Condition | Description |
|-----------|-------------|
| `always` | Always available |
| `element_unlock` | Requires specific element |
| `era_unlock` | Requires specific era |
| `recipe_complete` | Requires completing other recipe |

```gdscript
func is_recipe_unlocked(recipe: Dictionary) -> bool:
    var condition = recipe.unlock_condition
    match condition.type:
        "always":
            return true
        "element_unlock":
            return is_element_unlocked(condition.element_id)
        "era_unlock":
            return has_unlocked_era(condition.era_index)
        "recipe_complete":
            return is_recipe_claimed(condition.recipe_id)
    return false
```

## Save Integration

```gdscript
// Save data
{
    "oblation_claimed_recipe_ids": ["recipe_basic", "recipe_advanced"]
}

// Loading
func _load_oblations(oblations_content: Dictionary) -> void:
    _oblation_recipes_by_id.clear()
    oblation_recipe_ids_in_order.clear()
    
    for recipe_data in oblations_content.get("recipes", []):
        var recipe = parse_recipe(recipe_data)
        _oblation_recipes_by_id[recipe.id] = recipe
        oblation_recipe_ids_in_order.append(recipe.id)
```

## UI Integration

The oblations panel displays:
- Available recipes
- Slot selection options
- Dust preview
- Resonance bonus breakdown

```gdscript
// Controller integration
func refresh_oblations_panel() -> void:
    var recipes = game_state.get_oblation_recipe_entries()
    for recipe_data in recipes:
        var recipe_ui = create_recipe_ui(recipe_data)
        
        # Show slots
        for slot in recipe_data.slots:
            var slot_ui = create_slot_ui(slot)
            slot_ui.on_selected.connect(func(element_id):
                update_preview(recipe_data.id, slot.slot_id, element_id)
            )
```

## Related Documentation

- [Game Mechanics](./game_mechanics.md) - Core loop explanation
- [Elements](./elements.md) - Element system
- [Upgrades](./upgrades.md) - Elemental Resonance upgrade
- [Blessings](./blessings.md) - Dust gain multipliers
- [Planets](./planets.md) - Research points from planets
- [Data Format](./data_format.md) - JSON structure