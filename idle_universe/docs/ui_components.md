# UI Components

[Back to Project Documentation](./README.md)

## Overview

`src/ui/` holds reusable widget scripts. These are not controllers. They are small view pieces used by panel controllers and `GameLoader`.

## Components

### CurrencyDisplay
**File:** [`src/ui/currency_display.gd`](../src/ui/currency_display.gd)

Shows one resource row:
- resource name
- amount with short `DigitMaster` format

Used in top bar counters.

### ElementMenuTile
**File:** [`src/ui/element_menu_tile.gd`](../src/ui/element_menu_tile.gd)

Button for one element in element menu.

Behavior:
- shows element sprite from atlas
- shows owned amount
- shows selection overlay
- shows dust fill overlay in dust mode
- shows debug hitbox border when enabled

### ElementSelector
**File:** [`src/ui/element_selector.gd`](../src/ui/element_selector.gd)

Grid of toggle buttons for unlocked elements.

Used where player needs to pick active element.

### UpgradeButton
**File:** [`src/ui/upgrade_button.gd`](../src/ui/upgrade_button.gd)

Standalone upgrade card:
- title
- description
- effect summary
- cost button
- tier-specific background

Emits `purchase_requested(upgrade_id)`.

### BlessingCatalogRow
**File:** [`src/ui/blessing_catalog_row.gd`](../src/ui/blessing_catalog_row.gd)

Decorated row for blessing list.

Shows:
- blessing name
- level label
- summary text
- rarity accent styling

### UIFont
**File:** [`src/ui/ui_font.gd`](../src/ui/ui_font.gd)

Loads shared mono font once and caches it.

### UIMetrics
**File:** [`src/ui/ui_metrics.gd`](../src/ui/ui_metrics.gd)

Central layout constants.

Contains:
- font sizes
- panel padding and spacing
- top/bottom bar sizes
- world view sizes
- planet menu sizes
- element and upgrade tile sizing

## Design rule

UI components should:
- avoid owning game logic
- avoid changing game state directly
- expose signals for user actions
- be configured by controllers
- use `UIMetrics` for all layout numbers

## Related docs

- [Controllers](./controllers.md)
- [Game Icon Cache](./game_icon_cache.md)
- [Project Index](./project_index.md)
- [Back to docs index](./README.md)