# Tick System & Game Loop

## Overview

The tick system handles time-based game processing, executing game logic at fixed intervals and managing the main game loop.

**Key Files:**
- [`src/core/tick_system.gd`](../src/core/tick_system.gd) - Main tick processing
- [`src/core/action_queue.gd`](../src/core/action_queue.gd) - Action batching
- [`src/bootstrap/autosave_service.gd`](../src/bootstrap/autosave_service.gd) - Periodic saves

## Architecture

```
Godot _process(delta)
        │
        ├── Accumulate delta time
        │
        ├── While accumulator >= tick_duration:
        │   └── _process_tick()
        │       ├── Increment tick_count
        │       ├── Update played time
        │       ├── Process planet production
        │       ├── Drain action_queue
        │       └── _process_auto_smash()
        │
        └── Emit tick_processed signal
```

## Tick System Configuration

```gdscript
const DEFAULT_TICKS_PER_SECOND := 10.0  # 10 ticks = 100ms per tick
const MAX_TICKS_PER_FRAME := 5          # Prevent spiral on lag

var ticks_per_second := DEFAULT_TICKS_PER_SECOND
var _tick_accumulator := 0.0
```

## Game Loop Flow

### 1. Frame Processing (every engine frame)

```gdscript
func _process(delta: float) -> void:
    var tick_duration := 1.0 / ticks_per_second
    _tick_accumulator += delta

    # Process up to MAX_TICKS_PER_FRAME per frame
    var processed_ticks := 0
    while _tick_accumulator >= tick_duration 
          and processed_ticks < MAX_TICKS_PER_FRAME:
        _tick_accumulator -= tick_duration
        _process_tick(tick_duration)
        processed_ticks += 1
```

### 2. Tick Processing (every game tick)

```gdscript
func _process_tick(tick_duration: float) -> void:
    # Update global counters
    game_state.tick_count += 1
    game_state.total_played_seconds += tick_duration

    # Process planet production
    var production_changes := game_state.process_planet_production(tick_duration)

    # Apply queued actions
    var processed_actions: Array[String] = []
    for action in action_queue.drain():
        if _apply_action(action):
            processed_actions.append(action.type)

    # Process auto-smashes
    _process_auto_smash(tick_duration)

    # Emit signal for systems listening
    emit_signal("tick_processed", 
        game_state.tick_count, 
        processed_actions, 
        production_changes)
```

### 3. Auto-Smash Processing

```gdscript
func _process_auto_smash(tick_duration: float) -> void:
    # Get interval from upgrades (based on particle_smasher level)
    var interval := upgrades_system.get_auto_smash_interval_seconds(game_state)

    if is_inf(interval):  # No auto-smash purchased
        _auto_smash_accumulator = 0.0
        return

    _auto_smash_accumulator += tick_duration
    while _auto_smash_accumulator >= interval:
        _auto_smash_accumulator -= interval

        if game_state.current_element_id.is_empty():
            continue

        # Queue auto-smash request
        var request := {
            "target_element_id": game_state.current_element_id,
            "spawn_count": upgrades_system.get_auto_smash_spawn_count(game_state)
        }
        emit_signal("auto_smash_requested", request)
```

## Action Queue System

The action queue batches player actions to process on ticks:

```gdscript
class_name ActionQueue

var _queued_actions: Array[Dictionary]

func enqueue(action_type: String, payload: Dictionary = {}) -> void:
    _queued_actions.append({
        "type": action_type,
        "payload": payload.duplicate(true)
    })

func drain() -> Array[Dictionary]:
    var drained := _queued_actions
    _queued_actions = []
    return drained
```

### Supported Actions

| Action Type | Payload | Handler |
|-------------|---------|---------|
| `"manual_smash"` | - | `element_system.manual_smash()` |
| `"unlock_next"` | - | `element_system.unlock_next_element()` |
| `"select_adjacent"` | `direction: int` | `element_system.select_adjacent()` |
| `"select_element"` | `id: String` | `element_system.select_element()` |
| `"purchase_upgrade"` | `id: String` | `upgrades_system.purchase_upgrade()` |

### Enqueuing Actions

From UI controllers:

