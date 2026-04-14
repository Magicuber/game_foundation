extends RefCounted

class_name UiStateController

var menu_mode: int
var view_mode: int
var ui_dirty_flags: int

func _init(initial_menu_mode: int = 0, initial_view_mode: int = 0, initial_dirty_flags: int = 0) -> void:
	menu_mode = initial_menu_mode
	view_mode = initial_view_mode
	ui_dirty_flags = initial_dirty_flags

func set_menu_mode(new_mode: int) -> void:
	menu_mode = new_mode

func set_view_mode(new_mode: int) -> bool:
	if view_mode == new_mode:
		return false
	view_mode = new_mode
	return true

func mark_ui_dirty(flags: int) -> void:
	if flags == 0:
		return
	ui_dirty_flags |= flags

func has_dirty_ui() -> bool:
	return ui_dirty_flags != 0

func refresh_ui(flags: int, flush_callable: Callable) -> void:
	mark_ui_dirty(flags)
	flush_callable.call()

func flush_dirty_ui(game_state, refresh_entries: Array[Dictionary]) -> void:
	if game_state == null:
		return

	while ui_dirty_flags != 0:
		var flags := ui_dirty_flags
		ui_dirty_flags = 0
		for refresh_entry in refresh_entries:
			var refresh_flag := int(refresh_entry.get("flag", 0))
			if flags & refresh_flag:
				var refresh_callable: Callable = refresh_entry.get("callable", Callable())
				if refresh_callable.is_valid():
					refresh_callable.call()

func get_resource_refresh_flags(
	ui_dirty_top_bar: int,
	ui_dirty_counters: int,
	ui_dirty_upgrades: int,
	ui_dirty_elements: int,
	ui_dirty_era: int,
	ui_dirty_stats: int,
	ui_dirty_planets: int,
	ui_dirty_blessings_progress: int,
	ui_dirty_world: int,
	ui_dirty_prestige: int,
	ui_dirty_oblations: int
) -> int:
	return (
		ui_dirty_top_bar
		| ui_dirty_counters
		| ui_dirty_upgrades
		| ui_dirty_elements
		| ui_dirty_era
		| ui_dirty_stats
		| ui_dirty_planets
		| ui_dirty_blessings_progress
		| ui_dirty_world
		| ui_dirty_prestige
		| ui_dirty_oblations
	)

func get_selection_refresh_flags(
	ui_dirty_selection: int,
	ui_dirty_navigation: int,
	ui_dirty_elements: int,
	ui_dirty_stats: int
) -> int:
	return ui_dirty_selection | ui_dirty_navigation | ui_dirty_elements | ui_dirty_stats

func get_menu_mode_refresh_flags(
	menu_upgrades: int,
	menu_elements: int,
	menu_blessings: int,
	menu_era: int,
	menu_stats: int,
	menu_shop: int,
	menu_planets: int,
	menu_prestige: int,
	menu_oblations: int,
	menu_settings: int,
	ui_dirty_menu_buttons: int,
	ui_dirty_upgrades: int,
	ui_dirty_elements: int,
	ui_dirty_blessings_progress: int,
	ui_dirty_blessings_catalog: int,
	ui_dirty_era: int,
	ui_dirty_stats: int,
	ui_dirty_shop: int,
	ui_dirty_planets: int,
	ui_dirty_prestige: int,
	ui_dirty_oblations: int,
	ui_dirty_settings: int
) -> int:
	var flags := ui_dirty_menu_buttons
	match menu_mode:
		menu_upgrades:
			flags |= ui_dirty_upgrades
		menu_elements:
			flags |= ui_dirty_elements
		menu_blessings:
			flags |= ui_dirty_blessings_progress | ui_dirty_blessings_catalog
		menu_era:
			flags |= ui_dirty_era
		menu_stats:
			flags |= ui_dirty_stats
		menu_shop:
			flags |= ui_dirty_shop
		menu_planets:
			flags |= ui_dirty_planets
		menu_prestige:
			flags |= ui_dirty_prestige
		menu_oblations:
			flags |= ui_dirty_oblations
		menu_settings:
			flags |= ui_dirty_settings
	return flags

func get_view_mode_refresh_flags(
	ui_dirty_navigation: int,
	ui_dirty_counters: int,
	ui_dirty_world: int,
	ui_dirty_debug: int,
	ui_dirty_menu_buttons: int
) -> int:
	return ui_dirty_navigation | ui_dirty_counters | ui_dirty_world | ui_dirty_debug | ui_dirty_menu_buttons
