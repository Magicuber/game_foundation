extends RefCounted

class_name BlessingsPanelController

signal open_requested

const UIMetrics = preload("res://src/ui/ui_metrics.gd")
const BlessingCatalogRowScript = preload("res://src/ui/blessing_catalog_row.gd")

var _panel: VBoxContainer
var _info_label: Label
var _open_button: Button
var _scroll: ScrollContainer
var _section_list: VBoxContainer
var _ui_font: FontFile
var _section_rows: Dictionary = {}
var _catalog_built := false

func configure(panel: VBoxContainer, info_label: Label) -> void:
	_panel = panel
	_info_label = info_label
	_ui_font = UIFont.load_ui_font()

	_open_button = _panel.get_node_or_null("OpenBlessingsButton") as Button
	if _open_button == null:
		_open_button = Button.new()
		_open_button.name = "OpenBlessingsButton"
		_open_button.text = "Open Blessings"
		_panel.add_child(_open_button)
		_panel.move_child(_open_button, 2)

	_scroll = _panel.get_node_or_null("BlessingsScroll") as ScrollContainer
	if _scroll == null:
		_scroll = ScrollContainer.new()
		_scroll.name = "BlessingsScroll"
		_panel.add_child(_scroll)

	_section_list = _scroll.get_node_or_null("BlessingsSectionList") as VBoxContainer
	if _section_list == null:
		_section_list = VBoxContainer.new()
		_section_list.name = "BlessingsSectionList"
		_scroll.add_child(_section_list)

	_apply_layout()

func refresh(game_state: GameState) -> void:
	refresh_progress(game_state)
	refresh_catalog(game_state)

func refresh_progress(game_state: GameState) -> void:
	if not _is_visible(game_state):
		return

	_refresh_info(game_state)
	_refresh_open_button(game_state)

func refresh_catalog(game_state: GameState, changed_blessing_ids: Array[String] = []) -> void:
	if not _is_visible(game_state):
		return

	_ensure_catalog(game_state)
	if changed_blessing_ids.is_empty():
		for blessing_id_variant in _section_rows.keys():
			_refresh_row(game_state, str(blessing_id_variant))
		return

	for blessing_id in changed_blessing_ids:
		_refresh_row(game_state, blessing_id)

func _apply_layout() -> void:
	if _open_button == null or _scroll == null or _section_list == null:
		return

	_open_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_open_button.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
	_open_button.focus_mode = Control.FOCUS_NONE
	_open_button.pressed.connect(_on_open_pressed)
	if _ui_font != null:
		_open_button.add_theme_font_override("font", _ui_font)
	_open_button.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	_open_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.visible = true
	_section_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_section_list.add_theme_constant_override("separation", UIMetrics.MENU_SECTION_LIST_SEPARATION)

func _ensure_catalog(game_state: GameState) -> void:
	if _section_list == null:
		return
	if _catalog_built:
		return
	_catalog_built = true

	for rarity in game_state.get_blessing_rarity_order():
		var section_box := VBoxContainer.new()
		section_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section_box.add_theme_constant_override("separation", UIMetrics.MENU_SECTION_BOX_SEPARATION)
		_section_list.add_child(section_box)

		var header := Label.new()
		header.text = "%s  [%s]" % [
			rarity,
			game_state.get_blessing_rarity_roll_display(rarity)
		]
		header.add_theme_font_size_override("font_size", UIMetrics.MENU_SECTION_HEADER_FONT_SIZE)
		header.add_theme_color_override("font_color", game_state.get_blessing_rarity_color(rarity))
		if _ui_font != null:
			header.add_theme_font_override("font", _ui_font)
		section_box.add_child(header)

		var cards_box := VBoxContainer.new()
		cards_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cards_box.add_theme_constant_override("separation", UIMetrics.MENU_GRID_SPACING)
		section_box.add_child(cards_box)

		for blessing_id in game_state.get_blessing_ids_for_rarity(rarity):
			var blessing = game_state.get_blessing_state(blessing_id)
			if blessing == null:
				continue

			var row = BlessingCatalogRowScript.new()
			row.configure(blessing_id, _ui_font)
			cards_box.add_child(row)
			_section_rows[blessing_id] = row

func _refresh_info(game_state: GameState) -> void:
	var blessing_progress := game_state.get_blessing_progress_mass()
	var next_blessing_cost := game_state.get_next_blessing_cost()
	_info_label.text = "Open earned blessings here, then review the full catalog below.\nBlessings Earned: %d\nNext Blessing: %s / %s mass" % [
		game_state.blessings_count,
		blessing_progress.big_to_short_string(),
		next_blessing_cost.big_to_short_string()
	]

func _refresh_open_button(game_state: GameState) -> void:
	var unopened_count := game_state.get_unopened_blessings_count()
	_open_button.visible = true
	_open_button.disabled = unopened_count <= 0
	_open_button.text = "Open Blessings" if unopened_count <= 0 else "Open Blessings (%d)" % unopened_count

func _refresh_row(game_state: GameState, blessing_id: String) -> void:
	if not _section_rows.has(blessing_id):
		return

	var blessing = game_state.get_blessing_state(blessing_id)
	if blessing == null:
		return

	var row = _section_rows[blessing_id]
	row.refresh_from_state(blessing)

func _on_open_pressed() -> void:
	open_requested.emit()

func _is_visible(game_state: GameState) -> bool:
	return _panel != null and _panel.visible and game_state != null
