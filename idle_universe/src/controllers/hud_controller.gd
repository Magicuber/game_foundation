extends RefCounted

class_name HudController

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

var _counter_margin: MarginContainer
var _counter_list: VBoxContainer
var _top_bar: ColorRect
var _profile_button: Button
var _level_label: Label
var _currency_boxes: VBoxContainer
var _orbs_panel: PanelContainer
var _dust_panel: PanelContainer
var _orbs_row: HBoxContainer
var _dust_row: HBoxContainer
var _orbs_icon_slot: ColorRect
var _dust_icon_slot: ColorRect
var _orbs_label: Label
var _dust_label: Label
var _bottom_bar: ColorRect
var _nav_slots: HBoxContainer
var _prev_slot: Control
var _next_slot: Control
var _zin_slot: Control
var _zout_slot: Control
var _menu_slot: Control
var _prev_button: TextureButton
var _next_button: TextureButton
var _zin_button: TextureButton
var _zout_button: TextureButton
var _menu_button: TextureButton
var _shop_button: TextureButton
var _menu_button_texture: Texture2D
var _close_button_texture: Texture2D
var _enabled_button_modulate := Color(1, 1, 1, 1)
var _disabled_button_modulate := Color(0.45, 0.45, 0.45, 1.0)

func configure(
	counter_margin: MarginContainer,
	counter_list: VBoxContainer,
	top_bar: ColorRect,
	profile_button: Button,
	level_label: Label,
	currency_boxes: VBoxContainer,
	orbs_panel: PanelContainer,
	dust_panel: PanelContainer,
	orbs_row: HBoxContainer,
	dust_row: HBoxContainer,
	orbs_icon_slot: ColorRect,
	dust_icon_slot: ColorRect,
	orbs_label: Label,
	dust_label: Label,
	bottom_bar: ColorRect,
	nav_slots: HBoxContainer,
	prev_slot: Control,
	next_slot: Control,
	zin_slot: Control,
	zout_slot: Control,
	menu_slot: Control,
	prev_button: TextureButton,
	next_button: TextureButton,
	zin_button: TextureButton,
	zout_button: TextureButton,
	menu_button: TextureButton,
	shop_button: TextureButton,
	prev_button_texture: Texture2D,
	next_button_texture: Texture2D,
	zin_button_texture: Texture2D,
	zout_button_texture: Texture2D,
	menu_button_texture: Texture2D,
	close_button_texture: Texture2D,
	shop_button_texture: Texture2D,
	enabled_button_modulate: Color,
	disabled_button_modulate: Color
) -> void:
	_counter_margin = counter_margin
	_counter_list = counter_list
	_top_bar = top_bar
	_profile_button = profile_button
	_level_label = level_label
	_currency_boxes = currency_boxes
	_orbs_panel = orbs_panel
	_dust_panel = dust_panel
	_orbs_row = orbs_row
	_dust_row = dust_row
	_orbs_icon_slot = orbs_icon_slot
	_dust_icon_slot = dust_icon_slot
	_orbs_label = orbs_label
	_dust_label = dust_label
	_bottom_bar = bottom_bar
	_nav_slots = nav_slots
	_prev_slot = prev_slot
	_next_slot = next_slot
	_zin_slot = zin_slot
	_zout_slot = zout_slot
	_menu_slot = menu_slot
	_prev_button = prev_button
	_next_button = next_button
	_zin_button = zin_button
	_zout_button = zout_button
	_menu_button = menu_button
	_shop_button = shop_button
	_menu_button_texture = menu_button_texture
	_close_button_texture = close_button_texture
	_enabled_button_modulate = enabled_button_modulate
	_disabled_button_modulate = disabled_button_modulate

	_configure_texture_button(_prev_button, prev_button_texture)
	_configure_texture_button(_next_button, next_button_texture)
	_configure_texture_button(_zin_button, zin_button_texture)
	_configure_texture_button(_zout_button, zout_button_texture)
	_configure_texture_button(_menu_button, menu_button_texture)
	_configure_texture_button(_shop_button, shop_button_texture)

	_profile_button.focus_mode = Control.FOCUS_NONE

func apply_style() -> void:
	_apply_profile_button_style()
	_apply_currency_box_style(_orbs_panel)
	_apply_currency_box_style(_dust_panel)
	_configure_placeholder_slot(_orbs_icon_slot)
	_configure_placeholder_slot(_dust_icon_slot)

	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font != null:
		_level_label.add_theme_font_override("font", ui_font)
		_orbs_label.add_theme_font_override("font", ui_font)
		_dust_label.add_theme_font_override("font", ui_font)
		_profile_button.add_theme_font_override("font", ui_font)

	_level_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	_level_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_orbs_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	_orbs_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_dust_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	_dust_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func apply_shell_metrics() -> void:
	_counter_list.add_theme_constant_override("separation", UIMetrics.COUNTER_LIST_SEPARATION)
	_currency_boxes.add_theme_constant_override("separation", UIMetrics.TOP_BAR_ROW_SEPARATION)
	_orbs_row.add_theme_constant_override("separation", UIMetrics.TOP_BAR_ROW_SEPARATION)
	_dust_row.add_theme_constant_override("separation", UIMetrics.TOP_BAR_ROW_SEPARATION)
	_orbs_icon_slot.custom_minimum_size = UIMetrics.TOP_BAR_ICON_SLOT_SIZE
	_dust_icon_slot.custom_minimum_size = UIMetrics.TOP_BAR_ICON_SLOT_SIZE
	_nav_slots.add_theme_constant_override("separation", UIMetrics.NAV_SLOT_SEPARATION)
	for slot in [_prev_slot, _next_slot, _zin_slot, _zout_slot, _menu_slot]:
		slot.custom_minimum_size = UIMetrics.NAV_SLOT_SIZE

