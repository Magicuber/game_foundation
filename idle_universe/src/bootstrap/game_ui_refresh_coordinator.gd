extends RefCounted

class_name GameUiRefreshCoordinator

var _loader_ref: WeakRef = null
var loader:
	get:
		return null if _loader_ref == null else _loader_ref.get_ref()

func _init(owner = null) -> void:
	_loader_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_loader_ref = weakref(owner) if owner != null else null

func get_counter_ids() -> Array[String]:
	var game_loader = loader
	if game_loader == null:
		return []

	var visible_ids: Array[String] = game_loader.game_state.get_visible_counter_element_ids()
	var limited_ids: Array[String] = []
	for element_id in visible_ids:
		limited_ids.append(element_id)
		if limited_ids.size() >= game_loader.MAX_COUNTERS:
			break
	return limited_ids

func sync_resource_displays() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.counter_margin.visible:
		return

	var visible_ids: Array[String] = get_counter_ids()
	if game_loader.resource_display_ids != visible_ids:
		for child in game_loader.counter_list.get_children():
			child.queue_free()

		game_loader.resource_displays.clear()
		game_loader.resource_display_ids = visible_ids.duplicate()

		for element_id in game_loader.resource_display_ids:
			var display: CurrencyDisplay = CurrencyDisplay.new()
			display.configure(game_loader.game_state, element_id)
			game_loader.counter_list.add_child(display)
			game_loader.resource_displays[element_id] = display

	for element_id in game_loader.resource_display_ids:
		var display: CurrencyDisplay = game_loader.resource_displays[element_id]
		display.refresh()

func refresh_ui(flags: int) -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.ui_state_controller.refresh_ui(flags, game_loader._flush_dirty_ui)

func flush_dirty_ui() -> void:
	var game_loader = loader
	if game_loader == null:
		return

	var refresh_entries: Array[Dictionary] = [
		{"flag": game_loader.UI_DIRTY_NAVIGATION, "callable": Callable(self, "refresh_navigation")},
		{"flag": game_loader.UI_DIRTY_TOP_BAR, "callable": Callable(self, "refresh_top_bar")},
		{"flag": game_loader.UI_DIRTY_SELECTION, "callable": Callable(self, "refresh_selection_ui")},
		{"flag": game_loader.UI_DIRTY_MENU_BUTTONS, "callable": Callable(self, "refresh_menu_buttons")},
		{"flag": game_loader.UI_DIRTY_COUNTERS, "callable": Callable(self, "sync_resource_displays")},
		{"flag": game_loader.UI_DIRTY_UPGRADES, "callable": Callable(self, "refresh_upgrades_panel")},
		{"flag": game_loader.UI_DIRTY_ELEMENTS, "callable": Callable(self, "refresh_elements_panel")},
		{"flag": game_loader.UI_DIRTY_ERA, "callable": Callable(self, "refresh_era_ui")},
		{"flag": game_loader.UI_DIRTY_STATS, "callable": Callable(self, "refresh_stats_panel")},
		{"flag": game_loader.UI_DIRTY_SHOP, "callable": Callable(self, "refresh_shop_panel")},
		{"flag": game_loader.UI_DIRTY_PLANETS, "callable": Callable(self, "refresh_planets_panel")},
		{"flag": game_loader.UI_DIRTY_PRESTIGE, "callable": Callable(self, "refresh_prestige_panel")},
		{"flag": game_loader.UI_DIRTY_OBLATIONS, "callable": Callable(self, "refresh_oblations_panel")},
		{"flag": game_loader.UI_DIRTY_SETTINGS, "callable": Callable(self, "refresh_settings_panel")},
		{"flag": game_loader.UI_DIRTY_BLESSINGS_PROGRESS, "callable": Callable(self, "refresh_blessings_progress")},
		{"flag": game_loader.UI_DIRTY_BLESSINGS_CATALOG, "callable": Callable(self, "refresh_blessings_catalog")},
		{"flag": game_loader.UI_DIRTY_WORLD, "callable": Callable(self, "refresh_world_ui")},
		{"flag": game_loader.UI_DIRTY_DEBUG, "callable": Callable(self, "refresh_debug_hitboxes")}
	]
	game_loader.ui_state_controller.flush_dirty_ui(game_loader.game_state, refresh_entries)

func refresh_top_bar() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.hud_controller.refresh_top_bar(game_loader.game_state)

