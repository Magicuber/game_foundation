extends RefCounted

class_name BlessingsPanelController

signal open_requested

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

var _panel: VBoxContainer
var _info_label: Label
var _open_button: Button
var _scroll: ScrollContainer
var _section_list: VBoxContainer
var _ui_font: FontFile
var _section_cards: Dictionary = {}
var _name_labels: Dictionary = {}
var _level_labels: Dictionary = {}
var _summary_labels: Dictionary = {}

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
	if not _panel.visible or game_state == null:
		return

	_refresh_info(game_state)
	_refresh_open_button(game_state)
	_sync_sections(game_state)
	_refresh_cards(game_state)

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

func _sync_sections(game_state: GameState) -> void:
	if _section_list == null:
		return
	if not _section_cards.is_empty():
		return

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

			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cards_box.add_child(card)
			_section_cards[blessing_id] = card

			var margin := MarginContainer.new()
			margin.add_theme_constant_override("margin_left", 14)
			margin.add_theme_constant_override("margin_top", 12)
			margin.add_theme_constant_override("margin_right", 14)
			margin.add_theme_constant_override("margin_bottom", 12)
			card.add_child(margin)

			var content := VBoxContainer.new()
			content.add_theme_constant_override("separation", 6)
			margin.add_child(content)

			var top_row := HBoxContainer.new()
			top_row.add_theme_constant_override("separation", 10)
			content.add_child(top_row)

			var name_label := Label.new()
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.text = blessing.name
			name_label.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
			if _ui_font != null:
				name_label.add_theme_font_override("font", _ui_font)
			top_row.add_child(name_label)
			_name_labels[blessing_id] = name_label

			var level_label := Label.new()
			level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			level_label.text = blessing.get_level_label()
			level_label.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
			if _ui_font != null:
				level_label.add_theme_font_override("font", _ui_font)
			top_row.add_child(level_label)
			_level_labels[blessing_id] = level_label

			var summary_label := Label.new()
			summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			summary_label.text = blessing.get_summary()
			summary_label.add_theme_font_size_override("font_size", UIMetrics.CURRENCY_DISPLAY_FONT_SIZE)
			if _ui_font != null:
				summary_label.add_theme_font_override("font", _ui_font)
			content.add_child(summary_label)
			_summary_labels[blessing_id] = summary_label

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

func _refresh_cards(game_state: GameState) -> void:
	for blessing_id in _section_cards.keys():
		var blessing = game_state.get_blessing_state(str(blessing_id))
		if blessing == null:
			continue

		var accent: Color = blessing.get_color()
		var card: PanelContainer = _section_cards[blessing_id]
		var style := StyleBoxFlat.new()
		style.bg_color = accent.darkened(0.7)
		style.bg_color.a = 1.0
		style.border_color = accent
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_right = 10
		style.corner_radius_bottom_left = 10
		card.add_theme_stylebox_override("panel", style)

		var title_color: Color = Color.WHITE if blessing.level > 0 else accent.lightened(0.2)
		var detail_color := Color(1, 1, 1, 0.9) if blessing.level > 0 else Color(1, 1, 1, 0.72)
		_name_labels[blessing_id].text = blessing.name
		_name_labels[blessing_id].add_theme_color_override("font_color", title_color)
		_level_labels[blessing_id].text = blessing.get_level_label()
		_level_labels[blessing_id].add_theme_color_override("font_color", title_color)
		_summary_labels[blessing_id].text = blessing.get_summary()
		_summary_labels[blessing_id].add_theme_color_override("font_color", detail_color)

func _on_open_pressed() -> void:
	open_requested.emit()
