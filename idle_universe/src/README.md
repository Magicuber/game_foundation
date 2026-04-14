# Source Code Structure

This directory contains all the source code for the Idle Universe game, organized by functionality.

## Core Architecture

The game follows a structured architecture with:
- Core game state management
- Manager classes for different systems (planet, blessing, upgrade, etc.)
- State classes for individual game components
- Data loading and serialization
- Bootstrap components for game initialization

## Subdirectories

- `bootstrap/` - Game initialization and loading components
- `controllers/` - UI controllers for different game menus and interfaces
- `core/` - Core game logic and state management
- `data/` - Game data files (JSON)
- `managers/` - System managers that handle specific game mechanics
- `save/` - Save and load functionality
- `state/` - State classes that represent game entities
- `services/` - Service layer for game operations
- `systems/` - Game systems that coordinate various mechanics

## Key Files

- `game_state.gd` - Central game state class that coordinates all game systems
- `game_bootstrap.gd` - Entry point for game initialization and data loading
- Manager classes that handle specific game mechanics (planet, blessing, upgrade, etc.)