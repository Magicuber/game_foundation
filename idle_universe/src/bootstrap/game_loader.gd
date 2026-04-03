extends Control

const ELEMENTS_DATA_PATH := "res://src/data/elements.json"
const UPGRADES_DATA_PATH := "res://src/data/upgrades.json"
const PLANETS_DATA_PATH := "res://src/data/planets.json"
const UIMetrics = preload("res://src/ui/ui_metrics.gd")
const AUTO_SAVE_INTERVAL_TICKS := 50
const UPGRADE_BUTTON_TEXTURE = preload("res://assests/sprites/spr_upgrade_btn.png")
const DEBUG_HITBOX_COLOR := Color8(255, 80, 80)
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
const MENU_SHOP := 6
const MENU_PLANETS := 7
const MENU_SETTINGS := 8

const VIEW_ATOM := 0
const VIEW_WORLD := 1

const UI_DIRTY_TOP_BAR := 1 << 0
const UI_DIRTY_SELECTION := 1 << 1
const UI_DIRTY_NAVIGATION := 1 << 2
const UI_DIRTY_COUNTERS := 1 << 3
const UI_DIRTY_UPGRADES := 1 << 4
const UI_DIRTY_ELEMENTS := 1 << 5
const UI_DIRTY_ERA := 1 << 6
const UI_DIRTY_STATS := 1 << 7
const UI_DIRTY_SHOP := 1 << 8
const UI_DIRTY_PLANETS := 1 << 9
const UI_DIRTY_SETTINGS := 1 << 10
const UI_DIRTY_WORLD := 1 << 11
const UI_DIRTY_MENU_BUTTONS := 1 << 12
const UI_DIRTY_DEBUG := 1 << 13
const UI_DIRTY_ALL := (
	UI_DIRTY_TOP_BAR
	| UI_DIRTY_SELECTION
	| UI_DIRTY_NAVIGATION
	| UI_DIRTY_COUNTERS
	| UI_DIRTY_UPGRADES
	| UI_DIRTY_ELEMENTS
	| UI_DIRTY_ERA
	| UI_DIRTY_STATS
	| UI_DIRTY_SHOP
	| UI_DIRTY_PLANETS
	| UI_DIRTY_SETTINGS
	| UI_DIRTY_WORLD
	| UI_DIRTY_MENU_BUTTONS
	| UI_DIRTY_DEBUG
)

const PREV_BUTTON_TEXTURE = preload("res://assests/sprites/spr_prev_btn.png")
const NEXT_BUTTON_TEXTURE = preload("res://assests/sprites/spr_next_btn.png")
const MENU_BUTTON_TEXTURE = preload("res://assests/sprites/spr_menu_btn.png")
const CLOSE_BUTTON_TEXTURE = preload("res://assests/sprites/spr_close_btn1.png")
const ZIN_BUTTON_TEXTURE = preload("res://assests/sprites/spr_zin_btn.png")
const ZOUT_BUTTON_TEXTURE = preload("res://assests/sprites/spr_zout_btn.png")
const MENU_BACKGROUND_TEXTURE = preload("res://assests/sprites/spr_eleupgds_background.png")
const SHOP_BUTTON_TEXTURE = preload("res://assests/sprites/spr_shop_btn.png")

