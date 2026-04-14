extends RefCounted

class_name PlanetsPanelController

signal planet_selected(planet_id: String)
signal moon_selected(moon_id: String)
signal unlock_requested(planet_id: String)
signal moon_upgrade_requested(moon_id: String, upgrade_id: String)

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

const COLOR_SPACE_BG := "#1E1E2E"
const COLOR_PANEL_BG := "#2A2A3C"
const COLOR_DIVIDER := "#3A3A4F"
const COLOR_NODE_DEFAULT := "#4A7F78"
const COLOR_NODE_LOCKED := "#2E3F3C"
const COLOR_NODE_PURCHASED := "#6FD1B3"
const COLOR_GOLD_BUTTON := "#E6C84F"
const COLOR_TEXT := "#F3F3FF"
const COLOR_TEXT_MUTED := "#C7C7DD"
const COLOR_PREVIEW_BG := "#050507"

class TreeCanvas extends Control:
	var _line_entries: Array[Dictionary] = []

	func set_line_entries(line_entries: Array[Dictionary]) -> void:
		_line_entries = line_entries
		queue_redraw()

	func _draw() -> void:
		for line_entry in _line_entries:
			var start_point: Vector2 = line_entry.get("start", Vector2.ZERO)
			var end_point: Vector2 = line_entry.get("end", Vector2.ZERO)
			var color: Color = line_entry.get("color", Color.WHITE)
			var width := float(line_entry.get("width", 1.0))
			draw_line(start_point, end_point, color, width, false)

var _panel: VBoxContainer
var _info_label: Label
var _icon_cache: GameIconCache
var _ui_font: FontFile

var _layout_root: VBoxContainer
var _tree_panel: PanelContainer
var _tree_canvas: TreeCanvas
var _bottom_row: HBoxContainer
var _upgrades_panel: PanelContainer
var _upgrades_header: Label
var _upgrades_list: VBoxContainer
var _preview_panel: PanelContainer
var _preview_header: Label
var _preview_frame: PanelContainer
var _preview_icon: TextureRect
var _preview_name: Label
var _preview_subtitle: Label
var _preview_stats: Label
var _preview_costs: Label
var _action_button: Button

var _tree_node_buttons: Dictionary = {}
var _upgrade_buttons: Dictionary = {}
var _game_state: GameState
var _selected_planet_id := ""
var _selected_moon_id := ""
var _last_visible_node_ids: Array[String] = []
var _last_stage_index := 0
var _has_refreshed_once := false

func configure(panel: VBoxContainer, info_label: Label, icon_cache: GameIconCache) -> void:
	_panel = panel
	_info_label = info_label
	_icon_cache = icon_cache
	_ui_font = UIFont.load_ui_font()

	_layout_root = _panel.get_node_or_null("PlanetsMenuLayout") as VBoxContainer
	if _layout_root == null:
		_build_layout()

	_apply_layout()

func refresh(game_state: GameState) -> void:
	if not _panel.visible or game_state == null:
		return

	_game_state = game_state
	var view_model := game_state.get_planet_menu_view_model()
	_ensure_valid_selection(game_state, view_model)
	_refresh_tree(view_model)
	_refresh_upgrade_panel(game_state)
	_refresh_preview_panel(game_state)
	_last_stage_index = int(view_model.get("stage_index", 0))
	_has_refreshed_once = true

func play_planet_unlock_animation(planet_id: String) -> void:
	var node_button := _tree_node_buttons.get(planet_id, null) as Control
	_pulse_control(node_button)
	_pulse_control(_preview_frame)
	_pulse_control(_action_button)

func play_moon_upgrade_purchase_animation(moon_id: String, upgrade_id: String) -> void:
	var button_key := _get_upgrade_button_key(moon_id, upgrade_id)
	var upgrade_button := _upgrade_buttons.get(button_key, null) as Control
	_pulse_control(upgrade_button)

