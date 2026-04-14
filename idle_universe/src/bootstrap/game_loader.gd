extends Control

const GameBootstrapScript = preload("res://src/bootstrap/game_bootstrap.gd")
const AutosaveServiceScript = preload("res://src/bootstrap/autosave_service.gd")
const UiStateControllerScript = preload("res://src/bootstrap/ui_state_controller.gd")
const GameActionRouterScript = preload("res://src/bootstrap/game_action_router.gd")
const GameUiRefreshCoordinatorScript = preload("res://src/bootstrap/game_ui_refresh_coordinator.gd")
const GameLoaderSetupHelperScript = preload("res://src/bootstrap/game_loader_setup_helper.gd")
const BlessingsPanelControllerScript = preload("res://src/controllers/blessings_panel_controller.gd")
const PlanetsPanelControllerScript = preload("res://src/controllers/planets_panel_controller.gd")
const PrestigePanelControllerScript = preload("res://src/controllers/prestige_panel_controller.gd")
const OblationsPanelControllerScript = preload("res://src/controllers/oblations_panel_controller.gd")
const UIMetrics = preload("res://src/ui/ui_metrics.gd")
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
const MENU_OBLATIONS := 14

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
const UI_DIRTY_BLESSINGS_PROGRESS := 1 << 11
const UI_DIRTY_WORLD := 1 << 12
const UI_DIRTY_MENU_BUTTONS := 1 << 13
const UI_DIRTY_DEBUG := 1 << 14
const UI_DIRTY_PRESTIGE := 1 << 15
const UI_DIRTY_BLESSINGS_CATALOG := 1 << 16
const UI_DIRTY_OBLATIONS := 1 << 17
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
	| UI_DIRTY_BLESSINGS_PROGRESS
	| UI_DIRTY_WORLD
	| UI_DIRTY_MENU_BUTTONS
	| UI_DIRTY_DEBUG
	| UI_DIRTY_PRESTIGE
	| UI_DIRTY_BLESSINGS_CATALOG
	| UI_DIRTY_OBLATIONS
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
var oblations_menu_button: Button
var factory_panel: VBoxContainer
var factory_title: Label
var factory_info: Label
var collider_panel: VBoxContainer
var collider_title: Label
var collider_info: Label
var oblations_panel: VBoxContainer
var oblations_title: Label
var oblations_info: Label
var debug_show_element_hitboxes := false
var dust_mode_active := false
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
var oblations_panel_controller = OblationsPanelControllerScript.new()
var upgrades_panel_controller: UpgradesPanelController = UpgradesPanelController.new()
var era_panel_controller: EraPanelController = EraPanelController.new()
var game_bootstrap: GameBootstrap = GameBootstrapScript.new()
var autosave_service: AutosaveService = AutosaveServiceScript.new()
var ui_state_controller: UiStateController = UiStateControllerScript.new(MENU_CLOSED, VIEW_ATOM, UI_DIRTY_ALL)
var action_router
var ui_refresh_coordinator
var setup_helper

func _ready() -> void:
	set_process(true)

	game_state = game_bootstrap.build_and_load_game_state()
	action_router = GameActionRouterScript.new(self)
	ui_refresh_coordinator = GameUiRefreshCoordinatorScript.new(self)
	setup_helper = GameLoaderSetupHelperScript.new(self)
	upgrades_system.mark_cache_dirty()
	_ensure_oblations_menu_nodes()
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
	oblations_menu_button.pressed.connect(_on_oblations_menu_pressed)
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
	prestige_menu_button.text = "Milestones"
	prestige_title.text = "Milestones"

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
		oblations_panel,
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
		oblations_title,
		oblations_info,
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
		oblations_menu_button,
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
	oblations_panel_controller.configure(oblations_panel, oblations_info)
	oblations_panel_controller.oblation_confirm_requested.connect(_on_oblation_confirm_requested)
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
	if ui_state_controller.view_mode == VIEW_ATOM:
		var resolved_auto_smashes := atom_effects_controller.update(delta)
		if resolved_auto_smashes > 0:
			dust_recipe_service.invalidate()
			_pulse_fuse_element()
			_mark_ui_dirty(_get_resource_refresh_flags())
	world_view_controller.update(delta, ui_state_controller.view_mode == VIEW_WORLD)
	if ui_state_controller.ui_dirty_flags != 0:
		_flush_dirty_ui()

func _unhandled_input(event: InputEvent) -> void:
	pass

