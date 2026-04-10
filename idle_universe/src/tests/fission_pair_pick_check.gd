extends SceneTree

const GameStateScript = preload("res://src/core/game_state.gd")
const ElementSystemScript = preload("res://src/systems/element_system.gd")

func _initialize() -> void:
	var state: GameState = GameStateScript.from_content(
		_load_json("res://src/data/elements.json"),
		_load_json("res://src/data/upgrades.json"),
		_load_json("res://src/data/blessings.json"),
		_load_json("res://src/data/planets.json"),
		_load_json("res://src/data/planet_menu.json")
	)
	var element_system: ElementSystem = ElementSystemScript.new()

	_unlock_real_elements_up_to(state, 4)
	var impossible_target := state.get_element_state_by_index(8)
	if impossible_target == null:
		_fail("Missing target element at index 8.")
		return
	if not element_system._roll_fission_split(state, impossible_target.id).is_empty():
		_fail("Fission should fail when no unlocked 2-part split exists.")
		return

	_unlock_real_elements_up_to(state, 6)
	var target_element := state.get_element_state_by_index(6)
	if target_element == null:
		_fail("Missing target element at index 6.")
		return

	for _roll_index in range(200):
		var split: Array[String] = element_system._roll_fission_split(state, target_element.id)
		if split.size() != 2:
			_fail("Fission should always return exactly two parts for a valid target.")
			return
		var total_weight := 0
		for part_id in split:
			var part := state.get_element_state(part_id)
			if part == null:
				_fail("Fission returned an unknown element.")
				return
			if not part.unlocked:
				_fail("Fission returned a locked element.")
				return
			total_weight += part.index
		if total_weight != target_element.index:
			_fail("Fission result weights should sum to the target weight.")
			return

	print("Fission pair-pick check passed.")
	quit()

func _unlock_real_elements_up_to(state: GameState, max_index: int) -> void:
	for element_id in state.element_ids_in_order:
		var element := state.get_element_state(element_id)
		if element == null:
			continue
		if element.index <= 0:
			element.unlocked = true
			continue
		element.unlocked = element.index <= max_index
	state.refresh_progression_state()

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

func _fail(message: String) -> void:
	push_error("Fission pair-pick check failed: %s" % message)
	quit(1)
