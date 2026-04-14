extends RefCounted

class_name GameState

const BlessingStateScript = preload("res://src/core/state/blessing_state.gd")
const BlessingManagerScript = preload("res://src/core/managers/blessing_manager.gd")
const MilestoneManagerScript = preload("res://src/core/managers/milestone_manager.gd")
const OblationManagerScript = preload("res://src/core/managers/oblation_manager.gd")
const ResourceManagerScript = preload("res://src/core/managers/resource_manager.gd")
const PlanetManagerScript = preload("res://src/core/managers/planet_manager.gd")
const ProgressionManagerScript = preload("res://src/core/managers/progression_manager.gd")
const UpgradeManagerScript = preload("res://src/core/managers/upgrade_manager.gd")
const ResetManagerScript = preload("res://src/core/managers/reset_manager.gd")
const GameStateSerializerScript = preload("res://src/core/save/game_state_serializer.gd")

const SAVE_VERSION := 7
const DUST_RESOURCE_ID := "dust"
const BLESSINGS_MENU_UNLOCK_ELEMENT_ID := "ele_C"
# Centralize blessing cost tuning so playtest balance changes stay in one place.
const BLESSING_COST_QUADRATIC_A := 10.0
const BLESSING_COST_QUADRATIC_B := 400.0
const BLESSING_COST_QUADRATIC_C := 1600.0
const BLESSING_RARITY_ORDER := [
	"Uncommon",
	"Rare",
	"Legendary",
	"Exotic",
	"Exalted",
	"Divine"
]
const ERA_NAMES := [
	"Atomic Era",
	"Planetary Era",
	"Solar Era",
	"Space Era",
	"Coming Soon"
]
const ERA_MENU_UNLOCK_ELEMENT_ID := "ele_Ne"
const MAX_IMPLEMENTED_ERA_INDEX := 1
const PLANETARY_ERA_RESOURCE_IDS := ["ele_H", "ele_He", "ele_C", "ele_O", "ele_Ne"]
const PLANETARY_ERA_RESOURCE_COST := 10000.0
const PLANETARY_ERA_ORB_COST := 1000
const UNLOCK_SECTION_ENDS := [10, 30, 54, 86, 118]
const DEFAULT_PLANET_ID := "planet_a"
const PLANET_B_ID := "planet_b"
const PLANET_WORKER_BASE_COST := 1000.0
const PLANET_WORKER_COST_RATIO := 1.25
const PLANET_WORKER_COST_ROUND_TO := 25.0
const PLANET_XP_LEVEL_TWO_REQUIREMENT := 1500.0
const PLANET_XP_LEVEL_TWENTY_FIVE_REQUIREMENT := 10000000.0
const PLANET_A_MAX_LEVEL := 25
const RESEARCH_POINTS_PER_PRODUCTION := 0.001
const PRESTIGE_MILESTONES := [
	{
		"id": "planet_a_5",
		"title": "Planet A Lv. 5",
		"description": "Reach Planet A level 5.",
		"kind": "planet_level",
		"planet_id": DEFAULT_PLANET_ID,
		"planet_name": "Planet A",
		"required_level": 5,
		"reward_points": 1,
		"placeholder": false,
		"unlock_planet_id": PLANET_B_ID
	},
	{
		"id": "planet_b_5",
		"title": "Planet B Lv. 5",
		"description": "Reach Planet B level 5.",
		"kind": "planet_level",
		"planet_id": PLANET_B_ID,
		"planet_name": "Planet B",
		"required_level": 5,
		"reward_points": 1,
		"placeholder": false
	},
	{
		"id": "planet_c_5",
		"title": "Planet C Lv. 5",
		"description": "Reach Planet C level 5.",
		"kind": "planet_level",
		"planet_id": "planet_c",
		"planet_name": "Planet C",
		"required_level": 5,
		"reward_points": 1,
		"placeholder": true
	},
	{
		"id": "planet_d_5",
		"title": "Planet D Lv. 5",
		"description": "Reach Planet D level 5.",
		"kind": "planet_level",
		"planet_id": "planet_d",
		"planet_name": "Planet D",
		"required_level": 5,
		"reward_points": 1,
		"placeholder": true
	},
	{
		"id": "planet_e_5",
		"title": "Planet E Lv. 5",
		"description": "Reach Planet E level 5.",
		"kind": "planet_level",
		"planet_id": "planet_e",
		"planet_name": "Planet E",
		"required_level": 5,
		"reward_points": 1,
		"placeholder": true
	},
	{
		"id": "solar_1",
		"title": "Solar 1",
		"description": "Complete Solar milestone I.",
		"kind": "solar_rank",
		"required_rank": 1,
		"reward_points": 1,
		"placeholder": true
	},
	{
		"id": "solar_2",
		"title": "Solar 2",
		"description": "Complete Solar milestone II.",
		"kind": "solar_rank",
		"required_rank": 2,
		"reward_points": 1,
		"placeholder": true
	},
	{
		"id": "solar_3",
		"title": "Solar 3",
		"description": "Complete Solar milestone III.",
		"kind": "solar_rank",
		"required_rank": 3,
		"reward_points": 1,
		"placeholder": true
	},
	{
		"id": "solar_4",
		"title": "Solar 4",
		"description": "Complete Solar milestone IV.",
		"kind": "solar_rank",
		"required_rank": 4,
		"reward_points": 1,
		"placeholder": true
	},
	{
		"id": "solar_5",
		"title": "Solar 5",
		"description": "Complete Solar milestone V.",
		"kind": "solar_rank",
		"required_rank": 5,
		"reward_points": 1,
		"placeholder": true
	},
	{
		"id": "break_prestige",
		"title": "Break Prestige",
		"description": "Reserved for future milestone content.",
		"kind": "break_prestige",
		"reward_points": 0,
		"placeholder": true
	}
]
const PRESTIGE_NODES := []

