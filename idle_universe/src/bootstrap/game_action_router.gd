extends RefCounted

class_name GameActionRouter

var _loader_ref: WeakRef = null
var loader:
	get:
		return null if _loader_ref == null else _loader_ref.get_ref()

func _init(owner = null) -> void:
	_loader_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_loader_ref = weakref(owner) if owner != null else null

func perform_dust_conversion() -> bool:
	var game_loader = loader
	if game_loader == null:
		return false

	var selected_amounts: Dictionary = game_loader.dust_recipe_service.get_selected_amounts(game_loader.game_state, game_loader.upgrades_system)
	if selected_amounts.is_empty():
		return false

	var dust_preview: DigitMaster = game_loader.dust_recipe_service.get_preview(game_loader.game_state, game_loader.upgrades_system)
	if dust_preview.is_zero():
		return false

	for element_id_variant in selected_amounts.keys():
		var element_id := str(element_id_variant)
		var amount: DigitMaster = selected_amounts[element_id]
		if not game_loader.game_state.can_afford_resource(element_id, amount):
			return false

	for element_id_variant in selected_amounts.keys():
		var element_id := str(element_id_variant)
		var amount: DigitMaster = selected_amounts[element_id]
		if not game_loader.game_state.spend_resource(element_id, amount):
			return false

	game_loader.game_state.produce_resource(GameState.DUST_RESOURCE_ID, dust_preview)
	game_loader.dust_recipe_service.invalidate()
	return true

func on_tick_processed(_tick_count: int, processed_actions: Array, production_changes: Dictionary) -> void:
	var game_loader = loader
	if game_loader == null:
		return

	var dirty_flags := 0
	var current_planet_changed: bool = bool(production_changes.get("current_planet_changed", false))
	var any_planet_changed: bool = bool(production_changes.get("any_planet_changed", false))
	var research_changed: bool = bool(production_changes.get("research_changed", false))
	if game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD and (current_planet_changed or research_changed):
		dirty_flags |= game_loader.UI_DIRTY_WORLD
	if game_loader.ui_state_controller.menu_mode == game_loader.MENU_PLANETS and (any_planet_changed or research_changed):
		dirty_flags |= game_loader.UI_DIRTY_PLANETS
	for action_type_variant in processed_actions:
		match str(action_type_variant):
			"unlock_next":
				game_loader.dust_recipe_service.invalidate()
				dirty_flags |= game_loader._get_resource_refresh_flags() | game_loader._get_selection_refresh_flags() | game_loader.UI_DIRTY_MENU_BUTTONS
			"select_adjacent", "select_element":
				dirty_flags |= game_loader._get_selection_refresh_flags()
			"purchase_upgrade":
				game_loader.dust_recipe_service.invalidate()
				dirty_flags |= game_loader._get_resource_refresh_flags()
	if dirty_flags != 0:
		game_loader._mark_ui_dirty(dirty_flags)
	game_loader._autosave_if_needed()

func on_manual_smash_resolved(result: Dictionary) -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.dust_recipe_service.invalidate()
	game_loader._pulse_fuse_element()
	game_loader.atom_effects_controller.spawn_manual_result(result)
	game_loader._mark_ui_dirty(game_loader._get_resource_refresh_flags())

func on_auto_smash_requested(request: Dictionary) -> void:
	var game_loader = loader
	if game_loader == null:
		return

	var target_element_id := str(request.get("target_element_id", ""))
	var spawn_count := int(request.get("spawn_count", 1))
	if game_loader.ui_state_controller.view_mode != game_loader.VIEW_ATOM:
		var any_resolved: bool = false
		for _i in range(spawn_count):
			var result: Dictionary = game_loader.element_system.resolve_auto_smash(game_loader.game_state, game_loader.upgrades_system, target_element_id)
			if not result.is_empty():
				any_resolved = true
		if any_resolved:
			game_loader.dust_recipe_service.invalidate()
			game_loader._mark_ui_dirty(game_loader._get_resource_refresh_flags())
		return

	var pending_results: Array[Dictionary] = []
	for _i in range(spawn_count):
		var result: Dictionary = game_loader.element_system.preview_auto_smash(game_loader.game_state, game_loader.upgrades_system, target_element_id)
		if result.is_empty():
			continue
		pending_results.append(result)
	if not pending_results.is_empty():
		game_loader.atom_effects_controller.queue_auto_smash_results(pending_results)

func flush_pending_atom_hits(refresh_ui_after_flush: bool = true) -> int:
	var game_loader = loader
	if game_loader == null:
		return 0

	var resolved_auto_smashes: int = game_loader.atom_effects_controller.flush_pending_hits()
	if resolved_auto_smashes <= 0:
		return 0
	game_loader.dust_recipe_service.invalidate()
	if refresh_ui_after_flush:
		game_loader._refresh_ui(game_loader._get_resource_refresh_flags())
	return resolved_auto_smashes

