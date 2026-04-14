extends RefCounted

class_name PlanetManager

var _game_state_ref: WeakRef = null
var game_state:
	get:
		return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func load_planets(planets_data: Array) -> void:
	game_state.planets.clear()
	game_state.planet_ids_in_order.clear()

	for raw_planet_variant in planets_data:
		if typeof(raw_planet_variant) != TYPE_DICTIONARY:
			continue

		var raw_planet: Dictionary = raw_planet_variant
		var level := maxi(1, int(raw_planet.get("level", 1)))
		var planet := PlanetState.from_content(raw_planet, calculate_planet_xp_requirement(level))
		if planet.id.is_empty():
			continue

		game_state.planets[planet.id] = planet
		game_state.planet_ids_in_order.append(planet.id)

	ensure_planet_meta_defaults()
	if game_state.current_planet_id.is_empty() and not game_state.planet_ids_in_order.is_empty():
		game_state.current_planet_id = game_state.planet_ids_in_order[0]

func load_planet_menu_config(planet_menu_content: Dictionary) -> void:
	game_state._planet_menu_root = {}
	game_state._planet_menu_stages.clear()
	game_state._planet_menu_stage_by_index.clear()
	game_state._planet_menu_planets.clear()
	game_state._planet_menu_moons.clear()

	if typeof(planet_menu_content.get("root", {})) == TYPE_DICTIONARY:
		game_state._planet_menu_root = planet_menu_content.get("root", {}).duplicate(true)

	for stage_variant in planet_menu_content.get("stages", []):
		if typeof(stage_variant) != TYPE_DICTIONARY:
			continue
		var stage_entry: Dictionary = stage_variant.duplicate(true)
		var stage_index := int(stage_entry.get("stage_index", game_state._planet_menu_stages.size() + 1))
		stage_entry["stage_index"] = stage_index
		game_state._planet_menu_stages.append(stage_entry)
		game_state._planet_menu_stage_by_index[stage_index] = stage_entry

	var raw_planets: Dictionary = planet_menu_content.get("planets", {})
	for planet_id_variant in raw_planets.keys():
		var planet_id := str(planet_id_variant)
		if typeof(raw_planets[planet_id_variant]) != TYPE_DICTIONARY:
			continue
		var planet_entry: Dictionary = raw_planets[planet_id_variant].duplicate(true)
		planet_entry["id"] = planet_id
		game_state._planet_menu_planets[planet_id] = planet_entry

	var raw_moons: Dictionary = planet_menu_content.get("moons", {})
	for moon_id_variant in raw_moons.keys():
		var moon_id := str(moon_id_variant)
		if typeof(raw_moons[moon_id_variant]) != TYPE_DICTIONARY:
			continue
		var moon_entry: Dictionary = raw_moons[moon_id_variant].duplicate(true)
		moon_entry["id"] = moon_id
		game_state._planet_menu_moons[moon_id] = moon_entry

func ensure_planet_meta_defaults() -> void:
	for planet_id in game_state.planet_ids_in_order:
		if not game_state.planet_purchase_unlocks.has(planet_id):
			game_state.planet_purchase_unlocks[planet_id] = false
		if not game_state.planet_owned_flags.has(planet_id):
			game_state.planet_owned_flags[planet_id] = false
		if not game_state.sacrificed_planet_flags.has(planet_id):
			game_state.sacrificed_planet_flags[planet_id] = false

	if game_state.has_unlocked_era(1):
		game_state.planet_purchase_unlocks[game_state.DEFAULT_PLANET_ID] = true

func apply_planet_unlock_states() -> void:
	for planet_id in game_state.planet_ids_in_order:
		var planet: PlanetState = get_planet_state(planet_id)
		if planet == null:
			continue
		planet.unlocked = bool(game_state.planet_owned_flags.get(planet_id, false))
		if planet.unlocked:
			planet.level = maxi(1, planet.level)
			planet.xp_to_next_level = calculate_planet_xp_requirement(planet.level)

func update_best_planet_level(planet_id: String, level: int) -> void:
	if planet_id.is_empty():
		return
	var best_level := maxi(level, int(game_state.best_planet_levels_this_run.get(planet_id, 0)))
	game_state.best_planet_levels_this_run[planet_id] = best_level

func has_planet(planet_id: String) -> bool:
	return game_state.planets.has(planet_id)

