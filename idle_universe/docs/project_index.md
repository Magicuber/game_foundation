# Idle Universe - Project Index

## Complete System Walkthrough

This document provides a high-level overview connecting all systems together.

## The Game Loop

```
┌─────────────────────────────────────────────────────────────────┐
│                         GAME LOOP                                │
└─────────────────────────────────────────────────────────────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                    ▼                       ▼
            ┌──────────────┐          ┌──────────────┐
            │   TICK SYSTEM  │          │ PLAYER INPUT │
            │   (10/sec)     │          │              │
            └──────────────┘          └──────────────┘
                    │                       │
                    │                       │
                    ▼                       ▼
            ┌──────────────────────────────────┐
            │        ACTION QUEUE              │
            │  (Manual smashes, purchases, etc)│
            └─────────────────┬────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            ▼                 ▼                 ▼
    ┌───────────┐     ┌───────────┐     ┌───────────┐
    │  ELEMENT  │     │ UPGRADES  │     │   PLANET  │
    │  SYSTEM   │     │  SYSTEM   │     │  PRODUC.  │
    │  (smash)  │     │ (effects) │     │  (RP/XP)  │
    └─────┬─────┘     └───────────┘     └─────┬─────┘
          │                                     │
          │                                     │
          ▼                                     ▼
    ┌───────────┐                         ┌───────────┐
    │   GAME    │                         │   GAME    │
    │   STATE   │<──────────────────────▶│   STATE   │
    │  (updated)│                         │  (updated)│
    └─────┬─────┘                         └─────┬─────┘
          │                                     │
          └────────────────┬────────────────────┘
                         │
                         ▼
                  ┌───────────┐
                  │     UI    │
                  │  (refreshes)
                  └───────────┘
```

## System Dependencies

### Initialization Order

```
1. GameBootstrap
   ├── Load JSON data files
   ├── Create GameState
   └── Initialize managers (via GameState._init)

2. TickSystem
   ├── Configure with GameState
   ├── ElementSystem
   └── UpgradesSystem

3. AutosaveService
   └── Register with save manager

4. UI Controllers
   └── Connect to GameState signals
```

### Runtime Dependencies

```
TickSystem
    ├── GameState (read/write)
    ├── ElementSystem (via element_system)
    └── UpgradesSystem (via upgrades_system)

ElementSystem
    ├── GameState (read/write)
    └── UpgradesSystem (read)

UpgradesSystem
    ├── GameState (read)
    └── RNG (local)

PlanetManager
    └── GameState (via weakref)

AutosaveService
    ├── GameState (read)
    └── SaveManager (write)
```

## Data Flow Example: Manual Smash

```
1. Player clicks UI button
        │
        ▼
2. Controller calls:
   tick_system.enqueue_action("manual_smash")
        │
        ▼
3. Next tick, TickSystem.drain() returns the action
        │
        ▼
4. TickSystem._apply_action() routes to:
   element_system.manual_smash(game_state, upgrades_system)
        │
        ▼
5. ElementSystem._build_smash_result():
   - Check critical hits
   - Check fission
   - Roll variants (Foil/Holographic/Polychrome)
   - Calculate total output
        │
        ▼
6. ElementSystem._apply_smash_result():
   - Add elements to GameState
   - Update counters
        │
        ▼
7. Return result dictionary
        │
        ▼
8. TickSystem emits manual_smash_resolved(result)
        │
        ▼
9. Controller refreshes UI
        │
        ▼
10. Autosave (if interval reached)
```

## Resource Conversion Path

```
Player Actions → Game State → Resources

Example: Complete Oblation Recipe

1. Player selects elements for recipe
        │
        ▼
2. Controller queries OblationManager.get_oblation_preview()
        │
        ▼
3. Manager calculates:
   - Base dust from recipe
   - + Resonance bonus (Elemental Resonance upgrade level)
   - × Research multiplier (from RP)
   - × Dust gain multiplier (from blessings/oblations)
        │
        ▼
4. Player confirms
        │
        ▼
5. GameState.spend_cost_entries_atomic() (spend elements)
        │
        ▼
6. GameState.add_resource("dust", calculated_amount)
        │
        ▼
7. UI updates, player can spend Dust on upgrades
```

## Progression Path

```
EARLY GAME (Atomic Era)
═══════════════════════════════════════════════════════
Smash Protons → Get Hydrogen
                │
                ├── Buy Particle Smasher (auto-smash)
                │   └── Collect more Hydrogen automatically
                │
                ├── Unlock Helium (ele_He) with Dust
                └── Continue unlocking elements...

MID GAME (Planetary Era)
═══════════════════════════════════════════════════════
Unlock ele_Ne (Neon) → Unlock Planetary Era
                        │
                        └── Planet A purchase unlocks
                            │
                            ├── Buy Planet A with Dust + Orbs
                            │
                            ├── Hire Workers ( Dust)
                            │   └── Workers generate XP → Level up planet
                            │       └── Planet bonuses increase
                            │
                            ├── Research Points → Moon upgrades
                            │   └── Unlocks more powerful bonuses
                            │
                            └── Milestones (Planet A Level 5)
                                └── Unlocks Planet B

LATE GAME (Era 3+)
═══════════════════════════════════════════════════════
[Future content - placeholders defined]
Solar Era → Space Era → Future Eras
```

## Number System (DigitMaster)

