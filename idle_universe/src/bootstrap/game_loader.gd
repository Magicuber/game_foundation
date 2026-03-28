extends Control

const ELEMENTS_DATA_PATH := "res://src/data/elements.json"
const UPGRADES_DATA_PATH := "res://src/data/upgrades.json"
const AUTO_SAVE_INTERVAL_TICKS := 50
const ELEMENT_SHEET_FRAME_SIZE := Vector2i(32, 32)
const ERA_SHEET_FRAME_SIZE := Vector2i(540, 750)
const ERA_REQUIREMENT_CARD_TOP_RATIO := 0.80
const ERA_REQUIREMENT_CARD_SIDE_MARGIN := 8.0
const OFFSCREEN_MARGIN := 96.0
const PRODUCT_PARTICLE_SIZE := 52.0
const PROTON_PARTICLE_SIZE := 56.0
const PRODUCT_SPEED_MIN := 210.0
const PRODUCT_SPEED_MAX := 320.0
const PROTON_SPEED_MIN := 260.0
const PROTON_SPEED_MAX := 360.0
const PROTON_SPEED_VARIATION := 0.15
const MAX_COUNTERS := 10
const FIRST_TIER_UNLOCK_COUNT := 10
const DISABLED_BUTTON_MODULATE := Color(0.45, 0.45, 0.45, 1.0)
const ENABLED_BUTTON_MODULATE := Color(1, 1, 1, 1)
const ELEMENT_MENU_SECTIONS := [
	{"title": "1-10", "start": 1, "end": 10, "columns": 5},
	{"title": "11-30", "start": 11, "end": 30, "columns": 5},
	{"title": "31-54", "start": 31, "end": 54, "columns": 6},
	{"title": "55-86", "start": 55, "end": 86, "columns": 8},
	{"title": "87-118", "start": 87, "end": 118, "columns": 8}
]

const MENU_CLOSED := 0
const MENU_MAIN := 1
const MENU_UPGRADES := 2
const MENU_ELEMENTS := 3
const MENU_ERA := 4
const MENU_STATS := 5

const ELEMENT_SHEET = preload("res://assests/sprites/elements_01_strip119.png")
const ERA_SHEET = preload("res://assests/sprites/spr_era_strip4.png")
const PREV_BUTTON_TEXTURE = preload("res://assests/sprites/spr_prev_btn.png")
const NEXT_BUTTON_TEXTURE = preload("res://assests/sprites/spr_next_btn.png")
const MENU_BUTTON_TEXTURE = preload("res://assests/sprites/spr_menu_btn.png")
const CLOSE_BUTTON_TEXTURE = preload("res://assests/sprites/spr_close_btn1.png")
const ZIN_BUTTON_TEXTURE = preload("res://assests/sprites/spr_zin_btn.png")
const ZOUT_BUTTON_TEXTURE = preload("res://assests/sprites/spr_zout_btn.png")
const MENU_BACKGROUND_TEXTURE = preload("res://assests/sprites/spr_eleupgds_background.png")