func get_planet_state(planet_id: String) -> PlanetState:
	if not has_planet(planet_id):
		return null
	return game_state.planets[planet_id]

func get_planet_ids() -> Array[String]:
	return game_state.planet_ids_in_order.duplicate()

func get_current_planet_state() -> PlanetState:
	return get_planet_state(game_state.current_planet_id)

func is_planet_unlocked(planet_id: String) -> bool:
	var planet := get_planet_state(planet_id)
	return planet != null and planet.unlocked

func is_planet_owned(planet_id: String) -> bool:
	return bool(game_state.planet_owned_flags.get(planet_id, false))

func is_planet_sacrificed(planet_id: String) -> bool:
	return bool(game_state.sacrificed_planet_flags.get(planet_id, false))

func is_planet_purchase_unlocked(planet_id: String) -> bool:
	return bool(game_state.planet_purchase_unlocks.get(planet_id, false))

func can_oblate_planet(planet_id: String) -> bool:
	return is_planet_owned(planet_id)

func get_planet_display_state(planet_id: String) -> String:
	if is_planet_owned(planet_id):
		return "owned"
	if is_planet_sacrificed(planet_id):
		return "sacrificed"
	if is_planet_purchase_unlocked(planet_id):
		return "purchasable"
	return "locked"

func get_planet_purchase_cost_entries(planet_id: String) -> Array[Dictionary]:
	var planet := get_planet_state(planet_id)
	if planet == null:
		return []

	var cost_entries: Array[Dictionary] = []
	if not planet.purchase_cost_dust.is_zero():
		cost_entries.append({
			"resource_id": game_state.DUST_RESOURCE_ID,
			"resource_name": "Dust",
			"is_orb_requirement": false,
			"required_amount": planet.purchase_cost_dust.clone()
		})
	if planet.purchase_cost_orbs > 0:
		cost_entries.append({
			"resource_id": "orbs",
			"resource_name": "Orbs",
			"is_orb_requirement": true,
			"required_amount": planet.purchase_cost_orbs
		})
	return cost_entries

func can_purchase_planet(planet_id: String) -> bool:
	var planet := get_planet_state(planet_id)
	if planet == null:
		return false
	if is_planet_owned(planet_id):
		return false
	if not is_planet_purchase_unlocked(planet_id):
		return false
	return game_state.can_afford_cost_entries(get_planet_purchase_cost_entries(planet_id))

func purchase_planet(planet_id: String) -> bool:
	if not can_purchase_planet(planet_id):
		return false
	if not game_state.spend_cost_entries_atomic(get_planet_purchase_cost_entries(planet_id)):
		return false

	game_state.planet_owned_flags[planet_id] = true
	game_state.sacrificed_planet_flags[planet_id] = false
	game_state.refresh_progression_state()
	return true

func select_planet(planet_id: String) -> bool:
	if not is_planet_owned(planet_id):
		return false
	game_state.current_planet_id = planet_id
	return true

func get_planet_entries() -> Array[Dictionary]:
	var planet_entries: Array[Dictionary] = []
	for planet_id in game_state.planet_ids_in_order:
		var planet := get_planet_state(planet_id)
		if planet == null:
			continue
		planet_entries.append({
			"id": planet.id,
			"name": planet.name,
			"owned": is_planet_owned(planet_id),
			"sacrificed": is_planet_sacrificed(planet_id),
			"unlocked": is_planet_unlocked(planet_id),
			"purchase_unlocked": is_planet_purchase_unlocked(planet_id),
			"can_purchase": can_purchase_planet(planet_id),
			"selected": game_state.current_planet_id == planet_id,
			"display_state": get_planet_display_state(planet_id),
			"level": planet.level,
			"purchase_costs": get_planet_purchase_cost_entries(planet_id)
		})
	return planet_entries

func get_planet_menu_stage() -> int:
	var highest_completed_planet_rank := 0
	for milestone_id in game_state.completed_milestones:
		highest_completed_planet_rank = maxi(highest_completed_planet_rank, get_planet_menu_progress_rank(milestone_id))
	var stage_index := clampi(highest_completed_planet_rank + 1, 1, maxi(1, game_state._planet_menu_stages.size()))
	return stage_index

