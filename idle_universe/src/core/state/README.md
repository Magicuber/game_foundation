# Game State Classes

This directory contains state classes that represent individual game entities and their data.

## State Classes

- `element_state.gd` - Represents the state of an element in progression
- `planet_state.gd` - Represents the state of a planet
- `upgrade_state.gd` - Represents the state of an upgrade
- `blessing_state.gd` - Represents the state of a blessing
- `blessing_rarity.gd` - Defines blessing rarity properties and effects

## Purpose

These state classes hold the data and properties for specific game entities. They represent individual components of the overall game state managed by `GameState.gd`.

## Implementation

Each state class:
1. Defines properties specific to that game entity
2. Provides methods for initialization from data
3. Stores current state information
4. May include helper methods for calculations or data retrieval

The state classes are referenced by manager classes and are used to store and retrieve data about specific game components, while the central `GameState` class coordinates between all these entities.