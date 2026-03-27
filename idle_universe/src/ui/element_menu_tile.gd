extends Control

class_name ElementMenuTile

signal element_pressed(element_id: String)

const ATOM_MENU_SHEET = preload("res://assests/sprites/atoms_menu_strip119.png")
const FRAME_SIZE := Vector2i(32, 32)
const UNLOCKED_MODULATE := Color(1, 1, 1, 1)
const LOCKED_MODULATE := Color(0.4, 0.4, 0.4, 1)
const SELECTED_MODULATE := Color(1, 0.95, 0.7, 1)

var game_state: GameState
var element_id := ""
var is_unlocked := false

var button: TextureButton
var symbol_label: Label
var amount_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(0, 56)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	button = TextureButton.new()
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(_on_pressed)
	add_child(button)

	symbol_label = Label.new()
	symbol_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	symbol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	symbol_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	symbol_label.anchor_left = 0.0
	symbol_label.anchor_top = 0.0
	symbol_label.anchor_right = 1.0
	symbol_label.anchor_bottom = 0.0
	symbol_label.offset_top = 6.0
	symbol_label.offset_bottom = 26.0
	symbol_label.add_theme_font_size_override("font_size", 14)
	add_child(symbol_label)

	amount_label = Label.new()
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount_label.anchor_left = 0.0
	amount_label.anchor_top = 1.0
	amount_label.anchor_right = 1.0
	amount_label.anchor_bottom = 1.0
	amount_label.offset_top = -20.0
	amount_label.offset_bottom = -4.0
	amount_label.add_theme_font_size_override("font_size", 10)
	add_child(amount_label)

	_apply_font()
	call_deferred("_update_square_size")

func configure(new_game_state: GameState, new_element_id: String) -> void:
	game_state = new_game_state
	element_id = new_element_id
	refresh("")

func refresh(current_selected_id: String) -> void:
	if game_state == null or element_id.is_empty() or not game_state.has_element(element_id):
		button.visible = false
		symbol_label.text = ""
		amount_label.text = ""
		return

	button.visible = true
	var element: Dictionary = game_state.get_element(element_id)
	var element_index := int(element.get("index", 0))
	var background := AtlasTexture.new()
	background.atlas = ATOM_MENU_SHEET
	background.region = Rect2(
		Vector2(element_index * FRAME_SIZE.x, 0),
		Vector2(FRAME_SIZE.x, FRAME_SIZE.y)
	)
	button.texture_normal = background
	button.texture_pressed = background
	button.texture_hover = background
	button.texture_disabled = background

	is_unlocked = bool(element.get("unlocked", false))
	button.disabled = false
	if current_selected_id == element_id and is_unlocked:
		button.modulate = SELECTED_MODULATE
	elif is_unlocked:
		button.modulate = UNLOCKED_MODULATE
	else:
		button.modulate = LOCKED_MODULATE

	symbol_label.text = str(element.get("name", element_id))
	amount_label.text = game_state.get_resource_amount(element_id).big_to_short_string()

func _apply_font() -> void:
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font == null:
		return
	symbol_label.add_theme_font_override("font", ui_font)
	amount_label.add_theme_font_override("font", ui_font)

func _on_pressed() -> void:
	if is_unlocked and not element_id.is_empty():
		emit_signal("element_pressed", element_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_square_size()

func _update_square_size() -> void:
	if size.x <= 0.0:
		return
	var target_height := round(size.x)
	if absf(custom_minimum_size.y - target_height) > 0.5:
		custom_minimum_size = Vector2(0.0, target_height)
