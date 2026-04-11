extends RefCounted

class_name GameStateSerializer

func to_save_dict(state) -> Dictionary:
	var serialized_elements := {}
	for element_id in state.element_ids_in_order:
		var element: ElementState = state.get_element_state(element_id)
		if element == null:
			continue
		serialized_elements[element_id] = element.to_save_dict()

	var serialized_upgrades := {}
	for upgrade_id in state.upgrade_ids_in_order:
		var upgrade: UpgradeState = state.get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue
		serialized_upgrades[upgrade_id] = upgrade.to_save_dict()

	var serialized_blessings := {}
	for blessing_id in state.blessing_ids_in_order:
		var blessing = state.get_blessing_state(blessing_id)
		if blessing == null:
			continue
		serialized_blessings[blessing_id] = blessing.to_save_dict()

	return {
		"save_version": state.SAVE_VERSION,
		"orbs": state.orbs,
		"dust": state.dust.to_save_data(),
		"elements": serialized_elements,
		"upgrades": serialized_upgrades,
		"current_element_id": state.current_element_id,
		"player_level": state.player_level,
		"prestige_count": state.prestige_count,
		"global_multiplier": state.global_multiplier.to_save_data(),
		"tick_count": state.tick_count,
		"total_played_seconds": state.total_played_seconds,
		"last_save_tick": state.last_save_tick,
		"total_manual_smashes": state.total_manual_smashes,
		"total_auto_smashes": state.total_auto_smashes,
		"blessings_count": state.blessings_count,
		"unopened_blessings_count": state.unopened_blessings_count,
		"blessings_progress_mass": state.blessings_progress_mass.to_save_data(),
		"blessings_menu_unlocked": state.blessings_menu_unlocked,
		"blessings": serialized_blessings,
		"unlocked_era_index": state.unlocked_era_index,
		"research_points": state.research_points.to_save_data(),
		"research_progress": state.research_progress,
		"current_planet_id": state.current_planet_id,
		"planets": _serialize_planets(state),
		"completed_milestones": state.completed_milestones.duplicate(),
		"next_milestone_id": state.next_milestone_id,
		"prestige_points_total": state.prestige_points_total,
		"prestige_points_unspent": state.prestige_points_unspent,
		"prestige_nodes_claimed": state.prestige_nodes_claimed.duplicate(),
		"best_planet_levels_this_run": state.best_planet_levels_this_run.duplicate(true),
		"planet_purchase_unlocks": state.planet_purchase_unlocks.duplicate(true),
		"planet_owned_flags": state.planet_owned_flags.duplicate(true),
		"moon_upgrade_purchases": state.moon_upgrade_purchases.duplicate(true)
	}

