extends RefCounted

class_name MenuController

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

const MENU_CLOSED := 0
const MENU_MAIN := 1
const MENU_PROFILE := 2
const MENU_UPGRADES := 3
const MENU_ELEMENTS := 4
const MENU_BLESSINGS := 5
const MENU_ERA := 6
const MENU_STATS := 7
const MENU_SHOP := 8
const MENU_PLANETS := 9
const MENU_PRESTIGE := 10
const MENU_SETTINGS := 11

var _menu_overlay: Control
var _overlay_dim: ColorRect
var _menu_background: TextureRect
var _menu_content: MarginContainer
var _main_menu_panel: VBoxContainer
var _profile_panel: VBoxContainer
var _upgrades_panel: VBoxContainer
var _upgrades_scroll: ScrollContainer
var _elements_panel: VBoxContainer
var _blessings_panel: VBoxContainer
var _era_panel: Control
var _stats_panel: VBoxContainer
var _shop_panel: VBoxContainer
var _planets_panel: VBoxContainer
var _prestige_panel: VBoxContainer
var _settings_panel: VBoxContainer
var _main_menu_title: Label
var _profile_title: Label
var _profile_info: Label
var _upgrades_title: Label
var _upgrades_info: Label
var _elements_title: Label
var _elements_info: Label
var _blessings_title: Label
var _blessings_info: Label
var _era_title: Label
var _era_status: Label
var _era_requirement_margin: MarginContainer
var _era_requirement_vbox: VBoxContainer
var _era_requirement_title: Label
var _era_requirement_list: VBoxContainer
var _era_unlock_button: Button
var _stats_title: Label
var _stats_info: Label
var _planetary_stats_info: Label
var _shop_title: Label
var _shop_info: Label
var _planets_title: Label
var _planets_info: Label
var _prestige_title: Label
var _prestige_info: Label
var _settings_title: Label
var _settings_info: Label
var _prestige_debug_row: HBoxContainer
var _prestige_decrement_button: Button
var _prestige_count_label: Label
var _prestige_increment_button: Button
var _click_boxes_toggle: CheckButton
var _add_dust_button: Button
var _add_orbs_button: Button
var _profile_menu_button: Button
var _upgrades_menu_button: Button
var _elements_menu_button: Button
var _blessings_menu_button: Button
var _era_menu_button: Button
var _planets_menu_button: Button
var _prestige_menu_button: Button
var _stats_menu_button: Button
var _shop_menu_button: Button
var _settings_menu_button: Button
var _unlock_button: Button
var _elements_scroll: ScrollContainer
var _elements_section_list: VBoxContainer
var _dust_action_row: HBoxContainer
var _make_dust_button: TextureButton
var _make_dust_label: Label
var _dust_close_button: TextureButton
var _dust_close_label: Label
var _enabled_button_modulate := Color(1, 1, 1, 1)
var _disabled_button_modulate := Color(0.45, 0.45, 0.45, 1.0)

