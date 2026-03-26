extends Control

class_name UpgradeButton

signal purchase_requested(upgrade_id: String)

const UPGRADE_BACKGROUND_TEXTURE = preload("res://assests/sprites/spr_t1_upgrd.png")
const UPGRADE_BUTTON_TEXTURE = preload("res://assests/sprites/spr_upgrade_btn.png")
const ENABLED_MODULATE := Color(1, 1, 1, 1)
const DISABLED_MODULATE := Color(0.55, 0.55, 0.55, 1)

var game_state: GameState
var upgrades_system: UpgradesSystem
var upgrade_id := ""

var background_rect: TextureRect
var info_box: VBoxContainer
var title_label: Label
var description_label: Label
var effect_label: Label
var cost_button: TextureButton
var cost_label: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0, 96)

	background_rect = TextureRect.new()
	background_rect.texture = UPGRADE_BACKGROUND_TEXTURE
	background_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	background_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background_rect)

	info_box = VBoxContainer.new()
	info_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.alignment = BoxContainer.ALIGNMENT_CENTER
	info_box.add_theme_constant_override("separation", 2)
	info_box.anchor_left = 0.0
	info_box.anchor_top = 0.0
	info_box.anchor_right = 1.0
	info_box.anchor_bottom = 1.0
	info_box.offset_left = 12.0
	info_box.offset_top = 8.0
	info_box.offset_right = -108.0
	info_box.offset_bottom = -8.0
	add_child(info_box)

	title_label = _create_info_label(16, HORIZONTAL_ALIGNMENT_CENTER)
	description_label = _create_info_label(12, HORIZONTAL_ALIGNMENT_CENTER)
	effect_label = _create_info_label(12, HORIZONTAL_ALIGNMENT_CENTER)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	info_box.add_child(title_label)
	info_box.add_child(description_label)
	info_box.add_child(effect_label)

	cost_button = TextureButton.new()
	cost_button.texture_normal = UPGRADE_BUTTON_TEXTURE
	cost_button.texture_pressed = UPGRADE_BUTTON_TEXTURE
	cost_button.texture_hover = UPGRADE_BUTTON_TEXTURE
	cost_button.texture_disabled = UPGRADE_BUTTON_TEXTURE
	cost_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cost_button.ignore_texture_size = true
	cost_button.stretch_mode = TextureButton.STRETCH_SCALE
	cost_button.focus_mode = Control.FOCUS_NONE
	cost_button.anchor_left = 1.0
	cost_button.anchor_top = 0.5
	cost_button.anchor_right = 1.0
	cost_button.anchor_bottom = 0.5
	cost_button.offset_left = -92.0
	cost_button.offset_top = -24.0
	cost_button.offset_right = -10.0
	cost_button.offset_bottom = 24.0
	cost_button.pressed.connect(_on_cost_button_pressed)
	add_child(cost_button)

	cost_label = Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cost_label.add_theme_font_size_override("font_size", 12)
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
	var current_cost: DigitMaster = upgrade["current_cost"]
	var currency_name := game_state.get_resource_name(str(upgrade.get("currency_id", "")))
	var description := str(upgrade.get("description", ""))
	var effect_summary := upgrades_system.get_upgrade_effect_summary(game_state, upgrade_id)

	title_label.text = "%s Lv.%d/%d" % [
		str(upgrade.get("name", upgrade_id)),
		level,
		max_level
	]
	description_label.text = description
	effect_label.text = effect_summary
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
