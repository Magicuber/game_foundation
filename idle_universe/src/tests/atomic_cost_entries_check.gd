extends SceneTree

const GameStateScript = preload("res://src/core/game_state.gd")

func _initialize() -> void:
	var state: GameState = GameStateScript.from_content(
		_load_json("res://src/data/elements.json"),
		_load_json("res://src/data/upgrades.json"),
		_load_json("res://src/data/blessings.json"),
		_load_json("res://src/data/planets.json"),
		_load_json("res://src/data/planet_menu.json")
	)

	state.dust = DigitMaster.new(100.0)
	state.orbs = 10

	var duplicate_dust_costs: Array[Dictionary] = [
		{
			"resource_id": GameState.DUST_RESOURCE_ID,
			"cost": DigitMaster.new(60.0)
		},
		{
			"resource_id": GameState.DUST_RESOURCE_ID,
			"cost": DigitMaster.new(50.0)
		}
	]
	if state.can_afford_cost_entries(duplicate_dust_costs):
		_fail("Combined duplicate resource costs should be unaffordable.")
		return
	if state.spend_cost_entries_atomic(duplicate_dust_costs):
		_fail("Atomic spend should fail when combined duplicate costs exceed balance.")
		return
	if state.dust.compare(DigitMaster.new(100.0)) != 0:
		_fail("Failed atomic spend should not change dust balance.")
		return

	var mixed_costs: Array[Dictionary] = [
		{
			"resource_id": GameState.DUST_RESOURCE_ID,
			"required_amount": DigitMaster.new(25.0),
			"is_orb_requirement": false
		},
		{
			"resource_id": "orbs",
			"required_amount": 3,
			"is_orb_requirement": true
		}
	]
	if not state.spend_cost_entries_atomic(mixed_costs):
		_fail("Atomic spend should support mixed dust and orb costs.")
		return
	if state.dust.compare(DigitMaster.new(75.0)) != 0:
		_fail("Successful atomic spend should deduct dust once.")
		return
	if state.orbs != 7:
		_fail("Successful atomic spend should deduct orbs once.")
		return

	print("Atomic cost entries check passed.")
	quit()

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
	push_error("Atomic cost entries check failed: %s" % message)
	quit(1)