func _build_layout() -> void:
	_layout_root = VBoxContainer.new()
	_layout_root.name = "PlanetsMenuLayout"
	_panel.add_child(_layout_root)
	_panel.move_child(_layout_root, _panel.get_child_count() - 1)

	_tree_panel = PanelContainer.new()
	_tree_panel.name = "PlanetsTreePanel"
	_layout_root.add_child(_tree_panel)

	_tree_canvas = TreeCanvas.new()
	_tree_canvas.name = "PlanetsTreeCanvas"
	_tree_panel.add_child(_tree_canvas)

	_bottom_row = HBoxContainer.new()
	_bottom_row.name = "PlanetsBottomRow"
	_layout_root.add_child(_bottom_row)

	_upgrades_panel = PanelContainer.new()
	_upgrades_panel.name = "PlanetsMoonUpgradesPanel"
	_bottom_row.add_child(_upgrades_panel)

	var upgrades_margin := MarginContainer.new()
	upgrades_margin.name = "MoonUpgradesMargin"
	_upgrades_panel.add_child(upgrades_margin)

	var upgrades_content := VBoxContainer.new()
	upgrades_content.name = "MoonUpgradesContent"
	upgrades_margin.add_child(upgrades_content)

	_upgrades_header = Label.new()
	_upgrades_header.name = "MoonUpgradesHeader"
	upgrades_content.add_child(_upgrades_header)

	_upgrades_list = VBoxContainer.new()
	_upgrades_list.name = "MoonUpgradesList"
	upgrades_content.add_child(_upgrades_list)

	_preview_panel = PanelContainer.new()
	_preview_panel.name = "PlanetsPreviewPanel"
	_bottom_row.add_child(_preview_panel)

	var preview_margin := MarginContainer.new()
	preview_margin.name = "PlanetsPreviewMargin"
	_preview_panel.add_child(preview_margin)

	var preview_content := VBoxContainer.new()
	preview_content.name = "PlanetsPreviewContent"
	preview_margin.add_child(preview_content)

	_preview_header = Label.new()
	_preview_header.name = "PlanetsPreviewHeader"
	preview_content.add_child(_preview_header)

	_preview_frame = PanelContainer.new()
	_preview_frame.name = "PlanetsPreviewFrame"
	preview_content.add_child(_preview_frame)

	_preview_icon = TextureRect.new()
	_preview_icon.name = "PlanetsPreviewIcon"
	_preview_frame.add_child(_preview_icon)

	_preview_name = Label.new()
	_preview_name.name = "PlanetsPreviewName"
	preview_content.add_child(_preview_name)

	_preview_subtitle = Label.new()
	_preview_subtitle.name = "PlanetsPreviewSubtitle"
	preview_content.add_child(_preview_subtitle)

	_preview_stats = Label.new()
	_preview_stats.name = "PlanetsPreviewStats"
	preview_content.add_child(_preview_stats)

	_preview_costs = Label.new()
	_preview_costs.name = "PlanetsPreviewCosts"
	preview_content.add_child(_preview_costs)

	_action_button = Button.new()
	_action_button.name = "PlanetsActionButton"
	preview_content.add_child(_action_button)
	_action_button.pressed.connect(_on_unlock_pressed)