func configure(
	menu_overlay: Control,
	overlay_dim: ColorRect,
	menu_background: TextureRect,
	menu_content: MarginContainer,
	main_menu_panel: VBoxContainer,
	profile_panel: VBoxContainer,
	upgrades_panel: VBoxContainer,
	upgrades_scroll: ScrollContainer,
	elements_panel: VBoxContainer,
	blessings_panel: VBoxContainer,
	era_panel: Control,
	stats_panel: VBoxContainer,
	shop_panel: VBoxContainer,
	planets_panel: VBoxContainer,
	prestige_panel: VBoxContainer,
	settings_panel: VBoxContainer,
	main_menu_title: Label,
	profile_title: Label,
	profile_info: Label,
	upgrades_title: Label,
	upgrades_info: Label,
	elements_title: Label,
	elements_info: Label,
	blessings_title: Label,
	blessings_info: Label,
	era_title: Label,
	era_status: Label,
	era_requirement_margin: MarginContainer,
	era_requirement_vbox: VBoxContainer,
	era_requirement_title: Label,
	era_requirement_list: VBoxContainer,
	era_unlock_button: Button,
	stats_title: Label,
	stats_info: Label,
	planetary_stats_info: Label,
	shop_title: Label,
	shop_info: Label,
	planets_title: Label,
	planets_info: Label,
	prestige_title: Label,
	prestige_info: Label,
	settings_title: Label,
	settings_info: Label,
	prestige_debug_row: HBoxContainer,
	prestige_decrement_button: Button,
	prestige_count_label: Label,
	prestige_increment_button: Button,
	click_boxes_toggle: CheckButton,
	add_dust_button: Button,
	add_orbs_button: Button,
	profile_menu_button: Button,
	upgrades_menu_button: Button,
	elements_menu_button: Button,
	blessings_menu_button: Button,
	era_menu_button: Button,
	planets_menu_button: Button,
	prestige_menu_button: Button,
	stats_menu_button: Button,
	shop_menu_button: Button,
	settings_menu_button: Button,
	unlock_button: Button,
	elements_scroll: ScrollContainer,
	elements_section_list: VBoxContainer,
	dust_action_row: HBoxContainer,
	make_dust_button: TextureButton,
	make_dust_label: Label,
	dust_close_button: TextureButton,
	dust_close_label: Label,
	menu_background_texture: Texture2D,
	upgrade_button_texture: Texture2D,
	enabled_button_modulate: Color,
	disabled_button_modulate: Color
) -> void:
	_menu_overlay = menu_overlay
	_overlay_dim = overlay_dim
	_menu_background = menu_background
	_menu_content = menu_content
	_main_menu_panel = main_menu_panel
	_profile_panel = profile_panel
	_upgrades_panel = upgrades_panel
	_upgrades_scroll = upgrades_scroll
	_elements_panel = elements_panel
	_blessings_panel = blessings_panel
	_era_panel = era_panel
	_stats_panel = stats_panel
	_shop_panel = shop_panel
	_planets_panel = planets_panel
	_prestige_panel = prestige_panel
	_settings_panel = settings_panel
	_main_menu_title = main_menu_title
	_profile_title = profile_title
	_profile_info = profile_info
	_upgrades_title = upgrades_title
	_upgrades_info = upgrades_info
	_elements_title = elements_title
	_elements_info = elements_info
	_blessings_title = blessings_title
	_blessings_info = blessings_info
	_era_title = era_title
	_era_status = era_status
	_era_requirement_margin = era_requirement_margin
	_era_requirement_vbox = era_requirement_vbox
	_era_requirement_title = era_requirement_title
	_era_requirement_list = era_requirement_list
	_era_unlock_button = era_unlock_button
	_stats_title = stats_title
	_stats_info = stats_info
	_planetary_stats_info = planetary_stats_info
	_shop_title = shop_title
	_shop_info = shop_info
	_planets_title = planets_title
	_planets_info = planets_info
	_prestige_title = prestige_title
	_prestige_info = prestige_info
	_settings_title = settings_title
	_settings_info = settings_info
	_prestige_debug_row = prestige_debug_row
	_prestige_decrement_button = prestige_decrement_button
	_prestige_count_label = prestige_count_label
	_prestige_increment_button = prestige_increment_button
	_click_boxes_toggle = click_boxes_toggle
	_add_dust_button = add_dust_button
	_add_orbs_button = add_orbs_button
	_profile_menu_button = profile_menu_button
	_upgrades_menu_button = upgrades_menu_button
	_elements_menu_button = elements_menu_button
	_blessings_menu_button = blessings_menu_button
	_era_menu_button = era_menu_button
	_planets_menu_button = planets_menu_button
	_prestige_menu_button = prestige_menu_button
	_stats_menu_button = stats_menu_button
	_shop_menu_button = shop_menu_button
	_settings_menu_button = settings_menu_button
	_unlock_button = unlock_button
	_elements_scroll = elements_scroll
	_elements_section_list = elements_section_list
	_dust_action_row = dust_action_row
	_make_dust_button = make_dust_button
	_make_dust_label = make_dust_label
	_dust_close_button = dust_close_button
	_dust_close_label = dust_close_label
	_enabled_button_modulate = enabled_button_modulate
	_disabled_button_modulate = disabled_button_modulate

	_configure_texture_button(_make_dust_button, upgrade_button_texture)
	_configure_texture_button(_dust_close_button, upgrade_button_texture)

	_menu_background.texture = menu_background_texture
	_menu_background.modulate = Color(1, 1, 1, 0.7)
	_menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_menu_background.stretch_mode = TextureRect.STRETCH_SCALE
	_menu_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	for button in [
		_unlock_button,
		_era_unlock_button,
		_make_dust_button,
		_dust_close_button,
		_profile_menu_button,
		_upgrades_menu_button,
		_elements_menu_button,
		_blessings_menu_button,
		_era_menu_button,
		_planets_menu_button,
		_prestige_menu_button,
		_stats_menu_button,
		_shop_menu_button,
		_settings_menu_button
	]:
		button.focus_mode = Control.FOCUS_NONE