var orbs: int
var dust: DigitMaster
var elements: Dictionary
var element_ids_in_order: Array[String]
var upgrades: Dictionary
var upgrade_ids_in_order: Array[String]
var blessings: Dictionary
var blessing_ids_in_order: Array[String]
var blessing_ids_by_rarity: Dictionary
var blessing_rarity_roll_weights: Dictionary
var blessing_rarity_roll_displays: Dictionary
var blessing_rarity_colors: Dictionary
var _cached_blessing_effect_totals: Dictionary
var _blessing_effect_cache_dirty: bool
var planet_ids_in_order: Array[String]
var current_element_id: String
var next_unlock_id: String
var max_unlocked_element_id: String
var player_level: int
var prestige_count: int
var global_multiplier: DigitMaster
var tick_count: int
var total_played_seconds: float
var last_save_tick: int
var total_manual_smashes: int
var total_auto_smashes: int
var blessings_count: int
var unopened_blessings_count: int
var blessings_progress_mass: DigitMaster
var blessings_menu_unlocked: bool
var unlocked_era_index: int
var planets: Dictionary
var current_planet_id: String
var research_points: DigitMaster
var research_progress: float
var completed_milestones: Array[String]
var next_milestone_id: String
var prestige_points_total: int
var prestige_points_unspent: int
var prestige_nodes_claimed: Array[String]
var best_planet_levels_this_run: Dictionary
var planet_purchase_unlocks: Dictionary
var planet_owned_flags: Dictionary
var sacrificed_planet_flags: Dictionary
var moon_upgrade_purchases: Dictionary
var oblation_claimed_recipe_ids: Array[String]
var oblation_recipe_ids_in_order: Array[String]
var _planet_menu_root: Dictionary
var _planet_menu_stages: Array[Dictionary]
var _planet_menu_stage_by_index: Dictionary
var _planet_menu_planets: Dictionary
var _planet_menu_moons: Dictionary
var _oblation_recipes_by_id: Dictionary

var _element_ids_by_index: Dictionary
var _blessing_rng: RandomNumberGenerator
var blessing_manager
var resource_manager
var milestone_manager
var oblation_manager
var planet_manager
var progression_manager
var upgrade_manager
var reset_manager
var serializer

