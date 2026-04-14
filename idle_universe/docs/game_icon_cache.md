# Game Icon Cache

[Back to Project Documentation](./README.md)

## Overview

`GameIconCache` slices atlas textures into reusable icon objects.

**File:** [`src/services/game_icon_cache.gd`](../src/services/game_icon_cache.gd)

## What it caches

- element icons by index and visual variant
- planet icons by planet id and level frame
- era frames

## Sprite sheets

### Element sheets
- normal
- foil
- holographic
- polychrome

These use 32x32 frames in long horizontal strips.

### Planet sheets
- Planet A progression sheet
- Planet B sheet

### Era sheet
- 4 frames
- 540x750 each

## Element variants

Variant names:
- `normal`
- `foil`
- `holographic`
- `polychrome`

Unknown variant falls back to normal.

## Caching behavior

- first request builds `AtlasTexture`
- later requests reuse same instance
- avoids re-slicing sheet every refresh

## Main methods

- `get_element_icon(element_index)`
- `get_element_icon_for_variant(element_index, variant)`
- `get_planet_icon(planet_id, planet_level)`
- `get_era_frame(frame_index)`

## Usage

Controllers use cache to keep UI cheap:
- `HudController` for current element icon
- `GameUiRefreshCoordinator` for fuse button icon
- planet panels for planet art

## Related docs

- [Smasher Systems](./smasher_systems.md)
- [Controllers](./controllers.md)
- [Project Index](./project_index.md)
- [Back to docs index](./README.md)