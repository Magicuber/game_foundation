extends PanelContainer

class_name CurrencyDisplay

var game_state: GameState
var resource_id := ""
var value_label: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 28)

	var style := StyleBoxFlat.new()
	style.bg_color = Color8(213, 165, 104)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color8(89, 60, 27)
	style.content_margin_left = 8
	style.content_margin_top = 3
	style.content_margin_right = 8
	style.content_margin_bottom = 3
	add_theme_stylebox_override("panel", style)

	value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 14)
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font != null:
		value_label.add_theme_font_override("font", ui_font)
	add_child(value_label)

func configure(new_game_state: GameState, new_resource_id: String) -> void:
	game_state = new_game_state
	resource_id = new_resource_id
	refresh()

func refresh() -> void:
	if game_state == null or resource_id.is_empty():
		value_label.text = ""
		return

	if not game_state.has_element(resource_id):
		value_label.text = resource_id
		return

	var element: Dictionary = game_state.get_element(resource_id)
	value_label.text = "%s: %s" % [
		str(element.get("name", resource_id)),
		game_state.get_resource_amount(resource_id).big_to_short_string()
	]