func apply_save_dict(state, save_data: Dictionary) -> void:
	state.orbs = int(save_data.get("orbs", 0))
	state.dust = DigitMaster.from_variant(save_data.get("dust", 0))
	state.player_level = int(save_data.get("player_level", 1))
	state.prestige_count = clampi(int(save_data.get("prestige_count", save_data.get("world_level", 0))), 0, state.get_max_prestige_count())
	state.global_multiplier = DigitMaster.from_variant(save_data.get("global_multiplier", 1))
	state.tick_count = int(save_data.get("tick_count", 0))
	state.total_played_seconds = float(save_data.get("total_played_seconds", 0.0))
	state.last_save_tick = int(save_data.get("last_save_tick", 0))
	state.total_manual_smashes = int(save_data.get("total_manual_smashes", 0))
	state.total_auto_smashes = int(save_data.get("total_auto_smashes", 0))
	state.blessings_count = maxi(0, int(save_data.get("blessings_count", 0)))
	state.unopened_blessings_count = maxi(0, int(save_data.get("unopened_blessings_count", 0)))
	state.blessings_progress_mass = DigitMaster.from_variant(save_data.get("blessings_progress_mass", 0))
	state.blessings_menu_unlocked = bool(save_data.get("blessings_menu_unlocked", false))
	state.unlocked_era_index = int(save_data.get("unlocked_era_index", state.unlocked_era_index))
	state.research_points = DigitMaster.from_variant(save_data.get("research_points", 0))
	state.research_progress = clampf(float(save_data.get("research_progress", 0.0)), 0.0, 1.0)
	state.completed_milestones.clear()
	for milestone_id_variant in save_data.get("completed_milestones", []):
		state.completed_milestones.append(str(milestone_id_variant))
	state.next_milestone_id = str(save_data.get("next_milestone_id", state.next_milestone_id))
	state.prestige_points_total = maxi(0, int(save_data.get("prestige_points_total", 0)))
	state.prestige_points_unspent = maxi(0, int(save_data.get("prestige_points_unspent", 0)))
	state.prestige_nodes_claimed.clear()
	for node_id_variant in save_data.get("prestige_nodes_claimed", []):
		state.prestige_nodes_claimed.append(str(node_id_variant))
	state.best_planet_levels_this_run.clear()
	var saved_best_levels: Dictionary = save_data.get("best_planet_levels_this_run", {})
	for planet_id_variant in saved_best_levels.keys():
		state.best_planet_levels_this_run[str(planet_id_variant)] = maxi(0, int(saved_best_levels[planet_id_variant]))
	state.planet_purchase_unlocks.clear()
	var saved_purchase_unlocks: Dictionary = save_data.get("planet_purchase_unlocks", {})
	for planet_id_variant in saved_purchase_unlocks.keys():
		state.planet_purchase_unlocks[str(planet_id_variant)] = bool(saved_purchase_unlocks[planet_id_variant])
	state.planet_owned_flags.clear()
	var saved_owned_flags: Dictionary = save_data.get("planet_owned_flags", {})
	for planet_id_variant in saved_owned_flags.keys():
		state.planet_owned_flags[str(planet_id_variant)] = bool(saved_owned_flags[planet_id_variant])
	state.moon_upgrade_purchases.clear()
	var saved_moon_upgrades: Dictionary = save_data.get("moon_upgrade_purchases", {})
	for moon_id_variant in saved_moon_upgrades.keys():
		var moon_id := str(moon_id_variant)
		var saved_upgrade_ids: Array[String] = []
		for upgrade_id_variant in saved_moon_upgrades[moon_id_variant]:
			saved_upgrade_ids.append(str(upgrade_id_variant))
		state.moon_upgrade_purchases[moon_id] = saved_upgrade_ids
	state._ensure_planet_meta_defaults()

	var saved_elements: Dictionary = save_data.get("elements", {})
	for element_id_variant in saved_elements.keys():
		var element_id := str(element_id_variant)
		var element: ElementState = state.get_element_state(element_id)
		if element == null:
			continue
		var element_save: Dictionary = saved_elements[element_id]
		element.apply_save_dict(element_save)

	var saved_upgrades: Dictionary = save_data.get("upgrades", {})
	for upgrade_id_variant in saved_upgrades.keys():
		var upgrade_id := str(upgrade_id_variant)
		var upgrade: UpgradeState = state.get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue
		var upgrade_save: Dictionary = saved_upgrades[upgrade_id]
		upgrade.apply_save_dict(upgrade_save)

	var saved_blessings: Dictionary = save_data.get("blessings", {})
	state._apply_saved_blessing_levels(saved_blessings)
	if not save_data.has("unopened_blessings_count") and state.blessings_count > 0:
		var opened_blessings: int = state.get_discovered_blessing_count()
		state.unopened_blessings_count = maxi(0, state.blessings_count - opened_blessings)
	if saved_blessings.is_empty() and state.blessings_count > 0 and state.unopened_blessings_count <= 0:
		state.unopened_blessings_count = state.blessings_count
	state._invalidate_blessing_effect_cache()

	state.current_element_id = str(save_data.get("current_element_id", state.current_element_id))
	var saved_planets: Dictionary = save_data.get("planets", {})
	for planet_id_variant in saved_planets.keys():
		var planet_id := str(planet_id_variant)
		var planet: PlanetState = state.get_planet_state(planet_id)
		if planet == null:
			continue
		var planet_save: Dictionary = saved_planets[planet_id]
		var saved_level := maxi(1, int(planet_save.get("level", planet.level)))
		planet.apply_save_dict(planet_save, state._calculate_planet_xp_requirement(saved_level))

	state.current_planet_id = str(save_data.get("current_planet_id", state.current_planet_id))
	if state.next_milestone_id.is_empty():
		state.next_milestone_id = state._get_next_pending_milestone_id()
	state.refresh_progression_state()

func _serialize_planets(state) -> Dictionary:
	var serialized_planets := {}
	for planet_id in state.planet_ids_in_order:
		var planet: PlanetState = state.get_planet_state(planet_id)
		if planet == null:
			continue
		serialized_planets[planet_id] = planet.to_save_dict()
	return serialized_planets