static func from_content(
	elements_content: Dictionary,
	upgrades_content: Dictionary,
	blessings_content: Dictionary,
	planets_content: Dictionary,
	planet_menu_content: Dictionary = {},
	oblations_content: Dictionary = {}
) -> GameState:
	var state := GameState.new()
	state._load_elements(elements_content.get("elements", []))
	state._load_upgrades(upgrades_content.get("upgrades", []))
	state._load_blessings(
		blessings_content.get("blessings", []),
		blessings_content.get("rarities", [])
	)
	state._load_planets(planets_content.get("planets", []))
	state._load_planet_menu_config(planet_menu_content)
	state._load_oblations(oblations_content)
	state.refresh_progression_state()
	return state

func _init() -> void:
	orbs = 0
	dust = DigitMaster.zero()
	elements = {}
	element_ids_in_order = []
	upgrades = {}
	upgrade_ids_in_order = []
	blessings = {}
	blessing_ids_in_order = []
	blessing_ids_by_rarity = {}
	blessing_rarity_roll_weights = {}
	blessing_rarity_roll_displays = {}
	blessing_rarity_colors = {}
	_cached_blessing_effect_totals = {}
	_blessing_effect_cache_dirty = true
	planet_ids_in_order = []
	current_element_id = ""
	next_unlock_id = ""
	max_unlocked_element_id = ""
	player_level = 1
	prestige_count = 0
	global_multiplier = DigitMaster.one()
	tick_count = 0
	total_played_seconds = 0.0
	last_save_tick = 0
	total_manual_smashes = 0
	total_auto_smashes = 0
	blessings_count = 0
	unopened_blessings_count = 0
	blessings_progress_mass = DigitMaster.zero()
	blessings_menu_unlocked = false
	unlocked_era_index = 0
	planets = {}
	current_planet_id = DEFAULT_PLANET_ID
	research_points = DigitMaster.zero()
	research_progress = 0.0
	completed_milestones = []
	next_milestone_id = ""
	prestige_points_total = 0
	prestige_points_unspent = 0
	prestige_nodes_claimed = []
	best_planet_levels_this_run = {}
	planet_purchase_unlocks = {}
	planet_owned_flags = {}
	sacrificed_planet_flags = {}
	moon_upgrade_purchases = {}
	oblation_claimed_recipe_ids = []
	oblation_recipe_ids_in_order = []
	_planet_menu_root = {}
	_planet_menu_stages = []
	_planet_menu_stage_by_index = {}
	_planet_menu_planets = {}
	_planet_menu_moons = {}
	_oblation_recipes_by_id = {}
	_element_ids_by_index = {}
	_blessing_rng = RandomNumberGenerator.new()
	_blessing_rng.randomize()
	blessing_manager = BlessingManagerScript.new(self)
	milestone_manager = MilestoneManagerScript.new(self)
	oblation_manager = OblationManagerScript.new(self)
	resource_manager = ResourceManagerScript.new(self)
	planet_manager = PlanetManagerScript.new(self)
	progression_manager = ProgressionManagerScript.new(self)
	upgrade_manager = UpgradeManagerScript.new(self)
	reset_manager = ResetManagerScript.new(self)
	serializer = GameStateSerializerScript.new()
	next_milestone_id = _get_first_milestone_id()

func _load_elements(elements_data: Array) -> void:
	progression_manager.load_elements(elements_data)

func _load_upgrades(upgrades_data: Array) -> void:
	upgrade_manager.load_upgrades(upgrades_data)

func _load_blessings(blessings_data: Array, rarity_data: Array) -> void:
	blessing_manager.load_blessings(blessings_data, rarity_data)

func _rebuild_blessings_state(blessings_data: Array, rarity_data: Array) -> void:
	blessing_manager.rebuild_blessings_state(blessings_data, rarity_data)

func _reset_blessing_state_containers() -> void:
	blessing_manager.reset_blessing_state_containers()

func _load_blessing_rarity_metadata(rarity_data: Array) -> void:
	blessing_manager.load_blessing_rarity_metadata(rarity_data)

func _register_blessing_state(blessing: BlessingState) -> void:
	blessing_manager.register_blessing_state(blessing)