func get_planet_menu_view_model() -> Dictionary:
	var stage_index := get_planet_menu_stage()
	var stage_entry := get_planet_menu_stage_entry(stage_index)
	var node_positions: Dictionary = stage_entry.get("node_positions", {})
	var visible_planets: Array[String] = []
	for planet_id_variant in stage_entry.get("visible_planets", []):
		visible_planets.append(str(planet_id_variant))
	var visible_moons: Array[String] = []
	for moon_id_variant in stage_entry.get("visible_moons", []):
		visible_moons.append(str(moon_id_variant))

	var planet_entries: Array[Dictionary] = []
	for planet_id in visible_planets:
		var planet_entry := get_planet_menu_planet_entry(planet_id)
		if node_positions.has(planet_id):
			planet_entry["position"] = (node_positions[planet_id] as Dictionary).duplicate(true)
		planet_entries.append(planet_entry)

	var moon_entries: Array[Dictionary] = []
	for moon_id in visible_moons:
		var moon_entry := get_planet_menu_moon_entry(moon_id)
		if node_positions.has(moon_id):
			moon_entry["position"] = (node_positions[moon_id] as Dictionary).duplicate(true)
		moon_entries.append(moon_entry)

	var line_entries: Array[Dictionary] = []
	for line_variant in stage_entry.get("lines", []):
		if typeof(line_variant) != TYPE_DICTIONARY:
			continue
		var line_entry: Dictionary = line_variant.duplicate(true)
		var from_id := str(line_entry.get("from_id", ""))
		var to_id := str(line_entry.get("to_id", ""))
		if node_positions.has(from_id):
			line_entry["from_position"] = (node_positions[from_id] as Dictionary).duplicate(true)
		if node_positions.has(to_id):
			line_entry["to_position"] = (node_positions[to_id] as Dictionary).duplicate(true)
		line_entries.append(line_entry)

	return {
		"stage_id": str(stage_entry.get("id", "")),
		"stage_index": stage_index,
		"root": game_state._planet_menu_root.duplicate(true),
		"root_position": (node_positions.get("root", {}) as Dictionary).duplicate(true),
		"planets": planet_entries,
		"moons": moon_entries,
		"lines": line_entries
	}

func get_planet_menu_planet_entry(planet_id: String) -> Dictionary:
	var config_entry: Dictionary = game_state._planet_menu_planets.get(planet_id, {})
	var runtime_planet := get_planet_state(planet_id)
	var owned := is_planet_owned(planet_id) if runtime_planet != null else false
	var sacrificed := is_planet_sacrificed(planet_id) if runtime_planet != null else false
	var visible := is_planet_visible_in_stage(planet_id, get_planet_menu_stage())
	var purchase_unlocked := is_planet_purchase_unlocked(planet_id) if runtime_planet != null else false
	var can_purchase := can_purchase_planet(planet_id) if runtime_planet != null else false
	var is_placeholder := runtime_planet == null
	return {
		"id": planet_id,
		"label": str(config_entry.get("label", planet_id)),
		"tier": int(config_entry.get("tier", 1)),
		"panel_accent_color": str(config_entry.get("panel_accent_color", "#4A7F78")),
		"preview_title": str(config_entry.get("preview_title", config_entry.get("label", planet_id))),
		"preview_subtitle": str(config_entry.get("preview_subtitle", "")),
		"moon_ids": Array(config_entry.get("moon_ids", [])).duplicate(),
		"visible": visible,
		"owned": owned,
		"sacrificed": sacrificed,
		"purchase_unlocked": purchase_unlocked,
		"can_purchase": can_purchase,
		"is_placeholder": is_placeholder,
		"is_current_active_planet": game_state.current_planet_id == planet_id,
		"display_state": get_planet_display_state(planet_id) if runtime_planet != null else "locked",
		"level": runtime_planet.level if runtime_planet != null else 0,
		"max_level": runtime_planet.max_level if runtime_planet != null else 0,
		"workers": runtime_planet.workers.clone() if runtime_planet != null else DigitMaster.zero(),
		"research_points": game_state.get_research_points(),
		"purchase_costs": get_planet_purchase_cost_entries(planet_id) if runtime_planet != null else [],
		"action_label": get_planet_menu_action_label(planet_id),
		"action_enabled": can_purchase
	}