func _apply_layout() -> void:
	if _layout_root == null:
		return

	_layout_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_layout_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_layout_root.add_theme_constant_override("separation", UIMetrics.PLANETS_MENU_BOTTOM_SEPARATION)
	_info_label.visible = false
	_info_label.custom_minimum_size = Vector2.ZERO

	_tree_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree_panel.custom_minimum_size = Vector2(0.0, UIMetrics.PLANETS_MENU_TREE_MIN_HEIGHT)
	_tree_panel.add_theme_stylebox_override("panel", _make_panel_style(_color_from_hex(COLOR_SPACE_BG), _color_from_hex(COLOR_DIVIDER)))

	_tree_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_tree_canvas.custom_minimum_size = Vector2(0.0, UIMetrics.PLANETS_MENU_TREE_MIN_HEIGHT)

	_bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bottom_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bottom_row.add_theme_constant_override("separation", UIMetrics.PLANETS_MENU_BOTTOM_SEPARATION)
	_bottom_row.custom_minimum_size = Vector2(0.0, UIMetrics.PLANETS_MENU_BOTTOM_HEIGHT)

	_upgrades_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrades_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrades_panel.add_theme_stylebox_override("panel", _make_panel_style(_color_from_hex(COLOR_PANEL_BG), _color_from_hex(COLOR_DIVIDER)))

	_preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_panel.add_theme_stylebox_override("panel", _make_panel_style(_color_from_hex(COLOR_PANEL_BG), _color_from_hex(COLOR_DIVIDER)))

	var upgrades_margin := _upgrades_panel.get_node("MoonUpgradesMargin") as MarginContainer
	var preview_margin := _preview_panel.get_node("PlanetsPreviewMargin") as MarginContainer
	for margin in [upgrades_margin, preview_margin]:
		margin.add_theme_constant_override("margin_left", UIMetrics.PLANETS_MENU_PANEL_PADDING)
		margin.add_theme_constant_override("margin_top", UIMetrics.PLANETS_MENU_PANEL_PADDING)
		margin.add_theme_constant_override("margin_right", UIMetrics.PLANETS_MENU_PANEL_PADDING)
		margin.add_theme_constant_override("margin_bottom", UIMetrics.PLANETS_MENU_PANEL_PADDING)

	var upgrades_content := _upgrades_panel.get_node("MoonUpgradesMargin/MoonUpgradesContent") as VBoxContainer
	var preview_content := _preview_panel.get_node("PlanetsPreviewMargin/PlanetsPreviewContent") as VBoxContainer
	upgrades_content.add_theme_constant_override("separation", UIMetrics.PLANETS_MENU_UPGRADE_ROW_SPACING)
	preview_content.add_theme_constant_override("separation", UIMetrics.MENU_GRID_SPACING)

	_preview_frame.custom_minimum_size = UIMetrics.PLANETS_MENU_PLANET_PREVIEW_SIZE
	_preview_frame.add_theme_stylebox_override("panel", _make_panel_style(_color_from_hex(COLOR_PREVIEW_BG), _color_from_hex(COLOR_DIVIDER)))
	_preview_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_action_button.focus_mode = Control.FOCUS_NONE
	_action_button.custom_minimum_size = UIMetrics.PLANETS_MENU_RIGHT_BUTTON_SIZE

	for label in [_info_label, _upgrades_header, _preview_header, _preview_name, _preview_subtitle, _preview_stats, _preview_costs]:
		if label == null:
			continue
		_apply_label_font(label)
		label.add_theme_color_override("font_color", _color_from_hex(COLOR_TEXT))

	_preview_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_costs.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upgrades_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_name.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_TITLE)
	_preview_header.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	_upgrades_header.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	_preview_subtitle.add_theme_color_override("font_color", _color_from_hex(COLOR_TEXT_MUTED))
	_preview_costs.add_theme_color_override("font_color", _color_from_hex(COLOR_TEXT_MUTED))
	_apply_button_font(_action_button)

func _ensure_valid_selection(game_state: GameState, view_model: Dictionary) -> void:
	var visible_planets := view_model.get("planets", []) as Array
	var visible_planet_ids: Array[String] = []
	var first_owned_visible_planet := ""
	for planet_variant in visible_planets:
		if typeof(planet_variant) != TYPE_DICTIONARY:
			continue
		var planet_entry: Dictionary = planet_variant
		var planet_id := str(planet_entry.get("id", ""))
		if planet_id.is_empty():
			continue
		visible_planet_ids.append(planet_id)
		if first_owned_visible_planet.is_empty() and bool(planet_entry.get("owned", false)):
			first_owned_visible_planet = planet_id

	if _selected_planet_id.is_empty() or not visible_planet_ids.has(_selected_planet_id):
		var active_planet_id := game_state.current_planet_id
		if visible_planet_ids.has(active_planet_id):
			_selected_planet_id = active_planet_id
		elif not first_owned_visible_planet.is_empty():
			_selected_planet_id = first_owned_visible_planet
		elif not visible_planet_ids.is_empty():
			_selected_planet_id = visible_planet_ids[0]
		else:
			_selected_planet_id = ""

	if _selected_planet_id.is_empty():
		_selected_moon_id = ""
		return

	var selected_planet_entry := game_state.get_planet_menu_planet_entry(_selected_planet_id)
	var valid_moon_ids: Array[String] = []
	for moon_id_variant in selected_planet_entry.get("moon_ids", []):
		var moon_id := str(moon_id_variant)
		if moon_id.is_empty():
			continue
		valid_moon_ids.append(moon_id)

	if _selected_moon_id.is_empty() or not valid_moon_ids.has(_selected_moon_id):
		_selected_moon_id = "" if valid_moon_ids.is_empty() else valid_moon_ids[0]