@onready var tick_system: TickSystem = $TickSystem
@onready var effects_layer: Control = $EffectsLayer
@onready var fuse_button: TextureButton = $FuseButton
@onready var menu_overlay: Control = $MenuOverlay
@onready var menu_background: TextureRect = $MenuOverlay/MenuBackground
@onready var main_menu_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel
@onready var upgrades_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel
@onready var elements_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel
@onready var era_panel: Control = $MenuOverlay/MenuContent/MenuPanels/EraPanel
@onready var stats_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/StatsPanel
@onready var main_menu_title: Label = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/MainMenuTitle
@onready var upgrades_title: Label = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradesTitle
@onready var upgrades_info: Label = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradesInfo
@onready var elements_title: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsTitle
@onready var elements_info: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsInfo
@onready var elements_section_list: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsScroll/ElementsSectionList
@onready var era_title: Label = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraTitle
@onready var era_timeline: TextureRect = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraTimeline
@onready var era_status: Label = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraStatus
@onready var era_requirement_card: PanelContainer = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard
@onready var era_requirement_title: Label = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard/EraRequirementMargin/EraRequirementVBox/EraRequirementTitle
@onready var era_requirement_list: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard/EraRequirementMargin/EraRequirementVBox/EraRequirementList
@onready var era_unlock_button: Button = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard/EraRequirementMargin/EraRequirementVBox/EraUnlockButton
@onready var stats_title: Label = $MenuOverlay/MenuContent/MenuPanels/StatsPanel/StatsTitle
@onready var stats_info: Label = $MenuOverlay/MenuContent/MenuPanels/StatsPanel/StatsInfo
@onready var planetary_stats_info: Label = $MenuOverlay/MenuContent/MenuPanels/StatsPanel/PlanetaryStatsInfo
@onready var upgrades_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/UpgradesMenuButton
@onready var elements_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/ElementsMenuButton
@onready var era_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/EraMenuButton
@onready var stats_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/StatsMenuButton
@onready var settings_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/SettingsMenuButton
@onready var unlock_button: Button = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/UnlockButton
@onready var upgrade_list: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradeList
@onready var counter_margin: MarginContainer = $CounterMargin
@onready var counter_list: VBoxContainer = $CounterMargin/CounterList
@onready var top_bar: ColorRect = $TopBar
@onready var profile_button: Button = $TopBar/ProfileButton
@onready var level_label: Label = $TopBar/LevelLabel
@onready var orbs_panel: PanelContainer = $TopBar/CurrencyBoxes/OrbsPanel
@onready var dust_panel: PanelContainer = $TopBar/CurrencyBoxes/DustPanel
@onready var orbs_icon_slot: ColorRect = $TopBar/CurrencyBoxes/OrbsPanel/OrbsRow/OrbsIconSlot
@onready var dust_icon_slot: ColorRect = $TopBar/CurrencyBoxes/DustPanel/DustRow/DustIconSlot
@onready var orbs_label: Label = $TopBar/CurrencyBoxes/OrbsPanel/OrbsRow/OrbsLabel
@onready var dust_label: Label = $TopBar/CurrencyBoxes/DustPanel/DustRow/DustLabel
@onready var bottom_bar: ColorRect = $BottomBar
@onready var prev_button: TextureButton = $BottomBar/NavSlots/PrevSlot/PrevButton
@onready var next_button: TextureButton = $BottomBar/NavSlots/NextSlot/NextButton
@onready var zin_button: TextureButton = $BottomBar/NavSlots/ZinSlot/ZinButton
@onready var zout_button: TextureButton = $BottomBar/NavSlots/ZoutSlot/ZoutButton
@onready var menu_button: TextureButton = $BottomBar/NavSlots/MenuSlot/MenuButton

var game_state: GameState
var element_system: ElementSystem = ElementSystem.new()
var upgrades_system: UpgradesSystem = UpgradesSystem.new()
var resource_displays: Dictionary = {}
var resource_display_ids: Array[String] = []
var upgrade_buttons: Dictionary = {}
var upgrade_button_ids: Array[String] = []
var element_menu_tiles: Dictionary = {}
var visible_element_section_count := -1
var visual_particles: Array[Dictionary] = []
var era_requirement_labels: Array[Label] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var menu_mode: int = MENU_CLOSED