func refresh_selection_ui() -> void:
	var game_loader = loader
	if game_loader == null:
		return

	var current_element: ElementState = game_loader.game_state.get_current_element_state()
	var current_index: int = 0 if current_element == null else current_element.index
	var current_icon = game_loader.icon_cache.get_element_icon(current_index)
	game_loader.fuse_button.texture_normal = current_icon
	game_loader.fuse_button.texture_pressed = current_icon
	game_loader.fuse_button.texture_hover = current_icon
	game_loader.fuse_button.texture_disabled = current_icon

func refresh_navigation() -> void:
	var game_loader = loader
	if game_loader == null:
		return

	game_loader.fuse_button.visible = game_loader.ui_state_controller.view_mode == game_loader.VIEW_ATOM
	game_loader.effects_layer.visible = game_loader.ui_state_controller.view_mode == game_loader.VIEW_ATOM
	game_loader.world_view_controller.set_navigation_state(game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD, game_loader.game_state.has_unlocked_era(1))
	game_loader.hud_controller.refresh_navigation(
		game_loader.ui_state_controller.view_mode == game_loader.VIEW_ATOM,
		game_loader.game_state.has_adjacent_owned_planet(-1) if game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD else game_loader.game_state.has_adjacent_unlocked_element(-1),
		game_loader.game_state.has_adjacent_owned_planet(1) if game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD else game_loader.game_state.has_next_selectable_element_in_visible_sections(),
		game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD,
		game_loader.ui_state_controller.view_mode == game_loader.VIEW_ATOM and game_loader.game_state.has_unlocked_era(1)
	)

func refresh_menu_buttons() -> void:
	var game_loader = loader
	if game_loader == null:
		return

	var blessings_enabled: bool = game_loader.game_state.is_blessings_menu_unlocked()
	var era_menu_enabled: bool = game_loader.game_state.is_era_menu_unlocked()
	var planets_enabled: bool = game_loader.game_state.has_unlocked_era(1)
	var oblations_enabled: bool = game_loader.game_state.is_oblation_menu_unlocked()
	var shop_enabled: bool = game_loader.game_state.is_element_unlocked("ele_H")
	game_loader.menu_controller.refresh_main_menu_buttons(blessings_enabled, era_menu_enabled, planets_enabled, oblations_enabled, shop_enabled)
	game_loader.hud_controller.refresh_menu_button(game_loader.ui_state_controller.menu_mode != game_loader.MENU_CLOSED)
	game_loader.hud_controller.refresh_shop_button(shop_enabled, shop_enabled and game_loader.ui_state_controller.menu_mode == game_loader.MENU_CLOSED)

func refresh_upgrades_panel() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.upgrades_panel_controller.refresh(game_loader.game_state, game_loader.upgrades_system)

func refresh_stats_panel() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.stats_panel.visible:
		return

	var current_element: ElementState = game_loader.game_state.get_current_element_state()
	var current_name: String = "" if current_element == null else current_element.name
	var produced_name: String = "" if current_element == null else game_loader.game_state.get_resource_name(current_element.produces)
	var total_fission_chance: float = game_loader.upgrades_system.get_fission_chance_percent(game_loader.game_state)
	game_loader.stats_info.text = "Run Stats\nCurrent Element: %s\nProduces: %s\nManual Smashes: %d\nAuto Smashes: %d\n\nSmash Stats\n%s\nFission Sources Combined: %.2f%% total\n\nBlessing Progress\nBlessings Earned: %d\nDiscovered: %d / %d\n\nUpgrade Effects\n%s" % [
		current_name,
		produced_name,
		game_loader.game_state.total_manual_smashes,
		game_loader.game_state.total_auto_smashes,
		build_upgrade_stats_text(),
		total_fission_chance,
		game_loader.game_state.blessings_count,
		game_loader.game_state.get_discovered_blessing_count(),
		game_loader.game_state.get_blessing_ids().size(),
		build_upgrade_effects_text()
	]
	game_loader.planetary_stats_info.visible = game_loader.game_state.has_unlocked_era(1)
	if game_loader.planetary_stats_info.visible:
		var next_milestone: Dictionary = game_loader.game_state.get_next_milestone()
		var next_milestone_title: String = "None" if next_milestone.is_empty() else str(next_milestone.get("title", "None"))
		game_loader.planetary_stats_info.text = "Planetary Stats\nResearch Points: %s\nCompleted Milestones: %d\nOblations Claimed: %d\nNext Milestone: %s" % [
			game_loader.game_state.get_research_points().big_to_short_string(),
			game_loader.game_state.completed_milestones.size(),
			game_loader.game_state.oblation_claimed_recipe_ids.size(),
			next_milestone_title
		]

