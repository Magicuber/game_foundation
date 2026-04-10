extends Control

const ELEMENTS_DATA_PATH := "res://src/data/elements.json"
const UPGRADES_DATA_PATH := "res://src/data/upgrades.json"
const BLESSINGS_DATA_PATH := "res://src/data/blessings.json"
const PLANETS_DATA_PATH := "res://src/data/planets.json"
const PLANET_MENU_DATA_PATH := "res://src/data/planet_menu.json"
const BlessingsPanelControllerScript = preload("res://src/controllers/blessings_panel_controller.gd")
const PlanetsPanelControllerScript = preload("res://src/controllers/planets_panel_controller.gd")
const PrestigePanelControllerScript = preload("res://src/controllers/prestige_panel_controller.gd")
const UIMetrics = preload("res://src/ui/ui_metrics.gd")
const AUTO_SAVE_INTERVAL_TICKS := 50
const UPGRADE_BUTTON_TEXTURE = preload("res://assests/sprites/spr_upgrade_btn.png")
const DEBUG_HITBOX_COLOR := Color8(255, 80, 80)
const MAX_COUNTERS := 10
const FIRST_TIER_UNLOCK_COUNT := 10
const DISABLED_BUTTON_MODULATE := Color(0.45, 0.45, 0.45, 1.0)
const ENABLED_BUTTON_MODULATE := Color(1, 1, 1, 1)

const MENU_CLOSED := 0
const MENU_MAIN := 1
const MENU_PROFILE := 2
const MENU_UPGRADES := 3
const MENU_ELEMENTS := 4
const MENU_BLESSINGS := 5
const MENU_ERA := 6
const MENU_STATS := 7
const MENU_SHOP := 8
const MENU_PLANETS := 9
const MENU_PRESTIGE := 10
const MENU_FACTORY := 11
const MENU_COLLIDER := 12
const MENU_SETTINGS := 13

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
const UI_DIRTY_BLESSINGS := 1 << 11
const UI_DIRTY_WORLD := 1 << 12
const UI_DIRTY_MENU_BUTTONS := 1 << 13
const UI_DIRTY_DEBUG := 1 << 14
const UI_DIRTY_PRESTIGE := 1 << 15
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
	| UI_DIRTY_BLESSINGS
	| UI_DIRTY_WORLD
	| UI_DIRTY_MENU_BUTTONS
	| UI_DIRTY_DEBUG
	| UI_DIRTY_PRESTIGE
)

const PREV_BUTTON_TEXTURE = preload("res://assests/sprites/spr_prev_btn.png")
const NEXT_BUTTON_TEXTURE = preload("res://assests/sprites/spr_next_btn.png")
const MENU_BUTTON_TEXTURE = preload("res://assests/sprites/spr_menu_btn.png")
const CLOSE_BUTTON_TEXTURE = preload("res://assests/sprites/spr_close_btn1.png")
const ZIN_BUTTON_TEXTURE = preload("res://assests/sprites/spr_zin_btn.png")
const ZOUT_BUTTON_TEXTURE = preload("res://assests/sprites/spr_zout_btn.png")
const MENU_BACKGROUND_TEXTURE = preload("res://assests/sprites/spr_eleupgds_background.png")
const SHOP_BUTTON_TEXTURE = preload("res://assests/sprites/spr_shop_btn.png")
const NON_UNIQUE_UPGRADE_EFFECT_TYPES := {
	"auto_smash": true,
	"auto_smash_speed_bonus": true,
	"critical_auto_smash": true,
	"critical_spawn_bonus": true,
	"fission_split": true,
	"bonus_element_output": true,
	"manual_bonus_output": true
}