func _ready() -> void:
	set_process(true)
	rng.randomize()

	game_state = _build_default_state()
	SaveManager.load_into_state(game_state)

	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	zin_button.pressed.connect(_on_zin_pressed)
	zout_button.pressed.connect(_on_zout_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	fuse_button.pressed.connect(_on_smash_pressed)
	unlock_button.pressed.connect(_on_unlock_pressed)
	upgrades_menu_button.pressed.connect(_on_upgrades_menu_pressed)
	elements_menu_button.pressed.connect(_on_elements_menu_pressed)
	era_menu_button.pressed.connect(_on_era_menu_pressed)
	stats_menu_button.pressed.connect(_on_stats_menu_pressed)
	era_unlock_button.pressed.connect(_on_era_unlock_pressed)

	_configure_texture_button(prev_button, PREV_BUTTON_TEXTURE)
	_configure_texture_button(next_button, NEXT_BUTTON_TEXTURE)
	_configure_texture_button(zin_button, ZIN_BUTTON_TEXTURE)
	_configure_texture_button(zout_button, ZOUT_BUTTON_TEXTURE)

	menu_background.texture = MENU_BACKGROUND_TEXTURE
	menu_background.modulate = Color(1, 1, 1, 0.7)
	menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_background.stretch_mode = TextureRect.STRETCH_SCALE
	menu_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	fuse_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fuse_button.pivot_offset = fuse_button.size * 0.5
	era_timeline.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	era_timeline.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	era_timeline.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	era_title.visible = false
	era_status.visible = false
	profile_button.focus_mode = Control.FOCUS_NONE
	unlock_button.focus_mode = Control.FOCUS_NONE
	era_unlock_button.focus_mode = Control.FOCUS_NONE
	_apply_profile_button_style()
	_apply_currency_box_style(orbs_panel)
	_apply_currency_box_style(dust_panel)
	_apply_ui_font()
	_apply_currency_labels()
	_apply_menu_text_style()
	_apply_menu_button_style(upgrades_menu_button, true)
	_apply_menu_button_style(elements_menu_button, true)
	_apply_menu_button_style(era_menu_button, false)
	_apply_menu_button_style(stats_menu_button, true)
	_apply_menu_button_style(settings_menu_button, false)
	_configure_placeholder_slot(orbs_icon_slot)
	_configure_placeholder_slot(dust_icon_slot)
	_ensure_era_requirement_labels()

	effects_layer.z_index = 1
	fuse_button.z_index = 15
	menu_overlay.z_index = 30
	counter_margin.z_index = 20
	top_bar.z_index = 50
	bottom_bar.z_index = 50

	tick_system.configure(game_state, element_system, upgrades_system)
	tick_system.tick_processed.connect(_on_tick_processed)
	tick_system.manual_smash_resolved.connect(_on_manual_smash_resolved)
	tick_system.auto_smash_requested.connect(_on_auto_smash_requested)

	_set_menu_mode(MENU_CLOSED)
	_refresh_ui()

func _process(delta: float) -> void:
	_update_particles(delta)

func _exit_tree() -> void:
	if game_state != null and SaveManager.save_state(game_state):
		game_state.last_save_tick = game_state.tick_count

func _build_default_state() -> GameState:
	var elements_content: Dictionary = _load_json_dictionary(ELEMENTS_DATA_PATH)
	var upgrades_content: Dictionary = _load_json_dictionary(UPGRADES_DATA_PATH)
	return GameState.from_content(elements_content, upgrades_content)

func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: %s" % path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Unable to read data file: %s" % path)
		return {}

	var parsed_value: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_value) != TYPE_DICTIONARY:
		push_warning("Expected dictionary JSON at %s" % path)
		return {}

	var parsed: Dictionary = parsed_value
	return parsed

func _configure_texture_button(button: TextureButton, texture: Texture2D) -> void:
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture
	button.texture_disabled = texture
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.ignore_texture_size = true
	button.focus_mode = Control.FOCUS_NONE

func _update_menu_button_texture() -> void:
	var texture: Texture2D = MENU_BUTTON_TEXTURE
	if menu_mode != MENU_CLOSED:
		texture = CLOSE_BUTTON_TEXTURE
	_configure_texture_button(menu_button, texture)
	menu_button.modulate = ENABLED_BUTTON_MODULATE

func _apply_profile_button_style() -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color8(15, 100, 63)
	normal_style.border_width_left = 2
	normal_style.border_width_top = 2
	normal_style.border_width_right = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = Color8(8, 54, 34)

	var pressed_style: StyleBoxFlat = normal_style.duplicate()
	pressed_style.bg_color = Color8(12, 84, 53)

	profile_button.add_theme_stylebox_override("normal", normal_style)
	profile_button.add_theme_stylebox_override("hover", normal_style)
	profile_button.add_theme_stylebox_override("pressed", pressed_style)
	profile_button.add_theme_stylebox_override("disabled", normal_style)

func _apply_ui_font() -> void:
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font == null:
		return

	level_label.add_theme_font_override("font", ui_font)
	orbs_label.add_theme_font_override("font", ui_font)
	dust_label.add_theme_font_override("font", ui_font)
	main_menu_title.add_theme_font_override("font", ui_font)
	upgrades_title.add_theme_font_override("font", ui_font)
	upgrades_info.add_theme_font_override("font", ui_font)
	elements_title.add_theme_font_override("font", ui_font)
	elements_info.add_theme_font_override("font", ui_font)
	era_title.add_theme_font_override("font", ui_font)
	era_status.add_theme_font_override("font", ui_font)
	era_requirement_title.add_theme_font_override("font", ui_font)
	era_unlock_button.add_theme_font_override("font", ui_font)
	stats_title.add_theme_font_override("font", ui_font)
	stats_info.add_theme_font_override("font", ui_font)
	planetary_stats_info.add_theme_font_override("font", ui_font)
	upgrades_menu_button.add_theme_font_override("font", ui_font)
	elements_menu_button.add_theme_font_override("font", ui_font)
	era_menu_button.add_theme_font_override("font", ui_font)
	stats_menu_button.add_theme_font_override("font", ui_font)
	settings_menu_button.add_theme_font_override("font", ui_font)
	unlock_button.add_theme_font_override("font", ui_font)
	profile_button.add_theme_font_override("font", ui_font)

