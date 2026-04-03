extends RefCounted

class_name ElementMenuController

signal element_pressed(element_id: String)
signal unlock_requested
signal make_dust_requested
signal dust_close_requested

const UIMetrics = preload("res://src/ui/ui_metrics.gd")
const ELEMENT_MENU_SECTIONS := [
	{"title": "1-10", "start": 1, "end": 10, "columns": 5},
	{"title": "11-30", "start": 11, "end": 30, "columns": 5},
	{"title": "31-54", "start": 31, "end": 54, "columns": 6},
	{"title": "55-86", "start": 55, "end": 86, "columns": 8},
	{"title": "87-118", "start": 87, "end": 118, "columns": 8}
]

var _panel: VBoxContainer
var _info_label: Label
var _section_list: VBoxContainer
var _unlock_button: Button
var _make_dust_button: TextureButton
var _make_dust_label: Label
var _dust_close_button: TextureButton
var _enabled_button_modulate := Color(1, 1, 1, 1)
var _disabled_button_modulate := Color(0.45, 0.45, 0.45, 1.0)
var _visible_section_count := -1
var _element_menu_tiles: Dictionary = {}

func configure(
	panel: VBoxContainer,
	info_label: Label,
	section_list: VBoxContainer,
	unlock_button: Button,
	make_dust_button: TextureButton,
	make_dust_label: Label,
	dust_close_button: TextureButton,
	enabled_button_modulate: Color,
	disabled_button_modulate: Color
) -> void:
	_panel = panel
	_info_label = info_label
	_section_list = section_list
	_unlock_button = unlock_button
	_make_dust_button = make_dust_button
	_make_dust_label = make_dust_label
	_dust_close_button = dust_close_button
	_enabled_button_modulate = enabled_button_modulate
	_disabled_button_modulate = disabled_button_modulate

	_unlock_button.focus_mode = Control.FOCUS_NONE
	_make_dust_button.focus_mode = Control.FOCUS_NONE
	_dust_close_button.focus_mode = Control.FOCUS_NONE
	_unlock_button.pressed.connect(_on_unlock_pressed)
	_make_dust_button.pressed.connect(_on_make_dust_pressed)
	_dust_close_button.pressed.connect(_on_dust_close_pressed)

func refresh(
	game_state: GameState,
	upgrades_system: UpgradesSystem,
	dust_recipe_service: DustRecipeService,
	dust_mode_active: bool,
	debug_show_element_hitboxes: bool
) -> void:
	if not _panel.visible:
		return

	_sync_tiles(game_state, dust_recipe_service, dust_mode_active, debug_show_element_hitboxes)

	var current_element: Dictionary = game_state.get_current_element()
	var current_name := str(current_element.get("name", ""))
	var produced_name := game_state.get_resource_name(str(current_element.get("produces", "")))
	var next_unlock: Dictionary = game_state.get_next_unlock_element()
	var dust_preview := DigitMaster.zero()
	var selected_batch_count := 0
	if dust_mode_active:
		dust_preview = dust_recipe_service.get_preview(game_state, upgrades_system)
		selected_batch_count = dust_recipe_service.get_selected_element_ids(game_state, upgrades_system).size()

	if next_unlock.is_empty():
		if dust_mode_active:
			_info_label.text = "Dust Mode\nSelected Elements: %d\nPredicted Dust: %s" % [
				selected_batch_count,
				dust_preview.big_to_short_string()
			]
		else:
			_info_label.text = "Selected: %s\nAll elements unlocked." % current_name
		_unlock_button.text = "All elements unlocked"
		_unlock_button.disabled = true
		_unlock_button.visible = false
	else:
		var unlock_id := str(next_unlock.get("id", ""))
		var unlock_cost: DigitMaster = next_unlock["cost"]
		if not game_state.is_next_unlock_within_visible_sections():
			if dust_mode_active:
				_info_label.text = "Dust Mode\nSelected Elements: %d\nPredicted Dust: %s" % [
					selected_batch_count,
					dust_preview.big_to_short_string()
				]
			else:
				_info_label.text = "Selected: %s\nProduces: %s\nNext section is locked." % [
					current_name,
					produced_name
				]
			_unlock_button.text = "Next section locked"
			_unlock_button.disabled = true
			_unlock_button.visible = false
		else:
			if dust_mode_active:
				_info_label.text = "Dust Mode\nSelected Elements: %d\nPredicted Dust: %s" % [
					selected_batch_count,
					dust_preview.big_to_short_string()
				]
			else:
				_info_label.text = "Selected: %s\nProduces: %s\nNext: %s\nRequires: %s %s" % [
					current_name,
					produced_name,
					str(next_unlock.get("name", unlock_id)),
					unlock_cost.big_to_short_string(),
					game_state.get_resource_name(unlock_id)
				]
			_unlock_button.text = "Unlock %s" % str(next_unlock.get("name", unlock_id))
			_unlock_button.disabled = not game_state.can_unlock_next()
			_unlock_button.visible = true
		if dust_mode_active:
			_unlock_button.disabled = true

	_make_dust_button.visible = true
	_dust_close_button.visible = dust_mode_active
	_make_dust_label.text = "MAKE DUST"
	if dust_mode_active:
		_make_dust_label.text = "%s DUST" % dust_preview.big_to_short_string()
	_make_dust_button.disabled = dust_mode_active and dust_preview.is_zero()
	_make_dust_button.modulate = _enabled_button_modulate if not _make_dust_button.disabled else _disabled_button_modulate
	_dust_close_button.modulate = _enabled_button_modulate

