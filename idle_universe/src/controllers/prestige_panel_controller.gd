extends RefCounted

class_name PrestigePanelController

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

var _panel: VBoxContainer
var _info_label: Label
var _milestones_label: Label
var _ui_font: FontFile

func configure(panel: VBoxContainer, info_label: Label) -> void:
	_panel = panel
	_info_label = info_label
	_ui_font = UIFont.load_ui_font()
	_milestones_label = _ensure_label("MilestonesLabel")

func refresh(game_state: GameState) -> void:
	if not _panel.visible or game_state == null:
		return

	var next_milestone := game_state.get_next_milestone()
	var next_title := "All current milestones complete."
	if not next_milestone.is_empty():
		next_title = str(next_milestone.get("title", next_title))

	_info_label.text = "Milestones track permanent progression. They no longer reset the run.\nNext Milestone: %s" % next_title
	_milestones_label.text = _build_milestones_text(game_state)

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
	var lines: Array[String] = ["Milestone Ladder"]
	for milestone in game_state.get_milestone_entries():
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
