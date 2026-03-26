extends RefCounted

class_name SaveManager

const SAVE_PATH := "user://idle_universe_save.json"

static func save_state(game_state: GameState, save_path: String = SAVE_PATH) -> bool:
	if game_state == null:
		return false

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to open save file for writing: %s" % save_path)
		return false

	file.store_string(JSON.stringify(game_state.to_save_dict()))
	return true

static func load_into_state(game_state: GameState, save_path: String = SAVE_PATH) -> bool:
	if game_state == null or not FileAccess.file_exists(save_path):
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open save file for reading: %s" % save_path)
		return false

	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save data is not a dictionary; ignoring save.")
		return false

	game_state.apply_save_dict(parsed)
	return true