func refresh_debug_hitboxes(is_visible: bool) -> void:
	for element_id in _element_menu_tiles.keys():
		var tile: ElementMenuTile = _element_menu_tiles[element_id]
		tile.set_debug_hitbox_visible(is_visible)

func _get_visible_section_count(game_state: GameState) -> int:
	return clampi(game_state.prestige_count + 1, 1, ELEMENT_MENU_SECTIONS.size())

func _sync_tiles(
	game_state: GameState,
	dust_recipe_service: DustRecipeService,
	dust_mode_active: bool,
	debug_show_element_hitboxes: bool
) -> void:
	var section_count := _get_visible_section_count(game_state)
	if _visible_section_count != section_count:
		for child in _section_list.get_children():
			child.queue_free()

		_element_menu_tiles.clear()
		_visible_section_count = section_count

		for section_index in range(section_count):
			var section_data: Dictionary = ELEMENT_MENU_SECTIONS[section_index]
			var section_box := VBoxContainer.new()
			section_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			section_box.add_theme_constant_override("separation", UIMetrics.MENU_SECTION_BOX_SEPARATION)
			_section_list.add_child(section_box)

			var header := Label.new()
			header.text = str(section_data.get("title", ""))
			header.add_theme_font_size_override("font_size", UIMetrics.MENU_SECTION_HEADER_FONT_SIZE)
			header.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			var ui_font: FontFile = UIFont.load_ui_font()
			if ui_font != null:
				header.add_theme_font_override("font", ui_font)
			section_box.add_child(header)

			var grid := GridContainer.new()
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.columns = int(section_data.get("columns", 5))
			grid.add_theme_constant_override("h_separation", UIMetrics.MENU_GRID_SPACING)
			grid.add_theme_constant_override("v_separation", UIMetrics.MENU_GRID_SPACING)
			section_box.add_child(grid)

			var section_start := int(section_data.get("start", 1))
			var section_end := int(section_data.get("end", 1))
			for atomic_index in range(section_start, section_end + 1):
				var element: Dictionary = game_state.get_element_by_index(atomic_index)
				if element.is_empty():
					continue
				var element_id := str(element.get("id", ""))
				var tile := ElementMenuTile.new()
				tile.configure(game_state, element_id)
				tile.element_pressed.connect(_on_tile_pressed)
				grid.add_child(tile)
				_element_menu_tiles[element_id] = tile

	for element_id in _element_menu_tiles.keys():
		var tile: ElementMenuTile = _element_menu_tiles[element_id]
		var dust_fraction := 0.0
		if dust_mode_active:
			dust_fraction = dust_recipe_service.get_selection_fraction(element_id)
		tile.refresh(game_state.current_element_id, dust_fraction)
		tile.set_debug_hitbox_visible(debug_show_element_hitboxes)

func _on_tile_pressed(element_id: String) -> void:
	element_pressed.emit(element_id)

func _on_unlock_pressed() -> void:
	unlock_requested.emit()

func _on_make_dust_pressed() -> void:
	make_dust_requested.emit()

func _on_dust_close_pressed() -> void:
	dust_close_requested.emit()
