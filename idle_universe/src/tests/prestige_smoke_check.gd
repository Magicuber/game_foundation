extends SceneTree

const GameStateScript = preload("res://src/core/game_state.gd")

func _initialize() -> void:
	var state: GameState = GameStateScript.from_content(
		_load_json("res://src/data/elements.json"),
		_load_json("res://src/data/upgrades.json"),
		_load_json("res://src/data/blessings.json"),
		_load_json("res://src/data/planets.json")
	)
	state.unlocked_era_index = 1
	state.orbs = 5000
	state.refresh_progression_state()

	var planet_a := state.get_planet_state("planet_a")
	if planet_a == null:
		_fail("Planet A state missing.")
		return

	state.best_planet_levels_this_run["planet_a"] = 5
	planet_a.level = 5
	if not state.can_prestige():
		_fail("Planet A level 5 should unlock the first prestige.")
		return
	if not state.perform_prestige():
		_fail("First prestige did not complete.")
		return
	if state.prestige_points_total != 1 or state.prestige_points_unspent != 1:
		_fail("First prestige should grant exactly one point.")
		return
	if not state.is_planet_purchase_unlocked("planet_b"):
		_fail("First prestige should unlock Planet B purchase.")
		return
	if not state.claim_next_prestige_node():
		_fail("First prestige node should be claimable.")
		return
	if state.get_visible_element_section_count() != 2:
		_fail("Node 1 should unlock element section 11-30.")
		return

	state.dust = DigitMaster.new(25000.0)
	if not state.purchase_planet("planet_b"):
		_fail("Planet B should be purchasable after the first prestige.")
		return

	state.best_planet_levels_this_run["planet_b"] = 5
	var planet_b := state.get_planet_state("planet_b")
	if planet_b == null:
		_fail("Planet B state missing after purchase.")
		return
	planet_b.level = 5
	if not state.can_prestige():
		_fail("Planet B level 5 should unlock the second prestige.")
		return
	if not state.perform_prestige():
		_fail("Second prestige did not complete.")
		return
	if state.prestige_points_total != 2 or state.prestige_points_unspent != 1:
		_fail("Second prestige should be the source of the second point.")
		return
	if str(state.get_next_prestige_milestone().get("id", "")) != "planet_c_5":
		_fail("Planet C should be the next placeholder milestone after Planet B.")
		return
	if not state.claim_next_prestige_node():
		_fail("Second prestige point should claim the dust node.")
		return

	state.produce_resource(GameState.DUST_RESOURCE_ID, DigitMaster.new(10.0))
	if state.get_resource_amount(GameState.DUST_RESOURCE_ID).compare(DigitMaster.new(15.0)) != 0:
		_fail("Dust node should increase dust gains by 50%.")
		return

	print("Prestige smoke check passed.")
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
	push_error("Smoke check failed: %s" % message)
	quit(1)
