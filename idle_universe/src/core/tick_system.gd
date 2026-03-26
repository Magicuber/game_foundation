extends Node

class_name TickSystem

signal tick_processed(tick_count: int)
signal manual_smash_resolved(result: Dictionary)
signal auto_smash_requested(request: Dictionary)

const DEFAULT_TICKS_PER_SECOND := 10.0

var game_state: GameState
var element_system: ElementSystem
var upgrades_system: UpgradesSystem
var action_queue := ActionQueue.new()
var ticks_per_second := DEFAULT_TICKS_PER_SECOND

var _tick_accumulator := 0.0
var _auto_smash_accumulator := 0.0

func _ready() -> void:
	set_process(false)

func configure(new_game_state: GameState, new_element_system: ElementSystem, new_upgrades_system: UpgradesSystem) -> void:
	game_state = new_game_state
	element_system = new_element_system
	upgrades_system = new_upgrades_system
	_tick_accumulator = 0.0
	_auto_smash_accumulator = 0.0
	action_queue.clear()
	set_process(game_state != null)

func enqueue_action(action_type: String, payload: Dictionary = {}) -> void:
	action_queue.enqueue(action_type, payload)

func _process(delta: float) -> void:
	if game_state == null:
		return

	var tick_duration := 1.0 / ticks_per_second
	_tick_accumulator += delta

	while _tick_accumulator >= tick_duration:
		_tick_accumulator -= tick_duration
		_process_tick(tick_duration)

func _process_tick(tick_duration: float) -> void:
	game_state.tick_count += 1
	game_state.total_played_seconds += tick_duration

	for queued_action in action_queue.drain():
		_apply_action(queued_action)

	_process_auto_smash(tick_duration)

	emit_signal("tick_processed", game_state.tick_count)

func _apply_action(action: Dictionary) -> void:
	var action_type := str(action.get("type", ""))
	var payload: Dictionary = action.get("payload", {})

	match action_type:
		"manual_smash":
			var result: Dictionary = element_system.manual_smash(game_state, upgrades_system)
			if not result.is_empty():
				emit_signal("manual_smash_resolved", result)
		"unlock_next":
			element_system.unlock_next_element(game_state)
		"select_adjacent":
			element_system.select_adjacent(game_state, int(payload.get("direction", 0)))
		"select_element":
			element_system.select_element(game_state, str(payload.get("id", "")))
		"purchase_upgrade":
			upgrades_system.purchase_upgrade(game_state, str(payload.get("id", "")))

func _process_auto_smash(tick_duration: float) -> void:
	var interval := upgrades_system.get_auto_smash_interval_seconds(game_state)
	if is_inf(interval):
		_auto_smash_accumulator = 0.0
		return

	_auto_smash_accumulator += tick_duration
	while _auto_smash_accumulator >= interval:
		_auto_smash_accumulator -= interval
		if game_state.current_element_id.is_empty():
			continue
		var request := {
			"target_element_id": game_state.current_element_id,
			"spawn_count": upgrades_system.get_auto_smash_spawn_count(game_state)
		}
		emit_signal("auto_smash_requested", request)