func _apply_currency_box_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color8(45, 45, 45)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color8(16, 16, 16)
	style.content_margin_left = 8
	style.content_margin_top = 3
	style.content_margin_right = 8
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)

func _apply_currency_labels() -> void:
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	orbs_label.add_theme_font_size_override("font_size", 14)
	orbs_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	dust_label.add_theme_font_size_override("font_size", 14)
	dust_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _apply_menu_text_style() -> void:
	main_menu_title.add_theme_font_size_override("font_size", 26)
	upgrades_title.add_theme_font_size_override("font_size", 26)
	elements_title.add_theme_font_size_override("font_size", 26)
	era_title.add_theme_font_size_override("font_size", 26)
	era_status.add_theme_font_size_override("font_size", 16)
	era_requirement_title.add_theme_font_size_override("font_size", 18)
	stats_title.add_theme_font_size_override("font_size", 26)
	main_menu_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	upgrades_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	elements_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	era_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	stats_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	upgrades_info.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	elements_info.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	era_status.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	era_requirement_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	stats_info.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	planetary_stats_info.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _apply_menu_button_style(button: Button, is_enabled: bool) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not is_enabled
	if is_enabled:
		button.modulate = ENABLED_BUTTON_MODULATE
	else:
		button.modulate = DISABLED_BUTTON_MODULATE

func _configure_placeholder_slot(slot: ColorRect) -> void:
	slot.color = Color8(25, 25, 25, 180)

func _set_menu_mode(new_mode: int) -> void:
	menu_mode = new_mode
	menu_overlay.visible = menu_mode != MENU_CLOSED
	main_menu_panel.visible = menu_mode == MENU_MAIN
	upgrades_panel.visible = menu_mode == MENU_UPGRADES
	elements_panel.visible = menu_mode == MENU_ELEMENTS
	era_panel.visible = menu_mode == MENU_ERA
	stats_panel.visible = menu_mode == MENU_STATS
	_update_menu_button_texture()

func _ensure_era_requirement_labels() -> void:
	if not era_requirement_labels.is_empty():
		return

	var ui_font: FontFile = UIFont.load_ui_font()
	for _i in range(7):
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		if ui_font != null:
			label.add_theme_font_override("font", ui_font)
		era_requirement_list.add_child(label)
		era_requirement_labels.append(label)

func _apply_era_requirement_card_style(era_index: int) -> void:
	var accent_color := _get_era_card_color(era_index)
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
	era_requirement_card.add_theme_stylebox_override("panel", style)

func _get_era_card_color(era_index: int) -> Color:
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

func _make_era_frame(frame_index: int) -> AtlasTexture:
	var clamped_index := clampi(frame_index, 0, 3)
	var icon := AtlasTexture.new()
	icon.atlas = ERA_SHEET
	icon.region = Rect2(
		Vector2(clamped_index * ERA_SHEET_FRAME_SIZE.x, 0),
		Vector2(ERA_SHEET_FRAME_SIZE.x, ERA_SHEET_FRAME_SIZE.y)
	)
	return icon

func _get_counter_ids() -> Array[String]:
	var visible_ids: Array[String] = game_state.get_visible_counter_element_ids()
	var limited_ids: Array[String] = []
	for element_id in visible_ids:
		limited_ids.append(element_id)
		if limited_ids.size() >= MAX_COUNTERS:
			break
	return limited_ids

func _sync_resource_displays() -> void:
	var visible_ids: Array[String] = _get_counter_ids()
	if resource_display_ids != visible_ids:
		for child in counter_list.get_children():
			child.queue_free()

		resource_displays.clear()
		resource_display_ids = visible_ids.duplicate()

		for element_id in resource_display_ids:
			var display: CurrencyDisplay = CurrencyDisplay.new()
			display.configure(game_state, element_id)
			counter_list.add_child(display)
			resource_displays[element_id] = display

	for element_id in resource_display_ids:
		var display: CurrencyDisplay = resource_displays[element_id]
		display.refresh()

