extends GridContainer

class_name ElementSelector

signal element_selected(element_id: String)

var game_state: GameState
var _button_ids: Array[String] = []
var _buttons: Dictionary = {}

func configure(new_game_state: GameState) -> void:
	game_state = new_game_state
	columns = 4
	refresh()

func refresh() -> void:
	if game_state == null:
		return

	var unlocked_ids := game_state.get_unlocked_element_ids()
	if _button_ids != unlocked_ids:
		_rebuild_buttons(unlocked_ids)

	for element_id in _button_ids:
		var button: Button = _buttons[element_id]
		var element := game_state.get_element(element_id)
		button.text = str(element.get("name", element_id))
		button.button_pressed = element_id == game_state.current_element_id

func _rebuild_buttons(unlocked_ids: Array[String]) -> void:
	for child in get_children():
		child.queue_free()

	_button_ids = unlocked_ids.duplicate()
	_buttons.clear()

	for element_id in _button_ids:
		var button := Button.new()
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_button_pressed.bind(element_id))
		add_child(button)
		_buttons[element_id] = button

func _on_button_pressed(element_id: String) -> void:
	emit_signal("element_selected", element_id)
