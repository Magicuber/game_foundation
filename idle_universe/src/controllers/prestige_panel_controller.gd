extends RefCounted

class_name PrestigePanelController

signal prestige_requested
signal claim_node_requested

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

var _panel: VBoxContainer
var _info_label: Label
var _prestige_button: Button
var _claim_button: Button
var _milestones_label: Label
var _nodes_label: Label
var _ui_font: FontFile

func configure(panel: VBoxContainer, info_label: Label) -> void:
	_panel = panel
	_info_label = info_label
	_ui_font = UIFont.load_ui_font()

	_prestige_button = _ensure_button("PerformPrestigeButton", "Prestige Reset")
	_claim_button = _ensure_button("ClaimPrestigeNodeButton", "Claim Next Node")
	_milestones_label = _ensure_label("PrestigeMilestonesLabel")
	_nodes_label = _ensure_label("PrestigeNodesLabel")

	_prestige_button.pressed.connect(_on_prestige_pressed)
	_claim_button.pressed.connect(_on_claim_pressed)

func refresh(game_state: GameState) -> void:
	if not _panel.visible or game_state == null:
		return

	var preview := game_state.get_prestige_preview()
	var milestone: Dictionary = preview.get("milestone", {})
	var milestone_title := "No further milestones"
	if not milestone.is_empty():
		milestone_title = str(milestone.get("title", milestone_title))

	_info_label.text = "Prestige Points: %d total | %d unspent\nNext Milestone: %s\nProgress: %s\nReward: +%d Prestige Point\nReset: Atomic resources, upgrades, dust, RP, and temporary planet progress." % [
		game_state.prestige_points_total,
		game_state.prestige_points_unspent,
		milestone_title,
		game_state._get_milestone_progress_text(milestone),
		int(preview.get("reward_points", 0))
	]

	_prestige_button.disabled = not bool(preview.get("can_prestige", false))
	_prestige_button.text = "Perform Prestige" if not milestone.is_empty() else "No Prestige Available"

	var next_node: Dictionary = preview.get("next_node", {})
	var next_node_title := "No further nodes"
	if not next_node.is_empty():
		next_node_title = str(next_node.get("title", next_node_title))
	if bool(next_node.get("future_locked", false)):
		_claim_button.text = "%s (Future)" % next_node_title
	else:
		_claim_button.text = "Claim %s" % next_node_title
	_claim_button.disabled = not bool(preview.get("can_claim_node", false))

	_milestones_label.text = _build_milestones_text(game_state)
	_nodes_label.text = _build_nodes_text(game_state)

func _ensure_button(button_name: String, button_text: String) -> Button:
	var button := _panel.get_node_or_null(button_name) as Button
	if button == null:
		button = Button.new()
		button.name = button_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
		button.focus_mode = Control.FOCUS_NONE
		_panel.add_child(button)
		_panel.move_child(button, _panel.get_child_count() - 1)
	button.text = button_text
	if _ui_font != null:
		button.add_theme_font_override("font", _ui_font)
	button.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	return button

func _ensure_label(label_name: String) -> Label:
	var label := _panel.get_node_or_null(label_name) as Label
	if label == null:
		label = Label.new()
		label.name = label_name
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_panel.add_child(label)
	if _ui_font != null:
		label.add_theme_font_override("font", _ui_font)
	label.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	return label

func _build_milestones_text(game_state: GameState) -> String:
	var lines: Array[String] = ["Milestones"]
	for milestone in game_state.get_prestige_milestone_entries():
		var prefix := "[ ]"
		if bool(milestone.get("completed", false)):
			prefix = "[x]"
		elif bool(milestone.get("current", false)):
			prefix = "[>]"
		lines.append("%s %s | %s" % [
			prefix,
			str(milestone.get("title", "")),
			str(milestone.get("progress_text", ""))
		])
	return "\n".join(lines)

func _build_nodes_text(game_state: GameState) -> String:
	var lines: Array[String] = ["Fixed Node Path"]
	for node in game_state.get_prestige_node_entries():
		var prefix := "[ ]"
		if bool(node.get("claimed", false)):
			prefix = "[x]"
		elif bool(node.get("current", false)):
			prefix = "[>]"
		var suffix := ""
		if bool(node.get("future_locked", false)):
			suffix = " (Future)"
		lines.append("%s %s%s" % [
			prefix,
			str(node.get("title", "")),
			suffix
		])
	return "\n".join(lines)

func _on_prestige_pressed() -> void:
	prestige_requested.emit()

func _on_claim_pressed() -> void:
	claim_node_requested.emit()
