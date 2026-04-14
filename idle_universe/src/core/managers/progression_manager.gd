extends RefCounted

class_name ProgressionManager

var _game_state_ref: WeakRef = null
var game_state:
	get:
		return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func load_elements(elements_data: Array) -> void:
	game_state.elements.clear()
	game_state.element_ids_in_order.clear()
	game_state._element_ids_by_index.clear()

	for raw_element_variant in elements_data:
		if typeof(raw_element_variant) != TYPE_DICTIONARY:
			continue

		var raw_element: Dictionary = raw_element_variant
		var element := ElementState.from_content(raw_element, game_state.element_ids_in_order.size())
		if element.id.is_empty():
			continue

		game_state.elements[element.id] = element
		game_state.element_ids_in_order.append(element.id)
		game_state._element_ids_by_index[element.index] = element.id

func refresh_progression_state() -> void:
	game_state._ensure_planet_meta_defaults()
	if game_state.next_milestone_id.is_empty() or game_state.completed_milestones.has(game_state.next_milestone_id):
		game_state.next_milestone_id = game_state._get_next_pending_milestone_id()
	game_state._apply_planet_unlock_states()
	game_state._sync_legacy_prestige_count_from_nodes()

	var highest_unlocked_id := ""
	for element_id in game_state.element_ids_in_order:
		var element := get_element_state(element_id)
		if element != null and element.unlocked:
			highest_unlocked_id = element_id

	for planet_id in game_state.planet_ids_in_order:
		var planet: PlanetState = game_state.get_planet_state(planet_id)
		if planet == null or not planet.unlocked:
			continue
		game_state._update_best_planet_level(planet_id, planet.level)
	game_state.refresh_milestones()

	game_state.max_unlocked_element_id = highest_unlocked_id
	game_state.next_unlock_id = ""

	var found_highest := highest_unlocked_id.is_empty()
	for element_id in game_state.element_ids_in_order:
		if not found_highest:
			if element_id == highest_unlocked_id:
				found_highest = true
			continue

		var element := get_element_state(element_id)
		if element != null and not element.unlocked:
			game_state.next_unlock_id = element_id
			break

	if game_state.current_element_id.is_empty() or not is_element_unlocked(game_state.current_element_id):
		if not highest_unlocked_id.is_empty():
			game_state.current_element_id = highest_unlocked_id
		elif not game_state.element_ids_in_order.is_empty():
			game_state.current_element_id = game_state.element_ids_in_order[0]

	var current_planet_display_state: String = game_state.get_planet_display_state(game_state.current_planet_id)
	if game_state.current_planet_id.is_empty() or current_planet_display_state == "locked":
		game_state.current_planet_id = game_state.get_fallback_world_planet_id()
		if game_state.current_planet_id.is_empty() and not game_state.planet_ids_in_order.is_empty():
			game_state.current_planet_id = game_state.planet_ids_in_order[0]

	if is_element_unlocked(game_state.BLESSINGS_MENU_UNLOCK_ELEMENT_ID):
		game_state.blessings_menu_unlocked = true

func has_element(element_id: String) -> bool:
	return game_state.elements.has(element_id)

func get_element_state(element_id: String) -> ElementState:
	if not has_element(element_id):
		return null
	return game_state.elements[element_id]

func is_element_unlocked(element_id: String) -> bool:
	var element := get_element_state(element_id)
	return element != null and element.unlocked

func is_element_id(resource_id: String) -> bool:
	return game_state.elements.has(resource_id)

func get_element_state_by_index(index: int) -> ElementState:
	if not game_state._element_ids_by_index.has(index):
		return null
	return get_element_state(str(game_state._element_ids_by_index[index]))

func get_current_element_state() -> ElementState:
	return get_element_state(game_state.current_element_id)

func get_next_unlock_element_state() -> ElementState:
	if game_state.next_unlock_id.is_empty():
		return null
	return get_element_state(game_state.next_unlock_id)

func get_visible_element_section_count() -> int:
	return clampi(1 + int(game_state.get_oblation_effect_totals().get("unlock_section", 0)), 1, game_state.UNLOCK_SECTION_ENDS.size())