@onready var tick_system: TickSystem = $TickSystem
@onready var world_page: Control = $WorldPage
@onready var effects_layer: Control = $EffectsLayer
@onready var fuse_button: TextureButton = $FuseButton
@onready var fuse_hitbox_debug: Panel = $FuseButton/FuseHitboxDebug
@onready var menu_overlay: Control = $MenuOverlay
@onready var overlay_dim: ColorRect = $MenuOverlay/OverlayDim
@onready var menu_background: TextureRect = $MenuOverlay/MenuBackground
@onready var menu_content: MarginContainer = $MenuOverlay/MenuContent
@onready var menu_panels: Control = $MenuOverlay/MenuContent/MenuPanels
@onready var main_menu_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel
@onready var profile_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ProfilePanel
@onready var upgrades_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel
@onready var upgrades_scroll: ScrollContainer = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradeScroll
@onready var elements_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel
@onready var blessings_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/BlessingsPanel
@onready var era_panel: Control = $MenuOverlay/MenuContent/MenuPanels/EraPanel
@onready var stats_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/StatsPanel
@onready var shop_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ShopPanel
@onready var planets_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/PlanetsPanel
@onready var prestige_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/PrestigePanel
@onready var settings_panel: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel
@onready var main_menu_title: Label = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/MainMenuTitle
@onready var profile_title: Label = $MenuOverlay/MenuContent/MenuPanels/ProfilePanel/ProfileTitle
@onready var profile_info: Label = $MenuOverlay/MenuContent/MenuPanels/ProfilePanel/ProfileInfo
@onready var upgrades_title: Label = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradesTitle
@onready var upgrades_info: Label = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradesInfo
@onready var elements_title: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsTitle
@onready var elements_info: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsInfo
@onready var blessings_title: Label = $MenuOverlay/MenuContent/MenuPanels/BlessingsPanel/BlessingsTitle
@onready var blessings_info: Label = $MenuOverlay/MenuContent/MenuPanels/BlessingsPanel/BlessingsInfo
@onready var elements_scroll: ScrollContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsScroll
@onready var elements_section_list: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/ElementsScroll/ElementsSectionList
@onready var dust_action_row: HBoxContainer = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow
@onready var dust_cycle_all_button: TextureButton = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow/DustCycleAllButton
@onready var dust_cycle_all_label: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow/DustCycleAllButton/DustCycleAllLabel
@onready var dust_clear_all_button: TextureButton = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow/DustClearAllButton
@onready var dust_clear_all_label: Label = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/DustActionRow/DustClearAllButton/DustClearAllLabel
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
@onready var prestige_title: Label = $MenuOverlay/MenuContent/MenuPanels/PrestigePanel/PrestigeTitle
@onready var prestige_info: Label = $MenuOverlay/MenuContent/MenuPanels/PrestigePanel/PrestigeInfo
@onready var settings_title: Label = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/SettingsTitle
@onready var settings_info: Label = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/SettingsInfo
@onready var prestige_debug_row: HBoxContainer = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/PrestigeDebugRow
@onready var prestige_decrement_button: Button = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/PrestigeDebugRow/PrestigeDecrementButton
@onready var prestige_count_label: Label = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/PrestigeDebugRow/PrestigeCountLabel
@onready var prestige_increment_button: Button = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/PrestigeDebugRow/PrestigeIncrementButton
@onready var click_boxes_toggle: CheckButton = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/ClickBoxesToggle
@onready var add_dust_button: Button = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/AddDustButton
@onready var add_orbs_button: Button = $MenuOverlay/MenuContent/MenuPanels/SettingsPanel/AddOrbsButton
@onready var profile_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/ProfileMenuButton
@onready var upgrades_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/UpgradesMenuButton
@onready var elements_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/ElementsMenuButton
@onready var blessings_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/BlessingsMenuButton
@onready var era_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/EraMenuButton
@onready var planets_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/PlanetsMenuButton
@onready var prestige_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/PrestigeMenuButton
@onready var stats_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/StatsMenuButton
@onready var shop_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/ShopMenuButton
@onready var settings_menu_button: Button = $MenuOverlay/MenuContent/MenuPanels/MainMenuPanel/SettingsMenuButton
@onready var unlock_button: Button = $MenuOverlay/MenuContent/MenuPanels/ElementsPanel/UnlockButton
@onready var upgrade_list: VBoxContainer = $MenuOverlay/MenuContent/MenuPanels/UpgradesPanel/UpgradeScroll/UpgradeList
@onready var counter_margin: MarginContainer = $CounterMargin
@onready var counter_list: VBoxContainer = $CounterMargin/CounterList
@onready var top_bar: ColorRect = $TopBar
@onready var profile_button: Button = $TopBar/ProfileButton
@onready var level_label: Label = $TopBar/ProfileButton/LevelLabel
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
var reset_blessings_button: Button
var factory_menu_button: Button
var collider_menu_button: Button
var factory_panel: VBoxContainer
var factory_title: Label
var factory_info: Label
var collider_panel: VBoxContainer
var collider_title: Label
var collider_info: Label
var menu_mode: int = MENU_CLOSED
var view_mode: int = VIEW_ATOM
var debug_show_element_hitboxes := false
var dust_mode_active := false
var _ui_dirty_flags: int = UI_DIRTY_ALL
var icon_cache: GameIconCache = GameIconCache.new()
var dust_recipe_service: DustRecipeService = DustRecipeService.new()
var atom_effects_controller: AtomEffectsController = AtomEffectsController.new()
var world_view_controller: WorldViewController = WorldViewController.new()
var hud_controller: HudController = HudController.new()
var menu_controller: MenuController = MenuController.new()
var element_menu_controller: ElementMenuController = ElementMenuController.new()
var blessings_panel_controller = BlessingsPanelControllerScript.new()
var planets_panel_controller = PlanetsPanelControllerScript.new()
var prestige_panel_controller = PrestigePanelControllerScript.new()
var upgrades_panel_controller: UpgradesPanelController = UpgradesPanelController.new()
var era_panel_controller: EraPanelController = EraPanelController.new()