func _refresh_tree(view_model: Dictionary) -> void:
	var current_visible_node_ids: Array[String] = ["root"]
	var line_entries: Array[Dictionary] = []
	var selected_planet := _game_state.get_planet_menu_planet_entry(_selected_planet_id)
	var selected_moon := _game_state.get_planet_menu_moon_entry(_selected_moon_id)
	var selected_planet_highlight := _color_from_hex(str(selected_planet.get("panel_accent_color", COLOR_NODE_PURCHASED)), _color_from_hex(COLOR_NODE_PURCHASED))
	var selected_moon_highlight := _color_from_hex(str(selected_moon.get("color", COLOR_NODE_PURCHASED)), _color_from_hex(COLOR_NODE_PURCHASED))

	for line_variant in view_model.get("lines", []):
		if typeof(line_variant) != TYPE_DICTIONARY:
			continue
		var line_entry: Dictionary = line_variant
		var from_id := str(line_entry.get("from_id", ""))
		var to_id := str(line_entry.get("to_id", ""))
		var color := _color_from_hex(COLOR_DIVIDER)
		var width := UIMetrics.PLANETS_MENU_LINE_WIDTH
		if from_id == "root" and to_id == _selected_planet_id:
			color = selected_planet_highlight
			width = UIMetrics.PLANETS_MENU_LINE_WIDTH_HIGHLIGHT
		elif from_id == _selected_planet_id and to_id == _selected_moon_id:
			color = selected_moon_highlight
			width = UIMetrics.PLANETS_MENU_LINE_WIDTH_HIGHLIGHT
		line_entries.append({
			"start": _normalized_to_tree_point(line_entry.get("from_position", {})),
			"end": _normalized_to_tree_point(line_entry.get("to_position", {})),
			"color": color,
			"width": width
		})
	_tree_canvas.set_line_entries(line_entries)

	var root_position := _normalized_to_tree_point(view_model.get("root_position", {}))
	_sync_tree_node("root", root_position, UIMetrics.PLANETS_MENU_NODE_ROOT_SIZE, _color_from_hex(COLOR_NODE_DEFAULT), false, false, true)

	for planet_variant in view_model.get("planets", []):
		if typeof(planet_variant) != TYPE_DICTIONARY:
			continue
		var planet_entry: Dictionary = planet_variant
		var planet_id := str(planet_entry.get("id", ""))
		if planet_id.is_empty():
			continue
		current_visible_node_ids.append(planet_id)
		var node_color := _resolve_planet_node_color(planet_entry)
		_sync_tree_node(
			planet_id,
			_normalized_to_tree_point(planet_entry.get("position", {})),
			UIMetrics.PLANETS_MENU_NODE_MEDIUM_SIZE,
			node_color,
			true,
			planet_id == _selected_planet_id,
			false
		)

	for moon_variant in view_model.get("moons", []):
		if typeof(moon_variant) != TYPE_DICTIONARY:
			continue
		var moon_entry: Dictionary = moon_variant
		var moon_id := str(moon_entry.get("id", ""))
		if moon_id.is_empty():
			continue
		current_visible_node_ids.append(moon_id)
		var moon_color := _resolve_moon_node_color(moon_entry)
		_sync_tree_node(
			moon_id,
			_normalized_to_tree_point(moon_entry.get("position", {})),
			UIMetrics.PLANETS_MENU_NODE_SMALL_SIZE,
			moon_color,
			true,
			moon_id == _selected_moon_id,
			false
		)
	_remove_stale_tree_nodes(current_visible_node_ids)
	if _has_refreshed_once:
		for node_id in current_visible_node_ids:
			if node_id == "root" or _last_visible_node_ids.has(node_id):
				continue
			_animate_reveal(_tree_node_buttons.get(node_id, null) as Control)

	_last_visible_node_ids = current_visible_node_ids

