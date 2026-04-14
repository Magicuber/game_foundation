# Save Manager

## Overview

The `SaveManager` handles persistent storage with robust error handling, backup rotation, and validation. It ensures save file integrity through multiple safety mechanisms.

**File:** [`src/bootstrap/save_manager.gd`](../src/bootstrap/save_manager.gd)

## Save Strategy

### Three-File System

```
primary_save.json        ← Current save (most recent successful write)
primary_save.json.tmp    ← In-progress write (temporary)
primary_save.json.bak    ← Previous successful save (backup)
```

**Benefits:**
- Never overwrites primary directly (prevents corruption)
- Always has previous version to recover
- Atomic rename operations (all-or-nothing)

## Save Flow

```
┌──────────────────────────────────────────────────────────────┐
│                      save_state()                            │
└─────────────────────────┬────────────────────────────────────┘
                          │
1. Serialize             ▼
   - game_state.to_save_dict()
   - JSON.stringify()
                          │
2. Write                 ▼
   - Write to .tmp file
   - Verify written data
                          │
3. Verify                ▼
   - Load .tmp file back
   - Validate structure
                          │
4. Rotate                ▼
   - Delete old .bak
   - Move primary to .bak
   - Move .tmp to primary
                          │
5. Cleanup               ▼
   - Delete .tmp
   - Return success/failure
```

## Implementation

### Primary Save Method

```gdscript
static func save_state(game_state: GameState, save_path: String = SAVE_PATH) -> bool:
    if game_state == null:
        return false

    // 1. Serialize
    var serialized_save := JSON.stringify(game_state.to_save_dict())
    if serialized_save.is_empty():
        push_warning("Serialized save payload is empty; aborting save.")
        return false

    // 2. Write to temp
    var temp_path := _get_temp_path(save_path)
    var backup_path := _get_backup_path(save_path)

    if not _write_text_file(temp_path, serialized_save):
        push_warning("Unable to write temp save file: %s" % temp_path)
        return false

    // 3. Verify temp file
    var verified_temp_save := _load_save_dict_from_path(temp_path)
    if verified_temp_save.is_empty():
        push_warning("Temp save verification failed; aborting save.")
        _delete_file_if_exists(temp_path)
        return false

    // 4. Rotate files (atomic)
    if not _rotate_save_files(temp_path, save_path, backup_path):
        push_warning("Unable to promote temp save to primary save: %s" % save_path)
        _delete_file_if_exists(temp_path)
        return false

    // 5. Cleanup
    _delete_file_if_exists(temp_path)
    return true
```

### File Rotation

```gdscript
static func _rotate_save_files(
    temp_path: String, 
    save_path: String, 
    backup_path: String
) -> bool:

    // Step 1: Remove old backup
    if FileAccess.file_exists(backup_path):
        var err := DirAccess.remove_absolute(
            ProjectSettings.globalize_path(backup_path)
        )
        if err != OK:
            push_warning("Unable to remove old backup save: %s" % backup_path)
            return false

    // Step 2: Move current primary to backup
    var primary_exists := FileAccess.file_exists(save_path)
    if primary_exists:
        var err := DirAccess.rename_absolute(
            ProjectSettings.globalize_path(save_path),
            ProjectSettings.globalize_path(backup_path)
        )
        if err != OK:
            push_warning("Unable to rotate primary save into backup: %s" % save_path)
            return false

    // Step 3: Move temp to primary (atomic rename)
    var err := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(temp_path),
        ProjectSettings.globalize_path(save_path)
    )

    if err == OK:
        return true

    // Step 3 failed - try to recover
    push_warning("Unable to rename temp save into primary save: %s" % save_path)

    // Attempt restore from backup
    if primary_exists and FileAccess.file_exists(backup_path):
        var restore_err := DirAccess.rename_absolute(
            ProjectSettings.globalize_path(backup_path),
            ProjectSettings.globalize_path(save_path)
        )
        if restore_err != OK:
            push_warning("Unable to restore backup save after failed promotion")

    return false
```

**Key insight:** The rename to primary only fails if something goes catastrophically wrong (disk full, permissions). In that case, the backup is restored so the player at least has their previous save.

## Load Flow

```gdscript
static func load_into_state(
    game_state: GameState, 
    save_path: String = SAVE_PATH
) -> bool:

    if game_state == null:
        return false

    var backup_path := _get_backup_path(save_path)
    var loaded_save: Dictionary = {}

    // Try primary first
    if FileAccess.file_exists(save_path):
        loaded_save = _load_save_dict_from_path(save_path)

    // Primary failed - try backup
    if loaded_save.is_empty():
        loaded_save = _load_save_dict_from_path(backup_path)
        if not loaded_save.is_empty():
            push_warning("Primary save was unavailable or invalid; loaded backup save instead.")

            // Quarantine corrupted primary for analysis
            if FileAccess.file_exists(save_path):
                _quarantine_invalid_save(save_path)

    // Both failed
    if loaded_save.is_empty():
        return false

    // Apply to game state
    game_state.apply_save_dict(loaded_save)
    return true
```

**Recovery strategy:** Always fallback to backup, preserving corrupted files for debugging.

## Validation

### Save Data Validation

```gdscript
static func _is_valid_save_dict(save_data: Dictionary) -> bool:
    if save_data.is_empty():
        return false

    // Version check
    if not save_data.has("save_version"):
        return false

    var save_version = save_data.get("save_version", -1)
    if not _is_integer_number(save_version):
        return false

    if save_version <= 0 or save_version > GameState.SAVE_VERSION:
        return false

    // Structure validation - all must be dictionaries or expected types
    if typeof(save_data.get("elements", {})) != TYPE_DICTIONARY:
        return false
    if typeof(save_data.get("upgrades", {})) != TYPE_DICTIONARY:
        return false
    if typeof(save_data.get("blessings", {})) != TYPE_DICTIONARY:
        return false
    if typeof(save_data.get("planets", {})) != TYPE_DICTIONARY:
        return false
    if typeof(save_data.get("completed_milestones", [])) != TYPE_ARRAY:
        return false
    // ... etc for all expected fields

    return true
```

