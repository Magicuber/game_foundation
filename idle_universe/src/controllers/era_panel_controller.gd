extends RefCounted

class_name EraPanelController

signal unlock_requested

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

var _panel: Control
var _timeline: TextureRect
var _title_label: Label
var _status_label: Label
var _requirement_card: PanelContainer
var _requirement_title: Label
var _requirement_list: VBoxContainer
var _unlock_button: Button
var _icon_cache: GameIconCache
var _requirement_labels: Array[Label] = []

func configure(
	panel: Control,
	timeline: TextureRect,
	title_label: Label,
	status_label: Label,
	requirement_card: PanelContainer,
	requirement_title: Label,
	requirement_list: VBoxContainer,
	unlock_button: Button,
	icon_cache: GameIconCache
) -> void:
	_panel = panel
	_timeline = timeline
	_title_label = title_label
	_status_label = status_label
	_requirement_card = requirement_card
	_requirement_title = requirement_title
	_requirement_list = requirement_list
	_unlock_button = unlock_button
	_icon_cache = icon_cache

	_timeline.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_timeline.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_timeline.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_timeline.custom_minimum_size = Vector2(0.0, UIMetrics.ERA_TIMELINE_MIN_HEIGHT)
	_title_label.visible = false
	_status_label.visible = false
	_unlock_button.focus_mode = Control.FOCUS_NONE
	_unlock_button.pressed.connect(_on_unlock_pressed)
	_ensure_requirement_labels()

func refresh(game_state: GameState) -> void:
	if not _panel.visible:
		return

	var unlocked_era_index := game_state.get_unlocked_era_index()
	_timeline.texture = _icon_cache.get_era_frame(unlocked_era_index)
	update_layout()

	if not game_state.is_era_menu_unlocked():
		_requirement_title.text = "Era Menu Locked"
		_set_requirement_labels_hidden()
		_unlock_button.visible = false
		_apply_requirement_card_style(0)
		return

	var next_era_index := game_state.get_next_implemented_era_index()
	if next_era_index < 0:
		var current_era_name := game_state.get_era_name(unlocked_era_index)
		_requirement_title.text = "%s Unlocked" % current_era_name
		_set_requirement_labels_hidden()
		_unlock_button.visible = false
		_apply_requirement_card_style(unlocked_era_index)
		return

	var next_era_name := game_state.get_era_name(next_era_index)
	_requirement_title.text = "Next Era: %s" % next_era_name
	var requirements: Array[Dictionary] = game_state.get_next_era_requirements()
	for label_index in range(_requirement_labels.size()):
		var label := _requirement_labels[label_index]
		if label_index >= requirements.size():
			label.visible = false
			label.text = ""
			continue

		var requirement: Dictionary = requirements[label_index]
		label.visible = true
		if bool(requirement.get("is_orb_requirement", false)):
			var required_orbs := int(requirement.get("required_amount", 0))
			label.text = "%s: %s / %s" % [
				str(requirement.get("resource_name", "Orbs")),
				str(game_state.orbs),
				str(required_orbs)
			]
			continue

		var resource_id := str(requirement.get("resource_id", ""))
		var required_amount: DigitMaster = requirement["required_amount"]
		label.text = "%s: %s / %s" % [
			str(requirement.get("resource_name", resource_id)),
			game_state.get_resource_amount(resource_id).big_to_short_string(),
			required_amount.big_to_short_string()
		]

	_unlock_button.visible = true
	_unlock_button.text = "Unlock %s" % next_era_name
	_unlock_button.disabled = not game_state.can_unlock_next_era()
	_apply_requirement_card_style(next_era_index)

func update_layout() -> void:
	_update_timeline_height()
	_update_requirement_card_position()

func _ensure_requirement_labels() -> void:
	if not _requirement_labels.is_empty():
		return

	var ui_font: FontFile = UIFont.load_ui_font()
	for _i in range(7):
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		if ui_font != null:
			label.add_theme_font_override("font", ui_font)
		_requirement_list.add_child(label)
		_requirement_labels.append(label)

func _set_requirement_labels_hidden() -> void:
	for label in _requirement_labels:
		label.visible = false
		label.text = ""

func _apply_requirement_card_style(era_index: int) -> void:
	var accent_color := _get_card_color(era_index)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent_color.r * 0.28, accent_color.g * 0.28, accent_color.b * 0.28, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = accent_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_requirement_card.add_theme_stylebox_override("panel", style)

func _get_card_color(era_index: int) -> Color:
	match era_index:
		0:
			return Color8(197, 70, 70)
		1:
			return Color8(99, 150, 255)
		2:
			return Color8(255, 241, 65)
		3:
			return Color8(112, 74, 143)
		_:
			return Color8(126, 126, 126)

func _update_timeline_height() -> void:
	if not is_instance_valid(_panel) or not is_instance_valid(_timeline):
		return

	var target_width := _panel.size.x
	if target_width <= 0.0:
		target_width = _timeline.size.x
	if target_width <= 0.0:
		return

	var target_height := round(
		target_width * (
			float(GameIconCache.ERA_SHEET_FRAME_SIZE.y)
			/ float(GameIconCache.ERA_SHEET_FRAME_SIZE.x)
		)
	)
	if absf(_timeline.custom_minimum_size.y - target_height) > 0.5:
		_timeline.custom_minimum_size = Vector2(0.0, target_height)
		_timeline.offset_bottom = target_height

func _update_requirement_card_position() -> void:
	if not is_instance_valid(_timeline) or not is_instance_valid(_requirement_card):
		return

	var top_offset := round(_timeline.custom_minimum_size.y * UIMetrics.ERA_REQUIREMENT_CARD_TOP_RATIO)
	_requirement_card.offset_left = UIMetrics.ERA_REQUIREMENT_CARD_SIDE_MARGIN
	_requirement_card.offset_right = -UIMetrics.ERA_REQUIREMENT_CARD_SIDE_MARGIN
	_requirement_card.offset_top = top_offset

func _on_unlock_pressed() -> void:
	unlock_requested.emit()