@onready var tick_system: TickSystem = $TickSystem
@onready var world_page: Control = $WorldPage
@onready var effects_layer: Control = $EffectsLayer
@onready var fuse_button: TextureButton = $FuseButton
@onready var fuse_hitbox_debug: Panel = $FuseButton/FuseHitboxDebug
@onready var menu_overlay: Control = $MenuOverlay
@onready var overlay_dim: ColorRect = $MenuOverlay/OverlayDim
@onready var menu_background: TextureRect = $MenuOverlay/MenuBackground
@onready var menu_content: MarginContainer = $MenuOverlay/MenuContent
@onready var main_menu_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel
@onready var upgrades_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel
@onready var elements_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel
@onready var era_panel: Control = $MenuOverlay/MenuContent/MenuPanels/EraPanel
@onready var stats_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/StatsPanel
@onready var shop_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ShopPanel
@onready var planets_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/PlanetsPanel
@onready var settings_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel
@onready var main_menu_title: Label = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/MainMenuTitle
@onready var upgrades_title: Label = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradesTitle
@onready var upgrades_info: Label = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradesInfo
@onready var elements_title: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsTitle
@onready var elements_info: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsInfo
@onready var elements_scroll: ScrollContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsScroll
@onready var elements_section_list: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsScroll/ElementsSectionList
@onready var dust_action_row: HBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow
@onready var make_dust_button: TextureButton = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow/MakeDustButton
@onready var make_dust_label: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow/MakeDustButton/MakeDustLabel
@onready var dust_close_button: TextureButton = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow/DustCloseButton
@onready var dust_close_label: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow/DustCloseButton/DustCloseLabel
@onready var era_title: Label = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraTitle
@onready var era_timeline: TextureRect = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraTimeline
@onready var era_status: Label = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraStatus
@onready var era_requirement_card: PanelContainer = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard
@onready var era_requirement_margin: MarginContainer = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard/EraRequirementMargin
@onready var era_requirement_vbox: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard/EraRequirementMargin/EraRequirementVBox
@onready var era_requirement_title: Label = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard/EraRequirementMargin/EraRequirementVBox/EraRequirementTitle
@onready var era_requirement_list: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard/EraRequirementMargin/EraRequirementVBox/EraRequirementList
@onready var era_unlock_button: Button = $MenuOverlay/MenuContent/MenuPanels/EraPanel/EraRequirementCard/EraRequirementMargin/EraRequirementVBox/EraUnlockButton
@onready var stats_title: Label = $MenuOverlay/MenuContent/MenuPanels/StatsPanel/StatsTitle
@onready var stats_info: Label = $MenuOverlay/MenuContent/MenuPanels/StatsPanel/StatsInfo
@onready var planetary_stats_info: Label = $MenuOverlay/MenuContent/MenuPanels/StatsPanel/PlanetaryStatsInfo
@onready var shop_title: Label = $MenuOverlay/MenuContent/MenuPanels/ShopPanel/ShopTitle
@onready var shop_info: Label = $MenuOverlay/MenuContent/MenuPanels/ShopPanel/ShopInfo
@onready var planets_title: Label = $MenuOverlay/MenuContent/MenuPanels/PlanetsPanel/PlanetsTitle
@onready var planets_info: Label = $MenuOverlay/MenuContent/MenuPanels/PlanetsPanel/PlanetsInfo
@onready var settings_title: Label = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/SettingsTitle
@onready var settings_info: Label = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/SettingsInfo
@onready var click_boxes_toggle: CheckButton = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/ClickBoxesToggle
@onready var add_dust_button: Button = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/AddDustButton
@onready var add_orbs_button: Button = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/AddOrbsButton
@onready var upgrades_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/UpgradesMenuButton
@onready var elements_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/ElementsMenuButton
@onready var era_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/EraMenuButton
@onready var planets_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/PlanetsMenuButton
@onready var stats_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/StatsMenuButton
@onready var shop_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/ShopMenuButton
@onready var settings_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/SettingsMenuButton
@onready var unlock_button: Button = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/UnlockButton
@onready var upgrade_list: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradeList
@onready var counter_margin: MarginContainer = $CounterMargin
@onready var counter_list: VBoxContainer = $CounterMargin/CounterList
@onready var top_bar: ColorRect = $TopBar
@onready var profile_button: Button = $TopBar/ProfileButton
@onready var level_label: Label = $TopBar/LevelLabel
@onready var currency_boxes: VBoxContainer = $TopBar/CurrencyBoxes
@onready var orbs_panel: PanelContainer = $TopBar/CurrencyBoxes/OrbsPanel
@onready var dust_panel: PanelContainer = $TopBar/CurrencyBoxes/DustPanel
@onready var orbs_row: HBoxContainer = $TopBar/CurrencyBoxes/OrbsPanel/OrbsRow
@onready var dust_row: HBoxContainer = $TopBar/CurrencyBoxes/DustPanel/DustRow
@onready var orbs_icon_slot: ColorRect = $TopBar/CurrencyBoxes/OrbsPanel/OrbsRow/OrbsIconSlot
@onready var dust_icon_slot: ColorRect = $TopBar/CurrencyBoxes/DustPanel/DustRow/DustIconSlot
@onready var orbs_label: Label = $TopBar/CurrencyBoxes/OrbsPanel/OrbsRow/OrbsLabel
@onready var dust_label: Label = $TopBar/CurrencyBoxes/DustPanel/DustRow/DustLabel
@onready var bottom_bar: ColorRect = $BottomBar
@onready var nav_slots: HBoxContainer = $BottomBar/NavSlots
@onready var prev_slot: Control = $BottomBar/NavSlots/PrevSlot
@onready var next_slot: Control = $BottomBar/NavSlots/NextSlot
@onready var zin_slot: Control = $BottomBar/NavSlots/ZinSlot
@onready var zout_slot: Control = $BottomBar/NavSlots/ZoutSlot
@onready var menu_slot: Control = $BottomBar/NavSlots/MenuSlot
@onready var prev_button: TextureButton = $BottomBar/NavSlots/PrevSlot/PrevButton
@onready var next_button: TextureButton = $BottomBar/NavSlots/NextSlot/NextButton
@onready var zin_button: TextureButton = $BottomBar/NavSlots/ZinSlot/ZinButton
@onready var zout_button: TextureButton = $BottomBar/NavSlots/ZoutSlot/ZoutButton
@onready var menu_button: TextureButton = $BottomBar/NavSlots/MenuSlot/MenuButton
@onready var shop_button: TextureButton = $ShopButton

var game_state: GameState
var element_system: ElementSystem = ElementSystem.new()
var upgrades_system: UpgradesSystem = UpgradesSystem.new()
var resource_displays: Dictionary = {}
var resource_display_ids: Array[String] = []
var upgrade_buttons: Dictionary = {}
var upgrade_button_ids: Array[String] = []
var element_menu_tiles: Dictionary = {}
var visible_element_section_count := -1
var era_requirement_labels: Array[Label] = []
var menu_mode: int = MENU_CLOSED
var view_mode: int = VIEW_ATOM
var debug_show_element_hitboxes := false
var dust_mode_active := false
var _ui_dirty_flags: int = UI_DIRTY_ALL
var icon_cache: GameIconCache = GameIconCache.new()
var dust_recipe_service: DustRecipeService = DustRecipeService.new()
var atom_effects_controller: AtomEffectsController = AtomEffectsController.new()
var world_view_controller: WorldViewController = WorldViewController.new()

