extends SceneTree

const GameStateScript = preload("res://src/core/game_state.gd")
const SaveManagerScript = preload("res://src/bootstrap/save_manager.gd")

const TEST_SAVE_PATH := "user://save_manager_recovery_test.json"

func _initialize() -> void:
	_cleanup_test_files()

	var state: GameState = _build_state()
	state.orbs = 123
	if not SaveManagerScript.save_state(state, TEST_SAVE_PATH):
		_fail("Initial save failed.")
		return

	state.orbs = 456
	if not SaveManagerScript.save_state(state, TEST_SAVE_PATH):
		_fail("Second save failed.")
		return

	if not FileAccess.file_exists(TEST_SAVE_PATH):
		_fail("Primary save was not created.")
		return
	if not FileAccess.file_exists(_backup_path()):
		_fail("Backup save was not created.")
		return

	if not _write_text_file(TEST_SAVE_PATH, "{bad json"):
		_fail("Unable to corrupt primary save.")
		return

	var recovered_state: GameState = _build_state()
	if not SaveManagerScript.load_into_state(recovered_state, TEST_SAVE_PATH):
		_fail("Load should recover from backup when primary is corrupt.")
		return
	if recovered_state.orbs != 123:
		_fail("Recovered state should come from backup save.")
		return

	print("Save manager recovery check passed.")
	_cleanup_test_files()
	quit()

func _build_state() -> GameState:
	return GameStateScript.from_content(
		_load_json("res://src/data/elements.json"),
		_load_json("res://src/data/upgrades.json"),
		_load_json("res://src/data/blessings.json"),
		_load_json("res://src/data/planets.json"),
		_load_json("res://src/data/planet_menu.json")
	)

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_fail("Missing JSON file %s." % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail("Expected dictionary JSON at %s." % path)
		return {}
	return parsed

func _write_text_file(path: String, contents: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(contents)
	file.flush()
	return file.get_error() == OK

func _cleanup_test_files() -> void:
	for path in [TEST_SAVE_PATH, _temp_path(), _backup_path()]:
		if not FileAccess.file_exists(path):
			continue
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _temp_path() -> String:
	return "%s.tmp" % TEST_SAVE_PATH

func _backup_path() -> String:
	return "%s.bak" % TEST_SAVE_PATH

func _fail(message: String) -> void:
	push_error("Save manager recovery check failed: %s" % message)
	_cleanup_test_files()
	quit(1)