func _refresh_upgrade_panel(game_state: GameState) -> void:
	var moon_entry := game_state.get_planet_menu_moon_entry(_selected_moon_id)
	var moon_color := _color_from_hex(str(moon_entry.get("color", COLOR_NODE_DEFAULT)), _color_from_hex(COLOR_NODE_DEFAULT))
	_upgrades_header.text = "Moon Upgrades\n%s" % str(moon_entry.get("label", "Select a moon"))
	_upgrades_header.add_theme_color_override("font_color", moon_color.lightened(0.2))
	var active_button_keys: Array[String] = []
	var child_index := 0

	for upgrade_entry in game_state.get_moon_upgrade_entries(_selected_moon_id):

		var upgrade_id := str(upgrade_entry.get("id", ""))
		if upgrade_id.is_empty():
			continue
		var button_key := _get_upgrade_button_key(_selected_moon_id, upgrade_id)
		active_button_keys.append(button_key)
		var button := _upgrade_buttons.get(button_key, null) as Button
		if button == null:
			button = _create_upgrade_button(_selected_moon_id, upgrade_id)
		var rp_cost: DigitMaster = upgrade_entry.get("rp_cost", DigitMaster.zero())
		var locked := bool(upgrade_entry.get("locked", false))
		var purchased := bool(upgrade_entry.get("purchased", false))
		var can_purchase := bool(upgrade_entry.get("can_purchase", false))
		var state_text := "Locked"
		if purchased:
			state_text = "Purchased"
		elif can_purchase:
			state_text = "Purchase"
		elif not locked:
			state_text = "Need %s RP" % rp_cost.big_to_short_string()

		button.text = "%s\n%s | %s RP" % [
			str(upgrade_entry.get("name", upgrade_id)),
			state_text,
			rp_cost.big_to_short_string()
		]
		button.disabled = not can_purchase
		_apply_button_font(button)
		button.add_theme_color_override("font_color", _color_from_hex(COLOR_PREVIEW_BG))
		button.add_theme_color_override("font_disabled_color", _color_from_hex(COLOR_PREVIEW_BG).lightened(0.1))
		_apply_upgrade_button_style(button, moon_color, locked, purchased, can_purchase)
		_upgrades_list.move_child(button, child_index)
		child_index += 1

	_remove_stale_upgrade_buttons(active_button_keys)

