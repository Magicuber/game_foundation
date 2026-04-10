extends RefCounted

class_name ActionQueue

var _queued_actions: Array[Dictionary]

func _init() -> void:
	_queued_actions = []

func enqueue(action_type: String, payload: Dictionary = {}) -> void:
	_queued_actions.append({
		"type": action_type,
		"payload": payload.duplicate(true)
	})

func drain() -> Array[Dictionary]:
	var drained := _queued_actions
	_queued_actions = []
	return drained

func clear() -> void:
	_queued_actions.clear()
