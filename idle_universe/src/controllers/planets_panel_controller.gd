extends RefCounted

class_name PlanetsPanelController

signal select_requested(planet_id: String)
signal purchase_requested(planet_id: String)

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

var _panel: VBoxContainer
var _info_label: Label
var _list: VBoxContainer
var _ui_font: FontFile
var _planet_cards: Dictionary = {}
var _planet_title_labels: Dictionary = {}
var _planet_body_labels: Dictionary = {}
var _planet_action_buttons: Dictionary = {}
var _planet_action_modes: Dictionary = {}

func configure(panel: VBoxContainer, info_label: Label) -> void:
	_panel = panel
	_info_label = info_label
	_ui_font = UIFont.load_ui_font()

	_list = _panel.get_node_or_null("PlanetsCardList") as VBoxContainer
	if _list == null:
		_list = VBoxContainer.new()
		_list.name = "PlanetsCardList"
		_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_list.add_theme_constant_override("separation", UIMetrics.MENU_SECTION_LIST_SEPARATION)
		_panel.add_child(_list)

	_apply_info_style()

func refresh(game_state: GameState) -> void:
	if not _panel.visible or game_state == null:
		return

	_sync_planet_cards(game_state)
	_refresh_info(game_state)
	_refresh_cards(game_state)

func _apply_info_style() -> void:
	_info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_label.visible = true
	if _ui_font != null:
		_info_label.add_theme_font_override("font", _ui_font)
	_info_label.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	_info_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _sync_planet_cards(game_state: GameState) -> void:
	var planet_ids := game_state.get_planet_ids()
	if _planet_cards.size() == planet_ids.size():
		var ids_match := true
		for planet_id in planet_ids:
			if not _planet_cards.has(planet_id):
				ids_match = false
				break
		if ids_match:
			return

	for child in _list.get_children():
		child.queue_free()
	_planet_cards.clear()
	_planet_title_labels.clear()
	_planet_body_labels.clear()
	_planet_action_buttons.clear()
	_planet_action_modes.clear()

	for planet_id in planet_ids:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_list.add_child(card)
		_planet_cards[planet_id] = card

		var style := StyleBoxFlat.new()
		style.bg_color = Color8(36, 36, 36, 235)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color8(92, 124, 166)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		style.content_margin_left = 14
		style.content_margin_top = 12
		style.content_margin_right = 14
		style.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", style)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 8)
		card.add_child(content)

		var title_label := Label.new()
		title_label.text = planet_id
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _ui_font != null:
			title_label.add_theme_font_override("font", _ui_font)
		title_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_LARGE)
		title_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		content.add_child(title_label)
		_planet_title_labels[planet_id] = title_label

		var body_label := Label.new()
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _ui_font != null:
			body_label.add_theme_font_override("font", _ui_font)
		body_label.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
		body_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		content.add_child(body_label)
		_planet_body_labels[planet_id] = body_label

		var action_button := Button.new()
		action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_button.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
		action_button.focus_mode = Control.FOCUS_NONE
		if _ui_font != null:
			action_button.add_theme_font_override("font", _ui_font)
		action_button.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
		action_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		action_button.pressed.connect(_on_planet_action_pressed.bind(planet_id))
		content.add_child(action_button)
		_planet_action_buttons[planet_id] = action_button

func _refresh_info(game_state: GameState) -> void:
	var current_planet := game_state.get_current_planet_state()
	var current_planet_name := "None"
	if current_planet != null:
		current_planet_name = current_planet.name

	_info_label.text = "Owned planets persist through prestige.\nCurrent Planet: %s\nResearch Points: %s" % [
		current_planet_name,
		game_state.get_research_points().big_to_short_string()
	]

func _refresh_cards(game_state: GameState) -> void:
	for planet_entry in game_state.get_planet_entries():
		var planet_id := str(planet_entry.get("id", ""))
		if not _planet_body_labels.has(planet_id):
			continue

		var card: PanelContainer = _planet_cards[planet_id]
		var title_label: Label = _planet_title_labels[planet_id]
		var body_label: Label = _planet_body_labels[planet_id]
		var action_button: Button = _planet_action_buttons[planet_id]
		var owned := bool(planet_entry.get("owned", false))
		var selected := bool(planet_entry.get("selected", false))
		var purchase_unlocked := bool(planet_entry.get("purchase_unlocked", false))
		var can_purchase := bool(planet_entry.get("can_purchase", false))
		var level := int(planet_entry.get("level", 1))
		var costs: Array = planet_entry.get("purchase_costs", [])
		var purchase_cost_text := _get_purchase_cost_text(costs)
		title_label.text = str(planet_entry.get("name", planet_id))

		if owned:
			body_label.text = "Owned\nLevel: %d" % level
			action_button.text = "Current Planet" if selected else "Switch to %s" % str(planet_entry.get("name", planet_id))
			action_button.disabled = selected
			_planet_action_modes[planet_id] = "select"
			_apply_card_accent(card, Color8(84, 201, 124))
			continue

		if purchase_unlocked:
			body_label.text = "Available for purchase\nCost: %s" % purchase_cost_text
			action_button.text = "Buy %s" % str(planet_entry.get("name", planet_id))
			action_button.disabled = not can_purchase
			_planet_action_modes[planet_id] = "buy"
			_apply_card_accent(card, Color8(223, 178, 74))
			continue

		body_label.text = "Locked behind prestige milestones."
		action_button.text = "Locked"
		action_button.disabled = true
		_planet_action_modes[planet_id] = "locked"
		_apply_card_accent(card, Color8(104, 104, 104))

func _get_purchase_cost_text(costs: Array) -> String:
	if costs.is_empty():
		return "Free"

	var sections: Array[String] = []
	for cost_entry_variant in costs:
		if typeof(cost_entry_variant) != TYPE_DICTIONARY:
			continue
		var cost_entry: Dictionary = cost_entry_variant
		if bool(cost_entry.get("is_orb_requirement", false)):
			sections.append("%d Orbs" % int(cost_entry.get("required_amount", 0)))
			continue

		var required_amount: DigitMaster = cost_entry["required_amount"]
		sections.append("%s %s" % [
			required_amount.big_to_short_string(),
			str(cost_entry.get("resource_name", ""))
		])
	return ", ".join(sections)

func _apply_card_accent(card: PanelContainer, accent_color: Color) -> void:
	var flat_style := StyleBoxFlat.new()
	flat_style.bg_color = Color8(36, 36, 36, 235)
	flat_style.border_width_left = 2
	flat_style.border_width_top = 2
	flat_style.border_width_right = 2
	flat_style.border_width_bottom = 2
	flat_style.border_color = accent_color
	flat_style.corner_radius_top_left = 10
	flat_style.corner_radius_top_right = 10
	flat_style.corner_radius_bottom_left = 10
	flat_style.corner_radius_bottom_right = 10
	flat_style.content_margin_left = 14
	flat_style.content_margin_top = 12
	flat_style.content_margin_right = 14
	flat_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", flat_style)

func _on_planet_action_pressed(planet_id: String) -> void:
	if _planet_action_buttons[planet_id].disabled:
		return
	var action_mode := str(_planet_action_modes.get(planet_id, "locked"))
	if action_mode == "buy":
		purchase_requested.emit(planet_id)
	elif action_mode == "select":
		select_requested.emit(planet_id)