func _sync_upgrade_buttons() -> void:
	var upgrade_ids: Array[String] = game_state.get_upgrade_ids()
	if upgrade_button_ids != upgrade_ids:
		for child in upgrade_list.get_children():
			child.queue_free()

		upgrade_buttons.clear()
		upgrade_button_ids = upgrade_ids.duplicate()

		for upgrade_id in upgrade_button_ids:
			var button: UpgradeButton = UpgradeButton.new()
			button.configure(game_state, upgrades_system, upgrade_id)
			button.purchase_requested.connect(_on_upgrade_purchase_requested)
			upgrade_list.add_child(button)
			upgrade_buttons[upgrade_id] = button

	for upgrade_id in upgrade_button_ids:
		var button: UpgradeButton = upgrade_buttons[upgrade_id]
		button.refresh()

func _refresh_ui() -> void:
	_sync_resource_displays()
	_sync_upgrade_buttons()
	_sync_element_menu_tiles()

	level_label.text = "Lv. %d" % game_state.player_level
	orbs_label.text = "ORBS %s" % str(game_state.orbs)
	dust_label.text = "DUST %s" % game_state.dust.big_to_short_string()

	var current_element: Dictionary = game_state.get_current_element()
	var current_name := str(current_element.get("name", ""))
	var current_index := int(current_element.get("index", 0))
	var produced_name := game_state.get_resource_name(str(current_element.get("produces", "")))

	var current_icon: AtlasTexture = _make_element_icon(current_index)
	fuse_button.texture_normal = current_icon
	fuse_button.texture_pressed = current_icon
	fuse_button.texture_hover = current_icon
	fuse_button.texture_disabled = current_icon

	_set_button_enabled_state(prev_button, game_state.has_adjacent_unlocked_element(-1))
	_set_button_enabled_state(next_button, game_state.has_adjacent_unlocked_element(1))

	var first_tier_complete := game_state.has_unlocked_element_count(FIRST_TIER_UNLOCK_COUNT)
	zin_button.visible = first_tier_complete
	zout_button.visible = first_tier_complete
	if first_tier_complete:
		_set_button_enabled_state(zin_button, false)
		_set_button_enabled_state(zout_button, game_state.has_unlocked_era(1))

	upgrades_info.text = "Particle Smasher: %.2f actions/sec\nCrit Chance: %.0f%%\nFission Chance: %.0f%%" % [
		upgrades_system.get_auto_smashes_per_second(game_state),
		upgrades_system.get_global_critical_smash_chance_percent(game_state),
		upgrades_system.get_fission_chance_percent(game_state)
	]

	var era_menu_enabled := game_state.is_era_menu_unlocked()
	_apply_menu_button_style(era_menu_button, era_menu_enabled)

	stats_info.text = "Current Element: %s\nProduces: %s\nManual Smashes: %d\nAuto Smashes: %d" % [
		current_name,
		produced_name,
		game_state.total_manual_smashes,
		game_state.total_auto_smashes
	]
	planetary_stats_info.visible = game_state.has_unlocked_era(1)
	if planetary_stats_info.visible:
		planetary_stats_info.text = "Planetary Stats\nPlanets unlocked: 0\nPlanet systems coming soon"

	var next_unlock: Dictionary = game_state.get_next_unlock_element()
	if next_unlock.is_empty():
		elements_info.text = "Selected: %s\nAll elements unlocked." % current_name
		unlock_button.text = "All elements unlocked"
		unlock_button.disabled = true
	else:
		var unlock_id := str(next_unlock.get("id", ""))
		var unlock_cost: DigitMaster = next_unlock["cost"]
		elements_info.text = "Selected: %s\nProduces: %s\nNext: %s\nRequires: %s %s" % [
			current_name,
			produced_name,
			str(next_unlock.get("name", unlock_id)),
			unlock_cost.big_to_short_string(),
			game_state.get_resource_name(unlock_id)
		]
		unlock_button.text = "Unlock %s" % str(next_unlock.get("name", unlock_id))
		unlock_button.disabled = not game_state.can_unlock_next()

	_refresh_era_ui()
	_update_menu_button_texture()

