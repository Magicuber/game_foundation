extends RefCounted

class_name BlessingManager

const BlessingStateScript = preload("res://src/core/state/blessing_state.gd")

var _game_state_ref: WeakRef = null
var game_state:
	get:
		return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func load_blessings(blessings_data: Array, rarity_data: Array) -> void:
	rebuild_blessings_state(blessings_data, rarity_data)

func rebuild_blessings_state(blessings_data: Array, rarity_data: Array) -> void:
	reset_blessing_state_containers()
	load_blessing_rarity_metadata(rarity_data)

	for raw_blessing_variant in blessings_data:
		if typeof(raw_blessing_variant) != TYPE_DICTIONARY:
			continue

		var blessing := BlessingStateScript.from_content(raw_blessing_variant)
		register_blessing_state(blessing)

func reset_blessing_state_containers() -> void:
	game_state.blessings.clear()
	game_state.blessing_ids_in_order.clear()
	game_state.blessing_ids_by_rarity.clear()
	game_state.blessing_rarity_roll_weights.clear()
	game_state.blessing_rarity_roll_displays.clear()
	game_state.blessing_rarity_colors.clear()
	invalidate_blessing_effect_cache()

	for rarity in game_state.BLESSING_RARITY_ORDER:
		game_state.blessing_ids_by_rarity[rarity] = []

func load_blessing_rarity_metadata(rarity_data: Array) -> void:
	for raw_rarity_variant in rarity_data:
		if typeof(raw_rarity_variant) != TYPE_DICTIONARY:
			continue
		var raw_rarity: Dictionary = raw_rarity_variant
		var rarity := str(raw_rarity.get("rarity", ""))
		if rarity.is_empty():
			continue
		game_state.blessing_rarity_roll_weights[rarity] = maxf(0.0, float(raw_rarity.get("roll_weight", 0.0)))
		game_state.blessing_rarity_roll_displays[rarity] = str(raw_rarity.get("display_chance", ""))
		game_state.blessing_rarity_colors[rarity] = str(raw_rarity.get("color", "ffffff"))

func register_blessing_state(blessing: BlessingState) -> void:
	if blessing == null or blessing.id.is_empty():
		return

	game_state.blessings[blessing.id] = blessing
	game_state.blessing_ids_in_order.append(blessing.id)
	if not game_state.blessing_ids_by_rarity.has(blessing.rarity):
		game_state.blessing_ids_by_rarity[blessing.rarity] = []
	game_state.blessing_ids_by_rarity[blessing.rarity].append(blessing.id)

func has_blessing(blessing_id: String) -> bool:
	return game_state.blessings.has(blessing_id)

func get_blessing_state(blessing_id: String):
	if not has_blessing(blessing_id):
		return null
	return game_state.blessings[blessing_id]

func get_blessing_ids() -> Array[String]:
	var blessing_ids: Array[String] = []
	for blessing_id in game_state.blessing_ids_in_order:
		blessing_ids.append(blessing_id)
	return blessing_ids

func get_blessing_ids_for_rarity(rarity: String) -> Array[String]:
	if not game_state.blessing_ids_by_rarity.has(rarity):
		return []
	var blessing_ids: Array[String] = []
	for blessing_id in game_state.blessing_ids_by_rarity[rarity]:
		blessing_ids.append(str(blessing_id))
	return blessing_ids

func get_blessing_rarity_order() -> Array[String]:
	var rarity_order: Array[String] = []
	for rarity in game_state.BLESSING_RARITY_ORDER:
		rarity_order.append(rarity)
	return rarity_order

func get_blessing_rarity_roll_display(rarity: String) -> String:
	return str(game_state.blessing_rarity_roll_displays.get(rarity, ""))

func get_blessing_rarity_color(rarity: String) -> Color:
	var color_hex := str(game_state.blessing_rarity_colors.get(rarity, "ffffff"))
	return Color.from_string("#%s" % color_hex, Color.WHITE)

func get_discovered_blessing_count() -> int:
	var discovered := 0
	for blessing_id in game_state.blessing_ids_in_order:
		var blessing = get_blessing_state(blessing_id)
		if blessing != null and blessing.level > 0:
			discovered += 1
	return discovered

func get_unopened_blessings_count() -> int:
	return maxi(0, game_state.unopened_blessings_count)

func can_open_blessings() -> bool:
	return get_unopened_blessings_count() > 0

func is_blessings_menu_unlocked() -> bool:
	return game_state.blessings_menu_unlocked

func get_blessing_critical_smasher_bonus_percent() -> float:
	return get_blessing_effect_total(BlessingStateScript.EFFECT_CRITICAL_SMASHER_CHANCE)

func get_blessing_fission_bonus_percent() -> float:
	return get_blessing_effect_total(BlessingStateScript.EFFECT_FISSION_CHANCE)

func get_foil_spawn_chance_percent() -> float:
	return get_blessing_effect_total(BlessingStateScript.EFFECT_FOIL_SPAWN_CHANCE)

func get_holographic_spawn_chance_percent() -> float:
	return get_blessing_effect_total(BlessingStateScript.EFFECT_HOLOGRAPHIC_SPAWN_CHANCE)

func get_polychrome_spawn_chance_percent() -> float:
	return get_blessing_effect_total(BlessingStateScript.EFFECT_POLYCHROME_SPAWN_CHANCE)

func open_earned_blessings() -> int:
	var blessings_to_open := get_unopened_blessings_count()
	if blessings_to_open <= 0:
		return 0

	for _i in range(blessings_to_open):
		award_random_blessing()
	game_state.unopened_blessings_count = 0
	invalidate_blessing_effect_cache()
	return blessings_to_open

