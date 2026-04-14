# Elements Documentation

## Overview

The element system is the core progression mechanic of Idle Universe. Players progress through the periodic table, unlocking new elements that generate the next element in the chain.

**Key Files:**
- [`src/core/managers/progression_manager.gd`](../src/core/managers/progression_manager.gd) - Element progression logic
- [`src/core/state/element_state.gd`](../src/core/state/element_state.gd) - Element state class
- [`src/data/elements.json`](../src/data/elements.json) - Element definitions

## Element Structure

```gdscript
class_name ElementState

var id: String          # Unique identifier (e.g., "ele_H")
var name: String        # Display name (e.g., "H")
var index: int         # Priority/progression order
var unlocked: bool     # Whether player has access
var amount: DigitMaster # Current amount owned
var cost: DigitMaster   # Unlock cost
var produces: String    # ID of element this produces
var show_in_counter: bool # Whether to show in UI counter
```

## Element Chain

Elements are arranged in a linear progression chain:

```
ele_P (Protons) → ele_H (Hydrogen) → ele_He (Helium) → ele_Li (Lithium) → ... → ele_Og (Oganesson)
```

### Starting Element: Protons (ele_P)

**Special Properties:**
- Unlocked at game start (`"unlocked": true`)
- Produces Hydrogen (`"produces": "ele_H"`)
- `show_in_counter: false` - Hidden from main counter
- `cost: 0` - No unlock cost
- `amt: "infinity"` - Infinite supply (special value)

### Standard Elements

Hydrogen through Oganesson (118 elements) follow a pattern:
- Each produces the next element
- Costs scale as progression increases
- Grouped into sections for visibility

## Element Sections

Elements are grouped into visibility sections:

| Section | Indexes | Unlock Section End |
|---------|---------|-------------------|
| 1 | 0-10 | UNLOCK_SECTION_ENDS[0] = 10 |
| 2 | 11-30 | UNLOCK_SECTION_ENDS[1] = 30 |
| 3 | 31-54 | UNLOCK_SECTION_ENDS[2] = 54 |
| 4 | 55-86 | UNLOCK_SECTION_ENDS[3] = 86 |
| 5 | 87-118 | UNLOCK_SECTION_ENDS[4] = 118 |

**Code Reference:**
```gdscript
# game_state.gd
const UNLOCK_SECTION_ENDS := [10, 30, 54, 86, 118]
```

### Section Visibility

Sections are revealed based on `visible_section_count`:

```gdscript
# Always at least 1 section visible
var visible_section_count := maxi(1, unlocked_section_count)

# Current element clamped to visible sections
private func _clamp_current_element_to_visible_sections() -> void:
    var max_index := _get_max_index_for_visible_sections()
    var current_index := _get_element_index(current_element_id)
    if current_index > max_index:
        # Find closest unlocked element
        current_element_id = _find_closest_unlocked_element(max_index)
```

## Unlock Mechanics

### Unlocking Requirements

To unlock an element:
1. Previous element must be unlocked
2. Player must have enough Dust to pay unlock cost
3. Element must be within visible sections

### Unlock Cost

Element unlock costs are defined in [`src/data/elements.json`](../src/data/elements.json):

```json
{
    "id": "ele_He",
    "name": "He",
    "unlocked": false,
    "index": 2,
    "cost": 10,
    "amt": 0,
    "produces": "ele_Li",
    "show_in_counter": false
}
```

### Cost Patterns

- Early elements: Low base cost (10-100)
- Mid-game: Costs increase with index
- Costs may scale or require specific currencies

## Element Data Structure

### JSON Schema

Each element in `elements.json` has:

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique identifier (e.g., "ele_H") |
| `name` | String | Display name (e.g., "H") |
| `unlocked` | Boolean | Starting unlock state |
| `index` | Integer | Progression order (1-118) |
| `cost` | Integer | Unlock cost in appropriate currency |
| `amt` | Integer/String | Starting amount or "infinity" |
| `produces` | String | ID of element this produces |
| `show_in_counter` | Boolean | Whether to display in UI |

## Element Actions

### Select Element

```gdscript
# progression_manager.gd
func select_element(element_id: String) -> bool:
    if not has_element(element_id):
        return false
    game_state.current_element_id = element_id
    return true
```

### Unlock Next Element

```gdscript
# progression_manager.gd
func unlock_next_element() -> bool:
    if not can_unlock_next():
        return false
    
    var next_unlock = get_next_unlock_element_state()
    var cost = next_unlock.cost
    
    # Deduct cost (from appropriate resource)
    if spend_resource(next_unlock):
        next_unlock.unlocked = true
        refresh_progression_state()
        return true
    return false
```

### Can Unlock Check

```gdscript
# progression_manager.gd
func can_unlock_next() -> bool:
    var next_unlock = get_next_unlock_element_state()
    if next_unlock == null:
        return false
    return can_afford_resource(next_unlock)
```

## Element Production

### Auto-Production (Particle Smasher)

The Particle Smasher upgrade auto-generates elements:

```gdscript
# When Particle Smasher triggers:
var current_element = get_current_element_state()
produce_element(current_element.produces, amount)

# Critical hits provide bonus
if roll_critical():
    var bonus = amount * critical_payload_bonus
    produce_element(current_element.produces, bonus)
```

### Manual Smashing

Players can manually smash elements to generate the next:
- Base production: 1 unit
- Bonuses from blessings and upgrades
- Critical hits from manual smashing too

### Fission Splitting

When fission triggers:
1. Original element production is cancelled
2. Two smaller elements are produced instead
3. Sum of their atomic numbers = original element's atomic number
4. Both must already be unlocked

```gdscript
# pseudo-code
if roll_fission():
    var split = find_two_elements_summing_to(target_element.atomic_number)
    if split is valid:
        produce_element(split.element_a)
        produce_element(split.element_b)
    else:
        # Fall back to normal production
        produce_element(target_element)
```

## Element Amount Display

For visual clarity, elements track:
- Current amount owned
- Whether to show in counter UI
- Total lifetime production

```gdscript
# Get visible elements for UI
game_state.get_visible_counter_element_ids() -> Array[String]

# Current element info
game_state.get_current_element_state() -> ElementState
```

## Era Requirements

Elements can gate era progression:

```gdscript
# game_state.gd
const ERA_MENU_UNLOCK_ELEMENT_ID := "ele_Ne"

func is_era_menu_unlocked() -> bool:
    return is_element_unlocked(ERA_MENU_UNLOCK_ELEMENT_ID)
```

## Related Documentation

- [Game Mechanics](./game_mechanics.md) - Core loop explanation
- [Upgrades](./upgrades.md) - Element production upgrades
- [Planets](./planets.md) - Planetary era uses specific elements
- [Data Format](./data_format.md) - JSON structure details