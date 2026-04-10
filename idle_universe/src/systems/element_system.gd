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
	var result := _build_smash_result(game_state, upgrades_system, game_state.current_element_id, false)
	if result.is_empty():
		return {}
	_apply_smash_result(game_state, result, false)
	return result

func resolve_auto_smash(game_state: GameState, upgrades_system: UpgradesSystem, element_id: String) -> Dictionary:
	var result := preview_auto_smash(game_state, upgrades_system, element_id)
	if result.is_empty():
		return {}
	apply_deferred_auto_smash_result(game_state, result)
	return result

func preview_auto_smash(game_state: GameState, upgrades_system: UpgradesSystem, element_id: String) -> Dictionary:
	return _build_smash_result(game_state, upgrades_system, element_id, true)

func apply_deferred_auto_smash_result(game_state: GameState, result: Dictionary) -> void:
	_apply_smash_result(game_state, result, true)

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

func _build_smash_result(game_state: GameState, upgrades_system: UpgradesSystem, element_id: String, is_auto: bool) -> Dictionary:
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

	var bonus_resource_ids: Array[String] = []
	for resource_id in base_resource_ids:
		if is_auto and upgrades_system.should_trigger_critical_payload(game_state):
			_add_bonus_copies(bonus_resource_ids, resource_id, 2)
		if not is_auto and upgrades_system.should_trigger_manual_double_hit(game_state):
			_add_bonus_copies(bonus_resource_ids, resource_id, 1)
		if upgrades_system.should_trigger_resonant_yield(game_state):
			_add_bonus_copies(bonus_resource_ids, resource_id, 1)

	var final_resource_ids := base_resource_ids.duplicate()
	final_resource_ids.append_array(bonus_resource_ids)
	if final_resource_ids.is_empty():
		return {}
	var resource_counts := _build_resource_counts(final_resource_ids)

	return {
		"source_element_id": element_id,
		"produced_resource_ids": final_resource_ids,
		"produced_resource_id": final_resource_ids[0],
		"bonus_resource_ids": bonus_resource_ids,
		"resource_counts": resource_counts,
		"was_fission": was_fission,
		"variant": smasher_variant,
		"rolled_variants": rolled_variants,
		"base_reward_multiplier": base_reward_multiplier
	}

func _apply_smash_result(game_state: GameState, result: Dictionary, is_auto: bool) -> void:
	if game_state == null or result.is_empty():
		return

	var resource_counts: Dictionary = result.get("resource_counts", {})
	for resource_id_variant in resource_counts.keys():
		var resource_id := str(resource_id_variant)
		var count := maxi(0, int(resource_counts[resource_id_variant]))
		if resource_id.is_empty() or count <= 0:
			continue
		game_state.produce_resource(resource_id, DigitMaster.new(float(count)))

	if is_auto:
		game_state.total_auto_smashes += 1
	else:
		game_state.total_manual_smashes += 1

func _add_bonus_copies(bonus_resource_ids: Array[String], resource_id: String, copy_count: int) -> void:
	for _copy_index in range(copy_count):
		bonus_resource_ids.append(resource_id)

func _build_resource_counts(resource_ids: Array[String]) -> Dictionary:
	var resource_counts := {}
	for resource_id in resource_ids:
		var normalized_id := str(resource_id)
		if normalized_id.is_empty():
			continue
		resource_counts[normalized_id] = int(resource_counts.get(normalized_id, 0)) + 1
	return resource_counts

func _roll_fission_split(game_state: GameState, produced_resource_id: String) -> Array[String]:
	if not game_state.is_element_id(produced_resource_id):
		return []

	var produced_element := game_state.get_element_state(produced_resource_id)
	if produced_element == null:
		return []
	var target_weight := produced_element.index
	if target_weight <= 1:
		return []

	var max_unlocked_index := game_state.get_max_unlocked_real_element_index()
	if max_unlocked_index <= 0:
		return []

	var min_left := maxi(1, target_weight - max_unlocked_index)
	var max_left := mini(max_unlocked_index, int(floor(float(target_weight) / float(FISSION_PART_COUNT))))
	if min_left > max_left:
		return []

	var left_index := rng.randi_range(min_left, max_left)
	var right_index := target_weight - left_index
	var left_element := game_state.get_element_state_by_index(left_index)
	var right_element := game_state.get_element_state_by_index(right_index)
	if left_element == null or right_element == null:
		return []
	if not left_element.unlocked or not right_element.unlocked:
		return []

	return [left_element.id, right_element.id]

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