func get_max_unlockable_element_index() -> int:
	var section_index := clampi(get_visible_element_section_count() - 1, 0, game_state.UNLOCK_SECTION_ENDS.size() - 1)
	return int(game_state.UNLOCK_SECTION_ENDS[section_index])

func get_max_prestige_count() -> int:
	return maxi(0, game_state.UNLOCK_SECTION_ENDS.size() - 1)

func set_prestige_count(value: int) -> bool:
	var clamped_value := clampi(value, 0, get_max_prestige_count())
	if game_state.prestige_count == clamped_value:
		return false

	game_state.prestige_count = clamped_value
	return true

func adjust_prestige_count(delta: int) -> bool:
	if delta == 0:
		return false
	return set_prestige_count(game_state.prestige_count + delta)

func is_next_unlock_within_visible_sections() -> bool:
	var next_element := get_next_unlock_element_state()
	if next_element == null:
		return false
	return next_element.index <= get_max_unlockable_element_index()

func get_unlocked_element_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	for element_id in game_state.element_ids_in_order:
		if is_element_unlocked(element_id):
			unlocked_ids.append(element_id)
	return unlocked_ids

func get_unlocked_real_element_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	for element_id in game_state.element_ids_in_order:
		var element := get_element_state(element_id)
		if element == null or not element.unlocked or element.index <= 0:
			continue
		unlocked_ids.append(element_id)
	return unlocked_ids

func get_max_unlocked_real_element_index() -> int:
	var max_index := 0
	for element_id in game_state.element_ids_in_order:
		var element := get_element_state(element_id)
		if element == null or not element.unlocked or element.index <= 0:
			continue
		max_index = maxi(max_index, element.index)
	return max_index

func get_visible_counter_element_ids() -> Array[String]:
	var visible_ids: Array[String] = []
	for element_id in game_state.element_ids_in_order:
		var element := get_element_state(element_id)
		if element != null and element.show_in_counter:
			visible_ids.append(element_id)
	return visible_ids

func has_unlocked_element_count(required_count: int) -> bool:
	if required_count <= 0:
		return true
	return get_unlocked_element_ids().size() >= required_count

func is_era_menu_unlocked() -> bool:
	return is_element_unlocked(game_state.ERA_MENU_UNLOCK_ELEMENT_ID) or has_unlocked_era(1)

func get_unlocked_era_index() -> int:
	return clampi(game_state.unlocked_era_index, 0, game_state.ERA_NAMES.size() - 1)

func has_unlocked_era(era_index: int) -> bool:
	return get_unlocked_era_index() >= era_index

func get_era_name(era_index: int) -> String:
	if era_index < 0 or era_index >= game_state.ERA_NAMES.size():
		return ""
	return str(game_state.ERA_NAMES[era_index])

func get_next_implemented_era_index() -> int:
	if not is_era_menu_unlocked():
		return -1
	var next_era_index := get_unlocked_era_index() + 1
	if next_era_index > game_state.MAX_IMPLEMENTED_ERA_INDEX:
		return -1
	return next_era_index

func get_next_implemented_era_name() -> String:
	var next_era_index := get_next_implemented_era_index()
	if next_era_index < 0:
		return ""
	return get_era_name(next_era_index)

func get_next_era_requirements() -> Array[Dictionary]:
	var next_era_index := get_next_implemented_era_index()
	if next_era_index != 1:
		return []

	var requirements: Array[Dictionary] = []
	for resource_id in game_state.PLANETARY_ERA_RESOURCE_IDS:
		requirements.append({
			"resource_id": resource_id,
			"resource_name": game_state.get_resource_name(resource_id),
			"required_amount": DigitMaster.new(game_state.PLANETARY_ERA_RESOURCE_COST),
			"is_orb_requirement": false
		})

	requirements.append({
		"resource_id": game_state.DUST_RESOURCE_ID,
		"resource_name": "Dust",
		"required_amount": DigitMaster.new(game_state.PLANETARY_ERA_RESOURCE_COST),
		"is_orb_requirement": false
	})

	requirements.append({
		"resource_id": "orbs",
		"resource_name": "Orbs",
		"required_amount": game_state.PLANETARY_ERA_ORB_COST,
		"is_orb_requirement": true
	})

	return requirements

