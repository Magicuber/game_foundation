extends RefCounted

class_name GameBootstrap

const ELEMENTS_DATA_PATH := "res://src/data/elements.json"
const UPGRADES_DATA_PATH := "res://src/data/upgrades.json"
const BLESSINGS_DATA_PATH := "res://src/data/blessings.json"
const PLANETS_DATA_PATH := "res://src/data/planets.json"
const PLANET_MENU_DATA_PATH := "res://src/data/planet_menu.json"
const OBLATIONS_DATA_PATH := "res://src/data/oblations.json"

func build_game_state() -> GameState:
	var elements_content: Dictionary = _load_json_dictionary(ELEMENTS_DATA_PATH)
	var upgrades_content: Dictionary = _load_json_dictionary(UPGRADES_DATA_PATH)
	var blessings_content: Dictionary = _load_json_dictionary(BLESSINGS_DATA_PATH)
	var planets_content: Dictionary = _load_json_dictionary(PLANETS_DATA_PATH)
	var planet_menu_content: Dictionary = _load_json_dictionary(PLANET_MENU_DATA_PATH)
	var oblations_content: Dictionary = _load_json_dictionary(OBLATIONS_DATA_PATH)
	return GameState.from_content(
		elements_content,
		upgrades_content,
		blessings_content,
		planets_content,
		planet_menu_content,
		oblations_content
	)

func build_and_load_game_state() -> GameState:
	var state := build_game_state()
	SaveManager.load_into_state(state)
	return state

func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: %s" % path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Unable to read data file: %s" % path)
		return {}

	var parsed_value: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_value) != TYPE_DICTIONARY:
		push_warning("Expected dictionary JSON at %s" % path)
		return {}

	var parsed: Dictionary = parsed_value
	return parsed