func _refresh_preview_panel(game_state: GameState) -> void:
	var planet_entry := game_state.get_planet_menu_planet_entry(_selected_planet_id)
	var accent_color := _color_from_hex(str(planet_entry.get("panel_accent_color", COLOR_NODE_DEFAULT)), _color_from_hex(COLOR_NODE_DEFAULT))
	var owned := bool(planet_entry.get("owned", false))
	var sacrificed := bool(planet_entry.get("sacrificed", false))
	var can_purchase := bool(planet_entry.get("can_purchase", false))
	var is_placeholder := bool(planet_entry.get("is_placeholder", false))
	var purchase_unlocked := bool(planet_entry.get("purchase_unlocked", false))

	_preview_header.text = "Planet Unlock"
	_preview_header.add_theme_color_override("font_color", accent_color.lightened(0.15))
	_preview_name.text = str(planet_entry.get("preview_title", planet_entry.get("label", "Planet")))
	_preview_name.add_theme_color_override("font_color", accent_color.lightened(0.25))
	_preview_subtitle.text = str(planet_entry.get("preview_subtitle", ""))

	var level := int(planet_entry.get("level", 1))
	_preview_icon.texture = _icon_cache.get_planet_icon(str(planet_entry.get("id", "")), maxi(1, level))
	_preview_icon.modulate = Color(0.45, 0.45, 0.45, 1.0) if sacrificed else (Color.WHITE if owned else accent_color)

	var stats_lines: Array[String] = []
	if owned:
		stats_lines.append("Level: %d / %d" % [level, int(planet_entry.get("max_level", 0))])
		var workers: DigitMaster = planet_entry.get("workers", DigitMaster.zero())
		stats_lines.append("Workers: %s" % workers.big_to_short_string())
	elif sacrificed:
		stats_lines.append("State: Sacrificed")
		stats_lines.append("This planet is visible but inactive until repurchased.")
	elif is_placeholder:
		stats_lines.append("State: Future Content")
		stats_lines.append("This branch is visible for progression planning only.")
	elif purchase_unlocked:
		stats_lines.append("State: Unlock Available")
		stats_lines.append("Unlocking this planet does not switch the active world.")
	else:
		stats_lines.append("State: Locked")
		stats_lines.append("Complete earlier milestones to expose this branch.")
	if bool(planet_entry.get("is_current_active_planet", false)):
		stats_lines.append("Active World: Yes")
	else:
		stats_lines.append("Active World: No")
	_preview_stats.text = "\n".join(stats_lines)

	var cost_lines: Array[String] = []
	if not owned:
		for cost_entry in planet_entry.get("purchase_costs", []):
			if typeof(cost_entry) != TYPE_DICTIONARY:
				continue
			if bool(cost_entry.get("is_orb_requirement", false)):
				cost_lines.append("%s: %d" % [
					str(cost_entry.get("resource_name", "Orbs")),
					int(cost_entry.get("required_amount", 0))
				])
				continue
			var amount: DigitMaster = cost_entry.get("required_amount", DigitMaster.zero())
			cost_lines.append("%s: %s" % [
				str(cost_entry.get("resource_name", "")),
				amount.big_to_short_string()
			])
	_preview_costs.text = "" if cost_lines.is_empty() else "Costs\n%s" % "\n".join(cost_lines)

	_action_button.text = str(planet_entry.get("action_label", "Locked"))
	_action_button.disabled = not can_purchase
	_apply_action_button_style(_action_button, accent_color, owned, sacrificed, can_purchase)

func _sync_tree_node(
	node_id: String,
	center_position: Vector2,
	node_size: float,
	base_color: Color,
	clickable: bool,
	selected: bool,
	disabled: bool
) -> void:
	var button := _tree_node_buttons.get(node_id, null) as Button
	if button == null:
		button = _create_tree_node(node_id, clickable, disabled)
	button.disabled = disabled
	button.custom_minimum_size = Vector2(node_size, node_size)
	button.size = Vector2(node_size, node_size)
	button.position = Vector2(round(center_position.x - (node_size * 0.5)), round(center_position.y - (node_size * 0.5)))
	button.tooltip_text = node_id
	_apply_tree_node_style(button, base_color, node_size, selected, clickable and not disabled)

func _create_tree_node(node_id: String, clickable: bool, disabled: bool) -> Button:
	var button := Button.new()
	button.name = "Node_%s" % node_id
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.flat = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.disabled = disabled
	_tree_canvas.add_child(button)
	_tree_node_buttons[node_id] = button

	if not clickable or disabled:
		return button
	if node_id.begins_with("planet_"):
		button.gui_input.connect(_on_tree_node_gui_input.bind(node_id))
		button.pressed.connect(_on_planet_pressed.bind(node_id))
	else:
		button.gui_input.connect(_on_tree_node_gui_input.bind(node_id))
		button.pressed.connect(_on_moon_pressed.bind(node_id))
	return button

