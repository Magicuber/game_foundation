extends RefCounted

class_name MilestoneManager

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

func get_milestone_by_id(milestone_id: String) -> Dictionary:
	for milestone in game_state.PRESTIGE_MILESTONES:
		if str(milestone.get("id", "")) == milestone_id:
			return milestone.duplicate(true)
	return {}

func get_next_pending_milestone_id() -> String:
	for milestone in game_state.PRESTIGE_MILESTONES:
		var milestone_id := str(milestone.get("id", ""))
		if milestone_id.is_empty() or game_state.completed_milestones.has(milestone_id):
			continue
		return milestone_id
	return ""

func get_next_milestone() -> Dictionary:
	if game_state.next_milestone_id.is_empty():
		return {}
	return get_milestone_by_id(game_state.next_milestone_id)

func refresh_milestones() -> bool:
	var changed := false
	while true:
		if game_state.next_milestone_id.is_empty() or game_state.completed_milestones.has(game_state.next_milestone_id):
			game_state.next_milestone_id = get_next_pending_milestone_id()
		var milestone := get_next_milestone()
		if milestone.is_empty():
			break
		if bool(milestone.get("placeholder", false)):
			break
		if not _is_milestone_complete(milestone):
			break
		_complete_milestone(milestone)
		changed = true
	return changed

func get_milestone_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for milestone in game_state.PRESTIGE_MILESTONES:
		var entry: Dictionary = milestone.duplicate(true)
		var milestone_id := str(entry.get("id", ""))
		entry["completed"] = game_state.completed_milestones.has(milestone_id)
		entry["current"] = game_state.next_milestone_id == milestone_id
		entry["progress_text"] = get_milestone_progress_text(entry)
		entries.append(entry)
	return entries

func get_milestone_progress_text(milestone: Dictionary) -> String:
	if milestone.is_empty():
		return ""
	if bool(milestone.get("completed", false)):
		return "Completed"
	if bool(milestone.get("placeholder", false)):
		return "Future content"
	match str(milestone.get("kind", "")):
		"planet_level":
			var planet_id: String = str(milestone.get("planet_id", ""))
			var planet_name: String = str(milestone.get("planet_name", planet_id))
			var required_level: int = int(milestone.get("required_level", 0))
			var current_level: int = int(game_state.best_planet_levels_this_run.get(planet_id, 0))
			return "%s %d / %d" % [planet_name, current_level, required_level]
		_:
			return "Unavailable"

func get_completed_planet_rank() -> int:
	var highest_rank := 0
	for milestone_id in game_state.completed_milestones:
		highest_rank = maxi(highest_rank, game_state._get_planet_menu_progress_rank(milestone_id))
	return highest_rank

func is_oblation_menu_unlocked() -> bool:
	return game_state.completed_milestones.has("planet_a_5") or not game_state.oblation_claimed_recipe_ids.is_empty()

func _is_milestone_complete(milestone: Dictionary) -> bool:
	match str(milestone.get("kind", "")):
		"planet_level":
			var planet_id: String = str(milestone.get("planet_id", ""))
			var required_level: int = int(milestone.get("required_level", 0))
			return int(game_state.best_planet_levels_this_run.get(planet_id, 0)) >= required_level
		_:
			return false

func _complete_milestone(milestone: Dictionary) -> void:
	var milestone_id := str(milestone.get("id", ""))
	if milestone_id.is_empty():
		return
	if not game_state.completed_milestones.has(milestone_id):
		game_state.completed_milestones.append(milestone_id)
	var unlocked_planet_id := str(milestone.get("unlock_planet_id", ""))
	if not unlocked_planet_id.is_empty():
		game_state.planet_purchase_unlocks[unlocked_planet_id] = true
	game_state.next_milestone_id = get_next_pending_milestone_id()
