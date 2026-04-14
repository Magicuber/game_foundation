# Save System

This directory contains components responsible for saving and loading game state.

## Key Files

- `game_state_serializer.gd` - Serializes game state to/from dictionary format for saving
- `save_manager.gd` - Manages save/load operations and file I/O

## Architecture

The save system provides:
1. Serialization of game state to dictionary format
2. Loading of game state from dictionary format
3. File I/O operations for save files
4. Version compatibility handling

## Save Format

The system converts the entire `GameState` object into a dictionary structure suitable for JSON serialization. This includes:
- All game data (elements, planets, upgrades, blessings)
- Current state information (levels, progress, unlocks)
- Player metadata (statistics, counters)
- Configuration settings

## Operations

The system handles both:
- Full save operations
- Partial save operations
- Version migration when game data structure changes
- Error handling for save/load failures

This ensures that player progress is preserved between game sessions.