func apply_style() -> void:
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font != null:
		for control in [
			_main_menu_title,
			_profile_title,
			_profile_info,
			_upgrades_title,
			_upgrades_info,
			_elements_title,
			_elements_info,
			_blessings_title,
			_blessings_info,
			_era_title,
			_era_status,
			_era_requirement_title,
			_era_unlock_button,
			_stats_title,
			_stats_info,
			_planetary_stats_info,
			_shop_title,
			_shop_info,
			_planets_title,
			_planets_info,
			_prestige_title,
			_prestige_info,
			_settings_title,
			_settings_info,
			_prestige_decrement_button,
			_prestige_count_label,
			_prestige_increment_button,
			_click_boxes_toggle,
			_add_dust_button,
			_add_orbs_button,
			_profile_menu_button,
			_upgrades_menu_button,
			_elements_menu_button,
			_blessings_menu_button,
			_era_menu_button,
			_planets_menu_button,
			_prestige_menu_button,
			_stats_menu_button,
			_shop_menu_button,
			_settings_menu_button,
			_unlock_button,
			_make_dust_label,
			_dust_close_label
		]:
			control.add_theme_font_override("font", ui_font)

	_main_menu_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_profile_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_upgrades_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_elements_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_blessings_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_era_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_era_status.add_theme_font_size_override("font_size", UIMetrics.ERA_STATUS_FONT_SIZE)
	_era_requirement_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_LARGE)
	_stats_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_shop_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_planets_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_prestige_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_settings_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	for control in [
		_profile_info,
		_upgrades_info,
		_elements_info,
		_blessings_info,
		_era_status,
		_era_requirement_title,
		_era_unlock_button,
		_stats_info,
		_planetary_stats_info,
		_shop_info,
		_planets_info,
		_prestige_info,
		_settings_info,
		_prestige_decrement_button,
		_prestige_count_label,
		_prestige_increment_button,
		_click_boxes_toggle,
		_add_dust_button,
		_add_orbs_button,
		_profile_menu_button,
		_upgrades_menu_button,
		_elements_menu_button,
		_blessings_menu_button,
		_era_menu_button,
		_planets_menu_button,
		_prestige_menu_button,
		_stats_menu_button,
		_shop_menu_button,
		_settings_menu_button,
		_unlock_button
	]:
		control.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)

	for label in [
		_main_menu_title,
		_profile_title,
		_profile_info,
		_upgrades_title,
		_elements_title,
		_blessings_title,
		_blessings_info,
		_era_title,
		_stats_title,
		_upgrades_info,
		_elements_info,
		_era_status,
		_era_requirement_title,
		_stats_info,
		_planetary_stats_info,
		_shop_title,
		_shop_info,
		_planets_title,
		_planets_info,
		_prestige_title,
		_prestige_info,
		_settings_title,
		_settings_info,
		_prestige_count_label,
		_click_boxes_toggle,
		_add_dust_button,
		_add_orbs_button
	]:
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	for button in [_prestige_decrement_button, _prestige_increment_button]:
		button.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	_make_dust_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	_make_dust_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_dust_close_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	_dust_close_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))

func apply_shell_metrics() -> void:
	for panel in [
		_main_menu_panel,
		_profile_panel,
		_upgrades_panel,
		_elements_panel,
		_blessings_panel,
		_stats_panel,
		_shop_panel,
		_planets_panel,
		_prestige_panel,
		_settings_panel
	]:
		panel.add_theme_constant_override("separation", UIMetrics.MENU_PANEL_SEPARATION)

	_upgrades_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrades_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrades_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_elements_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_elements_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_elements_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_elements_section_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_elements_section_list.z_as_relative = false
	_elements_section_list.z_index = 60
	_elements_section_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_elements_section_list.add_theme_constant_override("separation", UIMetrics.MENU_SECTION_LIST_SEPARATION)
	_dust_action_row.add_theme_constant_override("separation", UIMetrics.DUST_ACTION_ROW_SEPARATION)
	_prestige_debug_row.add_theme_constant_override("separation", UIMetrics.DUST_ACTION_ROW_SEPARATION)
	for button in [
		_prestige_decrement_button,
		_prestige_increment_button,
		_profile_menu_button,
		_upgrades_menu_button,
		_elements_menu_button,
		_blessings_menu_button,
		_era_menu_button,
		_planets_menu_button,
		_prestige_menu_button,
		_stats_menu_button,
		_shop_menu_button,
		_settings_menu_button,
		_unlock_button,
		_era_unlock_button,
		_click_boxes_toggle,
		_add_dust_button,
		_add_orbs_button
	]:
		button.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
	_prestige_count_label.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
	_make_dust_button.custom_minimum_size = UIMetrics.DUST_ACTION_PRIMARY_BUTTON_SIZE
	_dust_close_button.custom_minimum_size = UIMetrics.DUST_ACTION_SECONDARY_BUTTON_SIZE
	_era_requirement_margin.add_theme_constant_override("margin_left", UIMetrics.ERA_REQUIREMENT_MARGIN)
	_era_requirement_margin.add_theme_constant_override("margin_top", UIMetrics.ERA_REQUIREMENT_MARGIN)
	_era_requirement_margin.add_theme_constant_override("margin_right", UIMetrics.ERA_REQUIREMENT_MARGIN)
	_era_requirement_margin.add_theme_constant_override("margin_bottom", UIMetrics.ERA_REQUIREMENT_MARGIN)
	_era_requirement_vbox.add_theme_constant_override("separation", UIMetrics.ERA_REQUIREMENT_VBOX_SEPARATION)
	_era_requirement_list.add_theme_constant_override("separation", UIMetrics.ERA_REQUIREMENT_LIST_SEPARATION)

