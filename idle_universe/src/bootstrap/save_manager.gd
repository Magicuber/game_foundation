extends RefCounted

class_name SaveManager

const SAVE_PATH := "user://idle_universe_save.json"
const TEMP_SUFFIX := ".tmp"
const BACKUP_SUFFIX := ".bak"
const INVALID_SUFFIX := ".invalid"

static func save_state(game_state: GameState, save_path: String = SAVE_PATH) -> bool:
	if game_state == null:
		return false

	var serialized_save := JSON.stringify(game_state.to_save_dict())
	if serialized_save.is_empty():
		push_warning("Serialized save payload is empty; aborting save.")
		return false

	var temp_path := _get_temp_path(save_path)
	var backup_path := _get_backup_path(save_path)
	if not _write_text_file(temp_path, serialized_save):
		push_warning("Unable to write temp save file: %s" % temp_path)
		return false

	var verified_temp_save := _load_save_dict_from_path(temp_path)
	if verified_temp_save.is_empty():
		push_warning("Temp save verification failed; aborting save.")
		_delete_file_if_exists(temp_path)
		return false

	if not _rotate_save_files(temp_path, save_path, backup_path):
		push_warning("Unable to promote temp save to primary save: %s" % save_path)
		_delete_file_if_exists(temp_path)
		return false

	_delete_file_if_exists(temp_path)
	return true

static func load_into_state(game_state: GameState, save_path: String = SAVE_PATH) -> bool:
	if game_state == null:
		return false

	var backup_path := _get_backup_path(save_path)
	var primary_exists := FileAccess.file_exists(save_path)
	var loaded_save := _load_save_dict_from_path(save_path)
	if loaded_save.is_empty():
		loaded_save = _load_save_dict_from_path(backup_path)
		if loaded_save.is_empty():
			return false
		if primary_exists:
			_quarantine_invalid_save(save_path)
		push_warning("Primary save was unavailable or invalid; loaded backup save instead.")

	game_state.apply_save_dict(loaded_save)
	return true

static func _get_temp_path(save_path: String) -> String:
	return "%s%s" % [save_path, TEMP_SUFFIX]

static func _get_backup_path(save_path: String) -> String:
	return "%s%s" % [save_path, BACKUP_SUFFIX]

static func _write_text_file(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	return file.get_error() == OK

static func _load_save_dict_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open save file for reading: %s" % path)
		return {}

	var raw_text := file.get_as_text()
	var json := JSON.new()
	var parse_error := json.parse(raw_text)
	if parse_error != OK:
		push_warning(
			"Save JSON parse failed for %s at line %d: %s" % [
				path,
				json.get_error_line(),
				json.get_error_message()
			]
		)
		return {}

	var parsed_value: Variant = json.data
	if typeof(parsed_value) != TYPE_DICTIONARY:
		push_warning("Save data is not a dictionary; ignoring save file %s." % path)
		return {}

	var parsed: Dictionary = parsed_value
	if not _is_valid_save_dict(parsed):
		push_warning("Save data failed validation; ignoring save file %s." % path)
		return {}
	return parsed

static func _is_valid_save_dict(save_data: Dictionary) -> bool:
	if save_data.is_empty():
		return false
	if not save_data.has("save_version"):
		return false
	var save_version_variant := save_data.get("save_version", -1)
	if not _is_integer_number(save_version_variant):
		return false
	var save_version := int(save_version_variant)
	if save_version <= 0 or save_version > GameState.SAVE_VERSION:
		return false

	if typeof(save_data.get("elements", {})) != TYPE_DICTIONARY:
		return false
	if typeof(save_data.get("upgrades", {})) != TYPE_DICTIONARY:
		return false
	if typeof(save_data.get("blessings", {})) != TYPE_DICTIONARY:
		return false
	if typeof(save_data.get("planets", {})) != TYPE_DICTIONARY:
		return false
	if typeof(save_data.get("planet_purchase_unlocks", {})) != TYPE_DICTIONARY:
		return false
	if typeof(save_data.get("planet_owned_flags", {})) != TYPE_DICTIONARY:
		return false
	if save_data.has("sacrificed_planet_flags") and typeof(save_data.get("sacrificed_planet_flags", {})) != TYPE_DICTIONARY:
		return false
	if typeof(save_data.get("moon_upgrade_purchases", {})) != TYPE_DICTIONARY:
		return false
	if save_data.has("oblation_claimed_recipe_ids") and typeof(save_data.get("oblation_claimed_recipe_ids", [])) != TYPE_ARRAY:
		return false
	if typeof(save_data.get("best_planet_levels_this_run", {})) != TYPE_DICTIONARY:
		return false
	if typeof(save_data.get("completed_milestones", [])) != TYPE_ARRAY:
		return false
	if save_data.has("prestige_nodes_claimed") and typeof(save_data.get("prestige_nodes_claimed", [])) != TYPE_ARRAY:
		return false
	if typeof(save_data.get("current_element_id", "")) != TYPE_STRING:
		return false
	if typeof(save_data.get("current_planet_id", "")) != TYPE_STRING:
		return false
	if not _is_integer_number(save_data.get("orbs", 0)):
		return false
	if not _is_integer_number(save_data.get("player_level", 1)):
		return false
	if not _is_integer_number(save_data.get("tick_count", 0)):
		return false
	if not _is_integer_number(save_data.get("last_save_tick", 0)):
		return false
	if not _is_integer_number(save_data.get("total_manual_smashes", 0)):
		return false
	if not _is_integer_number(save_data.get("total_auto_smashes", 0)):
		return false
	if not _is_integer_number(save_data.get("blessings_count", 0)):
		return false
	if not _is_integer_number(save_data.get("unopened_blessings_count", 0)):
		return false
	return true

static func _is_integer_number(value: Variant) -> bool:
	match typeof(value):
		TYPE_INT:
			return true
		TYPE_FLOAT:
			return is_equal_approx(value, round(value))
		_:
			return false

static func _rotate_save_files(temp_path: String, save_path: String, backup_path: String) -> bool:
	if FileAccess.file_exists(backup_path):
		var backup_remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
		if backup_remove_error != OK:
			push_warning("Unable to remove old backup save: %s" % backup_path)
			return false

	var primary_path_missing := not FileAccess.file_exists(save_path)
	if not primary_path_missing:
		var backup_rename_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(save_path),
			ProjectSettings.globalize_path(backup_path)
		)
		if backup_rename_error != OK:
			push_warning("Unable to rotate primary save into backup: %s" % save_path)
			return false

	var promote_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(save_path)
	)
	if promote_error == OK:
		return true

	push_warning("Unable to rename temp save into primary save: %s" % save_path)
	if not primary_path_missing and FileAccess.file_exists(backup_path):
		var restore_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(backup_path),
			ProjectSettings.globalize_path(save_path)
		)
		if restore_error != OK:
			push_warning("Unable to restore backup save after failed promotion: %s" % backup_path)
	return false

static func _quarantine_invalid_save(path: String) -> void:
	if not FileAccess.file_exists(path):
		return

	var invalid_path := "%s%s" % [path, INVALID_SUFFIX]
	if FileAccess.file_exists(invalid_path):
		_delete_file_if_exists(invalid_path)
	var quarantine_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path),
		ProjectSettings.globalize_path(invalid_path)
	)
	if quarantine_error != OK:
		push_warning("Unable to quarantine invalid save file: %s" % path)

static func _delete_file_if_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if remove_error != OK:
		push_warning("Unable to delete file: %s" % path)
