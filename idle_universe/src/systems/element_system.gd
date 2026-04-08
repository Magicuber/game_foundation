extends RefCounted

class_name ElementSystem

const FISSION_PART_COUNT := 2
const VARIANT_NORMAL := "normal"
const VARIANT_FOIL := "foil"
const VARIANT_HOLOGRAPHIC := "holographic"
const VARIANT_POLYCHROME := "polychrome"
const VARIANT_BASE_REWARD_MULTIPLIERS := {
	VARIANT_NORMAL: 1,
	VARIANT_FOIL: 2,
	VARIANT_HOLOGRAPHIC: 5,
	VARIANT_POLYCHROME: 10
}
const VARIANT_PRIORITY_ORDER := [
	VARIANT_POLYCHROME,
	VARIANT_HOLOGRAPHIC,
	VARIANT_FOIL
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func manual_smash(game_state: GameState, upgrades_system: UpgradesSystem) -> Dictionary:
	return _produce_from_element(game_state, upgrades_system, game_state.current_element_id, false)

func resolve_auto_smash(game_state: GameState, upgrades_system: UpgradesSystem, element_id: String) -> Dictionary:
	return _produce_from_element(game_state, upgrades_system, element_id, true)

func unlock_next_element(game_state: GameState) -> bool:
	if game_state == null:
		return false
	return game_state.unlock_next_element()

func select_adjacent(game_state: GameState, direction: int) -> bool:
	if game_state == null:
		return false
	return game_state.select_adjacent_unlocked(direction)

func select_element(game_state: GameState, element_id: String) -> bool:
	if game_state == null:
		return false
	return game_state.select_element(element_id)

func _produce_from_element(game_state: GameState, upgrades_system: UpgradesSystem, element_id: String, is_auto: bool) -> Dictionary:
	if game_state == null or upgrades_system == null or element_id.is_empty():
		return {}

	var source_element := game_state.get_element_state(element_id)
	if source_element == null:
		return {}

	var produced_resource := source_element.produces
	if produced_resource.is_empty():
		return {}

	var produced_resource_ids: Array[String] = [produced_resource]
	var was_fission := false
	if upgrades_system.should_trigger_fission(game_state):
		var fission_results: Array[String] = _roll_fission_split(game_state, produced_resource)
		if not fission_results.is_empty():
			produced_resource_ids = fission_results
			was_fission = true

	var rolled_variants := _roll_smasher_variants(game_state)
	var smasher_variant := _get_display_variant(rolled_variants)
	var base_reward_multiplier := _get_combined_reward_multiplier(rolled_variants)
	var base_resource_ids: Array[String] = []
	for resource_id in produced_resource_ids:
		for _copy_index in range(base_reward_multiplier):
			base_resource_ids.append(resource_id)
			game_state.produce_resource(resource_id, DigitMaster.one())

	var bonus_resource_ids: Array[String] = []
	for resource_id in base_resource_ids:
		if is_auto and upgrades_system.should_trigger_critical_payload(game_state):
			_add_bonus_copies(game_state, bonus_resource_ids, resource_id, 2)
		if not is_auto and upgrades_system.should_trigger_manual_double_hit(game_state):
			_add_bonus_copies(game_state, bonus_resource_ids, resource_id, 1)
		if upgrades_system.should_trigger_resonant_yield(game_state):
			_add_bonus_copies(game_state, bonus_resource_ids, resource_id, 1)

	var final_resource_ids := base_resource_ids.duplicate()
	final_resource_ids.append_array(bonus_resource_ids)

	if is_auto:
		game_state.total_auto_smashes += 1
	else:
		game_state.total_manual_smashes += 1

	return {
		"source_element_id": element_id,
		"produced_resource_ids": final_resource_ids,
		"produced_resource_id": final_resource_ids[0],
		"bonus_resource_ids": bonus_resource_ids,
		"was_fission": was_fission,
		"variant": smasher_variant,
		"rolled_variants": rolled_variants,
		"base_reward_multiplier": base_reward_multiplier
	}

func _add_bonus_copies(game_state: GameState, bonus_resource_ids: Array[String], resource_id: String, copy_count: int) -> void:
	for _copy_index in range(copy_count):
		bonus_resource_ids.append(resource_id)
		game_state.produce_resource(resource_id, DigitMaster.one())

func _roll_fission_split(game_state: GameState, produced_resource_id: String) -> Array[String]:
	if not game_state.is_element_id(produced_resource_id):
		return []

	var produced_element := game_state.get_element_state(produced_resource_id)
	if produced_element == null:
		return []
	var target_weight := produced_element.index
	if target_weight <= 1:
		return []

	var unlocked_ids: Array[String] = game_state.get_unlocked_real_element_ids()
	if unlocked_ids.is_empty():
		return []

	var candidates: Array = []
	_build_partitions(game_state, unlocked_ids, target_weight, FISSION_PART_COUNT, 0, [], candidates)
	if candidates.is_empty():
		return []

	var chosen_index := rng.randi_range(0, candidates.size() - 1)
	var chosen_partition: Array = candidates[chosen_index]
	var results: Array[String] = []
	for resource_id in chosen_partition:
		results.append(str(resource_id))
	return results

func _build_partitions(game_state: GameState, unlocked_ids: Array[String], remaining_weight: int, remaining_parts: int, start_index: int, current_ids: Array, results: Array) -> void:
	if remaining_parts == 0:
		if remaining_weight == 0:
			results.append(current_ids.duplicate())
		return

	if remaining_weight <= 0 or start_index >= unlocked_ids.size():
		return

	for i in range(start_index, unlocked_ids.size()):
		var element_id := unlocked_ids[i]
		var element := game_state.get_element_state(element_id)
		if element == null:
			continue
		var element_weight := element.index
		if element_weight <= 0 or element_weight > remaining_weight:
			continue

		var next_ids: Array = current_ids.duplicate()
		next_ids.append(element_id)
		_build_partitions(
			game_state,
			unlocked_ids,
			remaining_weight - element_weight,
			remaining_parts - 1,
			i,
			next_ids,
			results
		)

func _roll_smasher_variants(game_state: GameState) -> Array[String]:
	var rolled_variants: Array[String] = []
	if game_state == null:
		return rolled_variants

	if _roll_percent_chance(game_state.get_foil_spawn_chance_percent()):
		rolled_variants.append(VARIANT_FOIL)
	if _roll_percent_chance(game_state.get_holographic_spawn_chance_percent()):
		rolled_variants.append(VARIANT_HOLOGRAPHIC)
	if _roll_percent_chance(game_state.get_polychrome_spawn_chance_percent()):
		rolled_variants.append(VARIANT_POLYCHROME)
	return rolled_variants

func _roll_percent_chance(chance_percent: float) -> bool:
	var clamped_chance := clampf(chance_percent, 0.0, 100.0)
	if clamped_chance <= 0.0:
		return false
	return rng.randf() * 100.0 < clamped_chance

func _get_combined_reward_multiplier(rolled_variants: Array[String]) -> int:
	var reward_multiplier := 1
	for variant in rolled_variants:
		reward_multiplier *= int(VARIANT_BASE_REWARD_MULTIPLIERS.get(variant, 1))
	return reward_multiplier

func _get_display_variant(rolled_variants: Array[String]) -> String:
	for variant in VARIANT_PRIORITY_ORDER:
		if rolled_variants.has(variant):
			return variant
	return VARIANT_NORMAL