func _load_planets(planets_data: Array) -> void:
	planet_manager.load_planets(planets_data)

func _load_planet_menu_config(planet_menu_content: Dictionary) -> void:
	planet_manager.load_planet_menu_config(planet_menu_content)

func _load_oblations(oblations_content: Dictionary) -> void:
	oblation_manager.load_oblations(oblations_content)

func refresh_progression_state() -> void:
	progression_manager.refresh_progression_state()

func _ensure_planet_meta_defaults() -> void:
	planet_manager.ensure_planet_meta_defaults()

func _apply_planet_unlock_states() -> void:
	planet_manager.apply_planet_unlock_states()

func _get_first_milestone_id() -> String:
	return milestone_manager.get_first_milestone_id()

func _get_next_pending_milestone_id() -> String:
	return milestone_manager.get_next_pending_milestone_id()

func _sync_legacy_prestige_count_from_nodes() -> void:
	prestige_count = maxi(0, get_visible_element_section_count() - 1)

func _update_best_planet_level(planet_id: String, level: int) -> void:
	planet_manager.update_best_planet_level(planet_id, level)

func has_element(element_id: String) -> bool:
	return progression_manager.has_element(element_id)

func get_element_state(element_id: String) -> ElementState:
	return progression_manager.get_element_state(element_id)

func is_element_unlocked(element_id: String) -> bool:
	return progression_manager.is_element_unlocked(element_id)

func is_element_id(resource_id: String) -> bool:
	return progression_manager.is_element_id(resource_id)

func get_element_state_by_index(index: int) -> ElementState:
	return progression_manager.get_element_state_by_index(index)

func get_current_element_state() -> ElementState:
	return progression_manager.get_current_element_state()

func get_next_unlock_element_state() -> ElementState:
	return progression_manager.get_next_unlock_element_state()

func get_visible_element_section_count() -> int:
	return progression_manager.get_visible_element_section_count()

func get_max_unlockable_element_index() -> int:
	return progression_manager.get_max_unlockable_element_index()

func get_max_prestige_count() -> int:
	return progression_manager.get_max_prestige_count()

func set_prestige_count(value: int) -> bool:
	return progression_manager.set_prestige_count(value)

func adjust_prestige_count(delta: int) -> bool:
	return progression_manager.adjust_prestige_count(delta)

func get_milestone_by_id(milestone_id: String) -> Dictionary:
	return milestone_manager.get_milestone_by_id(milestone_id)

func get_next_milestone() -> Dictionary:
	return milestone_manager.get_next_milestone()

func get_milestone_entries() -> Array[Dictionary]:
	return milestone_manager.get_milestone_entries()

func refresh_milestones() -> bool:
	return milestone_manager.refresh_milestones()

func get_completed_planet_rank() -> int:
	return milestone_manager.get_completed_planet_rank()

func is_oblation_menu_unlocked() -> bool:
	return milestone_manager.is_oblation_menu_unlocked()

func get_oblation_recipe_entries() -> Array[Dictionary]:
	return oblation_manager.get_oblation_recipe_entries()

func get_oblation_slot_options(recipe_id: String, slot_id: String) -> Array[Dictionary]:
	return oblation_manager.get_oblation_slot_options(recipe_id, slot_id)

func get_oblation_preview(recipe_id: String, selected_inputs: Dictionary) -> Dictionary:
	return oblation_manager.get_oblation_preview(recipe_id, selected_inputs)

func can_confirm_oblation(recipe_id: String, selected_inputs: Dictionary) -> bool:
	return oblation_manager.can_confirm_oblation(recipe_id, selected_inputs)

func confirm_oblation(recipe_id: String, selected_inputs: Dictionary) -> bool:
	return oblation_manager.confirm_oblation(recipe_id, selected_inputs)

func get_oblation_effect_totals() -> Dictionary:
	return oblation_manager.get_oblation_effect_totals()

func get_dust_gain_multiplier() -> float:
	return oblation_manager.get_dust_gain_multiplier()

func get_research_gain_multiplier() -> float:
	return oblation_manager.get_research_gain_multiplier()