All large numbers use custom `DigitMaster` class:

```gdscript
# Internal representation: mantissa × 10^exponent
# Example: 1.5 × 10^308

var value := DigitMaster.new(1.5, 308)
var string := value.big_to_string()      # "1.50e308"
var short := value.big_to_short_string() # "10Dc" (decillion)

# Operations
var sum := value.add(another_value)
var diff := value.subtract(another_value)
var scaled := value.multiply_scalar(2.5)

# Comparison
var result := value.compare(another_value)  # -1, 0, or 1
```

### Short Notation Suffixes

| Suffix | Power | Example |
|--------|-------|---------|
| K | 10³ | 1.5K = 1,500 |
| M | 10⁶ | 2.0M = 2,000,000 |
| B | 10⁹ | 3.5B |
| T | 10¹² | 1.2T |
| Qa | 10¹⁵ | 5.0Qa |
| Qi | 10¹⁸ | |
| Sx | 10²¹ | |
| Sp | 10²⁴ | |
| Oc | 10²⁷ | |
| No | 10³⁰ | |
| Dc | 10³³ | |

## Effect Stacking Rules

When multiple sources provide the same effect:

### Additive Effects

```
Total = Base + UpgradeA + UpgradeB + BlessingA + BlessingB

Example: Critical Chance
  Base: 0%
  + critical_smasher_chance (level 5): +10%
  + critical_smasher_chance_2 (level 3): +6%
  + Blessing (level 2): +4%
  ───────────────────────────────────────────
  = 20%
```

### Multiplicative Effects

```
Total = Base × MultiplierA × MultiplierB

Example: Auto-smash speed
  Base interval: 5 seconds
  × Smasher Bearings (level 5): ×(0.96^5) = 0.82
  ───────────────────────────────────────────
  = 4.1 seconds per smash
```

### Capped Effects

Some effects have implicit or explicit caps:
- Manual double hit chance: Clamped to 100%
- Resonant yield chance: Clamped to 100%

## Configuration Values

### Timing

| Setting | Value | Description |
|---------|-------|-------------|
| Ticks per second | 10 | Game updates per second |
| Autosave interval | 50 ticks | 5 seconds between saves |
| Max ticks per frame | 5 | Prevents lag spiral |

### Costs

| Setting | Value | Description |
|---------|-------|-------------|
| Planet worker base | 1000 | Starting worker cost |
| Worker cost ratio | 1.25 | Exponential scaling |
| Worker cost round | 25 | Round to nearest |
| Blessing cost formula | 10x² + 400x + 1600 | Quadratic scaling |

### XP Requirements

| Setting | Value |
|---------|-------|
| Level 2 requirement | 1,500 |
| Level 25 requirement | 10,000,000 |
| Growth steps | 23 (level 2 to 25) |
| XP per worker/second | Varies by allocation |

## File Organization Quick Reference

### Core Logic
```
src/
├── core/
│   ├── game_state.gd           ← Central state container
│   ├── tick_system.gd          ← Game loop timing
│   ├── DigitMaster.gd          ← Large number math
│   └── managers/               ← Specialized logic
│       ├── planet_manager.gd
│       ├── upgrade_manager.gd
│       └── blessing_manager.gd
├── systems/
│   ├── element_system.gd       ← Element operations
│   └── upgrades_system.gd      ← Upgrade calculations
└── bootstrap/
    ├── game_bootstrap.gd       ← Initialization
    └── autosave_service.gd     ← Periodic saves
```

### Content Data
```
src/data/
├── elements.json               ← 118 elements
├── upgrades.json               ← Upgrade definitions
├── blessings.json              ← Blessing definitions
├── planets.json                ← Planet definitions
├── planet_menu.json            ← Menu layouts
└── oblations.json              ← Dust recipes
```

### UI
```
src/
├── controllers/                ← Logic for each UI panel
├── scenes/                     ← Godot scene files
└── ui/                         ← Reusable UI components
```

## Testing

All major systems have test coverage:

```
src/tests/
├── core_regression_suite.gd    ← Integration tests
├── blessing_lifecycle_smoke_check.gd
├── prestige_smoke_check.gd
└── ...
```

Run via Godot test harness or manually in editor.

## Debugging Tips

### Enable Detailed Logging

```gdscript
# In game_loader_setup_helper.gd or similar
if OS.is_debug_build():
    print_debug_state(game_state)
```

### Inspect Game State

```gdscript
# Get all current values
var dust = game_state.dust.big_to_string()
var element_count = game_state.elements.size()
var blessing_total = blessing_manager.get_blessing_effect_total("dust_gain")
```

### Test Specific Scenarios

1. Create a test save file with specific values
2. Load it with SaveManager.load_into_state()
3. Step through with breakpoints

## Related Documentation

Individual system documentation:
- [Architecture](./architecture.md) - Deep dive into system design
- [Game Mechanics](./game_mechanics.md) - Feature explanations
- [Tick System](./tick_system.md) - Game loop details
- [Smasher Systems](./smasher_systems.md) - Smash mechanics
- [Elements](./elements.md) - Element progression
- [Upgrades](./upgrades.md) - Upgrade system
- [Planets](./planets.md) - Planet mechanics
- [Blessings](./blessings.md) - Blessing system
- [Oblations](./oblations.md) - Dust recipes
- [Save System](./save_system.md) - Persistence
- [Data Format](./data_format.md) - Content structure