func _refresh_era_ui() -> void:
	var unlocked_era_index := game_state.get_unlocked_era_index()
	era_timeline.texture = _make_era_frame(unlocked_era_index)
	_update_era_timeline_height()
	_update_era_requirement_card_position()

	if not game_state.is_era_menu_unlocked():
		era_requirement_title.text = "Era Menu Locked"
		for label in era_requirement_labels:
			label.visible = false
			label.text = ""
		era_unlock_button.visible = false
		_apply_era_requirement_card_style(0)
		return

	var next_era_index := game_state.get_next_implemented_era_index()
	if next_era_index < 0:
		var current_era_name := game_state.get_era_name(unlocked_era_index)
		era_requirement_title.text = "%s Unlocked" % current_era_name
		for label in era_requirement_labels:
			label.visible = false
			label.text = ""
		era_unlock_button.visible = false
		_apply_era_requirement_card_style(unlocked_era_index)
		return

	var next_era_name := game_state.get_era_name(next_era_index)
	era_requirement_title.text = "Next Era: %s" % next_era_name
	var requirements: Array[Dictionary] = game_state.get_next_era_requirements()
	for label_index in range(era_requirement_labels.size()):
		var label := era_requirement_labels[label_index]
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

	era_unlock_button.visible = true
	era_unlock_button.text = "Unlock %s" % next_era_name
	era_unlock_button.disabled = not game_state.can_unlock_next_era()
	_apply_era_requirement_card_style(next_era_index)

func _update_era_timeline_height() -> void:
	if not is_instance_valid(era_timeline):
		return

	var target_width := era_panel.size.x
	if target_width <= 0.0:
		target_width = era_timeline.size.x
	if target_width <= 0.0:
		return

	var target_height := round(target_width * (float(ERA_SHEET_FRAME_SIZE.y) / float(ERA_SHEET_FRAME_SIZE.x)))
	if absf(era_timeline.custom_minimum_size.y - target_height) > 0.5:
		era_timeline.custom_minimum_size = Vector2(0.0, target_height)
		era_timeline.offset_bottom = target_height

func _update_era_requirement_card_position() -> void:
	if not is_instance_valid(era_requirement_card):
		return

	var top_offset := round(era_timeline.custom_minimum_size.y * ERA_REQUIREMENT_CARD_TOP_RATIO)
	era_requirement_card.offset_left = ERA_REQUIREMENT_CARD_SIDE_MARGIN
	era_requirement_card.offset_right = -ERA_REQUIREMENT_CARD_SIDE_MARGIN
	era_requirement_card.offset_top = top_offset

func _set_button_enabled_state(button: TextureButton, is_enabled: bool) -> void:
	button.disabled = not is_enabled
	if is_enabled:
		button.modulate = ENABLED_BUTTON_MODULATE
	else:
		button.modulate = DISABLED_BUTTON_MODULATE

func _get_visible_element_section_count() -> int:
	return clampi(game_state.world_level + 1, 1, ELEMENT_MENU_SECTIONS.size())

func _sync_element_menu_tiles() -> void:
	var section_count := _get_visible_element_section_count()
	if visible_element_section_count != section_count:
		for child in elements_section_list.get_children():
			child.queue_free()

		element_menu_tiles.clear()
		visible_element_section_count = section_count

		for section_index in range(section_count):
			var section_data: Dictionary = ELEMENT_MENU_SECTIONS[section_index]
			var section_box := VBoxContainer.new()
			section_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			section_box.add_theme_constant_override("separation", 6)
			elements_section_list.add_child(section_box)

			var header := Label.new()
			header.text = str(section_data.get("title", ""))
			header.add_theme_font_size_override("font_size", 16)
			header.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			var ui_font: FontFile = UIFont.load_ui_font()
			if ui_font != null:
				header.add_theme_font_override("font", ui_font)
			section_box.add_child(header)

			var grid := GridContainer.new()
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.columns = int(section_data.get("columns", 5))
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 6)
			section_box.add_child(grid)

			var section_start := int(section_data.get("start", 1))
			var section_end := int(section_data.get("end", 1))
			for atomic_index in range(section_start, section_end + 1):
				var element: Dictionary = game_state.get_element_by_index(atomic_index)
				if element.is_empty():
					continue
				var element_id := str(element.get("id", ""))
				var tile: ElementMenuTile = ElementMenuTile.new()
				tile.configure(game_state, element_id)
				tile.element_pressed.connect(_on_element_tile_pressed)
				grid.add_child(tile)
				element_menu_tiles[element_id] = tile

	for element_id in element_menu_tiles.keys():
		var tile: ElementMenuTile = element_menu_tiles[element_id]
		tile.refresh(game_state.current_element_id)