func get_planet_xp_gain_multiplier() -> float:
	return oblation_manager.get_planet_xp_gain_multiplier()

func _get_milestone_progress_text(milestone: Dictionary) -> String:
	return milestone_manager.get_milestone_progress_text(milestone)

func get_next_prestige_milestone() -> Dictionary:
	return get_next_milestone()

func get_prestige_milestone_entries() -> Array[Dictionary]:
	return get_milestone_entries()

func get_prestige_preview() -> Dictionary:
	return {
		"can_prestige": false,
		"milestone": get_next_milestone()
	}

func get_prestige_node_entries() -> Array[Dictionary]:
	return []

func get_next_prestige_node_definition() -> Dictionary:
	return {}

func get_prestige_dust_multiplier() -> float:
	return get_dust_gain_multiplier()

func can_prestige() -> bool:
	return false

func can_claim_next_prestige_node() -> bool:
	return false

func perform_prestige() -> bool:
	return false

func claim_next_prestige_node() -> bool:
	return false

func is_next_unlock_within_visible_sections() -> bool:
	return progression_manager.is_next_unlock_within_visible_sections()

func get_unlocked_element_ids() -> Array[String]:
	return progression_manager.get_unlocked_element_ids()

func get_unlocked_real_element_ids() -> Array[String]:
	return progression_manager.get_unlocked_real_element_ids()

func get_max_unlocked_real_element_index() -> int:
	return progression_manager.get_max_unlocked_real_element_index()

func get_visible_counter_element_ids() -> Array[String]:
	return progression_manager.get_visible_counter_element_ids()

func has_planet(planet_id: String) -> bool:
	return planet_manager.has_planet(planet_id)

func get_planet_state(planet_id: String) -> PlanetState:
	return planet_manager.get_planet_state(planet_id)

func get_planet_ids() -> Array[String]:
	return planet_manager.get_planet_ids()

func get_current_planet_state() -> PlanetState:
	return planet_manager.get_current_planet_state()

func is_planet_unlocked(planet_id: String) -> bool:
	return planet_manager.is_planet_unlocked(planet_id)

func is_planet_owned(planet_id: String) -> bool:
	return planet_manager.is_planet_owned(planet_id)

func is_planet_sacrificed(planet_id: String) -> bool:
	return planet_manager.is_planet_sacrificed(planet_id)

func is_planet_purchase_unlocked(planet_id: String) -> bool:
	return planet_manager.is_planet_purchase_unlocked(planet_id)

func can_oblate_planet(planet_id: String) -> bool:
	return planet_manager.can_oblate_planet(planet_id)

func get_planet_display_state(planet_id: String) -> String:
	return planet_manager.get_planet_display_state(planet_id)

func get_fallback_world_planet_id() -> String:
	return planet_manager.get_fallback_world_planet_id()

func get_planet_purchase_cost_entries(planet_id: String) -> Array[Dictionary]:
	return planet_manager.get_planet_purchase_cost_entries(planet_id)

func can_purchase_planet(planet_id: String) -> bool:
	return planet_manager.can_purchase_planet(planet_id)

func purchase_planet(planet_id: String) -> bool:
	return planet_manager.purchase_planet(planet_id)

func select_planet(planet_id: String) -> bool:
	return planet_manager.select_planet(planet_id)

func get_planet_entries() -> Array[Dictionary]:
	return planet_manager.get_planet_entries()

func get_planet_menu_stage() -> int:
	return planet_manager.get_planet_menu_stage()

func get_planet_menu_view_model() -> Dictionary:
	return planet_manager.get_planet_menu_view_model()

func get_planet_menu_planet_entry(planet_id: String) -> Dictionary:
	return planet_manager.get_planet_menu_planet_entry(planet_id)

func get_planet_menu_moon_entry(moon_id: String) -> Dictionary:
	return planet_manager.get_planet_menu_moon_entry(moon_id)

func get_moon_upgrade_entries(moon_id: String) -> Array[Dictionary]:
	return planet_manager.get_moon_upgrade_entries(moon_id)