func _remove_stale_tree_nodes(active_node_ids: Array[String]) -> void:
	var stale_node_ids: Array[String] = []
	for node_id_variant in _tree_node_buttons.keys():
		var node_id := str(node_id_variant)
		if active_node_ids.has(node_id):
			continue
		stale_node_ids.append(node_id)

	for node_id in stale_node_ids:
		var button := _tree_node_buttons.get(node_id, null) as Button
		if is_instance_valid(button):
			button.queue_free()
		_tree_node_buttons.erase(node_id)

func _create_upgrade_button(moon_id: String, upgrade_id: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, UIMetrics.PLANETS_MENU_UPGRADE_ROW_MIN_HEIGHT)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_on_upgrade_pressed.bind(moon_id, upgrade_id))
	_apply_button_font(button)
	_upgrades_list.add_child(button)
	_upgrade_buttons[_get_upgrade_button_key(moon_id, upgrade_id)] = button
	return button

func _remove_stale_upgrade_buttons(active_button_keys: Array[String]) -> void:
	var stale_button_keys: Array[String] = []
	for button_key_variant in _upgrade_buttons.keys():
		var button_key := str(button_key_variant)
		if active_button_keys.has(button_key):
			continue
		stale_button_keys.append(button_key)

	for button_key in stale_button_keys:
		var button := _upgrade_buttons.get(button_key, null) as Button
		if is_instance_valid(button):
			button.queue_free()
		_upgrade_buttons.erase(button_key)

func _apply_tree_node_style(button: Button, base_color: Color, node_size: float, selected: bool, interactive: bool) -> void:
	var fill_color := base_color
	if selected:
		fill_color = fill_color.lightened(0.2)
	button.scale = Vector2.ONE * (1.12 if selected else 1.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW

	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = _color_from_hex(COLOR_DIVIDER)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	var radius := maxi(4, int(round(node_size * 0.5)))
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if interactive:
		style.shadow_color = fill_color.darkened(0.3)
		style.shadow_size = 2
	if selected:
		style.border_color = fill_color.lightened(0.2)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2

	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, style)

func _apply_upgrade_button_style(button: Button, accent_color: Color, locked: bool, purchased: bool, can_purchase: bool) -> void:
	var base_color := accent_color
	if purchased:
		base_color = _color_from_hex(COLOR_NODE_PURCHASED)
	elif locked:
		base_color = _color_from_hex(COLOR_NODE_LOCKED)
	elif not can_purchase:
		base_color = accent_color.darkened(0.15)

	var style := StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_color = accent_color.darkened(0.5)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	if purchased:
		style.shadow_color = base_color.lightened(0.1)
		style.shadow_size = 2
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, style)

func _apply_action_button_style(button: Button, accent_color: Color, owned: bool, sacrificed: bool, can_purchase: bool) -> void:
	var fill_color := _color_from_hex(COLOR_GOLD_BUTTON)
	if owned:
		fill_color = _color_from_hex(COLOR_NODE_PURCHASED)
	elif sacrificed:
		fill_color = _color_from_hex(COLOR_NODE_LOCKED)
	elif not can_purchase:
		fill_color = accent_color.darkened(0.35)

	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = fill_color.darkened(0.35)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, style)

	button.add_theme_color_override("font_color", _color_from_hex(COLOR_PREVIEW_BG))
	button.add_theme_color_override("font_disabled_color", _color_from_hex(COLOR_PREVIEW_BG).lightened(0.15))

func _make_panel_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = UIMetrics.PLANETS_MENU_PANEL_BORDER
	style.border_width_top = UIMetrics.PLANETS_MENU_PANEL_BORDER
	style.border_width_right = UIMetrics.PLANETS_MENU_PANEL_BORDER
	style.border_width_bottom = UIMetrics.PLANETS_MENU_PANEL_BORDER
	style.corner_radius_top_left = UIMetrics.PLANETS_MENU_PANEL_RADIUS
	style.corner_radius_top_right = UIMetrics.PLANETS_MENU_PANEL_RADIUS
	style.corner_radius_bottom_left = UIMetrics.PLANETS_MENU_PANEL_RADIUS
	style.corner_radius_bottom_right = UIMetrics.PLANETS_MENU_PANEL_RADIUS
	return style

