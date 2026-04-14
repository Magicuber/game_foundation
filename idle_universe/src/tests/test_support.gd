extends RefCounted

class_name TestSupport

const GameStateScript = preload("res://src/core/game_state.gd")

static func build_state() -> GameState:
	return GameStateScript.from_content(
		_load_json("res://src/data/elements.json"),
		_load_json("res://src/data/upgrades.json"),
		_load_json("res://src/data/blessings.json"),
		_load_json("res://src/data/planets.json"),
		_load_json("res://src/data/planet_menu.json"),
		_load_json("res://src/data/oblations.json")
	)

static func require_element(state: GameState, element_id: String):
	var element := state.get_element_state(element_id)
	if element == null:
		push_error("Missing element %s in test setup." % element_id)
	return element

static func unlock_elements(state: GameState, element_ids: Array[String]) -> void:
	for element_id in element_ids:
		var element := require_element(state, element_id)
		if element != null:
			element.unlocked = true
	state.refresh_progression_state()

static func set_element_amount(state: GameState, element_id: String, amount: float) -> void:
	var element := require_element(state, element_id)
	if element != null:
		element.amount = DigitMaster.new(amount)

static func digit_equals(left: DigitMaster, right: DigitMaster) -> bool:
	if left == null or right == null:
		return false
	return left.compare(right) == 0

static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing JSON file %s." % path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Expected dictionary JSON at %s." % path)
		return {}
	return parsed