func _ready() -> void:
	set_process(true)

	game_state = _build_default_state()
	SaveManager.load_into_state(game_state)
	upgrades_system.mark_cache_dirty()

	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	zin_button.pressed.connect(_on_zin_pressed)
	zout_button.pressed.connect(_on_zout_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	fuse_button.pressed.connect(_on_smash_pressed)
	unlock_button.pressed.connect(_on_unlock_pressed)
	make_dust_button.pressed.connect(_on_make_dust_pressed)
	dust_close_button.pressed.connect(_on_dust_close_pressed)
	upgrades_menu_button.pressed.connect(_on_upgrades_menu_pressed)
	elements_menu_button.pressed.connect(_on_elements_menu_pressed)
	era_menu_button.pressed.connect(_on_era_menu_pressed)
	planets_menu_button.pressed.connect(_on_planets_menu_pressed)
	stats_menu_button.pressed.connect(_on_stats_menu_pressed)
	shop_menu_button.pressed.connect(_on_shop_pressed)
	settings_menu_button.pressed.connect(_on_settings_menu_pressed)
	era_unlock_button.pressed.connect(_on_era_unlock_pressed)
	click_boxes_toggle.toggled.connect(_on_click_boxes_toggled)
	add_dust_button.pressed.connect(_on_add_dust_pressed)
	add_orbs_button.pressed.connect(_on_add_orbs_pressed)

	_configure_texture_button(prev_button, PREV_BUTTON_TEXTURE)
	_configure_texture_button(next_button, NEXT_BUTTON_TEXTURE)
	_configure_texture_button(zin_button, ZIN_BUTTON_TEXTURE)
	_configure_texture_button(zout_button, ZOUT_BUTTON_TEXTURE)
	_configure_texture_button(shop_button, SHOP_BUTTON_TEXTURE)
	_configure_texture_button(make_dust_button, UPGRADE_BUTTON_TEXTURE)
	_configure_texture_button(dust_close_button, UPGRADE_BUTTON_TEXTURE)

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
	_apply_debug_hitbox_style(fuse_hitbox_debug)
	profile_button.focus_mode = Control.FOCUS_NONE
	unlock_button.focus_mode = Control.FOCUS_NONE
	era_unlock_button.focus_mode = Control.FOCUS_NONE
	make_dust_button.focus_mode = Control.FOCUS_NONE
	dust_close_button.focus_mode = Control.FOCUS_NONE
	_apply_profile_button_style()
	_apply_currency_box_style(orbs_panel)
	_apply_currency_box_style(dust_panel)
	_apply_ui_font()
	_apply_currency_labels()
	_apply_menu_text_style()
	_apply_dust_action_text_style()
	_apply_menu_button_style(upgrades_menu_button, true)
	_apply_menu_button_style(elements_menu_button, true)
	_apply_menu_button_style(era_menu_button, false)
	_apply_menu_button_style(planets_menu_button, false)
	_apply_menu_button_style(stats_menu_button, true)
	_apply_menu_button_style(shop_menu_button, false)
	_apply_menu_button_style(settings_menu_button, true)
	_configure_placeholder_slot(orbs_icon_slot)
	_configure_placeholder_slot(dust_icon_slot)
	_apply_shell_metrics()
	_ensure_era_requirement_labels()

	effects_layer.z_index = 1
	world_page.z_index = 5
	fuse_button.z_index = 15
	menu_overlay.z_index = 30
	counter_margin.z_index = 20
	top_bar.z_index = 50
	bottom_bar.z_index = 50
	shop_button.z_index = 40

	tick_system.configure(game_state, element_system, upgrades_system)
	tick_system.tick_processed.connect(_on_tick_processed)
	tick_system.manual_smash_resolved.connect(_on_manual_smash_resolved)
	tick_system.auto_smash_requested.connect(_on_auto_smash_requested)
	atom_effects_controller.configure(
		effects_layer,
		fuse_button,
		game_state,
		element_system,
		upgrades_system,
		icon_cache
	)
	world_view_controller.configure(
		world_page,
		icon_cache,
		UPGRADE_BUTTON_TEXTURE,
		ENABLED_BUTTON_MODULATE,
		DISABLED_BUTTON_MODULATE
	)
	world_view_controller.worker_purchase_requested.connect(_on_world_worker_button_pressed)
	world_view_controller.worker_allocation_changed.connect(_on_world_worker_slider_changed)
	_apply_reference_layout()

	_set_menu_mode(MENU_CLOSED)
	_refresh_ui()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_reference_layout()

func _process(delta: float) -> void:
	if view_mode == VIEW_ATOM:
		var resolved_auto_smashes := atom_effects_controller.update(delta)
		if resolved_auto_smashes > 0:
			dust_recipe_service.invalidate()
			_pulse_fuse_element()
			_refresh_ui(_get_resource_refresh_flags())
	world_view_controller.update(delta, view_mode == VIEW_WORLD)

func _unhandled_input(event: InputEvent) -> void:
	pass

func _exit_tree() -> void:
	if game_state != null and SaveManager.save_state(game_state):
		game_state.last_save_tick = game_state.tick_count

func _build_default_state() -> GameState:
	var elements_content: Dictionary = _load_json_dictionary(ELEMENTS_DATA_PATH)
	var upgrades_content: Dictionary = _load_json_dictionary(UPGRADES_DATA_PATH)
	var planets_content: Dictionary = _load_json_dictionary(PLANETS_DATA_PATH)
	return GameState.from_content(elements_content, upgrades_content, planets_content)

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

func _apply_shell_metrics() -> void:
	counter_list.add_theme_constant_override("separation", UIMetrics.COUNTER_LIST_SEPARATION)
	for panel in [
		main_menu_panel,
		upgrades_panel,
		elements_panel,
		stats_panel,
		shop_panel,
		planets_panel,
		settings_panel
	]:
		panel.add_theme_constant_override("separation", UIMetrics.MENU_PANEL_SEPARATION)

	elements_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	elements_section_list.add_theme_constant_override("separation", UIMetrics.MENU_SECTION_LIST_SEPARATION)
	dust_action_row.add_theme_constant_override("separation", UIMetrics.DUST_ACTION_ROW_SEPARATION)
	make_dust_button.custom_minimum_size = UIMetrics.DUST_ACTION_PRIMARY_BUTTON_SIZE
	dust_close_button.custom_minimum_size = UIMetrics.DUST_ACTION_SECONDARY_BUTTON_SIZE

	era_timeline.custom_minimum_size = Vector2(0.0, UIMetrics.ERA_TIMELINE_MIN_HEIGHT)
	era_requirement_margin.add_theme_constant_override("margin_left", UIMetrics.ERA_REQUIREMENT_MARGIN)
	era_requirement_margin.add_theme_constant_override("margin_top", UIMetrics.ERA_REQUIREMENT_MARGIN)
	era_requirement_margin.add_theme_constant_override("margin_right", UIMetrics.ERA_REQUIREMENT_MARGIN)
	era_requirement_margin.add_theme_constant_override("margin_bottom", UIMetrics.ERA_REQUIREMENT_MARGIN)
	era_requirement_vbox.add_theme_constant_override("separation", UIMetrics.ERA_REQUIREMENT_VBOX_SEPARATION)
	era_requirement_list.add_theme_constant_override("separation", UIMetrics.ERA_REQUIREMENT_LIST_SEPARATION)

	currency_boxes.add_theme_constant_override("separation", UIMetrics.TOP_BAR_ROW_SEPARATION)
	orbs_row.add_theme_constant_override("separation", UIMetrics.TOP_BAR_ROW_SEPARATION)
	dust_row.add_theme_constant_override("separation", UIMetrics.TOP_BAR_ROW_SEPARATION)
	orbs_icon_slot.custom_minimum_size = UIMetrics.TOP_BAR_ICON_SLOT_SIZE
	dust_icon_slot.custom_minimum_size = UIMetrics.TOP_BAR_ICON_SLOT_SIZE

	nav_slots.add_theme_constant_override("separation", UIMetrics.NAV_SLOT_SEPARATION)
	for slot in [prev_slot, next_slot, zin_slot, zout_slot, menu_slot]:
		slot.custom_minimum_size = UIMetrics.NAV_SLOT_SIZE

func _apply_reference_layout() -> void:
	custom_minimum_size = UIMetrics.REFERENCE_VIEWPORT_SIZE
	_layout_root_overlays()
	_layout_top_bar()
	_layout_bottom_bar()
	_layout_counter_column()
	_layout_atom_focus_controls()
	world_view_controller.apply_reference_layout()

func _layout_root_overlays() -> void:
	_set_fill_rect(overlay_dim, 0.0, 0.0, 0.0, 0.0)
	_set_fill_rect(menu_overlay, 0.0, UIMetrics.TOP_BAR_HEIGHT, 0.0, UIMetrics.BOTTOM_BAR_HEIGHT)
	_set_fill_rect(menu_background, UIMetrics.MENU_BACKGROUND_MARGIN, UIMetrics.MENU_BACKGROUND_MARGIN, UIMetrics.MENU_BACKGROUND_MARGIN, UIMetrics.MENU_BACKGROUND_MARGIN)
	_set_fill_rect(menu_content, UIMetrics.MENU_CONTENT_MARGIN, UIMetrics.MENU_CONTENT_MARGIN, UIMetrics.MENU_CONTENT_MARGIN, UIMetrics.MENU_CONTENT_MARGIN)

func _layout_top_bar() -> void:
	_set_top_strip_rect(top_bar, UIMetrics.TOP_BAR_HEIGHT)
	_set_top_left_rect(profile_button, UIMetrics.TOP_BAR_PROFILE_MARGIN, UIMetrics.TOP_BAR_PROFILE_SIZE)
	_set_top_left_rect(level_label, UIMetrics.TOP_BAR_LEVEL_MARGIN, UIMetrics.TOP_BAR_LEVEL_SIZE)
	_set_center_anchor_rect(currency_boxes, UIMetrics.CURRENCY_BOXES_SIZE)

func _layout_bottom_bar() -> void:
	_set_bottom_strip_rect(bottom_bar, UIMetrics.BOTTOM_BAR_HEIGHT)
	_set_center_anchor_rect(nav_slots, UIMetrics.NAV_SLOTS_SIZE)

func _layout_counter_column() -> void:
	_set_left_column_rect(
		counter_margin,
		UIMetrics.COUNTER_MARGIN_LEFT,
		UIMetrics.COUNTER_MARGIN_TOP,
		UIMetrics.COUNTER_COLUMN_WIDTH,
		UIMetrics.COUNTER_MARGIN_BOTTOM
	)

func _layout_atom_focus_controls() -> void:
	_set_center_anchor_rect(fuse_button, UIMetrics.FUSE_BUTTON_SIZE)
	_set_top_right_rect(shop_button, UIMetrics.SHOP_BUTTON_TOP_MARGIN, UIMetrics.SHOP_BUTTON_RIGHT_MARGIN, UIMetrics.SHOP_BUTTON_SIZE)

func _set_fill_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = -right
	control.offset_bottom = -bottom

func _set_top_strip_rect(control: Control, height: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = height

func _set_bottom_strip_rect(control: Control, height: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 1.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = 0.0
	control.offset_top = -height
	control.offset_right = 0.0
	control.offset_bottom = 0.0

func _set_top_wide_rect(control: Control, top: float, height: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = top
	control.offset_right = 0.0
	control.offset_bottom = top + height

func _set_top_left_rect(control: Control, margin: Vector2, size_value: Vector2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = margin.x
	control.offset_top = margin.y
	control.offset_right = margin.x + size_value.x
	control.offset_bottom = margin.y + size_value.y

func _set_top_right_rect(control: Control, top: float, right: float, size_value: Vector2) -> void:
	control.anchor_left = 1.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = -(right + size_value.x)
	control.offset_top = top
	control.offset_right = -right
	control.offset_bottom = top + size_value.y

func _set_left_column_rect(control: Control, left: float, top: float, width: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = left + width
	control.offset_bottom = -bottom

func _set_center_anchor_rect(control: Control, size_value: Vector2, center_offset: Vector2 = Vector2.ZERO) -> void:
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = center_offset.x - (size_value.x * 0.5)
	control.offset_top = center_offset.y - (size_value.y * 0.5)
	control.offset_right = center_offset.x + (size_value.x * 0.5)
	control.offset_bottom = center_offset.y + (size_value.y * 0.5)

func _set_bottom_center_rect(control: Control, size_value: Vector2, bottom: float) -> void:
	control.anchor_left = 0.5
	control.anchor_top = 1.0
	control.anchor_right = 0.5
	control.anchor_bottom = 1.0
	control.offset_left = -(size_value.x * 0.5)
	control.offset_top = -(bottom + size_value.y)
	control.offset_right = size_value.x * 0.5
	control.offset_bottom = -bottom

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
	shop_title.add_theme_font_override("font", ui_font)
	shop_info.add_theme_font_override("font", ui_font)
	planets_title.add_theme_font_override("font", ui_font)
	planets_info.add_theme_font_override("font", ui_font)
	settings_title.add_theme_font_override("font", ui_font)
	settings_info.add_theme_font_override("font", ui_font)
	click_boxes_toggle.add_theme_font_override("font", ui_font)
	add_dust_button.add_theme_font_override("font", ui_font)
	add_orbs_button.add_theme_font_override("font", ui_font)
	upgrades_menu_button.add_theme_font_override("font", ui_font)
	elements_menu_button.add_theme_font_override("font", ui_font)
	era_menu_button.add_theme_font_override("font", ui_font)
	planets_menu_button.add_theme_font_override("font", ui_font)
	stats_menu_button.add_theme_font_override("font", ui_font)
	shop_menu_button.add_theme_font_override("font", ui_font)
	settings_menu_button.add_theme_font_override("font", ui_font)
	unlock_button.add_theme_font_override("font", ui_font)
	profile_button.add_theme_font_override("font", ui_font)
	make_dust_label.add_theme_font_override("font", ui_font)
	dust_close_label.add_theme_font_override("font", ui_font)

func _apply_currency_box_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color8(45, 45, 45)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color8(16, 16, 16)
	style.content_margin_left = UIMetrics.CURRENCY_PANEL_MARGIN_X
	style.content_margin_top = UIMetrics.CURRENCY_PANEL_MARGIN_Y
	style.content_margin_right = UIMetrics.CURRENCY_PANEL_MARGIN_X
	style.content_margin_bottom = UIMetrics.CURRENCY_PANEL_MARGIN_Y
	panel.add_theme_stylebox_override("panel", style)

func _apply_currency_labels() -> void:
	level_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	level_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	orbs_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	orbs_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	dust_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	dust_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _apply_menu_text_style() -> void:
	main_menu_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	upgrades_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	elements_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	era_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	era_status.add_theme_font_size_override("font_size", UIMetrics.ERA_STATUS_FONT_SIZE)
	era_requirement_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_LARGE)
	stats_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	shop_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	planets_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	settings_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
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
	shop_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	shop_info.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	planets_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	planets_info.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	settings_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	settings_info.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	click_boxes_toggle.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_dust_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	add_orbs_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _apply_dust_action_text_style() -> void:
	make_dust_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	make_dust_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	dust_close_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	dust_close_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))

func _apply_menu_button_style(button: Button, is_enabled: bool) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not is_enabled
	if is_enabled:
		button.modulate = ENABLED_BUTTON_MODULATE
	else:
		button.modulate = DISABLED_BUTTON_MODULATE

func _configure_placeholder_slot(slot: ColorRect) -> void:
	slot.color = Color8(25, 25, 25, 180)

func _apply_debug_hitbox_style(panel: Panel) -> void:
	if panel == null:
		return
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = DEBUG_HITBOX_COLOR
	panel.add_theme_stylebox_override("panel", style)

func _refresh_debug_hitboxes() -> void:
	fuse_hitbox_debug.visible = debug_show_element_hitboxes and view_mode == VIEW_ATOM
	for element_id in element_menu_tiles.keys():
		var tile: ElementMenuTile = element_menu_tiles[element_id]
		tile.set_debug_hitbox_visible(debug_show_element_hitboxes)

func _set_menu_mode(new_mode: int) -> void:
	if new_mode != MENU_ELEMENTS:
		dust_mode_active = false
	menu_mode = new_mode
	menu_overlay.visible = menu_mode != MENU_CLOSED
	main_menu_panel.visible = menu_mode == MENU_MAIN
	upgrades_panel.visible = menu_mode == MENU_UPGRADES
	elements_panel.visible = menu_mode == MENU_ELEMENTS
	era_panel.visible = menu_mode == MENU_ERA
	stats_panel.visible = menu_mode == MENU_STATS
	shop_panel.visible = menu_mode == MENU_SHOP
	planets_panel.visible = menu_mode == MENU_PLANETS
	settings_panel.visible = menu_mode == MENU_SETTINGS
	_update_menu_button_texture()

func _set_view_mode(new_mode: int) -> void:
	if view_mode == new_mode:
		return
	view_mode = new_mode
	if view_mode == VIEW_WORLD:
		atom_effects_controller.clear()
	else:
		world_view_controller.clear_particles()
	_mark_ui_dirty(UI_DIRTY_DEBUG)

func _mark_ui_dirty(flags: int) -> void:
	if flags == 0:
		return
	_ui_dirty_flags |= flags

func _get_resource_refresh_flags() -> int:
	return (
		UI_DIRTY_TOP_BAR
		| UI_DIRTY_COUNTERS
		| UI_DIRTY_UPGRADES
		| UI_DIRTY_ELEMENTS
		| UI_DIRTY_ERA
		| UI_DIRTY_STATS
		| UI_DIRTY_PLANETS
		| UI_DIRTY_WORLD
	)

func _get_selection_refresh_flags() -> int:
	return UI_DIRTY_SELECTION | UI_DIRTY_NAVIGATION | UI_DIRTY_ELEMENTS | UI_DIRTY_STATS

func _get_menu_mode_refresh_flags() -> int:
	var flags := UI_DIRTY_MENU_BUTTONS
	match menu_mode:
		MENU_UPGRADES:
			flags |= UI_DIRTY_UPGRADES
		MENU_ELEMENTS:
			flags |= UI_DIRTY_ELEMENTS
		MENU_ERA:
			flags |= UI_DIRTY_ERA
		MENU_STATS:
			flags |= UI_DIRTY_STATS
		MENU_SHOP:
			flags |= UI_DIRTY_SHOP
		MENU_PLANETS:
			flags |= UI_DIRTY_PLANETS
		MENU_SETTINGS:
			flags |= UI_DIRTY_SETTINGS
	return flags

func _get_view_mode_refresh_flags() -> int:
	return UI_DIRTY_NAVIGATION | UI_DIRTY_COUNTERS | UI_DIRTY_WORLD | UI_DIRTY_DEBUG | UI_DIRTY_MENU_BUTTONS

func _ensure_era_requirement_labels() -> void:
	if not era_requirement_labels.is_empty():
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

func _get_counter_ids() -> Array[String]:
	var visible_ids: Array[String] = game_state.get_visible_counter_element_ids()
	var limited_ids: Array[String] = []
	for element_id in visible_ids:
		limited_ids.append(element_id)
		if limited_ids.size() >= MAX_COUNTERS:
			break
	return limited_ids

func _sync_resource_displays() -> void:
	if not counter_margin.visible:
		return

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
	if not upgrades_panel.visible:
		return

	var upgrade_ids: Array[String] = []
	for upgrade_id in game_state.get_upgrade_ids():
		if upgrades_system.should_show_upgrade(game_state, upgrade_id):
			upgrade_ids.append(upgrade_id)
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

func _refresh_ui(flags: int = UI_DIRTY_ALL) -> void:
	_mark_ui_dirty(flags)
	_flush_dirty_ui()

func _flush_dirty_ui() -> void:
	if game_state == null:
		return

	while _ui_dirty_flags != 0:
		var flags := _ui_dirty_flags
		_ui_dirty_flags = 0

		if flags & UI_DIRTY_NAVIGATION:
			_refresh_navigation()
		if flags & UI_DIRTY_TOP_BAR:
			_refresh_top_bar()
		if flags & UI_DIRTY_SELECTION:
			_refresh_selection_ui()
		if flags & UI_DIRTY_MENU_BUTTONS:
			_refresh_menu_buttons()
		if flags & UI_DIRTY_COUNTERS:
			_sync_resource_displays()
		if flags & UI_DIRTY_UPGRADES:
			_refresh_upgrades_panel()
		if flags & UI_DIRTY_ELEMENTS:
			_refresh_elements_panel()
		if flags & UI_DIRTY_ERA:
			_refresh_era_ui()
		if flags & UI_DIRTY_STATS:
			_refresh_stats_panel()
		if flags & UI_DIRTY_SHOP:
			_refresh_shop_panel()
		if flags & UI_DIRTY_PLANETS:
			_refresh_planets_panel()
		if flags & UI_DIRTY_SETTINGS:
			_refresh_settings_panel()
		if flags & UI_DIRTY_WORLD:
			_refresh_world_ui()
		if flags & UI_DIRTY_DEBUG:
			_refresh_debug_hitboxes()

func _refresh_top_bar() -> void:
	level_label.text = "Lv. %d" % game_state.player_level
	orbs_label.text = "ORBS %s" % str(game_state.orbs)
	dust_label.text = "DUST %s" % game_state.dust.big_to_short_string()

func _refresh_selection_ui() -> void:
	var current_element: Dictionary = game_state.get_current_element()
	var current_index := int(current_element.get("index", 0))
	var current_icon := icon_cache.get_element_icon(current_index)
	fuse_button.texture_normal = current_icon
	fuse_button.texture_pressed = current_icon
	fuse_button.texture_hover = current_icon
	fuse_button.texture_disabled = current_icon

func _refresh_navigation() -> void:
	fuse_button.visible = view_mode == VIEW_ATOM
	effects_layer.visible = view_mode == VIEW_ATOM
	counter_margin.visible = view_mode == VIEW_ATOM
	world_view_controller.set_navigation_state(view_mode == VIEW_WORLD, game_state.has_unlocked_era(1))

	if view_mode == VIEW_WORLD:
		_set_button_enabled_state(prev_button, false)
		_set_button_enabled_state(next_button, false)
		_set_button_enabled_state(zin_button, true)
		_set_button_enabled_state(zout_button, false)
	else:
		_set_button_enabled_state(prev_button, game_state.has_adjacent_unlocked_element(-1))
		_set_button_enabled_state(next_button, game_state.has_next_selectable_element_in_visible_sections())
		_set_button_enabled_state(zin_button, false)
		_set_button_enabled_state(zout_button, game_state.has_unlocked_era(1))

func _refresh_menu_buttons() -> void:
	var era_menu_enabled := game_state.is_era_menu_unlocked()
	_apply_menu_button_style(era_menu_button, era_menu_enabled)
	var planets_enabled := game_state.has_unlocked_era(1)
	_apply_menu_button_style(planets_menu_button, planets_enabled)
	var shop_enabled := game_state.is_element_unlocked("ele_H")
	_apply_menu_button_style(shop_menu_button, shop_enabled)
	shop_button.visible = shop_enabled and menu_mode == MENU_CLOSED

func _refresh_upgrades_panel() -> void:
	if not upgrades_panel.visible:
		return

	upgrades_info.text = "Particle Smasher: %.2f actions/sec\nCrit Chance: %.0f%% | Crit Payload: %.0f%%\nFission Chance: %.0f%% | Double Hit: %.0f%%\nResonant Yield: %.0f%%" % [
		upgrades_system.get_auto_smashes_per_second(game_state),
		upgrades_system.get_global_critical_smash_chance_percent(game_state),
		upgrades_system.get_critical_payload_chance_percent(game_state),
		upgrades_system.get_fission_chance_percent(game_state),
		upgrades_system.get_manual_double_hit_chance(game_state) * 100.0,
		upgrades_system.get_resonant_yield_chance(game_state) * 100.0
	]
	_sync_upgrade_buttons()

func _refresh_stats_panel() -> void:
	if not stats_panel.visible:
		return

	var current_element: Dictionary = game_state.get_current_element()
	var current_name := str(current_element.get("name", ""))
	var produced_name := game_state.get_resource_name(str(current_element.get("produces", "")))
	stats_info.text = "Current Element: %s\nProduces: %s\nManual Smashes: %d\nAuto Smashes: %d" % [
		current_name,
		produced_name,
		game_state.total_manual_smashes,
		game_state.total_auto_smashes
	]
	planetary_stats_info.visible = game_state.has_unlocked_era(1)
	if planetary_stats_info.visible:
		planetary_stats_info.text = "Planetary Stats\nResearch Points: %s\nPrestige Count: %d" % [
			game_state.get_research_points().big_to_short_string(),
			game_state.prestige_count
		]

func _refresh_shop_panel() -> void:
	if not shop_panel.visible:
		return

	shop_info.text = "Shop inventory is not implemented yet.\nThis panel will hold orb and meta purchases."

func _refresh_planets_panel() -> void:
	if not planets_panel.visible:
		return

	planets_info.text = "Planets menu is not implemented yet.\nCurrent RP: %s" % game_state.get_research_points().big_to_short_string()

func _refresh_settings_panel() -> void:
	if not settings_panel.visible:
		return

	settings_info.text = "Developer Tools"
	click_boxes_toggle.button_pressed = debug_show_element_hitboxes

func _refresh_elements_panel() -> void:
	if not elements_panel.visible:
		return

	_sync_element_menu_tiles()

	var current_element: Dictionary = game_state.get_current_element()
	var current_name := str(current_element.get("name", ""))
	var produced_name := game_state.get_resource_name(str(current_element.get("produces", "")))

	var next_unlock: Dictionary = game_state.get_next_unlock_element()
	var dust_preview := DigitMaster.zero()
	var selected_batch_count := 0
	if dust_mode_active:
		dust_preview = dust_recipe_service.get_preview(game_state, upgrades_system)
		selected_batch_count = dust_recipe_service.get_selected_element_ids(game_state, upgrades_system).size()
	if next_unlock.is_empty():
		if dust_mode_active:
			elements_info.text = "Dust Mode\nSelected Elements: %d\nPredicted Dust: %s" % [
				selected_batch_count,
				dust_preview.big_to_short_string()
			]
		else:
			elements_info.text = "Selected: %s\nAll elements unlocked." % current_name
		unlock_button.text = "All elements unlocked"
		unlock_button.disabled = true
		unlock_button.visible = false
	else:
		var unlock_id := str(next_unlock.get("id", ""))
		var unlock_cost: DigitMaster = next_unlock["cost"]
		if not game_state.is_next_unlock_within_visible_sections():
			if dust_mode_active:
				elements_info.text = "Dust Mode\nSelected Elements: %d\nPredicted Dust: %s" % [
					selected_batch_count,
					dust_preview.big_to_short_string()
				]
			else:
				elements_info.text = "Selected: %s\nProduces: %s\nNext section is locked." % [
					current_name,
					produced_name
				]
			unlock_button.text = "Next section locked"
			unlock_button.disabled = true
			unlock_button.visible = false
		else:
			if dust_mode_active:
				elements_info.text = "Dust Mode\nSelected Elements: %d\nPredicted Dust: %s" % [
					selected_batch_count,
					dust_preview.big_to_short_string()
				]
			else:
				elements_info.text = "Selected: %s\nProduces: %s\nNext: %s\nRequires: %s %s" % [
					current_name,
					produced_name,
					str(next_unlock.get("name", unlock_id)),
					unlock_cost.big_to_short_string(),
					game_state.get_resource_name(unlock_id)
				]
			unlock_button.text = "Unlock %s" % str(next_unlock.get("name", unlock_id))
			unlock_button.disabled = not game_state.can_unlock_next()
			unlock_button.visible = true
		if dust_mode_active:
			unlock_button.disabled = true

	make_dust_button.visible = true
	dust_close_button.visible = dust_mode_active
	make_dust_label.text = "MAKE DUST"
	if dust_mode_active:
		make_dust_label.text = "%s DUST" % dust_preview.big_to_short_string()
	make_dust_button.disabled = dust_mode_active and dust_preview.is_zero()
	make_dust_button.modulate = ENABLED_BUTTON_MODULATE if not make_dust_button.disabled else DISABLED_BUTTON_MODULATE
	dust_close_button.modulate = ENABLED_BUTTON_MODULATE

func _refresh_world_ui() -> void:
	world_view_controller.refresh(game_state, view_mode == VIEW_WORLD)

func _refresh_era_ui() -> void:
	if not era_panel.visible:
		return

	var unlocked_era_index := game_state.get_unlocked_era_index()
	era_timeline.texture = icon_cache.get_era_frame(unlocked_era_index)
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

	var target_height := round(
		target_width * (
			float(GameIconCache.ERA_SHEET_FRAME_SIZE.y)
			/ float(GameIconCache.ERA_SHEET_FRAME_SIZE.x)
		)
	)
	if absf(era_timeline.custom_minimum_size.y - target_height) > 0.5:
		era_timeline.custom_minimum_size = Vector2(0.0, target_height)
		era_timeline.offset_bottom = target_height

func _update_era_requirement_card_position() -> void:
	if not is_instance_valid(era_requirement_card):
		return

	var top_offset := round(era_timeline.custom_minimum_size.y * UIMetrics.ERA_REQUIREMENT_CARD_TOP_RATIO)
	era_requirement_card.offset_left = UIMetrics.ERA_REQUIREMENT_CARD_SIDE_MARGIN
	era_requirement_card.offset_right = -UIMetrics.ERA_REQUIREMENT_CARD_SIDE_MARGIN
	era_requirement_card.offset_top = top_offset

func _set_button_enabled_state(button: TextureButton, is_enabled: bool) -> void:
	button.disabled = not is_enabled
	if is_enabled:
		button.modulate = ENABLED_BUTTON_MODULATE
	else:
		button.modulate = DISABLED_BUTTON_MODULATE

func _get_visible_element_section_count() -> int:
	return clampi(game_state.prestige_count + 1, 1, ELEMENT_MENU_SECTIONS.size())

func _sync_element_menu_tiles() -> void:
	if not elements_panel.visible:
		return

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
			section_box.add_theme_constant_override("separation", UIMetrics.MENU_SECTION_BOX_SEPARATION)
			elements_section_list.add_child(section_box)

			var header := Label.new()
			header.text = str(section_data.get("title", ""))
			header.add_theme_font_size_override("font_size", UIMetrics.MENU_SECTION_HEADER_FONT_SIZE)
			header.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			var ui_font: FontFile = UIFont.load_ui_font()
			if ui_font != null:
				header.add_theme_font_override("font", ui_font)
			section_box.add_child(header)

			var grid := GridContainer.new()
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.columns = int(section_data.get("columns", 5))
			grid.add_theme_constant_override("h_separation", UIMetrics.MENU_GRID_SPACING)
			grid.add_theme_constant_override("v_separation", UIMetrics.MENU_GRID_SPACING)
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
		var dust_fraction := 0.0
		if dust_mode_active:
			dust_fraction = dust_recipe_service.get_selection_fraction(element_id)
		tile.refresh(game_state.current_element_id, dust_fraction)
		tile.set_debug_hitbox_visible(debug_show_element_hitboxes)

func _perform_dust_conversion() -> bool:
	var selected_amounts: Dictionary = dust_recipe_service.get_selected_amounts(game_state, upgrades_system)
	if selected_amounts.is_empty():
		return false

	var dust_preview: DigitMaster = dust_recipe_service.get_preview(game_state, upgrades_system)
	if dust_preview.is_zero():
		return false

	for element_id_variant in selected_amounts.keys():
		var element_id := str(element_id_variant)
		var amount: DigitMaster = selected_amounts[element_id]
		if not game_state.can_afford_resource(element_id, amount):
			return false

	for element_id_variant in selected_amounts.keys():
		var element_id := str(element_id_variant)
		var amount: DigitMaster = selected_amounts[element_id]
		if not game_state.spend_resource(element_id, amount):
			return false

	game_state.produce_resource(GameState.DUST_RESOURCE_ID, dust_preview)
	dust_recipe_service.invalidate()
	return true

func _autosave_if_needed() -> void:
	if game_state.tick_count - game_state.last_save_tick < AUTO_SAVE_INTERVAL_TICKS:
		return
	if SaveManager.save_state(game_state):
		game_state.last_save_tick = game_state.tick_count

func _on_tick_processed(_tick_count: int, processed_actions: Array) -> void:
	var dirty_flags := UI_DIRTY_WORLD | UI_DIRTY_PLANETS
	for action_type_variant in processed_actions:
		match str(action_type_variant):
			"unlock_next":
				dust_recipe_service.invalidate()
				dirty_flags |= _get_resource_refresh_flags() | _get_selection_refresh_flags() | UI_DIRTY_MENU_BUTTONS
			"select_adjacent", "select_element":
				dirty_flags |= _get_selection_refresh_flags()
			"purchase_upgrade":
				dust_recipe_service.invalidate()
				dirty_flags |= _get_resource_refresh_flags()
	if dirty_flags != 0:
		_refresh_ui(dirty_flags)
	_autosave_if_needed()

func _on_manual_smash_resolved(result: Dictionary) -> void:
	dust_recipe_service.invalidate()
	_pulse_fuse_element()
	atom_effects_controller.spawn_manual_result(result)
	_refresh_ui(_get_resource_refresh_flags())

func _on_auto_smash_requested(request: Dictionary) -> void:
	var target_element_id := str(request.get("target_element_id", ""))
	var spawn_count := int(request.get("spawn_count", 1))
	if view_mode != VIEW_ATOM:
		var any_resolved := false
		for _i in range(spawn_count):
			var result: Dictionary = element_system.resolve_auto_smash(game_state, upgrades_system, target_element_id)
			if not result.is_empty():
				any_resolved = true
		if any_resolved:
			dust_recipe_service.invalidate()
			_refresh_ui(_get_resource_refresh_flags())
		return
	atom_effects_controller.spawn_auto_smashes(target_element_id, spawn_count)

func _on_prev_pressed() -> void:
	tick_system.enqueue_action("select_adjacent", {"direction": -1})

func _on_next_pressed() -> void:
	tick_system.enqueue_action("select_adjacent", {"direction": 1})

func _on_zin_pressed() -> void:
	if view_mode != VIEW_WORLD:
		return
	_set_view_mode(VIEW_ATOM)
	_refresh_ui(_get_view_mode_refresh_flags())

func _on_zout_pressed() -> void:
	if not game_state.has_unlocked_era(1):
		return
	_set_view_mode(VIEW_WORLD)
	_refresh_ui(_get_view_mode_refresh_flags())

func _on_smash_pressed() -> void:
	if view_mode != VIEW_ATOM:
		return
	tick_system.enqueue_action("manual_smash")

func _on_menu_pressed() -> void:
	match menu_mode:
		MENU_CLOSED:
			_set_menu_mode(MENU_MAIN)
		MENU_MAIN:
			_set_menu_mode(MENU_CLOSED)
		_:
			_set_menu_mode(MENU_MAIN)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_upgrades_menu_pressed() -> void:
	_set_menu_mode(MENU_UPGRADES)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_elements_menu_pressed() -> void:
	_set_menu_mode(MENU_ELEMENTS)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_era_menu_pressed() -> void:
	if not game_state.is_era_menu_unlocked():
		return
	_set_menu_mode(MENU_ERA)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_planets_menu_pressed() -> void:
	if not game_state.has_unlocked_era(1):
		return
	_set_menu_mode(MENU_PLANETS)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_stats_menu_pressed() -> void:
	_set_menu_mode(MENU_STATS)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_shop_pressed() -> void:
	if not game_state.is_element_unlocked("ele_H"):
		return
	_set_menu_mode(MENU_SHOP)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_settings_menu_pressed() -> void:
	_set_menu_mode(MENU_SETTINGS)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_element_tile_pressed(element_id: String) -> void:
	if dust_mode_active:
		dust_recipe_service.cycle_selection(element_id)
		_refresh_ui(UI_DIRTY_ELEMENTS)
		return
	if game_state.select_element(element_id):
		_set_menu_mode(MENU_CLOSED)
		_refresh_ui(_get_selection_refresh_flags() | UI_DIRTY_MENU_BUTTONS)

func _on_unlock_pressed() -> void:
	tick_system.enqueue_action("unlock_next")

func _on_make_dust_pressed() -> void:
	if not dust_mode_active:
		dust_mode_active = true
		dust_recipe_service.invalidate()
		_refresh_ui(UI_DIRTY_ELEMENTS)
		return

	if _perform_dust_conversion():
		dust_mode_active = false
		_refresh_ui(_get_resource_refresh_flags())

func _on_dust_close_pressed() -> void:
	dust_mode_active = false
	_refresh_ui(UI_DIRTY_ELEMENTS)

func _on_click_boxes_toggled(toggled_on: bool) -> void:
	debug_show_element_hitboxes = toggled_on
	_refresh_ui(UI_DIRTY_DEBUG)

func _on_add_dust_pressed() -> void:
	game_state.produce_resource(GameState.DUST_RESOURCE_ID, DigitMaster.new(1000.0))
	dust_recipe_service.invalidate()
	_refresh_ui(_get_resource_refresh_flags())

func _on_add_orbs_pressed() -> void:
	game_state.orbs += 1000
	_refresh_ui(UI_DIRTY_TOP_BAR | UI_DIRTY_ERA)

func _on_era_unlock_pressed() -> void:
	if game_state.unlock_next_era():
		dust_recipe_service.invalidate()
		_refresh_ui(_get_resource_refresh_flags() | UI_DIRTY_NAVIGATION | UI_DIRTY_MENU_BUTTONS | UI_DIRTY_ERA)

func _on_world_worker_button_pressed() -> void:
	if game_state.buy_current_planet_worker():
		dust_recipe_service.invalidate()
		_refresh_ui(_get_resource_refresh_flags())

func _on_world_worker_slider_changed(value: float) -> void:
	game_state.set_current_planet_worker_allocation_to_xp(value / 100.0)
	if view_mode == VIEW_WORLD:
		_refresh_ui(UI_DIRTY_WORLD)

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
