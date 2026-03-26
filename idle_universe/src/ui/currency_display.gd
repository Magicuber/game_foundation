extends Label

class_name CurrencyDisplay

var game_state: GameState
var resource_id := ""

func configure(new_game_state: GameState, new_resource_id: String) -> void:
	game_state = new_game_state
	resource_id = new_resource_id
	horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	refresh()

func refresh() -> void:
	if game_state == null or resource_id.is_empty():
		text = ""
		return

	if resource_id.to_lower() == GameState.DUST_RESOURCE_ID:
		text = "Dust: %s" % game_state.dust.big_to_short_string()
		return

	if not game_state.has_element(resource_id):
		text = resource_id
		return

	var element := game_state.get_element(resource_id)
	text = "%s: %s" % [
		str(element.get("name", resource_id)),
		game_state.get_resource_amount(resource_id).big_to_short_string()
	]
