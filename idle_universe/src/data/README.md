# Game Data Files

This directory contains all JSON data files that define the game's content and mechanics.

## Data Files

- `elements.json` - Defines all elements in the periodic table and their progression mechanics
- `upgrades.json` - Defines all upgrades that players can purchase and their effects
- `blessings.json` - Defines blessings that can be generated and their effects
- `planets.json` - Defines planets and their properties, costs, and unlock conditions
- `planet_menu.json` - Defines the menu configuration and UI layout for planets
- `oblations.json` - Defines oblation recipes and dust production mechanics

## Data Structure

Each file contains arrays of objects with specific properties:
- Elements have IDs, names, costs, production rates, and unlocking conditions
- Upgrades have IDs, names, descriptions, costs, and effect types
- Blessings have ID, name, rarity, and effect properties
- Planets define their appearance, costs, and progression mechanics
- Planet menus define UI layout and visibility conditions
- Oblations define dust recipes and production rules

## Loading Process

The bootstrap system loads this data into memory when the game starts and uses it to populate the central `GameState` object. These files are essential for defining the core game content and mechanics.