func get_planet_menu_moon_entry(moon_id: String) -> Dictionary:
	var config_entry: Dictionary = game_state._planet_menu_moons.get(moon_id, {})
	var parent_planet_id := str(config_entry.get("parent_planet_id", ""))
	return {
		"id": moon_id,
		"label": str(config_entry.get("label", moon_id)),
		"color": str(config_entry.get("color", "#4A7F78")),
		"parent_planet_id": parent_planet_id,
		"parent_owned": is_planet_owned(parent_planet_id),
		"parent_sacrificed": is_planet_sacrificed(parent_planet_id),
		"visible": is_moon_visible_in_stage(moon_id, get_planet_menu_stage())
	}

func get_moon_upgrade_entries(moon_id: String) -> Array[Dictionary]:
	var moon_entry: Dictionary = game_state._planet_menu_moons.get(moon_id, {})
	if moon_entry.is_empty():
		return []

	var parent_planet_id := str(moon_entry.get("parent_planet_id", ""))
	var parent_owned := is_planet_owned(parent_planet_id)
	var purchased_ids := get_purchased_moon_upgrade_ids(moon_id)
	var upgrade_entries: Array[Dictionary] = []
	for upgrade_variant in moon_entry.get("upgrades", []):
		if typeof(upgrade_variant) != TYPE_DICTIONARY:
			continue
		var upgrade_entry: Dictionary = upgrade_variant.duplicate(true)
		var upgrade_id := str(upgrade_entry.get("id", ""))
		var rp_cost := DigitMaster.from_variant(upgrade_entry.get("rp_cost", 0))
		var purchased := purchased_ids.has(upgrade_id)
		var can_purchase: bool = parent_owned and not purchased and game_state.research_points.compare(rp_cost) >= 0
		upgrade_entry["rp_cost"] = rp_cost
		upgrade_entry["moon_id"] = moon_id
		upgrade_entry["parent_planet_id"] = parent_planet_id
		upgrade_entry["locked"] = not parent_owned
		upgrade_entry["purchased"] = purchased
		upgrade_entry["can_purchase"] = can_purchase
		upgrade_entries.append(upgrade_entry)
	return upgrade_entries

func can_purchase_moon_upgrade(moon_id: String, upgrade_id: String) -> bool:
	if upgrade_id.is_empty():
		return false
	for upgrade_entry in get_moon_upgrade_entries(moon_id):
		if str(upgrade_entry.get("id", "")) != upgrade_id:
			continue
		return bool(upgrade_entry.get("can_purchase", false))
	return false

func purchase_moon_upgrade(moon_id: String, upgrade_id: String) -> bool:
	if not can_purchase_moon_upgrade(moon_id, upgrade_id):
		return false

	for upgrade_entry in get_moon_upgrade_entries(moon_id):
		if str(upgrade_entry.get("id", "")) != upgrade_id:
			continue
		var cost: DigitMaster = upgrade_entry["rp_cost"]
		game_state.research_points = game_state.research_points.subtract(cost)
		var purchased_ids := get_purchased_moon_upgrade_ids(moon_id)
		purchased_ids.append(upgrade_id)
		game_state.moon_upgrade_purchases[moon_id] = purchased_ids
		return true
	return false

func has_adjacent_owned_planet(direction: int) -> bool:
	return not find_adjacent_owned_planet_id(direction).is_empty()

func select_adjacent_owned_planet(direction: int) -> bool:
	var target_planet_id := find_adjacent_owned_planet_id(direction)
	if target_planet_id.is_empty():
		return false
	game_state.current_planet_id = target_planet_id
	return true

func get_planet_menu_action_label(planet_id: String) -> String:
	if is_planet_owned(planet_id):
		return "Unlocked"
	if is_planet_sacrificed(planet_id):
		return "Restore" if can_purchase_planet(planet_id) else "Sacrificed"
	if can_purchase_planet(planet_id):
		return "Unlock"
	return "Locked"

func get_planet_menu_stage_entry(stage_index: int) -> Dictionary:
	if game_state._planet_menu_stage_by_index.has(stage_index):
		return (game_state._planet_menu_stage_by_index[stage_index] as Dictionary).duplicate(true)
	return {}

func is_planet_visible_in_stage(planet_id: String, stage_index: int) -> bool:
	var stage_entry := get_planet_menu_stage_entry(stage_index)
	for stage_planet_id_variant in stage_entry.get("visible_planets", []):
		if str(stage_planet_id_variant) == planet_id:
			return true
	return false

