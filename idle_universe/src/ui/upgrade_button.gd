extends Control

class_name UpgradeButton

signal purchase_requested(upgrade_id: String)

const UPGRADE_BACKGROUND_TEXTURE = preload("res://assests/sprites/spr_t1_upgrd.png")
const UPGRADE_BUTTON_TEXTURE = preload("res://assests/sprites/spr_upgrade_btn.png")
const UIMetrics = preload("res://src/ui/ui_metrics.gd")
const ENABLED_MODULATE := Color(1, 1, 1, 1)
const DISABLED_MODULATE := Color(0.55, 0.55, 0.55, 1)

var game_state: GameState
var upgrades_system: UpgradesSystem
var upgrade_id := ""

var background_rect: TextureRect
var content_margin: MarginContainer
var content_row: HBoxContainer
var info_box: VBoxContainer
var title_label: Label
var description_label: Label
var effect_label: Label
var cost_button: TextureButton
var cost_label: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, UIMetrics.UPGRADE_BUTTON_MIN_HEIGHT)

	background_rect = TextureRect.new()
	background_rect.texture = UPGRADE_BACKGROUND_TEXTURE
	background_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

	content_margin = MarginContainer.new()
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", UIMetrics.UPGRADE_CONTENT_MARGIN_X)
	content_margin.add_theme_constant_override("margin_top", UIMetrics.UPGRADE_CONTENT_MARGIN_Y)
	content_margin.add_theme_constant_override("margin_right", UIMetrics.UPGRADE_CONTENT_MARGIN_X)
	content_margin.add_theme_constant_override("margin_bottom", UIMetrics.UPGRADE_CONTENT_MARGIN_Y)
	add_child(content_margin)

	content_row = HBoxContainer.new()
	content_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_theme_constant_override("separation", UIMetrics.UPGRADE_CONTENT_SEPARATION)
	content_margin.add_child(content_row)

	info_box = VBoxContainer.new()
	info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.alignment = BoxContainer.ALIGNMENT_CENTER
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", UIMetrics.UPGRADE_INFO_SEPARATION)
	content_row.add_child(info_box)

	title_label = _create_info_label(UIMetrics.UPGRADE_TITLE_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER)
	description_label = _create_info_label(UIMetrics.UPGRADE_BODY_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER)
	effect_label = _create_info_label(UIMetrics.UPGRADE_BODY_FONT_SIZE, HORIZONTAL_ALIGNMENT_CENTER)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	info_box.add_child(title_label)
	info_box.add_child(description_label)
	info_box.add_child(effect_label)

	cost_button = TextureButton.new()
	cost_button.mouse_filter = Control.MOUSE_FILTER_STOP
	cost_button.texture_normal = UPGRADE_BUTTON_TEXTURE
	cost_button.texture_pressed = UPGRADE_BUTTON_TEXTURE
	cost_button.texture_hover = UPGRADE_BUTTON_TEXTURE
	cost_button.texture_disabled = UPGRADE_BUTTON_TEXTURE
	cost_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cost_button.ignore_texture_size = true
	cost_button.stretch_mode = TextureButton.STRETCH_SCALE
	cost_button.focus_mode = Control.FOCUS_NONE
	cost_button.custom_minimum_size = UIMetrics.UPGRADE_COST_BUTTON_SIZE
	cost_button.pressed.connect(_on_cost_button_pressed)
	content_row.add_child(cost_button)

	cost_label = Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cost_label.add_theme_font_size_override("font_size", UIMetrics.UPGRADE_BODY_FONT_SIZE)
	cost_button.add_child(cost_label)

	_apply_font()

func configure(new_game_state: GameState, new_upgrades_system: UpgradesSystem, new_upgrade_id: String) -> void:
	game_state = new_game_state
	upgrades_system = new_upgrades_system
	upgrade_id = new_upgrade_id
	refresh()

func refresh() -> void:
	if game_state == null or upgrades_system == null or upgrade_id.is_empty():
		_set_empty_state()
		return

	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		_set_empty_state()
		return

	var level := int(upgrade.get("current_level", 0))
	var max_level := int(upgrade.get("max_level", 0))
	var current_cost: DigitMaster = upgrades_system.get_upgrade_purchase_cost(game_state, upgrade_id)
	var purchase_currency_id := upgrades_system.get_upgrade_purchase_currency_id(game_state, upgrade_id)
	var currency_name := game_state.get_resource_name(purchase_currency_id)
	var description := str(upgrade.get("description", ""))
	var effect_summary := upgrades_system.get_upgrade_effect_summary(game_state, upgrade_id)

	title_label.text = "%s Lv.%d/%d" % [
		str(upgrade.get("name", upgrade_id)),
		level,
		max_level
	]
	description_label.text = description
	effect_label.text = effect_summary
	if level >= max_level:
		cost_label.text = "MAX\n-"
	else:
		cost_label.text = "%s\n%s" % [
			current_cost.big_to_short_string(),
			currency_name
		]

	var can_purchase := level < max_level and upgrades_system.can_purchase_upgrade(game_state, upgrade_id)
	cost_button.disabled = not can_purchase
	if can_purchase:
		cost_button.modulate = ENABLED_MODULATE
		background_rect.modulate = ENABLED_MODULATE
	else:
		cost_button.modulate = DISABLED_MODULATE
		background_rect.modulate = DISABLED_MODULATE

func _create_info_label(font_size: int, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _apply_font() -> void:
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font == null:
		return
	title_label.add_theme_font_override("font", ui_font)
	description_label.add_theme_font_override("font", ui_font)
	effect_label.add_theme_font_override("font", ui_font)
	cost_label.add_theme_font_override("font", ui_font)

func _set_empty_state() -> void:
	title_label.text = ""
	description_label.text = ""
	effect_label.text = ""
	cost_label.text = ""
	cost_button.disabled = true
	cost_button.modulate = DISABLED_MODULATE
	background_rect.modulate = DISABLED_MODULATE

func _on_cost_button_pressed() -> void:
	if not upgrade_id.is_empty():
		emit_signal("purchase_requested", upgrade_id)