func _exit_tree() -> void:
	_flush_pending_atom_hits(false)
	autosave_service.save_on_exit(game_state)

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
	fuse_hitbox_debug.visible = debug_show_element_hitboxes and ui_state_controller.view_mode == VIEW_ATOM
	element_menu_controller.refresh_debug_hitboxes(debug_show_element_hitboxes)

func _set_menu_mode(new_mode: int) -> void:
	if new_mode != MENU_ELEMENTS:
		dust_mode_active = false
	ui_state_controller.set_menu_mode(new_mode)
	menu_controller.set_menu_mode(ui_state_controller.menu_mode)

func _set_view_mode(new_mode: int) -> void:
	if not ui_state_controller.set_view_mode(new_mode):
		return
	if ui_state_controller.view_mode == VIEW_WORLD:
		var flushed_auto_smashes := _flush_pending_atom_hits(false)
		if flushed_auto_smashes > 0:
			_mark_ui_dirty(_get_resource_refresh_flags())
		atom_effects_controller.clear()
	else:
		world_view_controller.clear_particles()
	_mark_ui_dirty(UI_DIRTY_DEBUG)

func _mark_ui_dirty(flags: int) -> void:
	ui_state_controller.mark_ui_dirty(flags)

func _get_resource_refresh_flags() -> int:
	return ui_state_controller.get_resource_refresh_flags(
		UI_DIRTY_TOP_BAR,
		UI_DIRTY_COUNTERS,
		UI_DIRTY_UPGRADES,
		UI_DIRTY_ELEMENTS,
		UI_DIRTY_ERA,
		UI_DIRTY_STATS,
		UI_DIRTY_PLANETS,
		UI_DIRTY_BLESSINGS_PROGRESS,
		UI_DIRTY_WORLD,
		UI_DIRTY_PRESTIGE,
		UI_DIRTY_OBLATIONS
	)

func _get_selection_refresh_flags() -> int:
	return ui_state_controller.get_selection_refresh_flags(
		UI_DIRTY_SELECTION,
		UI_DIRTY_NAVIGATION,
		UI_DIRTY_ELEMENTS,
		UI_DIRTY_STATS
	)

func _get_menu_mode_refresh_flags() -> int:
	return ui_state_controller.get_menu_mode_refresh_flags(
		MENU_UPGRADES,
		MENU_ELEMENTS,
		MENU_BLESSINGS,
		MENU_ERA,
		MENU_STATS,
		MENU_SHOP,
		MENU_PLANETS,
		MENU_PRESTIGE,
		MENU_OBLATIONS,
		MENU_SETTINGS,
		UI_DIRTY_MENU_BUTTONS,
		UI_DIRTY_UPGRADES,
		UI_DIRTY_ELEMENTS,
		UI_DIRTY_BLESSINGS_PROGRESS,
		UI_DIRTY_BLESSINGS_CATALOG,
		UI_DIRTY_ERA,
		UI_DIRTY_STATS,
		UI_DIRTY_SHOP,
		UI_DIRTY_PLANETS,
		UI_DIRTY_PRESTIGE,
		UI_DIRTY_OBLATIONS,
		UI_DIRTY_SETTINGS
	)

func _get_view_mode_refresh_flags() -> int:
	return ui_state_controller.get_view_mode_refresh_flags(
		UI_DIRTY_NAVIGATION,
		UI_DIRTY_COUNTERS,
		UI_DIRTY_WORLD,
		UI_DIRTY_DEBUG,
		UI_DIRTY_MENU_BUTTONS
	)

func _refresh_ui(flags: int = UI_DIRTY_ALL) -> void:
	ui_refresh_coordinator.refresh_ui(flags)

func _flush_dirty_ui() -> void:
	ui_refresh_coordinator.flush_dirty_ui()

func _perform_dust_conversion() -> bool:
	return action_router.perform_dust_conversion()

func _autosave_if_needed() -> void:
	autosave_service.autosave_if_needed(game_state)

func _on_tick_processed(_tick_count: int, processed_actions: Array, production_changes: Dictionary) -> void:
	action_router.on_tick_processed(_tick_count, processed_actions, production_changes)

func _on_manual_smash_resolved(result: Dictionary) -> void:
	action_router.on_manual_smash_resolved(result)

func _on_auto_smash_requested(request: Dictionary) -> void:
	action_router.on_auto_smash_requested(request)

func _flush_pending_atom_hits(refresh_ui_after_flush: bool = true) -> int:
	return action_router.flush_pending_atom_hits(refresh_ui_after_flush)

func _on_prev_pressed() -> void:
	action_router.on_prev_pressed()

func _on_next_pressed() -> void:
	action_router.on_next_pressed()

