extends SceneTree

const GameStateScript = preload("res://src/core/game_state.gd")
const TestSupport = preload("res://src/tests/test_support.gd")

func _initialize() -> void:
	var state: GameState = GameStateScript.from_content(
		_load_json("res://src/data/elements.json"),
		_load_json("res://src/data/upgrades.json"),
		_load_json("res://src/data/blessings.json"),
		_load_json("res://src/data/planets.json"),
		_load_json("res://src/data/planet_menu.json"),
		_load_json("res://src/data/oblations.json")
	)

	_unlock_planetary_era(state)
	var planet_a := state.get_planet_state("planet_a")
	if planet_a == null or not state.is_planet_owned("planet_a"):
		_fail("Planet A should be granted on Planetary Era unlock.")
		return

	planet_a.level = 5
	state.best_planet_levels_this_run["planet_a"] = 5
	state.refresh_progression_state()
	if not state.completed_milestones.has("planet_a_5"):
		_fail("Planet A level 5 should auto-complete the first milestone.")
		return
	if not state.is_oblation_menu_unlocked():
		_fail("First milestone should unlock the Oblations menu.")
		return
	if not state.is_planet_purchase_unlocked("planet_b"):
		_fail("First milestone should unlock Planet B purchase.")
		return

	if not state.confirm_oblation("hydrogen_memory", {"element_slot": "ele_H"}):
		_fail("Hydrogen Memory should confirm after milestone 1.")
		return
	if state.get_visible_element_section_count() != 2:
		_fail("Hydrogen Memory should unlock element section 11-30.")
		return

	if not state.confirm_oblation("planet_a_ember", {"planet_slot": "planet_a"}):
		_fail("Planet A should be a valid oblation target.")
		return
	if state.is_planet_owned("planet_a"):
		_fail("Planet A should no longer be owned after oblation.")
		return
	if not state.is_planet_sacrificed("planet_a"):
		_fail("Planet A should be marked sacrificed after oblation.")
		return
	if state.current_planet_id != "planet_a":
		_fail("World focus should remain on sacrificed Planet A when no planets are owned.")
		return
	if state.buy_current_planet_worker():
		_fail("Sacrificed planets should not allow worker purchases.")
		return

	state.produce_resource(GameState.DUST_RESOURCE_ID, DigitMaster.new(50000.0))
	state.orbs = 3000
	if not state.purchase_planet("planet_a"):
		_fail("Planet A should be repurchasable after oblation.")
		return
	if state.is_planet_sacrificed("planet_a"):
		_fail("Repurchasing Planet A should clear its sacrificed state.")
		return

	if not state.purchase_planet("planet_b"):
		_fail("Planet B should be purchasable after milestone 1.")
		return
	if not state.confirm_oblation("planet_b_ashes", {"planet_slot": "planet_b"}):
		_fail("Planet B should be a valid oblation target.")
		return
	if not state.is_planet_sacrificed("planet_b"):
		_fail("Planet B should be marked sacrificed after oblation.")
		return

	state.produce_resource(GameState.DUST_RESOURCE_ID, DigitMaster.new(50000.0))
	state.orbs += 3000
	if not state.purchase_planet("planet_b"):
		_fail("Planet B should be repurchasable for later recipes.")
		return
	var planet_b := state.get_planet_state("planet_b")
	if planet_b == null:
		_fail("Planet B state missing.")
		return
	planet_b.level = 5
	state.best_planet_levels_this_run["planet_b"] = 5
	state.refresh_progression_state()
	if not state.completed_milestones.has("planet_b_5"):
		_fail("Planet B level 5 should auto-complete the second milestone.")
		return
	if state.get_planet_menu_stage() != 3:
		_fail("Second milestone should advance the planets menu to stage 3.")
		return

	TestSupport.unlock_elements(state, ["ele_H", "ele_He", "ele_C", "ele_O", "ele_Ne"])
	TestSupport.set_element_amount(state, "ele_Ne", 50000.0)
	if not state.confirm_oblation("neon_orbit", {"element_slot": "ele_Ne", "planet_slot": "planet_b"}):
		_fail("Neon Orbit should accept Neon plus Planet B after milestone 2.")
		return
	if state.get_planet_xp_gain_multiplier() <= 1.39:
		_fail("Planet XP oblations should stack persistent bonuses.")
		return
	if state.get_dust_gain_multiplier() <= 1.49:
		_fail("Planet B Ashes should grant a persistent dust bonus.")
		return

	print("Milestones and oblations smoke check passed.")
	quit()

func _unlock_planetary_era(state: GameState) -> void:
	var era_resource_ids: Array[String] = []
	for resource_id_variant in state.PLANETARY_ERA_RESOURCE_IDS:
		era_resource_ids.append(str(resource_id_variant))
	for resource_id in era_resource_ids:
		TestSupport.set_element_amount(state, resource_id, state.PLANETARY_ERA_RESOURCE_COST + 1000.0)
	state.dust = DigitMaster.new(state.PLANETARY_ERA_RESOURCE_COST + 1000.0)
	state.orbs = state.PLANETARY_ERA_ORB_COST + 100
	TestSupport.unlock_elements(state, era_resource_ids)
	if not state.unlock_next_era():
		_fail("Planetary Era unlock failed in setup.")

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