func can_purchase_moon_upgrade(moon_id: String, upgrade_id: String) -> bool:
	return planet_manager.can_purchase_moon_upgrade(moon_id, upgrade_id)

func purchase_moon_upgrade(moon_id: String, upgrade_id: String) -> bool:
	return planet_manager.purchase_moon_upgrade(moon_id, upgrade_id)

func has_adjacent_owned_planet(direction: int) -> bool:
	return planet_manager.has_adjacent_owned_planet(direction)

func select_adjacent_owned_planet(direction: int) -> bool:
	return planet_manager.select_adjacent_owned_planet(direction)

func _get_planet_menu_action_label(planet_id: String) -> String:
	return planet_manager.get_planet_menu_action_label(planet_id)

func _get_planet_menu_stage_entry(stage_index: int) -> Dictionary:
	return planet_manager.get_planet_menu_stage_entry(stage_index)

func _is_planet_visible_in_stage(planet_id: String, stage_index: int) -> bool:
	return planet_manager.is_planet_visible_in_stage(planet_id, stage_index)

func _is_moon_visible_in_stage(moon_id: String, stage_index: int) -> bool:
	return planet_manager.is_moon_visible_in_stage(moon_id, stage_index)

func _get_planet_menu_progress_rank(milestone_id: String) -> int:
	return planet_manager.get_planet_menu_progress_rank(milestone_id)

func _get_purchased_moon_upgrade_ids(moon_id: String) -> Array[String]:
	return planet_manager.get_purchased_moon_upgrade_ids(moon_id)

func _find_adjacent_owned_planet_id(direction: int) -> String:
	return planet_manager.find_adjacent_owned_planet_id(direction)

func get_current_planet_workers() -> DigitMaster:
	return planet_manager.get_current_planet_workers()

func get_current_planet_worker_cost() -> DigitMaster:
	return planet_manager.get_current_planet_worker_cost()

func can_buy_current_planet_worker() -> bool:
	return planet_manager.can_buy_current_planet_worker()

func buy_current_planet_worker() -> bool:
	return planet_manager.buy_current_planet_worker()

func set_current_planet_worker_allocation_to_xp(allocation_ratio: float) -> void:
	planet_manager.set_current_planet_worker_allocation_to_xp(allocation_ratio)

func get_current_planet_worker_allocation_to_xp() -> float:
	return planet_manager.get_current_planet_worker_allocation_to_xp()

func process_planet_production(delta_seconds: float) -> Dictionary:
	return planet_manager.process_planet_production(delta_seconds)

func get_current_planet_level_progress_ratio() -> float:
	return planet_manager.get_current_planet_level_progress_ratio()

func get_research_progress_ratio() -> float:
	return resource_manager.get_research_progress_ratio()

func get_current_planet_xp() -> DigitMaster:
	return planet_manager.get_current_planet_xp()

func get_current_planet_xp_to_next_level() -> DigitMaster:
	return planet_manager.get_current_planet_xp_to_next_level()

func get_research_points() -> DigitMaster:
	return resource_manager.get_research_points()

func get_research_progress_display() -> String:
	return resource_manager.get_research_progress_display()

func get_upgrade_state(upgrade_id: String) -> UpgradeState:
	return upgrade_manager.get_upgrade_state(upgrade_id)

func get_upgrade_ids() -> Array[String]:
	return upgrade_manager.get_upgrade_ids()

func has_blessing(blessing_id: String) -> bool:
	return blessing_manager.has_blessing(blessing_id)

func get_blessing_state(blessing_id: String):
	return blessing_manager.get_blessing_state(blessing_id)

func get_blessing_ids() -> Array[String]:
	return blessing_manager.get_blessing_ids()

func get_blessing_ids_for_rarity(rarity: String) -> Array[String]:
	return blessing_manager.get_blessing_ids_for_rarity(rarity)

func get_blessing_rarity_order() -> Array[String]:
	return blessing_manager.get_blessing_rarity_order()

func get_blessing_rarity_roll_display(rarity: String) -> String:
	return blessing_manager.get_blessing_rarity_roll_display(rarity)