func _on_zin_pressed() -> void:
	action_router.on_zin_pressed()

func _on_zout_pressed() -> void:
	action_router.on_zout_pressed()

func _on_smash_pressed() -> void:
	action_router.on_smash_pressed()

func _on_menu_pressed() -> void:
	action_router.on_menu_pressed()

func _on_upgrades_menu_pressed() -> void:
	action_router.on_upgrades_menu_pressed()

func _on_profile_menu_pressed() -> void:
	action_router.on_profile_menu_pressed()

func _on_elements_menu_pressed() -> void:
	action_router.on_elements_menu_pressed()

func _on_blessings_menu_pressed() -> void:
	action_router.on_blessings_menu_pressed()

func _on_open_blessings_pressed() -> void:
	action_router.on_open_blessings_pressed()

func _on_era_menu_pressed() -> void:
	action_router.on_era_menu_pressed()

func _on_planets_menu_pressed() -> void:
	action_router.on_planets_menu_pressed()

func _on_prestige_menu_pressed() -> void:
	action_router.on_prestige_menu_pressed()

func _on_oblations_menu_pressed() -> void:
	action_router.on_oblations_menu_pressed()

func _on_factory_menu_pressed() -> void:
	action_router.on_factory_menu_pressed()

func _on_collider_menu_pressed() -> void:
	action_router.on_collider_menu_pressed()

func _on_stats_menu_pressed() -> void:
	action_router.on_stats_menu_pressed()

func _on_shop_pressed() -> void:
	action_router.on_shop_pressed()

func _on_settings_menu_pressed() -> void:
	action_router.on_settings_menu_pressed()

func _on_element_tile_pressed(element_id: String) -> void:
	action_router.on_element_tile_pressed(element_id)

func _on_unlock_pressed() -> void:
	action_router.on_unlock_pressed()

func _on_make_dust_pressed() -> void:
	action_router.on_make_dust_pressed()

func _on_dust_close_pressed() -> void:
	action_router.on_dust_close_pressed()

func _on_dust_cycle_all_pressed() -> void:
	action_router.on_dust_cycle_all_pressed()

func _on_dust_clear_all_pressed() -> void:
	action_router.on_dust_clear_all_pressed()

func _on_click_boxes_toggled(toggled_on: bool) -> void:
	action_router.on_click_boxes_toggled(toggled_on)

func _on_add_dust_pressed() -> void:
	action_router.on_add_dust_pressed()

func _on_add_orbs_pressed() -> void:
	action_router.on_add_orbs_pressed()

func _on_reset_blessings_pressed() -> void:
	action_router.on_reset_blessings_pressed()

func _on_planet_purchase_requested(planet_id: String) -> void:
	action_router.on_planet_purchase_requested(planet_id)

func _on_moon_upgrade_requested(moon_id: String, upgrade_id: String) -> void:
	action_router.on_moon_upgrade_requested(moon_id, upgrade_id)

func _on_prestige_decrement_pressed() -> void:
	action_router.on_prestige_decrement_pressed()

func _on_prestige_increment_pressed() -> void:
	action_router.on_prestige_increment_pressed()

func _on_era_unlock_pressed() -> void:
	action_router.on_era_unlock_pressed()

func _on_world_worker_button_pressed() -> void:
	action_router.on_world_worker_button_pressed()

func _on_world_worker_slider_changed(value: float) -> void:
	action_router.on_world_worker_slider_changed(value)

func _on_upgrade_purchase_requested(upgrade_id: String) -> void:
	action_router.on_upgrade_purchase_requested(upgrade_id)

func _adjust_prestige_count(delta: int) -> void:
	action_router.adjust_prestige_count(delta)

func _on_oblation_confirm_requested(recipe_id: String, selected_inputs: Dictionary) -> void:
	action_router.on_oblation_confirm_requested(recipe_id, selected_inputs)

func _pulse_fuse_element() -> void:
	if not is_instance_valid(fuse_button):
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fuse_button, "scale", Vector2(0.9, 0.9), 0.06)
	tween.tween_property(fuse_button, "scale", Vector2.ONE, 0.08)

func _ensure_reset_blessings_button() -> void:
	setup_helper.ensure_reset_blessings_button()

func _style_reset_blessings_button() -> void:
	setup_helper.style_reset_blessings_button()

func _ensure_oblations_menu_nodes() -> void:
	setup_helper.ensure_oblations_menu_nodes()

func _ensure_factory_and_collider_menu_nodes() -> void:
	setup_helper.ensure_factory_and_collider_menu_nodes()