func refresh_shop_panel() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.shop_panel.visible:
		return
	game_loader.shop_info.text = "Shop inventory is not implemented yet.\nThis panel will hold orb and meta purchases."

func refresh_planets_panel() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.planets_panel.visible:
		return
	game_loader.planets_panel_controller.refresh(game_loader.game_state)

func refresh_prestige_panel() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.prestige_panel.visible:
		return
	game_loader.prestige_panel_controller.refresh(game_loader.game_state)

func refresh_oblations_panel() -> void:
	var game_loader = loader
	if game_loader == null or game_loader.oblations_panel == null or not game_loader.oblations_panel.visible:
		return
	game_loader.oblations_panel_controller.refresh(game_loader.game_state)

func refresh_blessings_progress() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.blessings_panel.visible:
		return
	game_loader.blessings_panel_controller.refresh_progress(game_loader.game_state)

func refresh_blessings_catalog() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.blessings_panel.visible:
		return
	game_loader.blessings_panel_controller.refresh_catalog(game_loader.game_state)

func refresh_settings_panel() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.settings_panel.visible:
		return

	game_loader.settings_info.text = "Developer Tools\nUse Dust and Orbs to test milestones, planets, and oblations."
	game_loader.prestige_debug_row.visible = false
	game_loader.prestige_count_label.text = "Prestige Count: %d" % game_loader.game_state.prestige_count
	game_loader.click_boxes_toggle.button_pressed = game_loader.debug_show_element_hitboxes

func refresh_elements_panel() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.element_menu_controller.refresh(
		game_loader.game_state,
		game_loader.upgrades_system,
		game_loader.dust_recipe_service,
		game_loader.dust_mode_active,
		game_loader.debug_show_element_hitboxes
	)

func refresh_world_ui() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.world_view_controller.refresh(game_loader.game_state, game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD)

func refresh_era_ui() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.era_panel_controller.refresh(game_loader.game_state)

func refresh_debug_hitboxes() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader._refresh_debug_hitboxes()

func build_upgrade_stats_text() -> String:
	var game_loader = loader
	if game_loader == null:
		return ""
	return "Particle Smasher: %.2f actions/sec\nCrit Chance: %.0f%% | Crit Payload: %.0f%%\nFission Chance: %.0f%% | Double Hit: %.0f%%\nResonant Yield: %.0f%%\nFoil Chance: %.0f%% | Holographic: %.0f%% | Polychrome: %.0f%%" % [
		game_loader.upgrades_system.get_auto_smashes_per_second(game_loader.game_state),
		game_loader.upgrades_system.get_global_critical_smash_chance_percent(game_loader.game_state),
		game_loader.upgrades_system.get_critical_payload_chance_percent(game_loader.game_state),
		game_loader.upgrades_system.get_fission_chance_percent(game_loader.game_state),
		game_loader.upgrades_system.get_manual_double_hit_chance(game_loader.game_state) * 100.0,
		game_loader.upgrades_system.get_resonant_yield_chance(game_loader.game_state) * 100.0,
		game_loader.game_state.get_foil_spawn_chance_percent(),
		game_loader.game_state.get_holographic_spawn_chance_percent(),
		game_loader.game_state.get_polychrome_spawn_chance_percent()
	]

func build_upgrade_effects_text() -> String:
	var game_loader = loader
	if game_loader == null:
		return ""

	var sections: Array[String] = []
	for upgrade_id in game_loader.game_state.get_upgrade_ids():
		if not game_loader.upgrades_system.should_show_upgrade(game_loader.game_state, upgrade_id):
			continue
		var upgrade: UpgradeState = game_loader.game_state.get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue
		if game_loader.NON_UNIQUE_UPGRADE_EFFECT_TYPES.has(upgrade.effect_type):
			continue
		sections.append(game_loader.upgrades_system.get_upgrade_effect_summary(game_loader.game_state, upgrade_id))
	if sections.is_empty():
		return "No upgrade effects unlocked yet."

	var summary := ""
	for index in range(sections.size()):
		if index > 0:
			summary += "\n"
		summary += sections[index]
	return summary
