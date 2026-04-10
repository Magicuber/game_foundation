extends SceneTree

const GameStateScript = preload("res://src/core/game_state.gd")

func _initialize() -> void:
	var state: GameState = _new_state()
	_verify_rarity_buckets(state)

	state.blessings_count = 20
	state.unopened_blessings_count = 20
	state._blessing_rng.seed = 12345
	if state.open_earned_blessings() != 20:
		_fail("Opening earned blessings should consume all unopened blessings.")
		return
	if state.get_unopened_blessings_count() != 0:
		_fail("Opened blessings should leave zero unopened blessings.")
		return
	if state.get_discovered_blessing_count() <= 0:
		_fail("Opening blessings should discover at least one non-placeholder blessing.")
		return
	for blessing_id in state.get_blessing_ids():
		var blessing: BlessingState = state.get_blessing_state(blessing_id)
		if blessing != null and blessing.placeholder and blessing.level > 0:
			_fail("Placeholder blessings should never be rolled.")
			return

	var precision: BlessingState = state.get_blessing_state("uncommon_precision_of_sparks")
	var foil: BlessingState = state.get_blessing_state("exotic_foil_genesis")
	if precision == null or foil == null:
		_fail("Known blessing definitions missing.")
		return
	precision.level = 3
	foil.level = 2
	state._invalidate_blessing_effect_cache()
	_assert_approx(state.get_blessing_critical_smasher_bonus_percent(), 0.75, "Critical blessing cache should reflect updated level.")
	_assert_approx(state.get_foil_spawn_chance_percent(), 2.0, "Foil blessing cache should reflect updated level.")

	var save_data := state.to_save_dict()
	var loaded_state: GameState = _new_state()
	loaded_state.apply_save_dict(save_data)
	_verify_blessing_levels_equal(state, loaded_state)
	_assert_approx(loaded_state.get_blessing_critical_smasher_bonus_percent(), 0.75, "Loaded critical blessing cache should match saved state.")
	_assert_approx(loaded_state.get_foil_spawn_chance_percent(), 2.0, "Loaded foil blessing cache should match saved state.")

	if not loaded_state.reset_blessings():
		_fail("Reset blessings should report changes after earned blessings and manual level setup.")
		return
	if loaded_state.get_unopened_blessings_count() != loaded_state.blessings_count:
		_fail("Reset blessings should restore unopened count to blessings_count.")
		return
	if loaded_state.get_discovered_blessing_count() != 0:
		_fail("Reset blessings should clear all discovered blessing levels.")
		return
	_assert_approx(loaded_state.get_blessing_critical_smasher_bonus_percent(), 0.0, "Critical blessing cache should clear after reset.")
	_assert_approx(loaded_state.get_foil_spawn_chance_percent(), 0.0, "Foil blessing cache should clear after reset.")

	print("Blessing lifecycle smoke check passed.")
	quit()

func _new_state() -> GameState:
	return GameStateScript.from_content(
		_load_json("res://src/data/elements.json"),
		_load_json("res://src/data/upgrades.json"),
		_load_json("res://src/data/blessings.json"),
		_load_json("res://src/data/planets.json"),
		_load_json("res://src/data/planet_menu.json")
	)

func _verify_rarity_buckets(state: GameState) -> void:
	var all_bucket_ids := {}
	for rarity in state.get_blessing_rarity_order():
		for blessing_id in state.get_blessing_ids_for_rarity(rarity):
			all_bucket_ids[blessing_id] = true
			var blessing: BlessingState = state.get_blessing_state(blessing_id)
			if blessing == null:
				_fail("Rarity bucket contains unknown blessing id %s." % blessing_id)
				return
			if blessing.rarity != rarity:
				_fail("Blessing %s is stored in wrong rarity bucket." % blessing_id)
				return

	for blessing_id in state.get_blessing_ids():
		if not all_bucket_ids.has(blessing_id):
			_fail("Blessing %s missing from rarity buckets." % blessing_id)
			return

func _verify_blessing_levels_equal(expected: GameState, actual: GameState) -> void:
	for blessing_id in expected.get_blessing_ids():
		var expected_blessing: BlessingState = expected.get_blessing_state(blessing_id)
		var actual_blessing: BlessingState = actual.get_blessing_state(blessing_id)
		if expected_blessing == null or actual_blessing == null:
			_fail("Missing blessing during save/load verification: %s." % blessing_id)
			return
		if expected_blessing.level != actual_blessing.level:
			_fail("Blessing level mismatch after save/load for %s." % blessing_id)
			return
	if expected.blessings_count != actual.blessings_count:
		_fail("blessings_count should persist across save/load.")
		return
	if expected.get_unopened_blessings_count() != actual.get_unopened_blessings_count():
		_fail("unopened_blessings_count should persist across save/load.")
		return

func _assert_approx(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		_fail("%s Expected %.4f, got %.4f." % [message, expected, actual])

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
	push_error("Blessing lifecycle smoke check failed: %s" % message)
	quit(1)