func reset_blessings() -> bool:
	var changed := reset_blessing_levels_to_zero()
	game_state.unopened_blessings_count = game_state.blessings_count
	if changed:
		invalidate_blessing_effect_cache()
	return changed

func get_next_blessing_cost() -> DigitMaster:
	var blessing_index := float(maxi(0, game_state.blessings_count))
	var cost: float = (
		game_state.BLESSING_COST_QUADRATIC_A * blessing_index * blessing_index
		+ game_state.BLESSING_COST_QUADRATIC_B * blessing_index
		+ game_state.BLESSING_COST_QUADRATIC_C
	)
	return DigitMaster.new(cost)

func get_blessing_progress_mass() -> DigitMaster:
	return game_state.blessings_progress_mass.clone()

func get_remaining_blessing_mass() -> DigitMaster:
	return get_next_blessing_cost().subtract(game_state.blessings_progress_mass)

func apply_blessing_progress_for_generated_element(element: ElementState, amount: DigitMaster) -> void:
	if element == null or amount == null or amount.is_zero():
		return
	if element.index <= 0:
		return

	var generated_mass := amount.multiply_scalar(float(element.index))
	if generated_mass.is_zero():
		return

	game_state.blessings_progress_mass = game_state.blessings_progress_mass.add(generated_mass)
	while game_state.blessings_progress_mass.compare(get_next_blessing_cost()) >= 0:
		var next_cost := get_next_blessing_cost()
		game_state.blessings_progress_mass = game_state.blessings_progress_mass.subtract(next_cost)
		game_state.blessings_count += 1
		game_state.unopened_blessings_count += 1

func award_random_blessing() -> void:
	var blessing_id := roll_random_blessing_id()
	if blessing_id.is_empty():
		return
	var blessing = get_blessing_state(blessing_id)
	if blessing == null:
		return
	blessing.level += 1

func roll_random_blessing_id() -> String:
	var rarity := roll_blessing_rarity()
	if rarity.is_empty():
		return ""

	var rarity_ids := get_rollable_blessing_ids_for_rarity(rarity)
	if rarity_ids.is_empty():
		return ""

	var chosen_index: int = game_state._blessing_rng.randi_range(0, rarity_ids.size() - 1)
	return str(rarity_ids[chosen_index])

func roll_blessing_rarity() -> String:
	var total_weight := 0.0
	var rollable_rarities := get_rollable_rarities()
	for rarity in rollable_rarities:
		total_weight += float(game_state.blessing_rarity_roll_weights.get(rarity, 0.0))
	if total_weight <= 0.0:
		return ""

	var roll: float = game_state._blessing_rng.randf() * total_weight
	var cursor := 0.0
	for rarity in rollable_rarities:
		cursor += float(game_state.blessing_rarity_roll_weights.get(rarity, 0.0))
		if roll <= cursor:
			return rarity
	return "" if rollable_rarities.is_empty() else str(rollable_rarities.back())

func get_rollable_rarities() -> Array[String]:
	var rollable_rarities: Array[String] = []
	for rarity in game_state.BLESSING_RARITY_ORDER:
		if get_rollable_blessing_ids_for_rarity(rarity).is_empty():
			continue
		rollable_rarities.append(rarity)
	return rollable_rarities

func get_rollable_blessing_ids_for_rarity(rarity: String) -> Array[String]:
	var rollable_ids: Array[String] = []
	for blessing_id in get_blessing_ids_for_rarity(rarity):
		var blessing = get_blessing_state(blessing_id)
		if blessing == null or blessing.placeholder:
			continue
		rollable_ids.append(blessing_id)
	return rollable_ids

func get_blessing_effect_total(effect_type: String) -> float:
	if effect_type.is_empty():
		return 0.0

	ensure_blessing_effect_cache()
	return float(game_state._cached_blessing_effect_totals.get(effect_type, 0.0))

func invalidate_blessing_effect_cache() -> void:
	game_state._cached_blessing_effect_totals.clear()
	game_state._blessing_effect_cache_dirty = true

func apply_saved_blessing_levels(saved_blessings: Dictionary) -> void:
	for blessing_id_variant in saved_blessings.keys():
		var blessing_id := str(blessing_id_variant)
		var blessing = get_blessing_state(blessing_id)
		if blessing == null:
			continue
		var blessing_save: Dictionary = saved_blessings[blessing_id]
		blessing.apply_save_dict(blessing_save)

func reset_blessing_levels_to_zero() -> bool:
	var changed := get_unopened_blessings_count() > 0
	for blessing_id in game_state.blessing_ids_in_order:
		var blessing = get_blessing_state(blessing_id)
		if blessing == null:
			continue
		if blessing.level > 0:
			changed = true
		blessing.level = 0
	return changed

func ensure_blessing_effect_cache() -> void:
	if not game_state._blessing_effect_cache_dirty:
		return

	game_state._cached_blessing_effect_totals.clear()
	for blessing_id in game_state.blessing_ids_in_order:
		var blessing = get_blessing_state(blessing_id)
		if blessing == null or blessing.effect_type.is_empty():
			continue
		var current_total := float(game_state._cached_blessing_effect_totals.get(blessing.effect_type, 0.0))
		game_state._cached_blessing_effect_totals[blessing.effect_type] = current_total + blessing.get_effect_value()
	game_state._blessing_effect_cache_dirty = false
