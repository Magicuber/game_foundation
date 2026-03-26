extends RefCounted

class_name ElementSystem

func manual_smash(game_state: GameState) -> Dictionary:
	return _produce_from_element(game_state, game_state.current_element_id, false)

func resolve_auto_smash(game_state: GameState, element_id: String) -> Dictionary:
	return _produce_from_element(game_state, element_id, true)

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

func _produce_from_element(game_state: GameState, element_id: String, is_auto: bool) -> Dictionary:
	if game_state == null or element_id.is_empty():
		return {}

	var source_element := game_state.get_element(element_id)
	if source_element.is_empty():
		return {}

	var produced_resource := str(source_element.get("produces", ""))
	if produced_resource.is_empty():
		return {}

	game_state.produce_resource(produced_resource, DigitMaster.one())
	if is_auto:
		game_state.total_auto_smashes += 1
	else:
		game_state.total_manual_smashes += 1

	return {
		"source_element_id": element_id,
		"produced_resource_id": produced_resource
	}
