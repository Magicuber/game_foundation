extends RefCounted

class_name GameLoaderSetupHelper

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

var _loader_ref: WeakRef = null
var loader:
	get:
		return null if _loader_ref == null else _loader_ref.get_ref()

func _init(owner = null) -> void:
	_game_loader_set(owner)

func configure(owner) -> void:
	_game_loader_set(owner)

func ensure_reset_blessings_button() -> void:
	var game_loader = loader
	if game_loader == null or is_instance_valid(game_loader.reset_blessings_button):
		return

	game_loader.reset_blessings_button = Button.new()
	game_loader.reset_blessings_button.name = "ResetBlessingsButton"
	game_loader.reset_blessings_button.text = "Reset Blessings"
	game_loader.reset_blessings_button.focus_mode = Control.FOCUS_NONE
	game_loader.settings_panel.add_child(game_loader.reset_blessings_button)
	game_loader.settings_panel.move_child(game_loader.reset_blessings_button, game_loader.settings_panel.get_child_count() - 1)
	game_loader.reset_blessings_button.pressed.connect(game_loader._on_reset_blessings_pressed)

func style_reset_blessings_button() -> void:
	var game_loader = loader
	if game_loader == null or not is_instance_valid(game_loader.reset_blessings_button):
		return

	game_loader.reset_blessings_button.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font != null:
		game_loader.reset_blessings_button.add_theme_font_override("font", ui_font)
	game_loader.reset_blessings_button.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	game_loader.reset_blessings_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func ensure_factory_and_collider_menu_nodes() -> void:
	var game_loader = loader
	if game_loader == null:
		return

	var insertion_anchor: Button = game_loader.oblations_menu_button if is_instance_valid(game_loader.oblations_menu_button) else game_loader.prestige_menu_button
	game_loader.factory_menu_button = ensure_main_menu_button("FactoryMenuButton", "Factory", insertion_anchor.get_index() + 1)
	game_loader.collider_menu_button = ensure_main_menu_button("ColliderMenuButton", "Collider", game_loader.factory_menu_button.get_index() + 1)
	game_loader.factory_panel = ensure_placeholder_menu_panel("FactoryPanel", "Factory", "Factory systems will live here.")
	game_loader.collider_panel = ensure_placeholder_menu_panel("ColliderPanel", "Collider", "Collider systems will live here.")
	game_loader.factory_title = game_loader.factory_panel.get_node("FactoryTitle")
	game_loader.factory_info = game_loader.factory_panel.get_node("FactoryInfo")
	game_loader.collider_title = game_loader.collider_panel.get_node("ColliderTitle")
	game_loader.collider_info = game_loader.collider_panel.get_node("ColliderInfo")

func ensure_oblations_menu_nodes() -> void:
	var game_loader = loader
	if game_loader == null:
		return

	game_loader.oblations_menu_button = ensure_main_menu_button("OblationsMenuButton", "Oblations", game_loader.prestige_menu_button.get_index() + 1)
	game_loader.oblations_panel = ensure_placeholder_menu_panel("OblationsPanel", "Oblations", "Select sacrifices to gain persistent bonuses.")
	game_loader.oblations_title = game_loader.oblations_panel.get_node("OblationsTitle")
	game_loader.oblations_info = game_loader.oblations_panel.get_node("OblationsInfo")

func ensure_main_menu_button(button_name: String, button_text: String, child_index: int) -> Button:
	var game_loader = loader
	if game_loader == null:
		return null

	var button: Button = game_loader.main_menu_panel.get_node_or_null(button_name) as Button
	if button == null:
		button = Button.new()
		button.name = button_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		game_loader.main_menu_panel.add_child(button)
	button.text = button_text
	game_loader.main_menu_panel.move_child(button, child_index)
	return button

func ensure_placeholder_menu_panel(panel_name: String, panel_title: String, panel_text: String) -> VBoxContainer:
	var game_loader = loader
	if game_loader == null:
		return null

	var panel: VBoxContainer = game_loader.menu_panels.get_node_or_null(panel_name) as VBoxContainer
	if panel == null:
		panel = VBoxContainer.new()
		panel.name = panel_name
		panel.visible = false
		panel.layout_mode = 1
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		game_loader.menu_panels.add_child(panel)

		var title: Label = Label.new()
		title.name = "%sTitle" % panel_title
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.text = panel_title
		panel.add_child(title)

		var info: Label = Label.new()
		info.name = "%sInfo" % panel_title
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(info)

	var title_label: Label = panel.get_node("%sTitle" % panel_title) as Label
	var info_label: Label = panel.get_node("%sInfo" % panel_title) as Label
	title_label.text = panel_title
	info_label.text = panel_text
	game_loader.menu_panels.move_child(panel, min(game_loader.menu_panels.get_child_count() - 1, game_loader.settings_panel.get_index()))
	return panel

func _game_loader_set(owner) -> void:
	_loader_ref = weakref(owner) if owner != null else null