func on_prev_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	if game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD:
		if not game_loader.game_state.select_adjacent_owned_planet(-1):
			return
		game_loader._refresh_ui(game_loader.UI_DIRTY_WORLD | game_loader.UI_DIRTY_PLANETS | game_loader.UI_DIRTY_NAVIGATION | game_loader.UI_DIRTY_STATS)
		return
	game_loader.tick_system.enqueue_action("select_adjacent", {"direction": -1})

func on_next_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	if game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD:
		if not game_loader.game_state.select_adjacent_owned_planet(1):
			return
		game_loader._refresh_ui(game_loader.UI_DIRTY_WORLD | game_loader.UI_DIRTY_PLANETS | game_loader.UI_DIRTY_NAVIGATION | game_loader.UI_DIRTY_STATS)
		return
	game_loader.tick_system.enqueue_action("select_adjacent", {"direction": 1})

func on_zin_pressed() -> void:
	var game_loader = loader
	if game_loader == null or game_loader.ui_state_controller.view_mode != game_loader.VIEW_WORLD:
		return
	game_loader._set_view_mode(game_loader.VIEW_ATOM)
	game_loader._refresh_ui(game_loader._get_view_mode_refresh_flags())

func on_zout_pressed() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.has_unlocked_era(1):
		return
	game_loader._set_view_mode(game_loader.VIEW_WORLD)
	game_loader._refresh_ui(game_loader._get_view_mode_refresh_flags())

func on_smash_pressed() -> void:
	var game_loader = loader
	if game_loader == null or game_loader.ui_state_controller.view_mode != game_loader.VIEW_ATOM:
		return
	game_loader.tick_system.enqueue_action("manual_smash")

func on_menu_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	match game_loader.ui_state_controller.menu_mode:
		game_loader.MENU_CLOSED:
			game_loader._set_menu_mode(game_loader.MENU_MAIN)
		game_loader.MENU_MAIN:
			game_loader._set_menu_mode(game_loader.MENU_CLOSED)
		_:
			game_loader._set_menu_mode(game_loader.MENU_MAIN)
	game_loader._refresh_ui(game_loader._get_menu_mode_refresh_flags())

func on_upgrades_menu_pressed() -> void:
	_open_menu(loader.MENU_UPGRADES)

func on_profile_menu_pressed() -> void:
	_open_menu(loader.MENU_PROFILE)

func on_elements_menu_pressed() -> void:
	_open_menu(loader.MENU_ELEMENTS)

func on_blessings_menu_pressed() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.is_blessings_menu_unlocked():
		return
	_open_menu(game_loader.MENU_BLESSINGS)

func on_open_blessings_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	if game_loader.game_state.open_earned_blessings() <= 0:
		return
	game_loader._refresh_ui(game_loader.UI_DIRTY_BLESSINGS_PROGRESS | game_loader.UI_DIRTY_BLESSINGS_CATALOG | game_loader.UI_DIRTY_STATS)

func on_era_menu_pressed() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.is_era_menu_unlocked():
		return
	_open_menu(game_loader.MENU_ERA)

func on_planets_menu_pressed() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.has_unlocked_era(1):
		return
	_open_menu(game_loader.MENU_PLANETS)

func on_prestige_menu_pressed() -> void:
	_open_menu(loader.MENU_PRESTIGE)

func on_factory_menu_pressed() -> void:
	_open_menu(loader.MENU_FACTORY)

func on_collider_menu_pressed() -> void:
	_open_menu(loader.MENU_COLLIDER)

func on_stats_menu_pressed() -> void:
	_open_menu(loader.MENU_STATS)

func on_shop_pressed() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.is_element_unlocked("ele_H"):
		return
	_open_menu(game_loader.MENU_SHOP)

func on_settings_menu_pressed() -> void:
	_open_menu(loader.MENU_SETTINGS)

func on_element_tile_pressed(element_id: String) -> void:
	var game_loader = loader
	if game_loader == null:
		return
	if game_loader.dust_mode_active:
		game_loader.dust_recipe_service.cycle_selection(element_id)
		game_loader._refresh_ui(game_loader.UI_DIRTY_ELEMENTS)
		return
	if game_loader.game_state.select_element(element_id):
		game_loader._set_menu_mode(game_loader.MENU_CLOSED)
		game_loader._refresh_ui(game_loader._get_selection_refresh_flags() | game_loader.UI_DIRTY_MENU_BUTTONS)

func on_unlock_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.tick_system.enqueue_action("unlock_next")

func on_make_dust_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	if not game_loader.dust_mode_active:
		game_loader.dust_mode_active = true
		game_loader.dust_recipe_service.invalidate()
		game_loader._refresh_ui(game_loader.UI_DIRTY_ELEMENTS)
		return

	if perform_dust_conversion():
		game_loader.dust_mode_active = false
		game_loader._refresh_ui(game_loader._get_resource_refresh_flags())

func on_dust_close_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.dust_mode_active = false
	game_loader._refresh_ui(game_loader.UI_DIRTY_ELEMENTS)

func on_dust_cycle_all_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.dust_recipe_service.cycle_all_unlocked_selections(game_loader.game_state)
	game_loader._refresh_ui(game_loader.UI_DIRTY_ELEMENTS)

