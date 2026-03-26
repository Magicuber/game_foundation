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
	var drained: Array[Dictionary] = []
	for action in _queued_actions:
		drained.append(action.duplicate(true))
	_queued_actions.clear()
	return drained

func clear() -> void:
	_queued_actions.clear()
