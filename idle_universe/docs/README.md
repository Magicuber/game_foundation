# Project Documentation

This directory contains comprehensive documentation for the Idle Universe game project.

## Quick Navigation

### Getting Started

| Document | Purpose |
|----------|---------|
| [Architecture](./architecture.md) | System design and patterns |
| [Game Mechanics](./game_mechanics.md) | Core gameplay loop and systems |
| [Bootstrap Systems](./bootstrap_systems.md) | Loader, router, dirty flags |

### Core Systems

| Document | Purpose |
|----------|---------|
| [Tick System](./tick_system.md) | Game loop and time processing |
| [Smasher Systems](./smasher_systems.md) | Element smashing, variants, critical hits, fission |
| [Elements](./elements.md) | Element progression |
| [Upgrades](./upgrades.md) | Upgrade mechanics |
| [Planets](./planets.md) | Planet system and workers |
| [Resource Manager](./resource_manager.md) | Resource spending and production |
| [Prestige Manager](./prestige_manager.md) | Milestones, prestige points, nodes |
| [Reset Manager](./reset_manager.md) | Run reset behavior |

### Secondary Systems

| Document | Purpose |
|----------|---------|
| [Blessings](./blessings.md) | Random bonus system |
| [Oblations](./oblations.md) | Dust conversion recipes |
| [Dust Recipe Service](./dust_recipe_service.md) | Element-to-dust calculations |
| [Save System](./save_system.md) | Persistence |
| [Save Manager](./save_manager.md) | File operations with backup |
| [Game State Serializer](./game_state_serializer.md) | Save dict conversion |
| [Game Icon Cache](./game_icon_cache.md) | Atlas icon slicing and caching |

### Deep Dive

| Document | Purpose |
|----------|---------|
| [DigitMaster](./digitmaster.md) | Large number system |
| [State Classes](./state_classes.md) | Data structures for game entities |
| [Controllers](./controllers.md) | UI bridge pattern |
| [UI Components](./ui_components.md) | Reusable widgets |
| [Tests](./tests.md) | Test patterns and suites |

### Master Reference

| Document | Purpose |
|----------|---------|
| [Project Index](./project_index.md) | Complete system walkthrough |
| [Change Log](./change_log.md) | Commit history and repo evolution |
| [Development Notes](./development_notes.md) | Why/what/how/when decisions |
| [TODO](./TODO.md) | Outstanding non-implemented items |
| [Balancing](./Balancing.md) | Balance pass targets |
| [Data Format](./data_format.md) | JSON schema for all data files |

## Documentation Map

```
┌─────────────────────────────────────────────────────┐
│                    ARCHITECTURE                     │
│          System design and patterns                 │
└─────────────────────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ TICK SYSTEM  │ │   ELEMENT    │ │   UPGRADE    │
│ (Game Loop)  │ │   SYSTEMS    │ │   SYSTEMS    │
└──────────────┘ └──────────────┘ └──────────────┘
        │              │              │
        └──────────────┼──────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   PLANETS    │ │  BLESSINGS   │ │  OBLATIONS   │
│              │ │              │ │              │
└──────────────┘ └──────────────┘ └──────────────┘
                       │
                       ▼
              ┌──────────────┐
              │  SAVE SYSTEM │
              │              │
              └──────────────┘
```

## How to Use Documentation

1. **New developers:** Start with [Architecture](./architecture.md) and [Game Mechanics](./game_mechanics.md)
2. **Implementing features:** See specific system docs for API details
3. **Content creation:** Refer to [Data Format](./data_format.md)
4. **Debugging:** Check specific system documentation for expected behavior

## Code Cross-References

All documentation includes links to relevant source files using relative paths like:
- `../src/core/game_state.gd`
- `../src/systems/element_system.gd`

## Contributing

When adding new features:
1. Document in relevant system docs
2. Update [Data Format](./data_format.md) if adding JSON content
3. Add examples where unclear

## Changelog

- **2024-04-14**: Expanded documentation
  - Added bootstrap / UI wiring docs
  - Added resource / prestige / reset docs
  - Added GameStateSerializer, GameIconCache, UI Components, Tests
  - Expanded controllers and main docs cross-links
- **2024-04-14**: Initial documentation set created
  - Core architecture and mechanics covered
  - All major systems documented
  - Data formats specified