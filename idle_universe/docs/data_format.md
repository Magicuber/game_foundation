# Data Format Documentation

## Overview

Idle Universe uses JSON files to define game content. These files are loaded at startup and used to construct the game state.

**Location:** [`src/data/`](../src/data/)

## Files Overview

| File | Purpose | Key Content |
|------|---------|-------------|
| `elements.json` | Element definitions | 118+ elements with costs and production |
| `upgrades.json` | Upgrades | Auto-smash, critical chance, etc. |
| `blessings.json` | Blessing definitions | Random bonuses by rarity |
| `planets.json` | Planet definitions | Purchase costs, XP scaling |
| `planet_menu.json` | Planet menu layout | Visual stage definitions |
| `oblations.json` | Dust recipes | Element-to-Dust conversions |

## Elements Data

**File:** `src/data/elements.json`

### Structure

```json
{
  "elements": [
    {
      "id": "ele_H",
      "name": "H",
      "unlocked": false,
      "index": 1,
      "cost": 100,
      "amt": 0,
      "produces": "ele_He",
      "show_in_counter": true
    }
  ]
}
```

### Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | String | Unique identifier | Yes |
| `name` | String | Display name | Yes |
| `unlocked` | Boolean | Starting unlock state | Yes |
| `index` | Integer | Progression order (1+) | Yes |
| `cost` | Number | Unlock cost | Yes |
| `amt` | Number/"infinity" | Starting amount | Yes |
| `produces` | String | ID of produced element | Yes |
| `show_in_counter` | Boolean | Display in counter UI | No (default: false) |

### Example: Starting Protons

```json
{
  "id": "ele_P",
  "name": "P",
  "unlocked": true,
  "index": 0,
  "cost": 0,
  "amt": "infinity",
  "produces": "ele_H",
  "show_in_counter": false
}
```

### Element Chain

Elements must form a valid chain where each element's `produces` field references another element's `id`:

```
ele_P → ele_H → ele_He → ele_Li → ... → ele_Og
```

## Upgrades Data

**File:** `src/data/upgrades.json`

### Structure

```json
{
  "upgrades": [
    {
      "id": "particle_smasher",
      "name": "Particle Smasher",
      "description": "Automatically smashes the selected element over time.",
      "currency_id": "ele_H",
      "tier": 1,
      "base_cost": 10,
      "cost_mode": "additive_power",
      "cost_scaling": 1.5,
      "max_level": 60,
      "current_level": 0,
      "effect_type": "auto_smash",
      "effect_amount": 1.0
    }
  ]
}
```

### Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | String | Unique identifier | Yes |
| `name` | String | Display name | Yes |
| `description` | String | Tooltip text | Yes |
| `currency_id` | String | Payment currency (element ID or "dust") | Yes |
| `secondary_currency_id` | String | Secondary currency (optional) | No |
| `tier` | Integer | Unlock tier/era | No (default: 1) |
| `required_era_index` | Integer | Minimum era required | No |
| `base_cost` | Number | Starting cost | Yes |
| `secondary_base_cost` | Number | Secondary starting cost | No |
| `cost_mode` | String | "additive_power" or "element_sequence_linear" | Yes |
| `cost_scaling` | Number | Exponential scaling factor | Yes (for additive_power) |
| `cost_step` | Number | Linear step amount | Yes (for element_sequence_linear) |
| `max_level` | Integer | Maximum purchaseable level | Yes |
| `current_level` | Integer | Starting level (usually 0) | Yes |
| `effect_type` | String | Type of effect | Yes |
| `effect_amount` | Number | Base effect value | Yes |
| `sequence_start_index` | Integer | Starting index for sequence mode | No |
| `sequence_requires_unlock` | Boolean | If sequence needs unlock | No |

### Effect Types

| Effect Type | Description |
|-------------|-------------|
| `auto_smash` | Auto-smashes selected element |
| `auto_smash_speed_bonus` | Reduces auto-smash cooldown |
| `critical_auto_smash` | Chance for bonus protons |
| `critical_spawn_bonus` | Increases critical output |
| `fission_split` | Chance to split production |
| `bonus_element_output` | Chance for extra elements |
| `manual_bonus_output` | Chance for extra manual smash |
| `dust_resonance_sequence` | Dust oblation bonus |