func _autosave_if_needed() -> void:
	if game_state.tick_count - game_state.last_save_tick < AUTO_SAVE_INTERVAL_TICKS:
		return
	if SaveManager.save_state(game_state):
		game_state.last_save_tick = game_state.tick_count

func _make_element_icon(element_index: int) -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = ELEMENT_SHEET
	icon.region = Rect2(
		Vector2(element_index * ELEMENT_SHEET_FRAME_SIZE.x, 0),
		Vector2(ELEMENT_SHEET_FRAME_SIZE.x, ELEMENT_SHEET_FRAME_SIZE.y)
	)
	return icon

func _fuse_center() -> Vector2:
	return fuse_button.position + (fuse_button.size * 0.5)

func _fuse_radius() -> float:
	return minf(fuse_button.size.x, fuse_button.size.y) * 0.5 * fuse_button.scale.x

func _random_offscreen_point() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var edge := rng.randi_range(0, 3)
	match edge:
		0:
			return Vector2(rng.randf_range(0.0, viewport_size.x), -OFFSCREEN_MARGIN)
		1:
			return Vector2(rng.randf_range(0.0, viewport_size.x), viewport_size.y + OFFSCREEN_MARGIN)
		2:
			return Vector2(-OFFSCREEN_MARGIN, rng.randf_range(0.0, viewport_size.y))
		_:
			return Vector2(viewport_size.x + OFFSCREEN_MARGIN, rng.randf_range(0.0, viewport_size.y))

func _spawn_outgoing_element(resource_id: String, spawn_center: Vector2) -> void:
	if not game_state.is_element_id(resource_id):
		return

	var element: Dictionary = game_state.get_element(resource_id)
	var element_index := int(element.get("index", 0))
	var target := _random_offscreen_point()
	var direction := (target - spawn_center).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var speed := rng.randf_range(PRODUCT_SPEED_MIN, PRODUCT_SPEED_MAX)
	_spawn_particle(_make_element_icon(element_index), spawn_center, direction * speed, PRODUCT_PARTICLE_SIZE, "product", "")

func _spawn_proton(target_element_id: String) -> void:
	var proton_start := _random_offscreen_point()
	var center := _fuse_center()
	var direction := (center - proton_start).normalized()
	var speed_variation := rng.randf_range(1.0 - PROTON_SPEED_VARIATION, 1.0 + PROTON_SPEED_VARIATION)
	var speed := rng.randf_range(PROTON_SPEED_MIN, PROTON_SPEED_MAX) * speed_variation
	_spawn_particle(_make_element_icon(0), proton_start, direction * speed, PROTON_PARTICLE_SIZE, "proton", target_element_id)

func _spawn_particle(texture: Texture2D, center_position: Vector2, velocity: Vector2, icon_size: float, kind: String, target_element_id: String) -> void:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.size = Vector2(icon_size, icon_size)
	rect.position = center_position - (rect.size * 0.5)
	effects_layer.add_child(rect)

	visual_particles.append({
		"node": rect,
		"velocity": velocity,
		"kind": kind,
		"target_element_id": target_element_id
	})

func _update_particles(delta: float) -> void:
	if visual_particles.is_empty():
		return

	var viewport_size := get_viewport_rect().size
	for i in range(visual_particles.size() - 1, -1, -1):
		var particle: Dictionary = visual_particles[i]
		var node: TextureRect = particle["node"]
		var velocity: Vector2 = particle["velocity"]
		node.position += velocity * delta

		if str(particle.get("kind", "")) == "proton":
			var collision_point := _get_particle_collision_point(node)
			if collision_point != Vector2.INF:
				var result: Dictionary = element_system.resolve_auto_smash(game_state, upgrades_system, str(particle.get("target_element_id", "")))
				if not result.is_empty():
					_pulse_fuse_element()
					_spawn_result_particles(result, collision_point)
					_refresh_ui()
				_remove_particle_at(i)
				continue

		if _is_offscreen(node, viewport_size):
			_remove_particle_at(i)

func _get_particle_collision_point(node: TextureRect) -> Vector2:
	var particle_center := node.position + (node.size * 0.5)
	var fuse_center := _fuse_center()
	var offset := particle_center - fuse_center
	var distance := offset.length()
	var particle_radius: float = minf(node.size.x, node.size.y) * 0.5
	var fuse_radius: float = _fuse_radius()
	if distance > fuse_radius + particle_radius:
		return Vector2.INF
	if distance == 0.0:
		return fuse_center + Vector2.RIGHT * fuse_radius
	return fuse_center + offset.normalized() * fuse_radius

