extends RefCounted

class_name DustRecipeService

const SELECTION_STEPS := [0.0, 0.10, 0.25, 0.50, 1.0]
const BASE_SCALAR := 0.024
const QUANTITY_EXPONENT := 0.90
const DIVERSITY_EXPONENT := 0.55
const STABILITY_WEIGHT := 0.65
const TIER_WEIGHT := 0.35
const STABILITY_BY_INDEX := {
	1: 0.000,
	2: 0.804,
	3: 0.637,
	4: 0.734,
	5: 0.787,
	6: 0.873,
	7: 0.850,
	8: 0.907,
	9: 0.884,
	10: 0.913
}

var _selection_indices: Dictionary = {}
var _cache_dirty := true
var _cached_selected_amounts: Dictionary = {}
var _cached_selected_element_ids: Array[String] = []
var _cached_preview: DigitMaster = DigitMaster.zero()

func invalidate() -> void:
	_cache_dirty = true

func clear_selection() -> void:
	if _selection_indices.is_empty():
		return
	_selection_indices.clear()
	invalidate()

func get_selection_step_count() -> int:
	return SELECTION_STEPS.size()

func get_selection_index(element_id: String) -> int:
	return int(_selection_indices.get(element_id, 0))

func get_selection_fraction(element_id: String) -> float:
	var selection_index := clampi(get_selection_index(element_id), 0, SELECTION_STEPS.size() - 1)
	return float(SELECTION_STEPS[selection_index])

func cycle_selection(element_id: String) -> void:
	var next_index := (get_selection_index(element_id) + 1) % SELECTION_STEPS.size()
	if next_index == 0:
		_selection_indices.erase(element_id)
	else:
		_selection_indices[element_id] = next_index
	invalidate()

func cycle_all_unlocked_selections(game_state: GameState) -> void:
	if game_state == null:
		return

	var unlocked_ids := game_state.get_unlocked_real_element_ids()
	if unlocked_ids.is_empty():
		return

	for element_id in unlocked_ids:
		var next_index := (get_selection_index(element_id) + 1) % SELECTION_STEPS.size()
		if next_index == 0:
			_selection_indices.erase(element_id)
		else:
			_selection_indices[element_id] = next_index
	invalidate()

func get_selected_amounts(game_state: GameState, upgrades_system: UpgradesSystem) -> Dictionary:
	_ensure_cache(game_state, upgrades_system)
	return _cached_selected_amounts

func get_selected_element_ids(game_state: GameState, upgrades_system: UpgradesSystem) -> Array[String]:
	_ensure_cache(game_state, upgrades_system)
	return _cached_selected_element_ids.duplicate()

func get_preview(game_state: GameState, upgrades_system: UpgradesSystem) -> DigitMaster:
	_ensure_cache(game_state, upgrades_system)
	return _cached_preview.clone()

func _ensure_cache(game_state: GameState, upgrades_system: UpgradesSystem) -> void:
	if not _cache_dirty:
		return

	_cached_selected_amounts.clear()
	_cached_selected_element_ids.clear()
	_cached_preview = DigitMaster.zero()

	for element_id_variant in _selection_indices.keys():
		var element_id := str(element_id_variant)
		var fraction := get_selection_fraction(element_id)
		if fraction <= 0.0:
			continue
		if not game_state.is_element_unlocked(element_id):
			continue
		var amount: DigitMaster = game_state.get_resource_amount(element_id)
		if amount.is_zero():
			continue
		_cached_selected_amounts[element_id] = amount.multiply_scalar(fraction)
		_cached_selected_element_ids.append(element_id)

	_cached_selected_element_ids.sort()
	if _cached_selected_amounts.is_empty():
		_cache_dirty = false
		return

	var total_quantity := DigitMaster.zero()
	var max_exponent := -999999
	for element_id_variant in _cached_selected_amounts.keys():
		var amount: DigitMaster = _cached_selected_amounts[element_id_variant]
		if amount.is_zero():
			continue
		total_quantity = total_quantity.add(amount)
		max_exponent = maxi(max_exponent, amount.exponent)

	if total_quantity.is_zero():
		_cache_dirty = false
		return

	var highest_unlocked_atomic_number := _get_highest_unlocked_atomic_number(game_state)
	var scaled_quantity_sum := 0.0
	var weighted_quality_sum := 0.0
	for element_id_variant in _cached_selected_amounts.keys():
		var element_id := str(element_id_variant)
		var amount: DigitMaster = _cached_selected_amounts[element_id]
		if amount.is_zero():
			continue
		var scaled_quantity := amount.mantissa * pow(10.0, amount.exponent - max_exponent)
		scaled_quantity_sum += scaled_quantity
		weighted_quality_sum += scaled_quantity * _get_hybrid_quality(game_state, element_id, highest_unlocked_atomic_number)

	if scaled_quantity_sum <= 0.0:
		_cache_dirty = false
		return

	var avg_h := weighted_quality_sum / scaled_quantity_sum
	var raw_dust := total_quantity.power(QUANTITY_EXPONENT)
	raw_dust = raw_dust.multiply_scalar(
		BASE_SCALAR
		* pow(float(_cached_selected_amounts.size()), DIVERSITY_EXPONENT)
		* avg_h
	)
	raw_dust = raw_dust.multiply_scalar(
		upgrades_system.get_dust_recipe_bonus_multiplier(game_state, _cached_selected_element_ids)
	)

	_cached_preview = total_quantity if raw_dust.compare(total_quantity) > 0 else raw_dust
	_cache_dirty = false

func _get_highest_unlocked_atomic_number(game_state: GameState) -> int:
	var highest_index := 1
	for element_id in game_state.get_unlocked_real_element_ids():
		var element := game_state.get_element_state(element_id)
		if element == null:
			continue
		highest_index = maxi(highest_index, element.index)
	return highest_index

func _get_stability_score(element_index: int) -> float:
	if STABILITY_BY_INDEX.has(element_index):
		return float(STABILITY_BY_INDEX[element_index])
	var tier_ratio := sqrt(clampf(float(element_index) / 118.0, 0.0, 1.0))
	return clampf(0.45 + (0.45 * tier_ratio), 0.0, 1.0)

func _get_hybrid_quality(game_state: GameState, element_id: String, highest_unlocked_atomic_number: int) -> float:
	var element := game_state.get_element_state(element_id)
	var atomic_number := 1
	if element != null:
		atomic_number = element.index
	var tier_score := sqrt(clampf(float(atomic_number) / float(maxi(1, highest_unlocked_atomic_number)), 0.0, 1.0))
	var stability_score := _get_stability_score(atomic_number)
	return clampf(
		(STABILITY_WEIGHT * stability_score) + (TIER_WEIGHT * tier_score),
		0.0,
		1.0
	)
