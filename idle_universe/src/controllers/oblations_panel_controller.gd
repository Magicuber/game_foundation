extends RefCounted

class_name OblationsPanelController

signal oblation_confirm_requested(recipe_id: String, selected_inputs: Dictionary)

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

var _panel: VBoxContainer
var _info_label: Label
var _ui_font: FontFile
var _game_state: GameState
var _selected_recipe_id := ""
var _selected_inputs: Dictionary = {}

var _recipe_buttons: Dictionary = {}
var _slot_buttons: Dictionary = {}
var _recipe_list: VBoxContainer
var _slots_label: Label
var _slots_list: VBoxContainer
var _preview_label: Label
var _confirm_button: Button

func configure(panel: VBoxContainer, info_label: Label) -> void:
	_panel = panel
	_info_label = info_label
	_ui_font = UIFont.load_ui_font()
	_recipe_list = _ensure_vbox("OblationRecipeList")
	_slots_label = _ensure_label("OblationSlotsLabel")
	_slots_list = _ensure_vbox("OblationSlotsList")
	_preview_label = _ensure_label("OblationPreviewLabel")
	_confirm_button = _ensure_button("OblationConfirmButton", "Confirm Oblation")
	_confirm_button.pressed.connect(_on_confirm_pressed)

func refresh(game_state: GameState) -> void:
	if not _panel.visible or game_state == null:
		return
	_game_state = game_state

	var entries: Array[Dictionary] = game_state.get_oblation_recipe_entries()
	_ensure_valid_selection(entries)
	_refresh_recipe_buttons(entries)
	_refresh_slot_buttons(game_state)
	_refresh_preview(game_state)

func _ensure_valid_selection(entries: Array[Dictionary]) -> void:
	var visible_recipe_ids: Array[String] = []
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY or not bool(entry.get("visible", false)):
			continue
		visible_recipe_ids.append(str(entry.get("id", "")))
	if _selected_recipe_id.is_empty() or not visible_recipe_ids.has(_selected_recipe_id):
		_selected_recipe_id = "" if visible_recipe_ids.is_empty() else visible_recipe_ids[0]
		_selected_inputs.clear()

func _refresh_recipe_buttons(entries: Array[Dictionary]) -> void:
	var active_ids: Array[String] = []
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY or not bool(entry.get("visible", false)):
			continue
		var recipe_id: String = str(entry.get("id", ""))
		active_ids.append(recipe_id)
		var button: Button = _recipe_buttons.get(recipe_id, null) as Button
		if button == null:
			button = _create_button(recipe_id)
			button.pressed.connect(_on_recipe_selected.bind(recipe_id))
			_recipe_buttons[recipe_id] = button
			_recipe_list.add_child(button)
		button.text = "%s\n%s\n%s" % [
			str(entry.get("title", recipe_id)),
			str(entry.get("description", "")),
			str(entry.get("locked_reason", entry.get("effect_text", "")))
		]
		button.disabled = bool(entry.get("claimed", false))
		button.button_pressed = recipe_id == _selected_recipe_id
	for existing_id in _recipe_buttons.keys():
		var recipe_id := str(existing_id)
		if active_ids.has(recipe_id):
			continue
		var stale_button: Button = _recipe_buttons[recipe_id] as Button
		if is_instance_valid(stale_button):
			stale_button.queue_free()
		_recipe_buttons.erase(recipe_id)

func _refresh_slot_buttons(game_state: GameState) -> void:
	for child in _slots_list.get_children():
		child.queue_free()
	_slot_buttons.clear()
	if _selected_recipe_id.is_empty():
		_slots_label.text = "Selections"
		return
	var recipe: Dictionary = game_state.oblation_manager.get_recipe_by_id(_selected_recipe_id)
	_slots_label.text = "Selections"
	for slot_variant in recipe.get("slots", []):
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		var slot_id: String = str(slot.get("id", ""))
		var slot_label: Label = Label.new()
		_style_label(slot_label)
		slot_label.text = str(slot.get("label", slot_id))
		_slots_list.add_child(slot_label)
		for option in game_state.get_oblation_slot_options(_selected_recipe_id, slot_id):
			var option_id: String = str(option.get("id", ""))
			var button: Button = _create_button("%s::%s" % [slot_id, option_id])
			button.text = str(option.get("label", option_id))
			button.disabled = not bool(option.get("available", false))
			button.button_pressed = str(_selected_inputs.get(slot_id, "")) == option_id
			button.pressed.connect(_on_slot_selected.bind(slot_id, option_id))
			_slots_list.add_child(button)
			_slot_buttons["%s::%s" % [slot_id, option_id]] = button

func _refresh_preview(game_state: GameState) -> void:
	if not game_state.is_oblation_menu_unlocked():
		_info_label.text = "Complete Planet A level 5 to unlock Oblations."
		_preview_label.text = ""
		_confirm_button.disabled = true
		return
	if _selected_recipe_id.is_empty():
		_info_label.text = "Select an Oblation recipe."
		_preview_label.text = ""
		_confirm_button.disabled = true
		return
	_info_label.text = "Select sacrifices and confirm to gain persistent bonuses."
	var preview: Dictionary = game_state.get_oblation_preview(_selected_recipe_id, _selected_inputs)
	var summary_lines: Array[String] = []
	for line in preview.get("selected_summary", []):
		summary_lines.append(str(line))
	var issues: Array[String] = []
	for issue in preview.get("issues", []):
		issues.append(str(issue))
	_preview_label.text = "%s\n\nSelections\n%s\n\nStatus\n%s" % [
		str(preview.get("effect_text", "")),
		"\n".join(summary_lines),
		"\n".join(issues)
	]
	_confirm_button.disabled = not bool(preview.get("can_confirm", false))

func _create_button(button_name: String) -> Button:
	var button: Button = Button.new()
	button.name = button_name
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	if _ui_font != null:
		button.add_theme_font_override("font", _ui_font)
	button.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	return button

func _ensure_vbox(name: String) -> VBoxContainer:
	var node: VBoxContainer = _panel.get_node_or_null(name) as VBoxContainer
	if node == null:
		node = VBoxContainer.new()
		node.name = name
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.add_theme_constant_override("separation", 6)
		_panel.add_child(node)
	return node

func _ensure_label(name: String) -> Label:
	var node: Label = _panel.get_node_or_null(name) as Label
	if node == null:
		node = Label.new()
		node.name = name
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_panel.add_child(node)
	_style_label(node)
	return node

func _ensure_button(name: String, text_value: String) -> Button:
	var node: Button = _panel.get_node_or_null(name) as Button
	if node == null:
		node = Button.new()
		node.name = name
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.focus_mode = Control.FOCUS_NONE
		node.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
		_panel.add_child(node)
	if _ui_font != null:
		node.add_theme_font_override("font", _ui_font)
	node.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	node.text = text_value
	return node

func _style_label(label: Label) -> void:
	if _ui_font != null:
		label.add_theme_font_override("font", _ui_font)
	label.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _on_slot_selected(slot_id: String, option_id: String) -> void:
	_selected_inputs[slot_id] = option_id
	if _game_state != null:
		refresh(_game_state)

func _on_recipe_selected(recipe_id: String) -> void:
	_selected_recipe_id = recipe_id
	_selected_inputs.clear()
	if _game_state != null:
		refresh(_game_state)

func _on_confirm_pressed() -> void:
	if _selected_recipe_id.is_empty():
		return
	oblation_confirm_requested.emit(_selected_recipe_id, _selected_inputs.duplicate(true))
