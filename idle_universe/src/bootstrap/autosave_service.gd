extends RefCounted

class_name AutosaveService

const DEFAULT_AUTO_SAVE_INTERVAL_TICKS := 50

var auto_save_interval_ticks := DEFAULT_AUTO_SAVE_INTERVAL_TICKS

func _init(interval_ticks: int = DEFAULT_AUTO_SAVE_INTERVAL_TICKS) -> void:
	auto_save_interval_ticks = maxi(1, interval_ticks)

func autosave_if_needed(game_state: GameState) -> bool:
	if game_state == null:
		return false
	if game_state.tick_count - game_state.last_save_tick < auto_save_interval_ticks:
		return false
	return save_now(game_state)

func save_on_exit(game_state: GameState) -> bool:
	if game_state == null:
		return false
	return save_now(game_state)

func save_now(game_state: GameState) -> bool:
	if game_state == null:
		return false
	if SaveManager.save_state(game_state):
		game_state.last_save_tick = game_state.tick_count
		return true
	return false