func can_unlock_next_era() -> bool:
	var requirements := get_next_era_requirements()
	if requirements.is_empty():
		return false
	return game_state.can_afford_cost_entries(requirements)

func unlock_next_era() -> bool:
	if not can_unlock_next_era():
		return false

	var next_era_index := get_next_implemented_era_index()
	if next_era_index < 0:
		return false

	if not game_state.spend_cost_entries_atomic(get_next_era_requirements()):
		return false

	game_state.unlocked_era_index = max(game_state.unlocked_era_index, next_era_index)
	if next_era_index == 1:
		game_state.planet_purchase_unlocks[game_state.DEFAULT_PLANET_ID] = true
		game_state.planet_owned_flags[game_state.DEFAULT_PLANET_ID] = true
		game_state.sacrificed_planet_flags[game_state.DEFAULT_PLANET_ID] = false
		var starting_planet: PlanetState = game_state.get_planet_state(game_state.DEFAULT_PLANET_ID)
		if starting_planet != null:
			starting_planet.unlocked = true
			starting_planet.level = maxi(1, starting_planet.level)
			starting_planet.xp_to_next_level = game_state._calculate_planet_xp_requirement(starting_planet.level)
	game_state.refresh_progression_state()
	return true

func select_element(element_id: String) -> bool:
	if not is_element_unlocked(element_id):
		return false
	game_state.current_element_id = element_id
	return true

func has_adjacent_unlocked_element(direction: int) -> bool:
	return not find_adjacent_unlocked_element_id(direction).is_empty()

func has_next_selectable_element_in_visible_sections() -> bool:
	if game_state.current_element_id.is_empty():
		return false

	var current_element := get_current_element_state()
	if current_element == null:
		return false

	var max_visible_index := get_max_unlockable_element_index()
	if current_element.index >= max_visible_index:
		return false

	return has_adjacent_unlocked_element(1)

func select_adjacent_unlocked(direction: int) -> bool:
	var target_id := find_adjacent_unlocked_element_id(direction)
	if target_id.is_empty():
		return false
	game_state.current_element_id = target_id
	return true

func find_adjacent_unlocked_element_id(direction: int) -> String:
	if game_state.current_element_id.is_empty() or direction == 0:
		return ""

	var current_element := get_current_element_state()
	if current_element == null:
		return ""

	var cursor := current_element.index + direction
	while true:
		var candidate := get_element_state_by_index(cursor)
		if candidate == null:
			return ""
		if candidate.unlocked:
			return candidate.id
		cursor += direction

	return ""

func can_unlock_next() -> bool:
	var next_element := get_next_unlock_element_state()
	if next_element == null:
		return false
	if not is_next_unlock_within_visible_sections():
		return false
	return game_state.can_afford_resource(game_state.next_unlock_id, next_element.cost)

func unlock_next_element() -> bool:
	var next_element := get_next_unlock_element_state()
	if next_element == null or not can_unlock_next():
		return false
	if not game_state.spend_resource(game_state.next_unlock_id, next_element.cost):
		return false

	next_element.unlocked = true
	game_state.current_element_id = game_state.next_unlock_id
	game_state.refresh_progression_state()
	return true

func reset_elements_to_defaults() -> void:
	for element_id in game_state.element_ids_in_order:
		var element := get_element_state(element_id)
		if element == null:
			continue
		element.reset_to_default()

func clamp_current_element_to_visible_sections() -> void:
	var current_element := get_current_element_state()
	if current_element != null and current_element.index <= get_max_unlockable_element_index():
		return

	var max_visible_index := get_max_unlockable_element_index()
	var fallback_element_id := ""
	for element_id in game_state.element_ids_in_order:
		var element := get_element_state(element_id)
		if element == null or not element.unlocked or element.index > max_visible_index:
			continue
		fallback_element_id = element.id

	if not fallback_element_id.is_empty():
		game_state.current_element_id = fallback_element_id
