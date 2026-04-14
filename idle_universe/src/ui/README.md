# UI Components

This directory contains reusable UI components and helper scripts.

## Files

| Component | Purpose |
|-----------|---------|
| `currency_display.gd` | Displays DigitMaster currency values with formatting |
| `element_menu_tile.gd` | Interactive tile for element menu display |
| `element_selector.gd` | Element selection widget |
| `blessing_catalog_row.gd` | Row display for blessing catalog |
| `upgrade_button.gd` | Button component for upgrade purchases |
| `ui_font.gd` | Font styling utilities |
| `ui_metrics.gd` | UI sizing and spacing constants |

## Usage

These components are instantiated by scene files and configured via exported properties:

```gdscript
extends Control

@export var currency_label: CurrencyDisplay

func _ready():
    currency_label.set_value(game_state.dust)
```

## Benefits

- Reusable across multiple scenes
- Centralized styling logic
- Consistent UI conventions
- Easy to modify globally