func apply_reference_layout(shop_button: TextureButton) -> void:
	_set_top_strip_rect(_top_bar, UIMetrics.TOP_BAR_HEIGHT)
	_set_top_left_rect(_profile_button, UIMetrics.TOP_BAR_PROFILE_MARGIN, UIMetrics.TOP_BAR_PROFILE_SIZE)
	_set_top_left_rect(_level_label, UIMetrics.TOP_BAR_LEVEL_MARGIN, UIMetrics.TOP_BAR_LEVEL_SIZE)
	_set_center_anchor_rect(_currency_boxes, UIMetrics.CURRENCY_BOXES_SIZE)
	_set_bottom_strip_rect(_bottom_bar, UIMetrics.BOTTOM_BAR_HEIGHT)
	_set_center_anchor_rect(_nav_slots, UIMetrics.NAV_SLOTS_SIZE)
	_set_left_column_rect(
		_counter_margin,
		UIMetrics.COUNTER_MARGIN_LEFT,
		UIMetrics.COUNTER_MARGIN_TOP,
		UIMetrics.COUNTER_COLUMN_WIDTH,
		UIMetrics.COUNTER_MARGIN_BOTTOM
	)
	_set_top_right_rect(
		shop_button,
		UIMetrics.SHOP_BUTTON_TOP_MARGIN,
		UIMetrics.SHOP_BUTTON_RIGHT_MARGIN,
		UIMetrics.SHOP_BUTTON_SIZE
	)

func refresh_top_bar(game_state: GameState) -> void:
	_level_label.text = "Lv. %d" % game_state.player_level
	_orbs_label.text = "ORBS %s" % str(game_state.orbs)
	_dust_label.text = "DUST %s" % game_state.dust.big_to_short_string()

func refresh_navigation(
	is_atom_view: bool,
	can_prev: bool,
	can_next: bool,
	can_zoom_in: bool,
	can_zoom_out: bool
) -> void:
	_counter_margin.visible = is_atom_view
	_set_button_enabled_state(_prev_button, can_prev)
	_set_button_enabled_state(_next_button, can_next)
	_set_button_enabled_state(_zin_button, can_zoom_in)
	_set_button_enabled_state(_zout_button, can_zoom_out)

func refresh_menu_button(is_menu_open: bool) -> void:
	var texture: Texture2D = _menu_button_texture
	if is_menu_open:
		texture = _close_button_texture
	_configure_texture_button(_menu_button, texture)
	_menu_button.modulate = _enabled_button_modulate

func refresh_shop_button(shop_enabled: bool, show_shop_button: bool) -> void:
	_shop_button.visible = show_shop_button
	_shop_button.modulate = _enabled_button_modulate if shop_enabled else _disabled_button_modulate

func _configure_texture_button(button: TextureButton, texture: Texture2D) -> void:
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture
	button.texture_disabled = texture
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.ignore_texture_size = true
	button.focus_mode = Control.FOCUS_NONE

func _set_button_enabled_state(button: TextureButton, is_enabled: bool) -> void:
	button.disabled = not is_enabled
	button.modulate = _enabled_button_modulate if is_enabled else _disabled_button_modulate

func _apply_profile_button_style() -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color8(15, 100, 63)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color8(8, 54, 34)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = Color8(12, 84, 53)

	_profile_button.add_theme_stylebox_override("normal", normal_style)
	_profile_button.add_theme_stylebox_override("hover", normal_style)
	_profile_button.add_theme_stylebox_override("pressed", pressed_style)
	_profile_button.add_theme_stylebox_override("disabled", normal_style)

func _apply_currency_box_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color8(45, 45, 45)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color8(16, 16, 16)
	style.content_margin_left = UIMetrics.CURRENCY_PANEL_MARGIN_X
	style.content_margin_top = UIMetrics.CURRENCY_PANEL_MARGIN_Y
	style.content_margin_right = UIMetrics.CURRENCY_PANEL_MARGIN_X
	style.content_margin_bottom = UIMetrics.CURRENCY_PANEL_MARGIN_Y
	panel.add_theme_stylebox_override("panel", style)

func _configure_placeholder_slot(slot: ColorRect) -> void:
	slot.color = Color8(25, 25, 25, 180)

func _set_top_strip_rect(control: Control, height: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = height

func _set_bottom_strip_rect(control: Control, height: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 1.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = -height
	control.offset_right = 0.0
	control.offset_bottom = 0.0

func _set_top_left_rect(control: Control, margin: Vector2, size_value: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = margin.x
	control.offset_top = margin.y
	control.offset_right = margin.x + size_value.x
	control.offset_bottom = margin.y + size_value.y

func _set_top_right_rect(control: Control, top: float, right: float, size_value: Vector2) -> void:
	control.anchor_left = 1.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = -(right + size_value.x)
	control.offset_top = top
	control.offset_right = -right
	control.offset_bottom = top + size_value.y

func _set_left_column_rect(control: Control, left: float, top: float, width: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = left + width
	control.offset_bottom = -bottom

func _set_center_anchor_rect(control: Control, size_value: Vector2, center_offset: Vector2 = Vector2.ZERO) -> void:
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = center_offset.x - (size_value.x * 0.5)
	control.offset_top = center_offset.y - (size_value.y * 0.5)
	control.offset_right = center_offset.x + (size_value.x * 0.5)
	control.offset_bottom = center_offset.y + (size_value.y * 0.5)
