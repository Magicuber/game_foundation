# Game Managers

This directory contains manager classes that handle specific game mechanics and systems.

## Manager Overview

Each manager is responsible for a distinct aspect of gameplay:

- `PlanetManager` - Manages planet purchase, ownership, and progression
- `BlessingManager` - Handles blessing generation, unlocking, and effects
- `UpgradeManager` - Manages upgrade purchases, levels, and effects
- `ResourceManager` - Controls resources (dust, orbs) and their progression
- `MilestoneManager` - Tracks and manages milestone completion
- `OblationManager` - Handles oblation recipes and dust production
- `ProgressionManager` - Manages element progression and unlock mechanics
- `ResetManager` - Handles game resets, prestige systems, and state reset

## Architecture

Managers are initialized with a reference to the central `GameState` and use this reference to access and modify all game data. They provide methods for:
- Loading data from game state
- Performing game logic operations
- Querying current state
- Modifying game state

## Data Flow

1. Managers receive game state reference during initialization
2. Game state holds all data structures and configuration
3. Managers perform operations and modify referenced game state
4. All interaction happens through standardized methods
5. State changes are persistent through the central `GameState` reference

This architecture ensures clean separation between data and logic while maintaining a centralized control point.