func get_blessing_rarity_color(rarity: String) -> Color:
	return blessing_manager.get_blessing_rarity_color(rarity)

func get_discovered_blessing_count() -> int:
	return blessing_manager.get_discovered_blessing_count()

func get_unopened_blessings_count() -> int:
	return blessing_manager.get_unopened_blessings_count()

func can_open_blessings() -> bool:
	return blessing_manager.can_open_blessings()

func get_resource_name(resource_id: String) -> String:
	return resource_manager.get_resource_name(resource_id)

func get_resource_amount(resource_id: String) -> DigitMaster:
	return resource_manager.get_resource_amount(resource_id)

func can_afford_resource(resource_id: String, cost: DigitMaster) -> bool:
	return resource_manager.can_afford_resource(resource_id, cost)

func can_afford_cost_entries(cost_entries: Array[Dictionary]) -> bool:
	return resource_manager.can_afford_cost_entries(cost_entries)

func add_resource(resource_id: String, amount: DigitMaster) -> void:
	resource_manager.add_resource(resource_id, amount)

func spend_resource(resource_id: String, amount: DigitMaster) -> bool:
	return resource_manager.spend_resource(resource_id, amount)

func spend_cost_entries_atomic(cost_entries: Array[Dictionary]) -> bool:
	return resource_manager.spend_cost_entries_atomic(cost_entries)

func _get_cost_entry_amount(cost_entry: Dictionary) -> DigitMaster:
	return resource_manager.get_cost_entry_amount(cost_entry)

func _set_resource_amount(resource_id: String, amount: DigitMaster) -> void:
	resource_manager.set_resource_amount(resource_id, amount)

func produce_resource(resource_id: String, amount: DigitMaster) -> void:
	resource_manager.produce_resource(resource_id, amount)

func is_blessings_menu_unlocked() -> bool:
	return blessing_manager.is_blessings_menu_unlocked()

func get_blessing_critical_smasher_bonus_percent() -> float:
	return blessing_manager.get_blessing_critical_smasher_bonus_percent()

func get_blessing_fission_bonus_percent() -> float:
	return blessing_manager.get_blessing_fission_bonus_percent()

func get_foil_spawn_chance_percent() -> float:
	return blessing_manager.get_foil_spawn_chance_percent()

func get_holographic_spawn_chance_percent() -> float:
	return blessing_manager.get_holographic_spawn_chance_percent()

func get_polychrome_spawn_chance_percent() -> float:
	return blessing_manager.get_polychrome_spawn_chance_percent()

func open_earned_blessings() -> int:
	return blessing_manager.open_earned_blessings()

func reset_blessings() -> bool:
	return blessing_manager.reset_blessings()

func get_next_blessing_cost() -> DigitMaster:
	return blessing_manager.get_next_blessing_cost()

func get_blessing_progress_mass() -> DigitMaster:
	return blessing_manager.get_blessing_progress_mass()

func get_remaining_blessing_mass() -> DigitMaster:
	return blessing_manager.get_remaining_blessing_mass()

func has_unlocked_element_count(required_count: int) -> bool:
	return progression_manager.has_unlocked_element_count(required_count)

func is_era_menu_unlocked() -> bool:
	return progression_manager.is_era_menu_unlocked()

func get_unlocked_era_index() -> int:
	return progression_manager.get_unlocked_era_index()

func has_unlocked_era(era_index: int) -> bool:
	return progression_manager.has_unlocked_era(era_index)

func get_era_name(era_index: int) -> String:
	return progression_manager.get_era_name(era_index)

func get_next_implemented_era_index() -> int:
	return progression_manager.get_next_implemented_era_index()

func get_next_implemented_era_name() -> String:
	return progression_manager.get_next_implemented_era_name()

func get_next_era_requirements() -> Array[Dictionary]:
	return progression_manager.get_next_era_requirements()

func can_unlock_next_era() -> bool:
	return progression_manager.can_unlock_next_era()

func unlock_next_era() -> bool:
	return progression_manager.unlock_next_era()

func select_element(element_id: String) -> bool:
	return progression_manager.select_element(element_id)