```gdscript
# When player clicks smash button
tick_system.enqueue_action("manual_smash")

# When player clicks next element
tick_system.enqueue_action("select_adjacent", {"direction": 1})

# When player purchases upgrade
tick_system.enqueue_action("purchase_upgrade", {"id": "particle_smasher"})
```

## Planet Production Timing

Planets generate XP and Research Points each tick:

```gdscript
# In GameState.process_planet_production(delta_seconds)
for planet_id in planet_ids_in_order:
    var planet = get_planet_state(planet_id)
    if not is_planet_owned(planet_id) or planet.workers.is_zero():
        continue

    # Split based on worker allocation
    var allocation_to_xp := planet.worker_allocation_to_xp

    # XP generation (for planet leveling)
    if allocation_to_xp > 0.0:
        var xp_per_second = workers × allocation_to_xp × xp_multiplier
        apply_planet_xp(planet, xp_per_second × delta_seconds)

    # RP generation (for moon upgrades)
    if allocation_to_xp < 1.0:
        var rp_per_second = workers × (1.0 - allocation_to_xp) × RESEARCH_POINTS_PER_PRODUCTION
        apply_research_progress(rp_per_second × delta_seconds)
```

## Auto-Save Integration

The autosave service piggybacks on tick counting:

```gdscript
class_name AutosaveService

const DEFAULT_AUTO_SAVE_INTERVAL_TICKS := 50  # Save every 5 seconds at 10 TPS

func autosave_if_needed(game_state: GameState) -> bool:
    if game_state.tick_count - game_state.last_save_tick < auto_save_interval_ticks:
        return false
    return save_now(game_state)

# Called externally each tick
if autosave_service.autosave_if_needed(game_state):
    print("Game auto-saved")
```

## Signals

### tick_processed

Emitted every tick after all processing:

```gdscript
signal tick_processed(
    tick_count: int,           # Current tick number
    processed_actions: Array,  # Actions executed this tick
    production_changes: Dictionary  # What changed in production
)
```

### manual_smash_resolved

Emitted when manual smash completes:

```gdscript
signal manual_smash_resolved(result: Dictionary)

# Result contains:
{
    "source_element_id": "ele_H",
    "produced_resource_ids": ["ele_He"],
    "resource_counts": {"ele_He": 2},
    "was_fission": false,
    "variant": "normal"
}
```

### auto_smash_requested

Emitted when auto-smash triggers:

```gdscript
signal auto_smash_requested(request: Dictionary)

# Request contains:
{
    "target_element_id": "ele_H",
    "spawn_count": 2
}
```

## Configuration

### Setting Up Tick System

```gdscript
var tick_system := TickSystem.new()
tick_system.configure(game_state, element_system, upgrades_system)

# Optionally adjust tick rate
tick_system.ticks_per_second = 10.0  # 10 ticks per second
```

### Configuring Autosave

```gdscript
var autosave_service := AutosaveService.new(50)  # Save every 50 ticks

# In tick signal handler:
func _on_tick_processed(_count, _actions, _changes):
    autosave_service.autosave_if_needed(game_state)
```

## Timing Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `DEFAULT_TICKS_PER_SECOND` | 10.0 | Base tick rate (100ms/tick) |
| `MAX_TICKS_PER_FRAME` | 5 | Max ticks processed per frame |
| `DEFAULT_AUTO_SAVE_INTERVAL_TICKS` | 50 | Save every 50 ticks (5s) |

## Frame Budget

With default settings:
- **Target:** 60 FPS
- **Tick rate:** 10 TPS
- **Tick duration:** 100ms
- **Max ticks/frame:** 5 (500ms max processing)
- **Budget remaining:** ~500ms for rendering

On lag spikes:
- Accumulator stores up to 5 ticks
- Prevents processing spiral
- Smooths out frame drops

## Related Documentation

- [Architecture](./architecture.md) - System overview
- [Game Mechanics](./game_mechanics.md) - How ticks drive gameplay
- [Element System](./smasher_systems.md#element-system) - Smash handling
- [Planet System](./planets.md) - Production on ticks
- [Save System](./save_system.md) - Autosave mechanics