func is_moon_visible_in_stage(moon_id: String, stage_index: int) -> bool:
	var stage_entry := get_planet_menu_stage_entry(stage_index)
	for stage_moon_id_variant in stage_entry.get("visible_moons", []):
		if str(stage_moon_id_variant) == moon_id:
			return true
	return false

func get_planet_menu_progress_rank(milestone_id: String) -> int:
	match milestone_id:
		"planet_a_5":
			return 1
		"planet_b_5":
			return 2
		"planet_c_5":
			return 3
		"planet_d_5":
			return 4
		_:
			return 0

func get_purchased_moon_upgrade_ids(moon_id: String) -> Array[String]:
	var purchased_ids: Array[String] = []
	for upgrade_id_variant in game_state.moon_upgrade_purchases.get(moon_id, []):
		purchased_ids.append(str(upgrade_id_variant))
	return purchased_ids

func find_adjacent_owned_planet_id(direction: int) -> String:
	if direction == 0:
		return ""

	var owned_planet_ids: Array[String] = []
	for planet_id in game_state.planet_ids_in_order:
		if is_planet_owned(planet_id):
			owned_planet_ids.append(planet_id)
	if owned_planet_ids.is_empty():
		return ""

	var current_index := owned_planet_ids.find(game_state.current_planet_id)
	if current_index < 0:
		return owned_planet_ids[0] if direction > 0 else owned_planet_ids[owned_planet_ids.size() - 1]

	var target_index := current_index + direction
	if target_index < 0 or target_index >= owned_planet_ids.size():
		return ""
	return owned_planet_ids[target_index]

func get_fallback_world_planet_id() -> String:
	var adjacent_owned := find_adjacent_owned_planet_id(-1)
	if adjacent_owned.is_empty():
		adjacent_owned = find_adjacent_owned_planet_id(1)
	if not adjacent_owned.is_empty():
		return adjacent_owned
	if is_planet_sacrificed(game_state.current_planet_id):
		return game_state.current_planet_id
	for planet_id in game_state.planet_ids_in_order:
		if is_planet_sacrificed(planet_id):
			return planet_id
	for planet_id in game_state.planet_ids_in_order:
		if is_planet_purchase_unlocked(planet_id):
			return planet_id
	return ""

func get_current_planet_workers() -> DigitMaster:
	var planet := get_current_planet_state()
	if planet == null:
		return DigitMaster.zero()
	return planet.workers.clone()

func get_current_planet_worker_cost() -> DigitMaster:
	var planet := get_current_planet_state()
	if planet == null:
		return DigitMaster.zero()
	return calculate_planet_worker_cost(planet)

func can_buy_current_planet_worker() -> bool:
	var planet := get_current_planet_state()
	if planet == null or not is_planet_owned(planet.id):
		return false
	return game_state.can_afford_resource(game_state.DUST_RESOURCE_ID, calculate_planet_worker_cost(planet))

func buy_current_planet_worker() -> bool:
	var planet := get_current_planet_state()
	if planet == null or not is_planet_owned(planet.id):
		return false

	var worker_cost := calculate_planet_worker_cost(planet)
	if not game_state.can_afford_resource(game_state.DUST_RESOURCE_ID, worker_cost):
		return false
	if not game_state.spend_resource(game_state.DUST_RESOURCE_ID, worker_cost):
		return false

	planet.workers = planet.workers.add(DigitMaster.one())
	return true

func set_current_planet_worker_allocation_to_xp(allocation_ratio: float) -> void:
	var planet := get_current_planet_state()
	if planet == null:
		return
	planet.worker_allocation_to_xp = clampf(allocation_ratio, 0.0, 1.0)

func get_current_planet_worker_allocation_to_xp() -> float:
	var planet := get_current_planet_state()
	if planet == null:
		return 1.0
	return clampf(planet.worker_allocation_to_xp, 0.0, 1.0)