## Blessings Data

**File:** `src/data/blessings.json`

### Structure

```json
{
  "rarities": [
    {
      "rarity": "Uncommon",
      "roll_weight": 40,
      "display_chance": "40%",
      "color": "ffffff"
    }
  ],
  "blessings": [
    {
      "id": "blessing_critical_chance",
      "name": "Smasher Precision",
      "description": "Increases critical smasher chance by 1% per level",
      "rarity": "Uncommon",
      "effect_type": "critical_smasher_chance",
      "effect_base": 0.01,
      "effect_scaling": 0.01,
      "placeholder": false
    }
  ]
}
```

### Rarity Fields

| Field | Type | Description |
|-------|------|-------------|
| `rarity` | String | Rarity name |
| `roll_weight` | Number | Weight in RNG selection (higher = more common) |
| `display_chance` | String | Text showing approximate chance |
| `color` | String | Hex color code |

### Blessing Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | String | Unique identifier | Yes |
| `name` | String | Display name | Yes |
| `description` | String | Effect description | Yes |
| `rarity` | String | Must match a rarity entry | Yes |
| `effect_type` | String | Type of bonus | Yes |
| `effect_base` | Number | Base bonus per level | Yes |
| `effect_scaling` | Number | Additional per level (if different from base) | No |
| `placeholder` | Boolean | If true, not yet implemented | No (default: false) |

### Rarity Order

Rarities should be ordered (in code):
1. Uncommon (most common)
2. Rare
3. Legendary
4. Exotic
5. Exalted
6. Divine (rarest)

## Planets Data

**File:** `src/data/planets.json`

### Structure

```json
{
  "planets": [
    {
      "id": "planet_a",
      "name": "Planet A",
      "level": 1,
      "max_level": 25,
      "purchase_cost_dust": 0,
      "purchase_cost_orbs": 0
    }
  ]
}
```

### Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | String | Unique identifier | Yes |
| `name` | String | Display name | Yes |
| `level` | Integer | Starting level (usually 1) | Yes |
| `max_level` | Integer | Maximum attainable level | Yes |
| `purchase_cost_dust` | Number/String | Dust cost to unlock | Yes |
| `purchase_cost_orbs` | Integer | Orb cost to unlock | Yes |

### Note

- `purchase_cost_dust` can be a number or "infinity" string
- Costs of 0 indicate default/unlockable planets

## Planet Menu Data

**File:** `src/data/planet_menu.json`

### Structure

```json
{
  "root": {
    "id": "root",
    "label": "Home"
  },
  "stages": [
    {
      "id": "solar_system_1",
      "stage_index": 1,
      "visible_planets": ["planet_a", "planet_b"],
      "visible_moons": ["moon_1a", "moon_1b"],
      "lines": [
        {"from_id": "root", "to_id": "planet_a"}
      ],
      "node_positions": {
        "root": {"x": 540, "y": 200},
        "planet_a": {"x": 300, "y": 500}
      }
    }
  ],
  "planets": {
    "planet_a": {
      "label": "Planet A",
      "tier": 1,
      "panel_accent_color": "#4A7F78",
      "preview_title": "Planet A",
      "preview_subtitle": "Starting Planet",
      "moon_ids": ["moon_1a"]
    }
  },
  "moons": {
    "moon_1a": {
      "label": "Moon 1A",
      "color": "#4A7F78",
      "parent_planet_id": "planet_a",
      "upgrades": [
        {
          "id": "upgrade_1",
          "name": "First Upgrade",
          "description": "Bonus to something",
          "rp_cost": 100
        }
      ]
    }
  }
}
```

### Fields

#### Root

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Identifier |
| `label` | String | Display text |

#### Stages

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Unique stage ID |
| `stage_index` | Integer | Progression order |
| `visible_planets` | Array | Planet IDs visible in this stage |
| `visible_moons` | Array | Moon IDs visible in this stage |
| `lines` | Array | Connection lines between nodes |
| `node_positions` | Object | X/Y positions for each node |

