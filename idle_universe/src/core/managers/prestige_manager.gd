extends RefCounted

class_name PrestigeManager

var _game_state_ref: WeakRef = null
var game_state:
	get:
		return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func get_first_milestone_id() -> String:
	return "" if game_state.PRESTIGE_MILESTONES.is_empty() else str(game_state.PRESTIGE_MILESTONES[0].get("id", ""))

func get_next_pending_milestone_id() -> String:
	for milestone in game_state.PRESTIGE_MILESTONES:
		var milestone_id := str(milestone.get("id", ""))
		if milestone_id.is_empty() or game_state.completed_milestones.has(milestone_id):
			continue
		return milestone_id
	return ""

func sync_legacy_prestige_count_from_nodes() -> void:
	game_state.prestige_count = maxi(0, game_state.get_visible_element_section_count() - 1)

func get_milestone_by_id(milestone_id: String) -> Dictionary:
	for milestone in game_state.PRESTIGE_MILESTONES:
		if str(milestone.get("id", "")) == milestone_id:
			return milestone.duplicate(true)
	return {}

func get_next_prestige_milestone() -> Dictionary:
	if game_state.next_milestone_id.is_empty():
		return {}
	return get_milestone_by_id(game_state.next_milestone_id)

func get_prestige_milestone_entries() -> Array[Dictionary]:
	var milestone_entries: Array[Dictionary] = []
	for milestone in game_state.PRESTIGE_MILESTONES:
		var entry: Dictionary = milestone.duplicate(true)
		var milestone_id := str(entry.get("id", ""))
		entry["completed"] = game_state.completed_milestones.has(milestone_id)
		entry["current"] = game_state.next_milestone_id == milestone_id
		entry["available"] = game_state.next_milestone_id == milestone_id and can_prestige()
		entry["progress_text"] = get_milestone_progress_text(entry)
		milestone_entries.append(entry)
	return milestone_entries

func get_next_prestige_node_definition() -> Dictionary:
	for node_definition in game_state.PRESTIGE_NODES:
		var node_id := str(node_definition.get("id", ""))
		if node_id.is_empty() or game_state.prestige_nodes_claimed.has(node_id):
			continue
		return node_definition.duplicate(true)
	return {}

func get_prestige_node_entries() -> Array[Dictionary]:
	var next_node := get_next_prestige_node_definition()
	var next_node_id := str(next_node.get("id", ""))
	var node_entries: Array[Dictionary] = []
	for node_definition in game_state.PRESTIGE_NODES:
		var entry: Dictionary = node_definition.duplicate(true)
		var node_id := str(entry.get("id", ""))
		entry["claimed"] = game_state.prestige_nodes_claimed.has(node_id)
		entry["current"] = node_id == next_node_id and not entry["claimed"]
		entry["can_claim"] = node_id == next_node_id and can_claim_next_prestige_node()
		node_entries.append(entry)
	return node_entries

func get_prestige_dust_multiplier() -> float:
	var dust_multiplier := 1.0
	for node_definition in game_state.PRESTIGE_NODES:
		var node_id := str(node_definition.get("id", ""))
		if node_id.is_empty() or not game_state.prestige_nodes_claimed.has(node_id):
			continue
		if str(node_definition.get("effect_type", "")) != "dust_multiplier":
			continue
		dust_multiplier += float(node_definition.get("effect_value", 0.0))
	return dust_multiplier

func can_prestige() -> bool:
	var milestone := get_next_prestige_milestone()
	if milestone.is_empty():
		return false
	if bool(milestone.get("placeholder", false)):
		return false

	match str(milestone.get("kind", "")):
		"planet_level":
			var planet_id := str(milestone.get("planet_id", ""))
			var required_level := int(milestone.get("required_level", 0))
			return int(game_state.best_planet_levels_this_run.get(planet_id, 0)) >= required_level
		_:
			return false

func can_claim_next_prestige_node() -> bool:
	if game_state.prestige_points_unspent <= 0:
		return false
	var next_node := get_next_prestige_node_definition()
	if next_node.is_empty():
		return false
	return not bool(next_node.get("future_locked", false))

func get_prestige_preview() -> Dictionary:
	var milestone := get_next_prestige_milestone()
	var next_node := get_next_prestige_node_definition()
	return {
		"can_prestige": can_prestige(),
		"milestone": milestone,
		"reward_points": int(milestone.get("reward_points", 0)),
		"next_node": next_node,
		"can_claim_node": can_claim_next_prestige_node(),
		"reset_summary": [
			"Resets atomic resources, upgrades, dust, RP, and temporary planet progress.",
			"Keeps blessings, orbs, Planetary Era, prestige progress, and owned planets."
		]
	}

func perform_prestige() -> bool:
	if not can_prestige():
		return false

	var milestone := get_next_prestige_milestone()
	var milestone_id := str(milestone.get("id", ""))
	if milestone_id.is_empty():
		return false
	if not game_state.completed_milestones.has(milestone_id):
		game_state.completed_milestones.append(milestone_id)

	var reward_points := maxi(0, int(milestone.get("reward_points", 0)))
	game_state.prestige_points_total += reward_points
	game_state.prestige_points_unspent += reward_points

	var unlocked_planet_id := str(milestone.get("unlock_planet_id", ""))
	if not unlocked_planet_id.is_empty():
		game_state.planet_purchase_unlocks[unlocked_planet_id] = true

	game_state.next_milestone_id = get_next_pending_milestone_id()
	game_state._reset_run_state()
	game_state.refresh_progression_state()
	return true

func claim_next_prestige_node() -> bool:
	if not can_claim_next_prestige_node():
		return false

	var next_node := get_next_prestige_node_definition()
	var node_id := str(next_node.get("id", ""))
	if node_id.is_empty():
		return false

	game_state.prestige_nodes_claimed.append(node_id)
	game_state.prestige_points_unspent = maxi(0, game_state.prestige_points_unspent - 1)
	game_state.refresh_progression_state()
	return true

func get_milestone_progress_text(milestone: Dictionary) -> String:
	if milestone.is_empty():
		return ""
	if bool(milestone.get("completed", false)):
		return "Completed"
	if bool(milestone.get("placeholder", false)):
		return "Future content"

	match str(milestone.get("kind", "")):
		"planet_level":
			var planet_id := str(milestone.get("planet_id", ""))
			var planet_name := str(milestone.get("planet_name", planet_id))
			var required_level := int(milestone.get("required_level", 0))
			var current_level := int(game_state.best_planet_levels_this_run.get(planet_id, 0))
			return "%s %d / %d" % [planet_name, current_level, required_level]
		_:
			return "Unavailable"