func process_planet_production(delta_seconds: float) -> Dictionary:
	var production_changes := {
		"current_planet_changed": false,
		"any_planet_changed": false,
		"research_changed": false,
		"milestones_changed": false
	}
	if delta_seconds <= 0.0:
		return production_changes
	var completed_milestones_before: int = game_state.completed_milestones.size()

	for planet_id in game_state.planet_ids_in_order:
		var planet: PlanetState = get_planet_state(planet_id)
		if planet == null or not is_planet_owned(planet_id) or planet.workers.is_zero():
			continue

		var allocation_to_xp := clampf(planet.worker_allocation_to_xp, 0.0, 1.0)
		if allocation_to_xp > 0.0:
			var previous_level := planet.level
			var previous_xp: DigitMaster = planet.xp
			apply_planet_xp(
				planet,
				planet.workers.multiply_scalar(delta_seconds * allocation_to_xp * game_state.get_planet_xp_gain_multiplier())
			)
			var planet_changed := planet.level != previous_level or planet.xp.compare(previous_xp) != 0
			if planet_changed:
				production_changes["any_planet_changed"] = true
				if planet_id == game_state.current_planet_id:
					production_changes["current_planet_changed"] = true
		if allocation_to_xp < 1.0:
			var previous_research_points: DigitMaster = game_state.research_points
			var previous_research_progress: float = game_state.research_progress
			game_state._apply_research_progress(planet.workers.multiply_scalar(delta_seconds * (1.0 - allocation_to_xp) * game_state.RESEARCH_POINTS_PER_PRODUCTION))
			if game_state.research_points.compare(previous_research_points) != 0 or game_state.research_progress != previous_research_progress:
				production_changes["research_changed"] = true
	production_changes["milestones_changed"] = game_state.completed_milestones.size() != completed_milestones_before

	return production_changes

func get_current_planet_level_progress_ratio() -> float:
	var planet := get_current_planet_state()
	if planet == null:
		return 0.0
	return game_state._get_digit_ratio(planet.xp, planet.xp_to_next_level)

func get_current_planet_xp() -> DigitMaster:
	var planet := get_current_planet_state()
	if planet == null:
		return DigitMaster.zero()
	return planet.xp.clone()

func get_current_planet_xp_to_next_level() -> DigitMaster:
	var planet := get_current_planet_state()
	if planet == null:
		return DigitMaster.one()
	return planet.xp_to_next_level.clone()

func calculate_planet_xp_requirement(level: int) -> DigitMaster:
	if level <= 1:
		return DigitMaster.new(game_state.PLANET_XP_LEVEL_TWO_REQUIREMENT)

	var growth_steps := float(maxi(1, game_state.PLANET_A_MAX_LEVEL - 2))
	var growth_ratio := pow(
		game_state.PLANET_XP_LEVEL_TWENTY_FIVE_REQUIREMENT / game_state.PLANET_XP_LEVEL_TWO_REQUIREMENT,
		1.0 / growth_steps
	)
	var requirement_float: float = game_state.PLANET_XP_LEVEL_TWO_REQUIREMENT * pow(growth_ratio, float(level - 1))
	return DigitMaster.new(round(requirement_float))

func apply_planet_xp(planet: PlanetState, xp_amount: DigitMaster) -> void:
	if xp_amount.is_zero():
		return

	var level := planet.level
	update_best_planet_level(planet.id, level)
	if level >= planet.max_level:
		return

	var current_xp := planet.xp.add(xp_amount)
	var xp_to_next := planet.xp_to_next_level
	while level < planet.max_level and current_xp.compare(xp_to_next) >= 0:
		if xp_to_next.is_zero():
			push_warning("Planet XP requirement reached zero for %s at level %d; stopping XP application." % [planet.id, level])
			break

		current_xp = current_xp.subtract(xp_to_next)
		level += 1
		planet.level = level
		if level >= planet.max_level:
			current_xp = DigitMaster.zero()
			break
		xp_to_next = calculate_planet_xp_requirement(level)
		if xp_to_next.is_zero():
			push_warning("Calculated planet XP requirement reached zero for %s at level %d; stopping XP application." % [planet.id, level])
			break

	planet.xp = current_xp
	planet.xp_to_next_level = DigitMaster.one() if level >= planet.max_level else xp_to_next
	update_best_planet_level(planet.id, planet.level)
	game_state.refresh_milestones()

func calculate_planet_worker_cost(planet: PlanetState) -> DigitMaster:
	if planet == null:
		return DigitMaster.zero()

	var worker_count: float = planet.workers.to_float()
	var raw_cost: float = game_state.PLANET_WORKER_BASE_COST * pow(game_state.PLANET_WORKER_COST_RATIO, worker_count)
	var rounded_cost: float = ceil(raw_cost / game_state.PLANET_WORKER_COST_ROUND_TO) * game_state.PLANET_WORKER_COST_ROUND_TO
	return DigitMaster.new(rounded_cost)