#### Lines

| Field | Type | Description |
|-------|------|-------------|
| `from_id` | String | Starting node |
| `to_id` | String | Ending node |

#### Planets

| Field | Type | Description |
|-------|------|-------------|
| `label` | String | Display name |
| `tier` | Integer | Unlock tier |
| `panel_accent_color` | String | UI color |
| `preview_title` | String | Panel title |
| `preview_subtitle` | String | Panel subtitle |
| `moon_ids` | Array | Associated moons |

#### Moons

| Field | Type | Description |
|-------|------|-------------|
| `label` | String | Display name |
| `color` | String | Moon color |
| `parent_planet_id` | String | Owning planet |
| `upgrades` | Array | Available upgrades |

## Oblations Data

**File:** `src/data/oblations.json`

### Structure

```json
{
  "recipes": [
    {
      "id": "recipe_simple_dust",
      "name": "Simple Conversion",
      "unlock_condition": {
        "type": "always"
      },
      "slots": [
        {
          "slot_id": "input_1",
          "type": "specific",
          "element_id": "ele_H",
          "required": true
        },
        {
          "slot_id": "input_2",
          "type": "any_unlocked",
          "required": false
        }
      ],
      "base_dust": 100
    }
  ]
}
```

### Fields

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | String | Unique identifier | Yes |
| `name` | String | Display name | Yes |
| `unlock_condition` | Object | When recipe becomes available | Yes |
| `slots` | Array | Input requirements | Yes |
| `base_dust` | Number | Base dust reward | Yes |

### Unlock Condition Types

| Type | Description | Additional Fields |
|------|-------------|-------------------|
| `always` | Always available | None |
| `element_unlock` | Requires element ID | `element_id` |
| `era_unlock` | Requires era index | `era_index` |
| `recipe_complete` | Requires recipe completion | `recipe_id` |
| `milestone_complete` | Requires milestone | `milestone_id` |

### Slot Types

| Type | Description | Additional Fields |
|------|-------------|-------------------|
| `specific` | Exact element | `element_id` |
| `category` | Element category | `category` |
| `any_unlocked` | Any unlocked element | None |
| `index_range` | Elements in range | `min_index`, `max_index` |

### Slot Fields

| Field | Type | Description |
|-------|------|-------------|
| `slot_id` | String | Unique slot identifier |
| `type` | String | Slot type (see above) |
| `element_id` | String | For specific type |
| `category` | String | For category type |
| `required` | Boolean | If slot must be filled |

## Loading Process

**File:** [`src/bootstrap/game_bootstrap.gd`](../src/bootstrap/game_bootstrap.gd)

```gdscript
func build_game_state() -> GameState:
    var elements = _load_json_dictionary(ELEMENTS_DATA_PATH)
    var upgrades = _load_json_dictionary(UPGRADES_DATA_PATH)
    var blessings = _load_json_dictionary(BLESSINGS_DATA_PATH)
    var planets = _load_json_dictionary(PLANETS_DATA_PATH)
    var planet_menu = _load_json_dictionary(PLANET_MENU_DATA_PATH)
    var oblations = _load_json_dictionary(OBLATIONS_DATA_PATH)
    
    return GameState.from_content(
        elements, upgrades, blessings,
        planets, planet_menu, oblations
    )
```

## Validation

Data should pass these checks:
1. IDs must be unique within type
2. References must exist (e.g., `produces` element ID)
3. Rarity names in blessings must match rarity definitions
4. Planet IDs in menu must exist in planets
5. Numeric values must be positive where applicable
6. No circular dependencies in unlock conditions

## Related Documentation

- [Architecture](./architecture.md) - How data is loaded
- [Game Mechanics](./game_mechanics.md) - How data is used
- [Elements](./elements.md) - Element system details
- [Upgrades](./upgrades.md) - Upgrade system details
- [Planets](./planets.md) - Planet system details
- [Blessings](./blessings.md) - Blessing system details
- [Oblations](./oblations.md) - Recipe system details