func on_dust_clear_all_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.dust_recipe_service.clear_selection()
	game_loader._refresh_ui(game_loader.UI_DIRTY_ELEMENTS)

func on_click_boxes_toggled(toggled_on: bool) -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.debug_show_element_hitboxes = toggled_on
	game_loader._refresh_ui(game_loader.UI_DIRTY_DEBUG)

func on_add_dust_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.game_state.produce_resource(GameState.DUST_RESOURCE_ID, DigitMaster.new(1000.0))
	game_loader.dust_recipe_service.invalidate()
	game_loader._refresh_ui(game_loader._get_resource_refresh_flags())

func on_add_orbs_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.game_state.orbs += 1000
	game_loader._refresh_ui(game_loader.UI_DIRTY_TOP_BAR | game_loader.UI_DIRTY_ERA | game_loader.UI_DIRTY_PLANETS | game_loader.UI_DIRTY_PRESTIGE)

func on_reset_blessings_pressed() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.reset_blessings():
		return
	game_loader._refresh_ui(game_loader.UI_DIRTY_BLESSINGS_PROGRESS | game_loader.UI_DIRTY_BLESSINGS_CATALOG | game_loader.UI_DIRTY_STATS)

func on_planet_purchase_requested(planet_id: String) -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.purchase_planet(planet_id):
		return
	game_loader._refresh_ui(game_loader._get_resource_refresh_flags() | game_loader.UI_DIRTY_PLANETS | game_loader.UI_DIRTY_WORLD | game_loader.UI_DIRTY_NAVIGATION | game_loader.UI_DIRTY_STATS)
	game_loader.planets_panel_controller.play_planet_unlock_animation(planet_id)

func on_moon_upgrade_requested(moon_id: String, upgrade_id: String) -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.purchase_moon_upgrade(moon_id, upgrade_id):
		return
	game_loader._refresh_ui(game_loader.UI_DIRTY_PLANETS | game_loader.UI_DIRTY_WORLD | game_loader.UI_DIRTY_STATS | game_loader.UI_DIRTY_TOP_BAR)
	game_loader.planets_panel_controller.play_moon_upgrade_purchase_animation(moon_id, upgrade_id)

func on_prestige_requested() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.perform_prestige():
		return
	game_loader.dust_recipe_service.invalidate()
	game_loader.upgrades_system.mark_cache_dirty()
	game_loader.tick_system.configure(game_loader.game_state, game_loader.element_system, game_loader.upgrades_system)
	game_loader.atom_effects_controller.clear()
	game_loader.world_view_controller.clear_particles()
	game_loader._refresh_ui(game_loader.UI_DIRTY_ALL)

func on_claim_prestige_node_requested() -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.claim_next_prestige_node():
		return
	game_loader.dust_recipe_service.invalidate()
	game_loader.upgrades_system.mark_cache_dirty()
	game_loader._refresh_ui(game_loader.UI_DIRTY_PRESTIGE | game_loader.UI_DIRTY_ELEMENTS | game_loader.UI_DIRTY_STATS | game_loader.UI_DIRTY_TOP_BAR)

func on_prestige_decrement_pressed() -> void:
	adjust_prestige_count(-1)

func on_prestige_increment_pressed() -> void:
	adjust_prestige_count(1)

func on_era_unlock_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	if game_loader.game_state.unlock_next_era():
		game_loader.dust_recipe_service.invalidate()
		game_loader._refresh_ui(game_loader._get_resource_refresh_flags() | game_loader.UI_DIRTY_NAVIGATION | game_loader.UI_DIRTY_MENU_BUTTONS | game_loader.UI_DIRTY_ERA)

func on_world_worker_button_pressed() -> void:
	var game_loader = loader
	if game_loader == null:
		return
	if game_loader.game_state.buy_current_planet_worker():
		game_loader.dust_recipe_service.invalidate()
		game_loader._refresh_ui(game_loader._get_resource_refresh_flags())

func on_world_worker_slider_changed(value: float) -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.game_state.set_current_planet_worker_allocation_to_xp(value / 100.0)
	if game_loader.ui_state_controller.view_mode == game_loader.VIEW_WORLD:
		game_loader._refresh_ui(game_loader.UI_DIRTY_WORLD)

func on_upgrade_purchase_requested(upgrade_id: String) -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader.tick_system.enqueue_action("purchase_upgrade", {"id": upgrade_id})

func adjust_prestige_count(delta: int) -> void:
	var game_loader = loader
	if game_loader == null or not game_loader.game_state.adjust_prestige_count(delta):
		return
	game_loader._refresh_ui(game_loader._get_selection_refresh_flags() | game_loader.UI_DIRTY_SETTINGS)

func _open_menu(menu_id: int) -> void:
	var game_loader = loader
	if game_loader == null:
		return
	game_loader._set_menu_mode(menu_id)
	game_loader._refresh_ui(game_loader._get_menu_mode_refresh_flags())
