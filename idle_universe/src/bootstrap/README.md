# Bootstrap Components

This directory contains components responsible for initializing and setting up the game.

## Key Files

- `game_bootstrap.gd` - Main entry point that constructs the game state from data files
- `game_loader.gd` - Handles loading of game data into memory
- `save_manager.gd` - Manages save and load functionality
- `ui_state_controller.gd` - Controls UI state and transitions

## Architecture

The bootstrap system loads data from JSON files, constructs the game state, and sets up the initial game environment. It's responsible for:

1. Loading game data from `src/data/` directory
2. Creating the central `GameState` instance
3. Setting up manager instances and linking them to the game state
4. Handling save/load operations

## Data Loading

The bootstrap process reads from JSON files in `src/data/` to populate:
- Elements data
- Upgrades data
- Blessings data
- Planet data
- Planet menu configuration
- Oblations data

This ensures that the game has all necessary data to start playing.