func _ready() -> void:
	set_process(true)

	game_state = _build_default_state()
	SaveManager.load_into_state(game_state)
	upgrades_system.mark_cache_dirty()
	_ensure_factory_and_collider_menu_nodes()

	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	zin_button.pressed.connect(_on_zin_pressed)
	zout_button.pressed.connect(_on_zout_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	fuse_button.pressed.connect(_on_smash_pressed)
	profile_button.pressed.connect(_on_profile_menu_pressed)
	profile_menu_button.pressed.connect(_on_profile_menu_pressed)
	upgrades_menu_button.pressed.connect(_on_upgrades_menu_pressed)
	elements_menu_button.pressed.connect(_on_elements_menu_pressed)
	blessings_menu_button.pressed.connect(_on_blessings_menu_pressed)
	era_menu_button.pressed.connect(_on_era_menu_pressed)
	planets_menu_button.pressed.connect(_on_planets_menu_pressed)
	prestige_menu_button.pressed.connect(_on_prestige_menu_pressed)
	factory_menu_button.pressed.connect(_on_factory_menu_pressed)
	collider_menu_button.pressed.connect(_on_collider_menu_pressed)
	stats_menu_button.pressed.connect(_on_stats_menu_pressed)
	shop_menu_button.pressed.connect(_on_shop_pressed)
	settings_menu_button.pressed.connect(_on_settings_menu_pressed)
	prestige_decrement_button.pressed.connect(_on_prestige_decrement_pressed)
	prestige_increment_button.pressed.connect(_on_prestige_increment_pressed)
	click_boxes_toggle.toggled.connect(_on_click_boxes_toggled)
	add_dust_button.pressed.connect(_on_add_dust_pressed)
	add_orbs_button.pressed.connect(_on_add_orbs_pressed)
	_ensure_reset_blessings_button()
	blessings_menu_button.text = "Blessings"

	fuse_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fuse_button.pivot_offset = fuse_button.size * 0.5
	_apply_debug_hitbox_style(fuse_hitbox_debug)

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
	hud_controller.configure(
		counter_margin,
		counter_list,
		top_bar,
		profile_button,
		level_label,
		currency_boxes,
		orbs_panel,
		dust_panel,
		orbs_row,
		dust_row,
		orbs_icon_slot,
		dust_icon_slot,
		orbs_label,
		dust_label,
		bottom_bar,
		nav_slots,
		prev_slot,
		next_slot,
		zin_slot,
		zout_slot,
		menu_slot,
		prev_button,
		next_button,
		zin_button,
		zout_button,
		menu_button,
		shop_button,
		PREV_BUTTON_TEXTURE,
		NEXT_BUTTON_TEXTURE,
		ZIN_BUTTON_TEXTURE,
		ZOUT_BUTTON_TEXTURE,
		MENU_BUTTON_TEXTURE,
		CLOSE_BUTTON_TEXTURE,
		SHOP_BUTTON_TEXTURE,
		ENABLED_BUTTON_MODULATE,
		DISABLED_BUTTON_MODULATE
	)
	hud_controller.apply_style()
	hud_controller.apply_shell_metrics()
	menu_controller.configure(
		menu_overlay,
		overlay_dim,
		menu_background,
		menu_content,
		main_menu_panel,
		profile_panel,
		upgrades_panel,
		upgrades_scroll,
		elements_panel,
		blessings_panel,
		era_panel,
		stats_panel,
		shop_panel,
		planets_panel,
		prestige_panel,
		factory_panel,
		collider_panel,
		settings_panel,
		main_menu_title,
		profile_title,
		profile_info,
		upgrades_title,
		upgrades_info,
		elements_title,
		elements_info,
		blessings_title,
		blessings_info,
		era_title,
		era_status,
		era_requirement_margin,
		era_requirement_vbox,
		era_requirement_title,
		era_requirement_list,
		era_unlock_button,
		stats_title,
		stats_info,
		planetary_stats_info,
		shop_title,
		shop_info,
		planets_title,
		planets_info,
		prestige_title,
		prestige_info,
		factory_title,
		factory_info,
		collider_title,
		collider_info,
		settings_title,
		settings_info,
		prestige_debug_row,
		prestige_decrement_button,
		prestige_count_label,
		prestige_increment_button,
		click_boxes_toggle,
		add_dust_button,
		add_orbs_button,
		profile_menu_button,
		upgrades_menu_button,
		elements_menu_button,
		blessings_menu_button,
		era_menu_button,
		planets_menu_button,
		prestige_menu_button,
		factory_menu_button,
		collider_menu_button,
		stats_menu_button,
		shop_menu_button,
		settings_menu_button,
		unlock_button,
		elements_scroll,
		elements_section_list,
		dust_action_row,
		dust_cycle_all_button,
		dust_cycle_all_label,
		dust_clear_all_button,
		dust_clear_all_label,
		make_dust_button,
		make_dust_label,
		dust_close_button,
		dust_close_label,
		MENU_BACKGROUND_TEXTURE,
		UPGRADE_BUTTON_TEXTURE,
		ENABLED_BUTTON_MODULATE,
		DISABLED_BUTTON_MODULATE
	)
	menu_controller.apply_style()
	menu_controller.apply_shell_metrics()
	_style_reset_blessings_button()
	element_menu_controller.configure(
		elements_panel,
		elements_info,
		elements_section_list,
		unlock_button,
		dust_cycle_all_button,
		dust_cycle_all_label,
		dust_clear_all_button,
		dust_clear_all_label,
		make_dust_button,
		make_dust_label,
		dust_close_button,
		ENABLED_BUTTON_MODULATE,
		DISABLED_BUTTON_MODULATE
	)
	element_menu_controller.element_pressed.connect(_on_element_tile_pressed)
	element_menu_controller.unlock_requested.connect(_on_unlock_pressed)
	element_menu_controller.dust_cycle_all_requested.connect(_on_dust_cycle_all_pressed)
	element_menu_controller.dust_clear_all_requested.connect(_on_dust_clear_all_pressed)
	element_menu_controller.make_dust_requested.connect(_on_make_dust_pressed)
	element_menu_controller.dust_close_requested.connect(_on_dust_close_pressed)
	blessings_panel_controller.configure(blessings_panel, blessings_info)
	blessings_panel_controller.open_requested.connect(_on_open_blessings_pressed)
	planets_panel_controller.configure(planets_panel, planets_info, icon_cache)
	planets_panel_controller.unlock_requested.connect(_on_planet_purchase_requested)
	planets_panel_controller.moon_upgrade_requested.connect(_on_moon_upgrade_requested)
	prestige_panel_controller.configure(prestige_panel, prestige_info)
	prestige_panel_controller.prestige_requested.connect(_on_prestige_requested)
	prestige_panel_controller.claim_node_requested.connect(_on_claim_prestige_node_requested)
	upgrades_panel_controller.configure(upgrades_panel, upgrades_info, upgrade_list)
	upgrades_panel_controller.purchase_requested.connect(_on_upgrade_purchase_requested)
	era_panel_controller.configure(
		era_panel,
		era_timeline,
		era_title,
		era_status,
		era_requirement_card,
		era_requirement_title,
		era_requirement_list,
		era_unlock_button,
		icon_cache
	)
	era_panel_controller.unlock_requested.connect(_on_era_unlock_pressed)
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
	_flush_pending_atom_hits(false)
	if game_state != null and SaveManager.save_state(game_state):
		game_state.last_save_tick = game_state.tick_count

func _build_default_state() -> GameState:
	var elements_content: Dictionary = _load_json_dictionary(ELEMENTS_DATA_PATH)
	var upgrades_content: Dictionary = _load_json_dictionary(UPGRADES_DATA_PATH)
	var blessings_content: Dictionary = _load_json_dictionary(BLESSINGS_DATA_PATH)
	var planets_content: Dictionary = _load_json_dictionary(PLANETS_DATA_PATH)
	var planet_menu_content: Dictionary = _load_json_dictionary(PLANET_MENU_DATA_PATH)
	return GameState.from_content(
		elements_content,
		upgrades_content,
		blessings_content,
		planets_content,
		planet_menu_content
	)

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

func _apply_reference_layout() -> void:
	custom_minimum_size = UIMetrics.REFERENCE_VIEWPORT_SIZE
	menu_controller.apply_reference_layout()
	hud_controller.apply_reference_layout(shop_button)
	_layout_atom_focus_controls()
	era_panel_controller.update_layout()
	world_view_controller.apply_reference_layout()

func _layout_atom_focus_controls() -> void:
	_set_center_anchor_rect(fuse_button, UIMetrics.FUSE_BUTTON_SIZE)

func _set_center_anchor_rect(control: Control, size_value: Vector2, center_offset: Vector2 = Vector2.ZERO) -> void:
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = center_offset.x - (size_value.x * 0.5)
	control.offset_top = center_offset.y - (size_value.y * 0.5)
	control.offset_right = center_offset.x + (size_value.x * 0.5)
	control.offset_bottom = center_offset.y + (size_value.y * 0.5)

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
	element_menu_controller.refresh_debug_hitboxes(debug_show_element_hitboxes)

func _set_menu_mode(new_mode: int) -> void:
	if new_mode != MENU_ELEMENTS:
		dust_mode_active = false
	menu_mode = new_mode
	menu_controller.set_menu_mode(menu_mode)

func _set_view_mode(new_mode: int) -> void:
	if view_mode == new_mode:
		return
	view_mode = new_mode
	if view_mode == VIEW_WORLD:
		var flushed_auto_smashes := _flush_pending_atom_hits(false)
		if flushed_auto_smashes > 0:
			_mark_ui_dirty(_get_resource_refresh_flags())
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
		| UI_DIRTY_BLESSINGS
		| UI_DIRTY_WORLD
		| UI_DIRTY_PRESTIGE
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
		MENU_BLESSINGS:
			flags |= UI_DIRTY_BLESSINGS
		MENU_ERA:
			flags |= UI_DIRTY_ERA
		MENU_STATS:
			flags |= UI_DIRTY_STATS
		MENU_SHOP:
			flags |= UI_DIRTY_SHOP
		MENU_PLANETS:
			flags |= UI_DIRTY_PLANETS
		MENU_PRESTIGE:
			flags |= UI_DIRTY_PRESTIGE
		MENU_SETTINGS:
			flags |= UI_DIRTY_SETTINGS
	return flags

func _get_view_mode_refresh_flags() -> int:
	return UI_DIRTY_NAVIGATION | UI_DIRTY_COUNTERS | UI_DIRTY_WORLD | UI_DIRTY_DEBUG | UI_DIRTY_MENU_BUTTONS

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
		if flags & UI_DIRTY_PRESTIGE:
			_refresh_prestige_panel()
		if flags & UI_DIRTY_SETTINGS:
			_refresh_settings_panel()
		if flags & UI_DIRTY_BLESSINGS:
			_refresh_blessings_panel()
		if flags & UI_DIRTY_WORLD:
			_refresh_world_ui()
		if flags & UI_DIRTY_DEBUG:
			_refresh_debug_hitboxes()

func _refresh_top_bar() -> void:
	hud_controller.refresh_top_bar(game_state)

func _refresh_selection_ui() -> void:
	var current_element := game_state.get_current_element_state()
	var current_index := 0 if current_element == null else current_element.index
	var current_icon := icon_cache.get_element_icon(current_index)
	fuse_button.texture_normal = current_icon
	fuse_button.texture_pressed = current_icon
	fuse_button.texture_hover = current_icon
	fuse_button.texture_disabled = current_icon

func _refresh_navigation() -> void:
	fuse_button.visible = view_mode == VIEW_ATOM
	effects_layer.visible = view_mode == VIEW_ATOM
	world_view_controller.set_navigation_state(view_mode == VIEW_WORLD, game_state.has_unlocked_era(1))
	hud_controller.refresh_navigation(
		view_mode == VIEW_ATOM,
		game_state.has_adjacent_owned_planet(-1) if view_mode == VIEW_WORLD else game_state.has_adjacent_unlocked_element(-1),
		game_state.has_adjacent_owned_planet(1) if view_mode == VIEW_WORLD else game_state.has_next_selectable_element_in_visible_sections(),
		view_mode == VIEW_WORLD,
		view_mode == VIEW_ATOM and game_state.has_unlocked_era(1)
	)

func _refresh_menu_buttons() -> void:
	var blessings_enabled := game_state.is_blessings_menu_unlocked()
	var era_menu_enabled := game_state.is_era_menu_unlocked()
	var planets_enabled := game_state.has_unlocked_era(1)
	var shop_enabled := game_state.is_element_unlocked("ele_H")
	menu_controller.refresh_main_menu_buttons(blessings_enabled, era_menu_enabled, planets_enabled, shop_enabled)
	hud_controller.refresh_menu_button(menu_mode != MENU_CLOSED)
	hud_controller.refresh_shop_button(shop_enabled, shop_enabled and menu_mode == MENU_CLOSED)

func _refresh_upgrades_panel() -> void:
	upgrades_panel_controller.refresh(game_state, upgrades_system)

func _refresh_stats_panel() -> void:
	if not stats_panel.visible:
		return

	var current_element := game_state.get_current_element_state()
	var current_name := "" if current_element == null else current_element.name
	var produced_name := "" if current_element == null else game_state.get_resource_name(current_element.produces)
	var total_fission_chance := upgrades_system.get_fission_chance_percent(game_state)
	stats_info.text = "Run Stats\nCurrent Element: %s\nProduces: %s\nManual Smashes: %d\nAuto Smashes: %d\n\nSmash Stats\n%s\nFission Sources Combined: %.2f%% total\n\nBlessing Progress\nBlessings Earned: %d\nDiscovered: %d / %d\n\nUpgrade Effects\n%s" % [
		current_name,
		produced_name,
		game_state.total_manual_smashes,
		game_state.total_auto_smashes,
		_build_upgrade_stats_text(),
		total_fission_chance,
		game_state.blessings_count,
		game_state.get_discovered_blessing_count(),
		game_state.get_blessing_ids().size(),
		_build_upgrade_effects_text()
	]
	planetary_stats_info.visible = game_state.has_unlocked_era(1)
	if planetary_stats_info.visible:
		var next_milestone := game_state.get_next_prestige_milestone()
		var next_milestone_title := "None" if next_milestone.is_empty() else str(next_milestone.get("title", "None"))
		planetary_stats_info.text = "Planetary Stats\nResearch Points: %s\nPrestige Points: %d (%d unspent)\nNext Milestone: %s" % [
			game_state.get_research_points().big_to_short_string(),
			game_state.prestige_points_total,
			game_state.prestige_points_unspent,
			next_milestone_title
		]

func _refresh_shop_panel() -> void:
	if not shop_panel.visible:
		return

	shop_info.text = "Shop inventory is not implemented yet.\nThis panel will hold orb and meta purchases."

func _refresh_planets_panel() -> void:
	if not planets_panel.visible:
		return

	planets_panel_controller.refresh(game_state)

func _refresh_prestige_panel() -> void:
	if not prestige_panel.visible:
		return

	prestige_panel_controller.refresh(game_state)

func _refresh_blessings_panel() -> void:
	if not blessings_panel.visible:
		return
	blessings_panel_controller.refresh(game_state)

func _refresh_settings_panel() -> void:
	if not settings_panel.visible:
		return

	settings_info.text = "Developer Tools\nUse Dust and Orbs to test prestige milestones and planet purchases."
	prestige_debug_row.visible = false
	prestige_count_label.text = "Prestige Count: %d" % game_state.prestige_count
	click_boxes_toggle.button_pressed = debug_show_element_hitboxes

func _refresh_elements_panel() -> void:
	element_menu_controller.refresh(
		game_state,
		upgrades_system,
		dust_recipe_service,
		dust_mode_active,
		debug_show_element_hitboxes
	)

func _refresh_world_ui() -> void:
	world_view_controller.refresh(game_state, view_mode == VIEW_WORLD)

func _refresh_era_ui() -> void:
	era_panel_controller.refresh(game_state)

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
	var pending_results: Array[Dictionary] = []
	for _i in range(spawn_count):
		var result := element_system.preview_auto_smash(game_state, upgrades_system, target_element_id)
		if result.is_empty():
			continue
		pending_results.append(result)
	if not pending_results.is_empty():
		atom_effects_controller.queue_auto_smash_results(pending_results)

func _flush_pending_atom_hits(refresh_ui_after_flush: bool = true) -> int:
	var resolved_auto_smashes := atom_effects_controller.flush_pending_hits()
	if resolved_auto_smashes <= 0:
		return 0
	dust_recipe_service.invalidate()
	if refresh_ui_after_flush:
		_refresh_ui(_get_resource_refresh_flags())
	return resolved_auto_smashes

func _on_prev_pressed() -> void:
	if view_mode == VIEW_WORLD:
		if not game_state.select_adjacent_owned_planet(-1):
			return
		_refresh_ui(UI_DIRTY_WORLD | UI_DIRTY_PLANETS | UI_DIRTY_NAVIGATION | UI_DIRTY_STATS)
		return
	tick_system.enqueue_action("select_adjacent", {"direction": -1})

func _on_next_pressed() -> void:
	if view_mode == VIEW_WORLD:
		if not game_state.select_adjacent_owned_planet(1):
			return
		_refresh_ui(UI_DIRTY_WORLD | UI_DIRTY_PLANETS | UI_DIRTY_NAVIGATION | UI_DIRTY_STATS)
		return
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

func _on_profile_menu_pressed() -> void:
	_set_menu_mode(MENU_PROFILE)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_elements_menu_pressed() -> void:
	_set_menu_mode(MENU_ELEMENTS)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_blessings_menu_pressed() -> void:
	if not game_state.is_blessings_menu_unlocked():
		return
	_set_menu_mode(MENU_BLESSINGS)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_open_blessings_pressed() -> void:
	if game_state.open_earned_blessings() <= 0:
		return
	_refresh_ui(UI_DIRTY_BLESSINGS | UI_DIRTY_STATS)

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

func _on_prestige_menu_pressed() -> void:
	_set_menu_mode(MENU_PRESTIGE)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_factory_menu_pressed() -> void:
	_set_menu_mode(MENU_FACTORY)
	_refresh_ui(_get_menu_mode_refresh_flags())

func _on_collider_menu_pressed() -> void:
	_set_menu_mode(MENU_COLLIDER)
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

func _on_dust_cycle_all_pressed() -> void:
	dust_recipe_service.cycle_all_unlocked_selections(game_state)
	_refresh_ui(UI_DIRTY_ELEMENTS)

func _on_dust_clear_all_pressed() -> void:
	dust_recipe_service.clear_selection()
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
	_refresh_ui(UI_DIRTY_TOP_BAR | UI_DIRTY_ERA | UI_DIRTY_PLANETS | UI_DIRTY_PRESTIGE)

func _on_reset_blessings_pressed() -> void:
	if not game_state.reset_blessings():
		return
	_refresh_ui(UI_DIRTY_BLESSINGS | UI_DIRTY_STATS)

func _on_planet_purchase_requested(planet_id: String) -> void:
	if not game_state.purchase_planet(planet_id):
		return
	_refresh_ui(_get_resource_refresh_flags() | UI_DIRTY_PLANETS | UI_DIRTY_WORLD | UI_DIRTY_NAVIGATION | UI_DIRTY_STATS)
	planets_panel_controller.play_planet_unlock_animation(planet_id)

func _on_moon_upgrade_requested(moon_id: String, upgrade_id: String) -> void:
	if not game_state.purchase_moon_upgrade(moon_id, upgrade_id):
		return
	_refresh_ui(UI_DIRTY_PLANETS | UI_DIRTY_WORLD | UI_DIRTY_STATS | UI_DIRTY_TOP_BAR)
	planets_panel_controller.play_moon_upgrade_purchase_animation(moon_id, upgrade_id)

func _on_prestige_requested() -> void:
	if not game_state.perform_prestige():
		return
	dust_recipe_service.invalidate()
	upgrades_system.mark_cache_dirty()
	tick_system.configure(game_state, element_system, upgrades_system)
	atom_effects_controller.clear()
	world_view_controller.clear_particles()
	_refresh_ui(UI_DIRTY_ALL)

func _on_claim_prestige_node_requested() -> void:
	if not game_state.claim_next_prestige_node():
		return
	dust_recipe_service.invalidate()
	upgrades_system.mark_cache_dirty()
	_refresh_ui(UI_DIRTY_PRESTIGE | UI_DIRTY_ELEMENTS | UI_DIRTY_STATS | UI_DIRTY_TOP_BAR)

func _on_prestige_decrement_pressed() -> void:
	_adjust_prestige_count(-1)

func _on_prestige_increment_pressed() -> void:
	_adjust_prestige_count(1)

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

func _adjust_prestige_count(delta: int) -> void:
	if not game_state.adjust_prestige_count(delta):
		return
	_refresh_ui(_get_selection_refresh_flags() | UI_DIRTY_SETTINGS)

func _build_upgrade_stats_text() -> String:
	return "Particle Smasher: %.2f actions/sec\nCrit Chance: %.0f%% | Crit Payload: %.0f%%\nFission Chance: %.0f%% | Double Hit: %.0f%%\nResonant Yield: %.0f%%\nFoil Chance: %.0f%% | Holographic: %.0f%% | Polychrome: %.0f%%" % [
		upgrades_system.get_auto_smashes_per_second(game_state),
		upgrades_system.get_global_critical_smash_chance_percent(game_state),
		upgrades_system.get_critical_payload_chance_percent(game_state),
		upgrades_system.get_fission_chance_percent(game_state),
		upgrades_system.get_manual_double_hit_chance(game_state) * 100.0,
		upgrades_system.get_resonant_yield_chance(game_state) * 100.0,
		game_state.get_foil_spawn_chance_percent(),
		game_state.get_holographic_spawn_chance_percent(),
		game_state.get_polychrome_spawn_chance_percent()
	]

func _build_upgrade_effects_text() -> String:
	var sections: Array[String] = []
	for upgrade_id in game_state.get_upgrade_ids():
		if not upgrades_system.should_show_upgrade(game_state, upgrade_id):
			continue
		var upgrade := game_state.get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue
		if NON_UNIQUE_UPGRADE_EFFECT_TYPES.has(upgrade.effect_type):
			continue
		sections.append(upgrades_system.get_upgrade_effect_summary(game_state, upgrade_id))
	if sections.is_empty():
		return "No upgrade effects unlocked yet."

	var summary := ""
	for index in range(sections.size()):
		if index > 0:
			summary += "\n"
		summary += sections[index]
	return summary

func _pulse_fuse_element() -> void:
	if not is_instance_valid(fuse_button):
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fuse_button, "scale", Vector2(0.9, 0.9), 0.06)
	tween.tween_property(fuse_button, "scale", Vector2.ONE, 0.08)