func _is_offscreen(node: TextureRect, viewport_size: Vector2) -> bool:
	return node.position.x > viewport_size.x + OFFSCREEN_MARGIN \
		or node.position.x + node.size.x < -OFFSCREEN_MARGIN \
		or node.position.y > viewport_size.y + OFFSCREEN_MARGIN \
		or node.position.y + node.size.y < -OFFSCREEN_MARGIN

func _remove_particle_at(index: int) -> void:
	var particle: Dictionary = visual_particles[index]
	var node: TextureRect = particle["node"]
	if is_instance_valid(node):
		node.queue_free()
	visual_particles.remove_at(index)

func _on_tick_processed(_tick_count: int) -> void:
	_refresh_ui()
	_autosave_if_needed()

func _on_manual_smash_resolved(result: Dictionary) -> void:
	_pulse_fuse_element()
	var spawn_target := _random_offscreen_point()
	var spawn_direction := (spawn_target - _fuse_center()).normalized()
	if spawn_direction == Vector2.ZERO:
		spawn_direction = Vector2.RIGHT
	var spawn_point := _fuse_center() + (spawn_direction * _fuse_radius())
	_spawn_result_particles(result, spawn_point)
	_refresh_ui()

func _on_auto_smash_requested(request: Dictionary) -> void:
	var target_element_id := str(request.get("target_element_id", ""))
	var spawn_count := int(request.get("spawn_count", 1))
	for _i in range(spawn_count):
		_spawn_proton(target_element_id)

func _on_prev_pressed() -> void:
	tick_system.enqueue_action("select_adjacent", {"direction": -1})

func _on_next_pressed() -> void:
	tick_system.enqueue_action("select_adjacent", {"direction": 1})

func _on_zin_pressed() -> void:
	pass

func _on_zout_pressed() -> void:
	pass

func _on_smash_pressed() -> void:
	tick_system.enqueue_action("manual_smash")

func _on_menu_pressed() -> void:
	match menu_mode:
		MENU_CLOSED:
			_set_menu_mode(MENU_MAIN)
		MENU_MAIN:
			_set_menu_mode(MENU_CLOSED)
		_:
			_set_menu_mode(MENU_MAIN)
	_refresh_ui()

func _on_upgrades_menu_pressed() -> void:
	_set_menu_mode(MENU_UPGRADES)
	_refresh_ui()

func _on_elements_menu_pressed() -> void:
	_set_menu_mode(MENU_ELEMENTS)
	_refresh_ui()

func _on_era_menu_pressed() -> void:
	if not game_state.is_era_menu_unlocked():
		return
	_set_menu_mode(MENU_ERA)
	_refresh_ui()

func _on_stats_menu_pressed() -> void:
	_set_menu_mode(MENU_STATS)
	_refresh_ui()

func _on_element_tile_pressed(element_id: String) -> void:
	if game_state.select_element(element_id):
		_set_menu_mode(MENU_CLOSED)
		_refresh_ui()

func _on_unlock_pressed() -> void:
	tick_system.enqueue_action("unlock_next")

func _on_era_unlock_pressed() -> void:
	if game_state.unlock_next_era():
		_refresh_ui()

func _on_upgrade_purchase_requested(upgrade_id: String) -> void:
	tick_system.enqueue_action("purchase_upgrade", {"id": upgrade_id})

func _pulse_fuse_element() -> void:
	if not is_instance_valid(fuse_button):
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fuse_button, "scale", Vector2(0.9, 0.9), 0.06)
	tween.tween_property(fuse_button, "scale", Vector2.ONE, 0.08)

func _spawn_result_particles(result: Dictionary, spawn_center: Vector2) -> void:
	for resource_id in _get_result_resource_ids(result):
		_spawn_outgoing_element(resource_id, spawn_center)

func _get_result_resource_ids(result: Dictionary) -> Array[String]:
	var resource_ids: Array[String] = []
	var raw_ids: Variant = result.get("produced_resource_ids", [])
	if typeof(raw_ids) == TYPE_ARRAY:
		for raw_id in raw_ids:
			resource_ids.append(str(raw_id))
	if resource_ids.is_empty():
		var fallback_id := str(result.get("produced_resource_id", ""))
		if not fallback_id.is_empty():
			resource_ids.append(fallback_id)
	return resource_ids