func apply_reference_layout() -> void:
	_set_fill_rect(_overlay_dim, 0.0, 0.0, 0.0, 0.0)
	_set_fill_rect(_menu_overlay, 0.0, UIMetrics.TOP_BAR_HEIGHT, 0.0, UIMetrics.BOTTOM_BAR_HEIGHT)
	_set_fill_rect(
		_menu_background,
		UIMetrics.MENU_BACKGROUND_MARGIN,
		UIMetrics.MENU_BACKGROUND_MARGIN,
		UIMetrics.MENU_BACKGROUND_MARGIN,
		UIMetrics.MENU_BACKGROUND_MARGIN
	)
	_set_fill_rect(
		_menu_content,
		UIMetrics.MENU_CONTENT_MARGIN,
		UIMetrics.MENU_CONTENT_MARGIN,
		UIMetrics.MENU_CONTENT_MARGIN,
		UIMetrics.MENU_CONTENT_MARGIN
	)
	_elements_section_list.custom_minimum_size.x = maxf(0.0, _elements_scroll.size.x)

func set_menu_mode(menu_mode: int) -> void:
	_menu_overlay.visible = menu_mode != MENU_CLOSED
	_main_menu_panel.visible = menu_mode == MENU_MAIN
	_profile_panel.visible = menu_mode == MENU_PROFILE
	_upgrades_panel.visible = menu_mode == MENU_UPGRADES
	_elements_panel.visible = menu_mode == MENU_ELEMENTS
	_blessings_panel.visible = menu_mode == MENU_BLESSINGS
	_era_panel.visible = menu_mode == MENU_ERA
	_stats_panel.visible = menu_mode == MENU_STATS
	_shop_panel.visible = menu_mode == MENU_SHOP
	_planets_panel.visible = menu_mode == MENU_PLANETS
	_prestige_panel.visible = menu_mode == MENU_PRESTIGE
	_settings_panel.visible = menu_mode == MENU_SETTINGS

func refresh_main_menu_buttons(blessings_enabled: bool, era_enabled: bool, planets_enabled: bool, shop_enabled: bool) -> void:
	_apply_menu_button_style(_profile_menu_button, true)
	_apply_menu_button_style(_upgrades_menu_button, true)
	_apply_menu_button_style(_elements_menu_button, true)
	_apply_menu_button_style(_blessings_menu_button, blessings_enabled)
	_apply_menu_button_style(_prestige_menu_button, true)
	_apply_menu_button_style(_stats_menu_button, true)
	_apply_menu_button_style(_settings_menu_button, true)
	_apply_menu_button_style(_era_menu_button, era_enabled)
	_apply_menu_button_style(_planets_menu_button, planets_enabled)
	_apply_menu_button_style(_shop_menu_button, shop_enabled)

func _configure_texture_button(button: TextureButton, texture: Texture2D) -> void:
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture
	button.texture_disabled = texture
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.ignore_texture_size = true
	button.focus_mode = Control.FOCUS_NONE

func _apply_menu_button_style(button: Button, is_enabled: bool) -> void:
	button.disabled = not is_enabled
	button.modulate = _enabled_button_modulate if is_enabled else _disabled_button_modulate

func _set_fill_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = -right
	control.offset_bottom = -bottom