func _ensure_reset_blessings_button() -> void:
	if is_instance_valid(reset_blessings_button):
		return

	reset_blessings_button = Button.new()
	reset_blessings_button.name = "ResetBlessingsButton"
	reset_blessings_button.text = "Reset Blessings"
	reset_blessings_button.focus_mode = Control.FOCUS_NONE
	settings_panel.add_child(reset_blessings_button)
	settings_panel.move_child(reset_blessings_button, settings_panel.get_child_count() - 1)
	reset_blessings_button.pressed.connect(_on_reset_blessings_pressed)

func _style_reset_blessings_button() -> void:
	if not is_instance_valid(reset_blessings_button):
		return

	reset_blessings_button.custom_minimum_size = Vector2(0.0, UIMetrics.MENU_BUTTON_MIN_HEIGHT)
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font != null:
		reset_blessings_button.add_theme_font_override("font", ui_font)
	reset_blessings_button.add_theme_font_size_override("font_size", UIMetrics.FONT_SIZE_BODY)
	reset_blessings_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _ensure_factory_and_collider_menu_nodes() -> void:
	factory_menu_button = _ensure_main_menu_button("FactoryMenuButton", "Factory", prestige_menu_button.get_index() + 1)
	collider_menu_button = _ensure_main_menu_button("ColliderMenuButton", "Collider", factory_menu_button.get_index() + 1)
	factory_panel = _ensure_placeholder_menu_panel("FactoryPanel", "Factory", "Factory systems will live here.")
	collider_panel = _ensure_placeholder_menu_panel("ColliderPanel", "Collider", "Collider systems will live here.")
	factory_title = factory_panel.get_node("FactoryTitle")
	factory_info = factory_panel.get_node("FactoryInfo")
	collider_title = collider_panel.get_node("ColliderTitle")
	collider_info = collider_panel.get_node("ColliderInfo")