func _apply_label_font(label: Label) -> void:
	if _ui_font != null:
		label.add_theme_font_override("font", _ui_font)
	label.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)

func _apply_button_font(button: Button) -> void:
	if _ui_font != null:
		button.add_theme_font_override("font", _ui_font)
	button.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)

func _normalized_to_tree_point(position_data: Variant) -> Vector2:
	var position_dict := position_data as Dictionary
	var inner_width := maxf(1.0, _tree_canvas.size.x - (UIMetrics.PLANETS_MENU_TREE_PADDING * 2.0))
	var inner_height := maxf(1.0, _tree_canvas.size.y - (UIMetrics.PLANETS_MENU_TREE_PADDING * 2.0))
	return Vector2(
		round(UIMetrics.PLANETS_MENU_TREE_PADDING + (float(position_dict.get("x", 0.5)) * inner_width)),
		round(UIMetrics.PLANETS_MENU_TREE_PADDING + (float(position_dict.get("y", 0.5)) * inner_height))
	)

func _resolve_planet_node_color(planet_entry: Dictionary) -> Color:
	if bool(planet_entry.get("owned", false)):
		return _color_from_hex(COLOR_NODE_PURCHASED)
	if bool(planet_entry.get("sacrificed", false)):
		return _color_from_hex(COLOR_NODE_LOCKED).lightened(0.08)
	if bool(planet_entry.get("purchase_unlocked", false)) and not bool(planet_entry.get("is_placeholder", false)):
		return _color_from_hex(COLOR_NODE_DEFAULT)
	return _color_from_hex(COLOR_NODE_LOCKED)

func _resolve_moon_node_color(moon_entry: Dictionary) -> Color:
	if bool(moon_entry.get("parent_owned", false)):
		return _color_from_hex(str(moon_entry.get("color", COLOR_NODE_DEFAULT)), _color_from_hex(COLOR_NODE_DEFAULT))
	return _color_from_hex(COLOR_NODE_LOCKED)

func _color_from_hex(hex: String, fallback: Color = Color.WHITE) -> Color:
	return Color.from_string(hex, fallback)

func _pulse_control(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2(0.9, 0.9), 0.06)
	tween.tween_property(control, "scale", Vector2.ONE * 1.1, 0.08)
	tween.tween_property(control, "scale", Vector2.ONE, 0.08)

func _animate_reveal(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var original_position := control.position
	control.modulate = Color(1, 1, 1, 0)
	control.position = original_position + Vector2(0, 8)
	var tween := control.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(control, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(control, "position", original_position, 0.18)

func _get_upgrade_button_key(moon_id: String, upgrade_id: String) -> String:
	return "%s::%s" % [moon_id, upgrade_id]

func _on_tree_node_gui_input(event: InputEvent, node_id: String) -> void:
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
		return
	if node_id.begins_with("planet_"):
		_on_planet_pressed(node_id)
		return
	_on_moon_pressed(node_id)

func _on_planet_pressed(planet_id: String) -> void:
	if _game_state == null:
		return
	_selected_planet_id = planet_id
	var planet_entry := _game_state.get_planet_menu_planet_entry(planet_id)
	var moon_ids := planet_entry.get("moon_ids", []) as Array
	_selected_moon_id = "" if moon_ids.is_empty() else str(moon_ids[0])
	planet_selected.emit(planet_id)
	refresh(_game_state)

func _on_moon_pressed(moon_id: String) -> void:
	if _game_state == null:
		return
	var moon_entry := _game_state.get_planet_menu_moon_entry(moon_id)
	_selected_planet_id = str(moon_entry.get("parent_planet_id", _selected_planet_id))
	_selected_moon_id = moon_id
	moon_selected.emit(moon_id)
	refresh(_game_state)

func _on_unlock_pressed() -> void:
	if _selected_planet_id.is_empty():
		return
	unlock_requested.emit(_selected_planet_id)

func _on_upgrade_pressed(moon_id: String, upgrade_id: String) -> void:
	moon_upgrade_requested.emit(moon_id, upgrade_id)
