# Core Game Logic

This directory contains the core game logic and state management components.

## Central Game State

The `GameState` class (`game_state.gd`) is the heart of the game's architecture. It coordinates all game systems and provides a central source of truth for all game data and logic.

## Managers

The core system is built around several manager classes:
- `PlanetManager` - Handles planet purchase, ownership, and progression
- `BlessingManager` - Manages blessings, their generation, and effects
- `UpgradeManager` - Handles upgrade purchases, levels, and effects
- `ResourceManager` - Manages resources (dust, orbs, etc.) and their progression
- `MilestoneManager` - Handles milestone tracking and completion
- `OblationManager` - Manages oblation recipes and dust production
- `ProgressionManager` - Handles element progression and unlock mechanics
- `ResetManager` - Manages game resets and prestige systems

## State Classes

- `ElementState` - Represents the state of an element in the game
- `PlanetState` - Represents the state of a planet
- `UpgradeState` - Represents the state of an upgrade
- `BlessingState` - Represents the state of a blessing
- `BlessingRarity` - Defines blessing rarity data

## Serialization

- `GameStateSerializer` - Handles saving and loading of game state to/from JSON

## Architecture

The architecture follows a dependency injection pattern where managers are initialized with references to the central `GameState` and can access and modify all game data. This creates a loosely-coupled system that's easy to modify and extend.

The separation between managers and the central state ensures that game logic is well-organized and that each system has a clear responsibility.