func _ensure_main_menu_button(button_name: String, button_text: String, child_index: int) -> Button:
	var button := main_menu_panel.get_node_or_null(button_name) as Button
	if button == null:
		button = Button.new()
		button.name = button_name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		main_menu_panel.add_child(button)
	button.text = button_text
	main_menu_panel.move_child(button, child_index)
	return button

func _ensure_placeholder_menu_panel(panel_name: String, panel_title: String, panel_text: String) -> VBoxContainer:
	var panel := menu_panels.get_node_or_null(panel_name) as VBoxContainer
	if panel == null:
		panel = VBoxContainer.new()
		panel.name = panel_name
		panel.visible = false
		panel.layout_mode = 1
		panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		panel.grow_vertical = Control.GROW_DIRECTION_BOTH
		menu_panels.add_child(panel)

		var title := Label.new()
		title.name = "%sTitle" % panel_title
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.text = panel_title
		panel.add_child(title)

		var info := Label.new()
		info.name = "%sInfo" % panel_title
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(info)

	var title_label := panel.get_node("%sTitle" % panel_title) as Label
	var info_label := panel.get_node("%sInfo" % panel_title) as Label
	title_label.text = panel_title
	info_label.text = panel_text
	menu_panels.move_child(panel, min(menu_panels.get_child_count() - 1, settings_panel.get_index()))
	return panel