**Why strict validation?** Prevents corrupted/malformed saves from crashing the game.

### Recovery from Invalid Saves

```gdscript
static func _quarantine_invalid_save(path: String) -> void:
    if not FileAccess.file_exists(path):
        return

    var invalid_path := "%s%s" % [path, INVALID_SUFFIX]  // .json.invalid

    // Remove old quarantine
    if FileAccess.file_exists(invalid_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(invalid_path))

    // Move to quarantine
    var err := DirAccess.rename_absolute(
        ProjectSettings.globalize_path(path),
        ProjectSettings.globalize_path(invalid_path)
    )
    if err != OK:
        push_warning("Unable to quarantine invalid save file: %s" % path)
```

**Purpose:** Corrupted saves are moved to `.invalid` suffix rather than deleted, allowing for debugging and potential recovery.

## File Extensions

| Extension | Purpose |
|-----------|---------|
| `.json` | Current primary save file |
| `.json.tmp` | Temporary file during write |
| `.json.bak` | Backup from previous successful save |
| `.json.invalid` | Quarantined corrupted saves |

## Path Configuration

```gdscript
const SAVE_PATH := "user://idle_universe_save.json"
const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"
const INVALID_SUFFIX := ".invalid"

static func _get_temp_path(save_path: String) -> String:
    return "%s%s" % [save_path, TEMP_SUFFIX]

static func _get_backup_path(save_path: String) -> String:
    return "%s%s" % [save_path, BACKUP_SUFFIX]
```

**Platform paths:**
- Windows: `%APPDATA%/Godot/app_userdata/Idle_Universe/`
- macOS: `~/Library/Application Support/Godot/app_userdata/Idle_Universe/`
- Linux: `~/.local/share/godot/app_userdata/Idle_Universe/`

## Autosave Integration

The `AutosaveService` uses `SaveManager`:

```gdscript
class_name AutosaveService

const DEFAULT_AUTO_SAVE_INTERVAL_TICKS := 50  // 5 seconds at 10 TPS

func autosave_if_needed(game_state: GameState) -> bool:
    if game_state == null:
        return false

    // Check if enough ticks passed
    if game_state.tick_count - game_state.last_save_tick < auto_save_interval_ticks:
        return false

    return save_now(game_state)

func save_now(game_state: GameState) -> bool:
    if SaveManager.save_state(game_state):
        game_state.last_save_tick = game_state.tick_count
        return true
    return false

func save_on_exit(game_state: GameState) -> bool:
    return save_now(game_state)
```

### Save on Exit Hook

```gdscript
# In main scene
func _notification(what):
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        # Attempt save before closing
        autosave_service.save_on_exit(game_state)
        get_tree().quit()
```

## Error Handling Summary

| Scenario | Behavior |
|----------|----------|
| Write temp fails | Abort, no changes to existing saves |
| Verify temp fails | Delete temp, abort, preserve primary |
| Rotate primary→backup fails | Abort, preserve existing primary |
| Rotate temp→primary fails | Restore backup→primary, return failure |
| Load primary fails | Try backup, quarantine primary if corrupted |
| Load backup fails | Return failure, new game starts |
| Validation fails | Reject save, quarantine file |

## Testing Save Robustness

From [`src/tests/save_manager_recovery_check.gd`](../src/tests/save_manager_recovery_check.gd):

```gdscript
func test_save_and_load() -> bool:
    var test_state := create_test_game_state()

    // Save
    var saved := SaveManager.save_state(test_state)
    assert(saved, "Save should succeed")

    // Modify
    test_state.dust = DigitMaster.new(999999)

    // Load back
    var loaded := SaveManager.load_into_state(test_state)
    assert(loaded, "Load should succeed")

    // Verify restored to saved value
    assert(test_state.dust.compare(DigitMaster.new(0)) == 0, "Dust should be reset")

    return true

func test_backup_recovery() -> bool:
    // Corrupt primary save
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string("corrupted garbage")
    file.close()

    // Should load from backup
    var success := SaveManager.load_into_state(game_state)
    assert(success, "Should recover from backup")

    return true
```

## Storage Limits

GD4 `user://` directory limits depend on platform:
- **Desktop:** Typically unlimited (filesystem limits)
- **Mobile:** May have restrictions
- **Web:** Browser storage quota (~5-50MB typically)

**Save file size estimate:**
```
- Elements: ~2KB (118 elements × small dict)
- Upgrades: ~1KB
- Blessings: ~1KB
- Planets: ~1KB
- Other state: ~1KB
Total: ~6-10KB per save
```

**With history:** Can rotate multiple backups if needed.

## Migration Support

For version upgrades:

```gdscript
# GameState.apply_save_dict handles version migration
func apply_save_dict(save_data: Dictionary) -> void:
    var version = save_data.get("save_version", 0)

    // Apply migrations in sequence
    if version < 2:
        _migrate_v1_to_v2(save_data)
    if version < 3:
        _migrate_v2_to_v3(save_data)
    # ... etc

    // Apply final version
    serializer.apply_save_dict(self, save_data)
```

## Related Documentation

- [Architecture](./architecture.md) - System overview
- [Save System](./save_system.md) - Serialization details
- [State Classes](./state_classes.md) - What gets saved
- [Project Index](./project_index.md) - Data flow diagrams