func has_adjacent_unlocked_element(direction: int) -> bool:
	return progression_manager.has_adjacent_unlocked_element(direction)

func has_next_selectable_element_in_visible_sections() -> bool:
	return progression_manager.has_next_selectable_element_in_visible_sections()

func select_adjacent_unlocked(direction: int) -> bool:
	return progression_manager.select_adjacent_unlocked(direction)

func _find_adjacent_unlocked_element_id(direction: int) -> String:
	return progression_manager.find_adjacent_unlocked_element_id(direction)

func can_unlock_next() -> bool:
	return progression_manager.can_unlock_next()

func unlock_next_element() -> bool:
	return progression_manager.unlock_next_element()

func set_upgrade_level(upgrade_id: String, level: int) -> void:
	upgrade_manager.set_upgrade_level(upgrade_id, level)

func set_upgrade_current_cost(upgrade_id: String, cost: DigitMaster) -> void:
	upgrade_manager.set_upgrade_current_cost(upgrade_id, cost)

func set_upgrade_secondary_current_cost(upgrade_id: String, cost: DigitMaster) -> void:
	upgrade_manager.set_upgrade_secondary_current_cost(upgrade_id, cost)

func to_save_dict() -> Dictionary:
	return serializer.to_save_dict(self)

func apply_save_dict(save_data: Dictionary) -> void:
	serializer.apply_save_dict(self, save_data)

func _reset_run_state() -> void:
	reset_manager.reset_run_state()

func _reset_elements_to_defaults() -> void:
	progression_manager.reset_elements_to_defaults()

func _reset_upgrades_to_defaults() -> void:
	upgrade_manager.reset_upgrades_to_defaults()

func _reset_planets_to_owned_defaults() -> void:
	reset_manager.reset_planets_to_owned_defaults()

func _calculate_planet_xp_requirement(level: int) -> DigitMaster:
	return planet_manager.calculate_planet_xp_requirement(level)

func _apply_planet_xp(planet: PlanetState, xp_amount: DigitMaster) -> void:
	planet_manager.apply_planet_xp(planet, xp_amount)

func _calculate_planet_worker_cost(planet: PlanetState) -> DigitMaster:
	return planet_manager.calculate_planet_worker_cost(planet)

func _apply_research_progress(rp_amount: DigitMaster) -> void:
	resource_manager.apply_research_progress(rp_amount)

func _apply_blessing_progress_for_generated_element(element: ElementState, amount: DigitMaster) -> void:
	blessing_manager.apply_blessing_progress_for_generated_element(element, amount)

func _award_random_blessing() -> void:
	blessing_manager.award_random_blessing()

func _roll_random_blessing_id() -> String:
	return blessing_manager.roll_random_blessing_id()

func _roll_blessing_rarity() -> String:
	return blessing_manager.roll_blessing_rarity()

func _get_rollable_rarities() -> Array[String]:
	return blessing_manager.get_rollable_rarities()

func _get_rollable_blessing_ids_for_rarity(rarity: String) -> Array[String]:
	return blessing_manager.get_rollable_blessing_ids_for_rarity(rarity)

func _get_blessing_effect_total(effect_type: String) -> float:
	return blessing_manager.get_blessing_effect_total(effect_type)

func _invalidate_blessing_effect_cache() -> void:
	blessing_manager.invalidate_blessing_effect_cache()

func _apply_saved_blessing_levels(saved_blessings: Dictionary) -> void:
	blessing_manager.apply_saved_blessing_levels(saved_blessings)

func _reset_blessing_levels_to_zero() -> bool:
	return blessing_manager.reset_blessing_levels_to_zero()

func _ensure_blessing_effect_cache() -> void:
	blessing_manager.ensure_blessing_effect_cache()

func _get_digit_ratio(current: DigitMaster, maximum: DigitMaster) -> float:
	var max_float := maximum.to_float()
	if max_float <= 0.0:
		return 0.0
	return clampf(current.to_float() / max_float, 0.0, 1.0)

func _clamp_current_element_to_visible_sections() -> void:
	progression_manager.clamp_current_element_to_visible_sections()
