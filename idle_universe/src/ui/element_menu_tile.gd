extends Control

class_name ElementMenuTile

signal element_pressed(element_id: String)

const ATOM_MENU_SHEET = preload("res://assests/sprites/atoms_menu_strip119.png")
const FRAME_SIZE := Vector2i(32, 32)
const UNLOCKED_MODULATE := Color(1, 1, 1, 1)
const LOCKED_MODULATE := Color(0.4, 0.4, 0.4, 1)
const SELECTED_BORDER_COLOR := Color8(105, 145, 102)
const DEBUG_HITBOX_COLOR := Color8(255, 80, 80)
const DUST_FILL_COLOR := Color(0.82, 0.14, 0.14, 0.42)

static var _background_cache: Dictionary = {}

var game_state: GameState
var element_id := ""
var is_unlocked := false
var dust_selection_fraction := 0.0

var background_rect: TextureRect
var dust_fill_rect: ColorRect
var selected_border: Panel
var debug_hitbox_border: Panel
var symbol_label: Label
var amount_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(0, 56)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	background_rect = TextureRect.new()
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

	dust_fill_rect = ColorRect.new()
	dust_fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dust_fill_rect.color = DUST_FILL_COLOR
	dust_fill_rect.anchor_left = 0.0
	dust_fill_rect.anchor_top = 0.0
	dust_fill_rect.anchor_right = 1.0
	dust_fill_rect.anchor_bottom = 0.0
	dust_fill_rect.offset_top = 0.0
	dust_fill_rect.offset_bottom = 0.0
	dust_fill_rect.visible = false
	add_child(dust_fill_rect)

	selected_border = Panel.new()
	selected_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_border.visible = false
	selected_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = Color(0, 0, 0, 0)
	selected_style.border_width_left = 4
	selected_style.border_width_top = 4
	selected_style.border_width_right = 4
	selected_style.border_width_bottom = 4
	selected_style.border_color = SELECTED_BORDER_COLOR
	selected_border.add_theme_stylebox_override("panel", selected_style)
	add_child(selected_border)

	debug_hitbox_border = Panel.new()
	debug_hitbox_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_hitbox_border.visible = false
	debug_hitbox_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var debug_style := StyleBoxFlat.new()
	debug_style.bg_color = Color(0, 0, 0, 0)
	debug_style.border_width_left = 2
	debug_style.border_width_top = 2
	debug_style.border_width_right = 2
	debug_style.border_width_bottom = 2
	debug_style.border_color = DEBUG_HITBOX_COLOR
	debug_hitbox_border.add_theme_stylebox_override("panel", debug_style)
	add_child(debug_hitbox_border)

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
	refresh("", 0.0)

func refresh(current_selected_id: String, new_dust_selection_fraction: float = 0.0) -> void:
	if game_state == null or element_id.is_empty() or not game_state.has_element(element_id):
		visible = false
		symbol_label.text = ""
		amount_label.text = ""
		return

	visible = true
	var element: Dictionary = game_state.get_element(element_id)
	var element_index := int(element.get("index", 0))
	background_rect.texture = _get_background_texture(element_index)

	is_unlocked = bool(element.get("unlocked", false))
	dust_selection_fraction = clampf(new_dust_selection_fraction, 0.0, 1.0)
	selected_border.visible = current_selected_id == element_id and is_unlocked
	if is_unlocked:
		background_rect.modulate = UNLOCKED_MODULATE
	else:
		background_rect.modulate = LOCKED_MODULATE

	symbol_label.text = str(element.get("name", element_id))
	amount_label.text = game_state.get_resource_amount(element_id).big_to_short_string()
	_update_dust_fill()

func _apply_font() -> void:
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font == null:
		return
	symbol_label.add_theme_font_override("font", ui_font)
	amount_label.add_theme_font_override("font", ui_font)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_on_pressed()
			accept_event()

func _on_pressed() -> void:
	if is_unlocked and not element_id.is_empty():
		emit_signal("element_pressed", element_id)

func set_debug_hitbox_visible(is_visible: bool) -> void:
	debug_hitbox_border.visible = is_visible

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_square_size()
		_update_dust_fill()

func _update_square_size() -> void:
	if size.x <= 0.0:
		return
	var target_height := round(size.x)
	if absf(custom_minimum_size.x - target_height) > 0.5 or absf(custom_minimum_size.y - target_height) > 0.5:
		custom_minimum_size = Vector2(target_height, target_height)

func _update_dust_fill() -> void:
	if dust_fill_rect == null:
		return
	var fill_height := round(size.y * dust_selection_fraction)
	dust_fill_rect.visible = fill_height > 0.0
	dust_fill_rect.offset_bottom = fill_height

func _get_background_texture(element_index: int) -> AtlasTexture:
	if not _background_cache.has(element_index):
		var background := AtlasTexture.new()
		background.atlas = ATOM_MENU_SHEET
		background.region = Rect2(
			Vector2(element_index * FRAME_SIZE.x, 0),
			Vector2(FRAME_SIZE.x, FRAME_SIZE.y)
		)
		_background_cache[element_index] = background
	return _background_cache[element_index]
