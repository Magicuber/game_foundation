extends RefCounted

class_name ResetManager

var _game_state_ref: WeakRef = null
var game_state:
	get:
		return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func reset_run_state() -> void:
	game_state.dust = DigitMaster.zero()
	game_state.current_element_id = ""
	game_state.next_unlock_id = ""
	game_state.max_unlocked_element_id = ""
	game_state.player_level = 1
	game_state.global_multiplier = DigitMaster.one()
	game_state.tick_count = 0
	game_state.total_played_seconds = 0.0
	game_state.last_save_tick = 0
	game_state.total_manual_smashes = 0
	game_state.total_auto_smashes = 0
	game_state.research_points = DigitMaster.zero()
	game_state.research_progress = 0.0
	game_state.best_planet_levels_this_run.clear()
	game_state.moon_upgrade_purchases.clear()
	game_state._reset_elements_to_defaults()
	game_state._reset_upgrades_to_defaults()
	game_state._reset_planets_to_owned_defaults()
	game_state.current_planet_id = game_state.get_fallback_world_planet_id()
	if game_state.current_planet_id.is_empty():
		game_state.current_planet_id = game_state.DEFAULT_PLANET_ID

func reset_planets_to_owned_defaults() -> void:
	game_state._ensure_planet_meta_defaults()

	for planet_id in game_state.planet_ids_in_order:
		var planet: PlanetState = game_state.get_planet_state(planet_id)
		if planet == null:
			continue
		planet.reset_to_default(game_state._calculate_planet_xp_requirement(planet.default_level))
		planet.unlocked = bool(game_state.planet_owned_flags.get(planet_id, false))
		if planet.unlocked:
			planet.level = maxi(1, planet.level)
			planet.xp_to_next_level = game_state._calculate_planet_xp_requirement(planet.level)
