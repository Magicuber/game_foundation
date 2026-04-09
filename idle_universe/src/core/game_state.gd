extends RefCounted

class_name GameState

const BlessingStateScript = preload("res://src/core/state/blessing_state.gd")

const SAVE_VERSION := 6
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
		"description": "Unlock repeatable multi-point prestige runs.",
		"kind": "break_prestige",
		"reward_points": 0,
		"placeholder": true
	}
]
const PRESTIGE_NODES := [
	{
		"id": "unlock_section_2",
		"title": "Node 1: Atomic Section II",
		"description": "Unlock element section 11-30.",
		"effect_type": "unlock_section",
		"effect_value": 1,
		"future_locked": false
	},
	{
		"id": "dust_gain_1",
		"title": "Node 2: Dust Yield",
		"description": "Increase all dust gains by 50%.",
		"effect_type": "dust_multiplier",
		"effect_value": 0.5,
		"future_locked": false
	},
	{
		"id": "future_node_3",
		"title": "Node 3: Future Unlock",
		"description": "Reserved for later milestone content.",
		"effect_type": "",
		"effect_value": 0,
		"future_locked": true
	},
	{
		"id": "future_node_4",
		"title": "Node 4: Future Unlock",
		"description": "Reserved for later milestone content.",
		"effect_type": "",
		"effect_value": 0,
		"future_locked": true
	},
	{
		"id": "future_node_5",
		"title": "Node 5: Future Unlock",
		"description": "Reserved for later milestone content.",
		"effect_type": "",
		"effect_value": 0,
		"future_locked": true
	},
	{
		"id": "future_node_6",
		"title": "Node 6: Future Unlock",
		"description": "Reserved for later milestone content.",
		"effect_type": "",
		"effect_value": 0,
		"future_locked": true
	},
	{
		"id": "future_node_7",
		"title": "Node 7: Future Unlock",
		"description": "Reserved for later milestone content.",
		"effect_type": "",
		"effect_value": 0,
		"future_locked": true
	},
	{
		"id": "future_node_8",
		"title": "Node 8: Future Unlock",
		"description": "Reserved for later milestone content.",
		"effect_type": "",
		"effect_value": 0,
		"future_locked": true
	},
	{
		"id": "future_node_9",
		"title": "Node 9: Future Unlock",
		"description": "Reserved for later milestone content.",
		"effect_type": "",
		"effect_value": 0,
		"future_locked": true
	},
	{
		"id": "future_node_10",
		"title": "Node 10: Future Unlock",
		"description": "Reserved for later milestone content.",
		"effect_type": "",
		"effect_value": 0,
		"future_locked": true
	}
]

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
var moon_upgrade_purchases: Dictionary
var _planet_menu_root: Dictionary
var _planet_menu_stages: Array[Dictionary]
var _planet_menu_stage_by_index: Dictionary
var _planet_menu_planets: Dictionary
var _planet_menu_moons: Dictionary

var _element_ids_by_index: Dictionary
var _blessing_rng: RandomNumberGenerator

static func from_content(
	elements_content: Dictionary,
	upgrades_content: Dictionary,
	blessings_content: Dictionary,
	planets_content: Dictionary,
	planet_menu_content: Dictionary = {}
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
	next_milestone_id = _get_first_milestone_id()
	prestige_points_total = 0
	prestige_points_unspent = 0
	prestige_nodes_claimed = []
	best_planet_levels_this_run = {}
	planet_purchase_unlocks = {}
	planet_owned_flags = {}
	moon_upgrade_purchases = {}
	_planet_menu_root = {}
	_planet_menu_stages = []
	_planet_menu_stage_by_index = {}
	_planet_menu_planets = {}
	_planet_menu_moons = {}
	_element_ids_by_index = {}
	_blessing_rng = RandomNumberGenerator.new()
	_blessing_rng.randomize()

func _load_elements(elements_data: Array) -> void:
	elements.clear()
	element_ids_in_order.clear()
	_element_ids_by_index.clear()

	for raw_element_variant in elements_data:
		if typeof(raw_element_variant) != TYPE_DICTIONARY:
			continue

		var raw_element: Dictionary = raw_element_variant
		var element := ElementState.from_content(raw_element, element_ids_in_order.size())
		if element.id.is_empty():
			continue

		elements[element.id] = element
		element_ids_in_order.append(element.id)
		_element_ids_by_index[element.index] = element.id

func _load_upgrades(upgrades_data: Array) -> void:
	upgrades.clear()
	upgrade_ids_in_order.clear()

	for raw_upgrade_variant in upgrades_data:
		if typeof(raw_upgrade_variant) != TYPE_DICTIONARY:
			continue

		var raw_upgrade: Dictionary = raw_upgrade_variant
		var upgrade := UpgradeState.from_content(raw_upgrade)
		if upgrade.id.is_empty():
			continue

		upgrades[upgrade.id] = upgrade
		upgrade_ids_in_order.append(upgrade.id)

func _load_blessings(blessings_data: Array, rarity_data: Array) -> void:
	blessings.clear()
	blessing_ids_in_order.clear()
	blessing_ids_by_rarity.clear()
	blessing_rarity_roll_weights.clear()
	blessing_rarity_roll_displays.clear()
	blessing_rarity_colors.clear()
	_invalidate_blessing_effect_cache()

	for rarity in BLESSING_RARITY_ORDER:
		blessing_ids_by_rarity[rarity] = []

	for raw_rarity_variant in rarity_data:
		if typeof(raw_rarity_variant) != TYPE_DICTIONARY:
			continue
		var raw_rarity: Dictionary = raw_rarity_variant
		var rarity := str(raw_rarity.get("rarity", ""))
		if rarity.is_empty():
			continue
		blessing_rarity_roll_weights[rarity] = maxf(0.0, float(raw_rarity.get("roll_weight", 0.0)))
		blessing_rarity_roll_displays[rarity] = str(raw_rarity.get("display_chance", ""))
		blessing_rarity_colors[rarity] = str(raw_rarity.get("color", "ffffff"))

	for raw_blessing_variant in blessings_data:
		if typeof(raw_blessing_variant) != TYPE_DICTIONARY:
			continue

		var raw_blessing: Dictionary = raw_blessing_variant
		var blessing = BlessingStateScript.new()
		blessing.id = str(raw_blessing.get("id", ""))
		blessing.name = str(raw_blessing.get("name", blessing.id))
		blessing.description = str(raw_blessing.get("description", ""))
		blessing.rarity = str(raw_blessing.get("rarity", ""))
		blessing.color_hex = str(raw_blessing.get("color", blessing.color_hex))
		blessing.slot_index = int(raw_blessing.get("slot_index", 0))
		blessing.level = maxi(0, int(raw_blessing.get("level", 0)))
		blessing.max_level = maxi(0, int(raw_blessing.get("max_level", 0)))
		blessing.effect_type = str(raw_blessing.get("effect_type", ""))
		blessing.effect_amount = float(raw_blessing.get("effect_amount", 0.0))
		blessing.effect_cap = maxf(0.0, float(raw_blessing.get("effect_cap", 0.0)))
		blessing.placeholder = bool(raw_blessing.get("placeholder", false))
		if blessing.id.is_empty():
			continue

		blessings[blessing.id] = blessing
		blessing_ids_in_order.append(blessing.id)
		if not blessing_ids_by_rarity.has(blessing.rarity):
			blessing_ids_by_rarity[blessing.rarity] = []
		blessing_ids_by_rarity[blessing.rarity].append(blessing.id)

func _load_planets(planets_data: Array) -> void:
	planets.clear()
	planet_ids_in_order.clear()

	for raw_planet_variant in planets_data:
		if typeof(raw_planet_variant) != TYPE_DICTIONARY:
			continue

		var raw_planet: Dictionary = raw_planet_variant
		var level := maxi(1, int(raw_planet.get("level", 1)))
		var planet := PlanetState.from_content(raw_planet, _calculate_planet_xp_requirement(level))
		if planet.id.is_empty():
			continue

		planets[planet.id] = planet
		planet_ids_in_order.append(planet.id)

	_ensure_planet_meta_defaults()
	if current_planet_id.is_empty() and not planet_ids_in_order.is_empty():
		current_planet_id = planet_ids_in_order[0]

func _load_planet_menu_config(planet_menu_content: Dictionary) -> void:
	_planet_menu_root = {}
	_planet_menu_stages.clear()
	_planet_menu_stage_by_index.clear()
	_planet_menu_planets.clear()
	_planet_menu_moons.clear()

	if typeof(planet_menu_content.get("root", {})) == TYPE_DICTIONARY:
		_planet_menu_root = planet_menu_content.get("root", {}).duplicate(true)

	for stage_variant in planet_menu_content.get("stages", []):
		if typeof(stage_variant) != TYPE_DICTIONARY:
			continue
		var stage_entry: Dictionary = stage_variant.duplicate(true)
		var stage_index := int(stage_entry.get("stage_index", _planet_menu_stages.size() + 1))
		stage_entry["stage_index"] = stage_index
		_planet_menu_stages.append(stage_entry)
		_planet_menu_stage_by_index[stage_index] = stage_entry

	var raw_planets: Dictionary = planet_menu_content.get("planets", {})
	for planet_id_variant in raw_planets.keys():
		var planet_id := str(planet_id_variant)
		if typeof(raw_planets[planet_id_variant]) != TYPE_DICTIONARY:
			continue
		var planet_entry: Dictionary = raw_planets[planet_id_variant].duplicate(true)
		planet_entry["id"] = planet_id
		_planet_menu_planets[planet_id] = planet_entry

	var raw_moons: Dictionary = planet_menu_content.get("moons", {})
	for moon_id_variant in raw_moons.keys():
		var moon_id := str(moon_id_variant)
		if typeof(raw_moons[moon_id_variant]) != TYPE_DICTIONARY:
			continue
		var moon_entry: Dictionary = raw_moons[moon_id_variant].duplicate(true)
		moon_entry["id"] = moon_id
		_planet_menu_moons[moon_id] = moon_entry

func refresh_progression_state() -> void:
	_ensure_planet_meta_defaults()
	if next_milestone_id.is_empty() or completed_milestones.has(next_milestone_id):
		next_milestone_id = _get_next_pending_milestone_id()
	if has_unlocked_era(1):
		planet_owned_flags[DEFAULT_PLANET_ID] = true
	_apply_planet_unlock_states()
	_sync_legacy_prestige_count_from_nodes()

	var highest_unlocked_id := ""
	for element_id in element_ids_in_order:
		var element := get_element_state(element_id)
		if element != null and element.unlocked:
			highest_unlocked_id = element_id

	if has_unlocked_era(1):
		var starting_planet := get_planet_state(DEFAULT_PLANET_ID)
		if starting_planet != null:
			starting_planet.unlocked = true
			starting_planet.level = maxi(1, starting_planet.level)
			starting_planet.xp_to_next_level = _calculate_planet_xp_requirement(starting_planet.level)
			_update_best_planet_level(starting_planet.id, starting_planet.level)

	for planet_id in planet_ids_in_order:
		var planet := get_planet_state(planet_id)
		if planet == null or not planet.unlocked:
			continue
		_update_best_planet_level(planet_id, planet.level)

	max_unlocked_element_id = highest_unlocked_id
	next_unlock_id = ""

	var found_highest := highest_unlocked_id.is_empty()
	for element_id in element_ids_in_order:
		if not found_highest:
			if element_id == highest_unlocked_id:
				found_highest = true
			continue

		var element := get_element_state(element_id)
		if element != null and not element.unlocked:
			next_unlock_id = element_id
			break

	if current_element_id.is_empty() or not is_element_unlocked(current_element_id):
		if not highest_unlocked_id.is_empty():
			current_element_id = highest_unlocked_id
		elif not element_ids_in_order.is_empty():
			current_element_id = element_ids_in_order[0]

	if current_planet_id.is_empty() or not is_planet_unlocked(current_planet_id):
		for planet_id in planet_ids_in_order:
			if is_planet_unlocked(planet_id):
				current_planet_id = planet_id
				break
		if current_planet_id.is_empty() and not planet_ids_in_order.is_empty():
			current_planet_id = planet_ids_in_order[0]

	if is_element_unlocked(BLESSINGS_MENU_UNLOCK_ELEMENT_ID):
		blessings_menu_unlocked = true

func _ensure_planet_meta_defaults() -> void:
	for planet_id in planet_ids_in_order:
		if not planet_purchase_unlocks.has(planet_id):
			planet_purchase_unlocks[planet_id] = false
		if not planet_owned_flags.has(planet_id):
			planet_owned_flags[planet_id] = false

	planet_purchase_unlocks[DEFAULT_PLANET_ID] = true
	if not planet_owned_flags.has(DEFAULT_PLANET_ID):
		planet_owned_flags[DEFAULT_PLANET_ID] = false

func _apply_planet_unlock_states() -> void:
	for planet_id in planet_ids_in_order:
		var planet := get_planet_state(planet_id)
		if planet == null:
			continue
		planet.unlocked = bool(planet_owned_flags.get(planet_id, false))
		if planet.unlocked:
			planet.level = maxi(1, planet.level)
			planet.xp_to_next_level = _calculate_planet_xp_requirement(planet.level)

func _get_first_milestone_id() -> String:
	return "" if PRESTIGE_MILESTONES.is_empty() else str(PRESTIGE_MILESTONES[0].get("id", ""))

func _get_next_pending_milestone_id() -> String:
	for milestone in PRESTIGE_MILESTONES:
		var milestone_id := str(milestone.get("id", ""))
		if milestone_id.is_empty() or completed_milestones.has(milestone_id):
			continue
		return milestone_id
	return ""

func _sync_legacy_prestige_count_from_nodes() -> void:
	prestige_count = maxi(0, get_visible_element_section_count() - 1)

func _update_best_planet_level(planet_id: String, level: int) -> void:
	if planet_id.is_empty():
		return
	var best_level := maxi(level, int(best_planet_levels_this_run.get(planet_id, 0)))
	best_planet_levels_this_run[planet_id] = best_level

func has_element(element_id: String) -> bool:
	return elements.has(element_id)

func get_element_state(element_id: String) -> ElementState:
	if not has_element(element_id):
		return null
	return elements[element_id]

func is_element_unlocked(element_id: String) -> bool:
	var element := get_element_state(element_id)
	return element != null and element.unlocked

func is_element_id(resource_id: String) -> bool:
	return elements.has(resource_id)

func get_element_state_by_index(index: int) -> ElementState:
	if not _element_ids_by_index.has(index):
		return null
	return get_element_state(str(_element_ids_by_index[index]))

func get_current_element_state() -> ElementState:
	return get_element_state(current_element_id)

func get_next_unlock_element_state() -> ElementState:
	if next_unlock_id.is_empty():
		return null
	return get_element_state(next_unlock_id)

func get_visible_element_section_count() -> int:
	var visible_sections := 1
	for node_definition in PRESTIGE_NODES:
		var node_id := str(node_definition.get("id", ""))
		if node_id.is_empty() or not prestige_nodes_claimed.has(node_id):
			continue
		if str(node_definition.get("effect_type", "")) != "unlock_section":
			continue
		visible_sections += int(node_definition.get("effect_value", 0))
	return clampi(visible_sections, 1, UNLOCK_SECTION_ENDS.size())

func get_max_unlockable_element_index() -> int:
	var section_index := clampi(get_visible_element_section_count() - 1, 0, UNLOCK_SECTION_ENDS.size() - 1)
	return int(UNLOCK_SECTION_ENDS[section_index])

func get_max_prestige_count() -> int:
	return maxi(0, UNLOCK_SECTION_ENDS.size() - 1)

func set_prestige_count(value: int) -> bool:
	var clamped_value := clampi(value, 0, get_max_prestige_count())
	if prestige_count == clamped_value:
		return false

	prestige_count = clamped_value
	return true

func adjust_prestige_count(delta: int) -> bool:
	if delta == 0:
		return false
	return set_prestige_count(prestige_count + delta)

func get_milestone_by_id(milestone_id: String) -> Dictionary:
	for milestone in PRESTIGE_MILESTONES:
		if str(milestone.get("id", "")) == milestone_id:
			return milestone.duplicate(true)
	return {}

func get_next_prestige_milestone() -> Dictionary:
	if next_milestone_id.is_empty():
		return {}
	return get_milestone_by_id(next_milestone_id)

func get_prestige_milestone_entries() -> Array[Dictionary]:
	var milestone_entries: Array[Dictionary] = []
	for milestone in PRESTIGE_MILESTONES:
		var entry: Dictionary = milestone.duplicate(true)
		var milestone_id := str(entry.get("id", ""))
		entry["completed"] = completed_milestones.has(milestone_id)
		entry["current"] = next_milestone_id == milestone_id
		entry["available"] = next_milestone_id == milestone_id and can_prestige()
		entry["progress_text"] = _get_milestone_progress_text(entry)
		milestone_entries.append(entry)
	return milestone_entries

func get_next_prestige_node_definition() -> Dictionary:
	for node_definition in PRESTIGE_NODES:
		var node_id := str(node_definition.get("id", ""))
		if node_id.is_empty() or prestige_nodes_claimed.has(node_id):
			continue
		return node_definition.duplicate(true)
	return {}

func get_prestige_node_entries() -> Array[Dictionary]:
	var next_node := get_next_prestige_node_definition()
	var next_node_id := str(next_node.get("id", ""))
	var node_entries: Array[Dictionary] = []
	for node_definition in PRESTIGE_NODES:
		var entry: Dictionary = node_definition.duplicate(true)
		var node_id := str(entry.get("id", ""))
		entry["claimed"] = prestige_nodes_claimed.has(node_id)
		entry["current"] = node_id == next_node_id and not entry["claimed"]
		entry["can_claim"] = node_id == next_node_id and can_claim_next_prestige_node()
		node_entries.append(entry)
	return node_entries

func get_prestige_dust_multiplier() -> float:
	var dust_multiplier := 1.0
	for node_definition in PRESTIGE_NODES:
		var node_id := str(node_definition.get("id", ""))
		if node_id.is_empty() or not prestige_nodes_claimed.has(node_id):
			continue
		if str(node_definition.get("effect_type", "")) != "dust_multiplier":
			continue
		dust_multiplier += float(node_definition.get("effect_value", 0.0))
	return dust_multiplier

func can_prestige() -> bool:
	var milestone := get_next_prestige_milestone()
	if milestone.is_empty():
		return false
	if bool(milestone.get("placeholder", false)):
		return false

	match str(milestone.get("kind", "")):
		"planet_level":
			var planet_id := str(milestone.get("planet_id", ""))
			var required_level := int(milestone.get("required_level", 0))
			return int(best_planet_levels_this_run.get(planet_id, 0)) >= required_level
		_:
			return false

func can_claim_next_prestige_node() -> bool:
	if prestige_points_unspent <= 0:
		return false
	var next_node := get_next_prestige_node_definition()
	if next_node.is_empty():
		return false
	return not bool(next_node.get("future_locked", false))

func get_prestige_preview() -> Dictionary:
	var milestone := get_next_prestige_milestone()
	var next_node := get_next_prestige_node_definition()
	return {
		"can_prestige": can_prestige(),
		"milestone": milestone,
		"reward_points": int(milestone.get("reward_points", 0)),
		"next_node": next_node,
		"can_claim_node": can_claim_next_prestige_node(),
		"reset_summary": [
			"Resets atomic resources, upgrades, dust, RP, and temporary planet progress.",
			"Keeps blessings, orbs, Planetary Era, prestige progress, and owned planets."
		]
	}

func perform_prestige() -> bool:
	if not can_prestige():
		return false

	var milestone := get_next_prestige_milestone()
	var milestone_id := str(milestone.get("id", ""))
	if milestone_id.is_empty():
		return false
	if not completed_milestones.has(milestone_id):
		completed_milestones.append(milestone_id)

	var reward_points := maxi(0, int(milestone.get("reward_points", 0)))
	prestige_points_total += reward_points
	prestige_points_unspent += reward_points

	var unlocked_planet_id := str(milestone.get("unlock_planet_id", ""))
	if not unlocked_planet_id.is_empty():
		planet_purchase_unlocks[unlocked_planet_id] = true

	next_milestone_id = _get_next_pending_milestone_id()
	_reset_run_state()
	refresh_progression_state()
	return true

func claim_next_prestige_node() -> bool:
	if not can_claim_next_prestige_node():
		return false

	var next_node := get_next_prestige_node_definition()
	var node_id := str(next_node.get("id", ""))
	if node_id.is_empty():
		return false

	prestige_nodes_claimed.append(node_id)
	prestige_points_unspent = maxi(0, prestige_points_unspent - 1)
	refresh_progression_state()
	return true

func _get_milestone_progress_text(milestone: Dictionary) -> String:
	if milestone.is_empty():
		return ""
	if bool(milestone.get("completed", false)):
		return "Completed"
	if bool(milestone.get("placeholder", false)):
		return "Future content"

	match str(milestone.get("kind", "")):
		"planet_level":
			var planet_id := str(milestone.get("planet_id", ""))
			var planet_name := str(milestone.get("planet_name", planet_id))
			var required_level := int(milestone.get("required_level", 0))
			var current_level := int(best_planet_levels_this_run.get(planet_id, 0))
			return "%s %d / %d" % [planet_name, current_level, required_level]
		_:
			return "Unavailable"

func is_next_unlock_within_visible_sections() -> bool:
	var next_element := get_next_unlock_element_state()
	if next_element == null:
		return false
	return next_element.index <= get_max_unlockable_element_index()

func get_unlocked_element_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	for element_id in element_ids_in_order:
		if is_element_unlocked(element_id):
			unlocked_ids.append(element_id)
	return unlocked_ids

func get_unlocked_real_element_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	for element_id in element_ids_in_order:
		var element := get_element_state(element_id)
		if element == null or not element.unlocked or element.index <= 0:
			continue
		unlocked_ids.append(element_id)
	return unlocked_ids

func get_visible_counter_element_ids() -> Array[String]:
	var visible_ids: Array[String] = []
	for element_id in element_ids_in_order:
		var element := get_element_state(element_id)
		if element != null and element.show_in_counter:
			visible_ids.append(element_id)
	return visible_ids

func has_planet(planet_id: String) -> bool:
	return planets.has(planet_id)

func get_planet_state(planet_id: String) -> PlanetState:
	if not has_planet(planet_id):
		return null
	return planets[planet_id]

func get_planet_ids() -> Array[String]:
	return planet_ids_in_order.duplicate()

func get_current_planet_state() -> PlanetState:
	return get_planet_state(current_planet_id)

func is_planet_unlocked(planet_id: String) -> bool:
	var planet := get_planet_state(planet_id)
	return planet != null and planet.unlocked

func is_planet_owned(planet_id: String) -> bool:
	return bool(planet_owned_flags.get(planet_id, false))

func is_planet_purchase_unlocked(planet_id: String) -> bool:
	if planet_id == DEFAULT_PLANET_ID:
		return has_unlocked_era(1)
	return bool(planet_purchase_unlocks.get(planet_id, false))

func get_planet_purchase_cost_entries(planet_id: String) -> Array[Dictionary]:
	var planet := get_planet_state(planet_id)
	if planet == null:
		return []

	var cost_entries: Array[Dictionary] = []
	if not planet.purchase_cost_dust.is_zero():
		cost_entries.append({
			"resource_id": DUST_RESOURCE_ID,
			"resource_name": "Dust",
			"is_orb_requirement": false,
			"required_amount": planet.purchase_cost_dust.clone()
		})
	if planet.purchase_cost_orbs > 0:
		cost_entries.append({
			"resource_id": "orbs",
			"resource_name": "Orbs",
			"is_orb_requirement": true,
			"required_amount": planet.purchase_cost_orbs
		})
	return cost_entries

func can_purchase_planet(planet_id: String) -> bool:
	var planet := get_planet_state(planet_id)
	if planet == null:
		return false
	if is_planet_owned(planet_id):
		return false
	if not is_planet_purchase_unlocked(planet_id):
		return false

	for cost_entry in get_planet_purchase_cost_entries(planet_id):
		if bool(cost_entry.get("is_orb_requirement", false)):
			if orbs < int(cost_entry.get("required_amount", 0)):
				return false
			continue

		var resource_id := str(cost_entry.get("resource_id", ""))
		var required_amount: DigitMaster = cost_entry["required_amount"]
		if not can_afford_resource(resource_id, required_amount):
			return false
	return true

func purchase_planet(planet_id: String) -> bool:
	if not can_purchase_planet(planet_id):
		return false

	for cost_entry in get_planet_purchase_cost_entries(planet_id):
		if bool(cost_entry.get("is_orb_requirement", false)):
			orbs -= int(cost_entry.get("required_amount", 0))
			continue

		var resource_id := str(cost_entry.get("resource_id", ""))
		var required_amount: DigitMaster = cost_entry["required_amount"]
		if not spend_resource(resource_id, required_amount):
			return false

	planet_owned_flags[planet_id] = true
	refresh_progression_state()
	return true

func select_planet(planet_id: String) -> bool:
	if not is_planet_unlocked(planet_id):
		return false
	current_planet_id = planet_id
	return true

func get_planet_entries() -> Array[Dictionary]:
	var planet_entries: Array[Dictionary] = []
	for planet_id in planet_ids_in_order:
		var planet := get_planet_state(planet_id)
		if planet == null:
			continue
		planet_entries.append({
			"id": planet.id,
			"name": planet.name,
			"owned": is_planet_owned(planet_id),
			"unlocked": is_planet_unlocked(planet_id),
			"purchase_unlocked": is_planet_purchase_unlocked(planet_id),
			"can_purchase": can_purchase_planet(planet_id),
			"selected": current_planet_id == planet_id,
			"level": planet.level,
			"purchase_costs": get_planet_purchase_cost_entries(planet_id)
		})
	return planet_entries

func get_planet_menu_stage() -> int:
	var highest_completed_planet_rank := 0
	for milestone_id in completed_milestones:
		highest_completed_planet_rank = maxi(highest_completed_planet_rank, _get_planet_menu_progress_rank(milestone_id))
	var stage_index := clampi(highest_completed_planet_rank + 1, 1, maxi(1, _planet_menu_stages.size()))
	return stage_index

func get_planet_menu_view_model() -> Dictionary:
	var stage_index := get_planet_menu_stage()
	var stage_entry := _get_planet_menu_stage_entry(stage_index)
	var node_positions: Dictionary = stage_entry.get("node_positions", {})
	var visible_planets: Array[String] = []
	for planet_id_variant in stage_entry.get("visible_planets", []):
		visible_planets.append(str(planet_id_variant))
	var visible_moons: Array[String] = []
	for moon_id_variant in stage_entry.get("visible_moons", []):
		visible_moons.append(str(moon_id_variant))

	var planet_entries: Array[Dictionary] = []
	for planet_id in visible_planets:
		var planet_entry := get_planet_menu_planet_entry(planet_id)
		if node_positions.has(planet_id):
			planet_entry["position"] = (node_positions[planet_id] as Dictionary).duplicate(true)
		planet_entries.append(planet_entry)

	var moon_entries: Array[Dictionary] = []
	for moon_id in visible_moons:
		var moon_entry := get_planet_menu_moon_entry(moon_id)
		if node_positions.has(moon_id):
			moon_entry["position"] = (node_positions[moon_id] as Dictionary).duplicate(true)
		moon_entries.append(moon_entry)

	var line_entries: Array[Dictionary] = []
	for line_variant in stage_entry.get("lines", []):
		if typeof(line_variant) != TYPE_DICTIONARY:
			continue
		var line_entry: Dictionary = line_variant.duplicate(true)
		var from_id := str(line_entry.get("from_id", ""))
		var to_id := str(line_entry.get("to_id", ""))
		if node_positions.has(from_id):
			line_entry["from_position"] = (node_positions[from_id] as Dictionary).duplicate(true)
		if node_positions.has(to_id):
			line_entry["to_position"] = (node_positions[to_id] as Dictionary).duplicate(true)
		line_entries.append(line_entry)

	return {
		"stage_id": str(stage_entry.get("id", "")),
		"stage_index": stage_index,
		"root": _planet_menu_root.duplicate(true),
		"root_position": (node_positions.get("root", {}) as Dictionary).duplicate(true),
		"planets": planet_entries,
		"moons": moon_entries,
		"lines": line_entries
	}

func get_planet_menu_planet_entry(planet_id: String) -> Dictionary:
	var config_entry: Dictionary = _planet_menu_planets.get(planet_id, {})
	var runtime_planet := get_planet_state(planet_id)
	var owned := is_planet_owned(planet_id) if runtime_planet != null else false
	var visible := _is_planet_visible_in_stage(planet_id, get_planet_menu_stage())
	var purchase_unlocked := is_planet_purchase_unlocked(planet_id) if runtime_planet != null else false
	var can_purchase := can_purchase_planet(planet_id) if runtime_planet != null else false
	var is_placeholder := runtime_planet == null
	return {
		"id": planet_id,
		"label": str(config_entry.get("label", planet_id)),
		"tier": int(config_entry.get("tier", 1)),
		"panel_accent_color": str(config_entry.get("panel_accent_color", "#4A7F78")),
		"preview_title": str(config_entry.get("preview_title", config_entry.get("label", planet_id))),
		"preview_subtitle": str(config_entry.get("preview_subtitle", "")),
		"moon_ids": Array(config_entry.get("moon_ids", [])).duplicate(),
		"visible": visible,
		"owned": owned,
		"purchase_unlocked": purchase_unlocked,
		"can_purchase": can_purchase,
		"is_placeholder": is_placeholder,
		"is_current_active_planet": current_planet_id == planet_id,
		"level": runtime_planet.level if runtime_planet != null else 0,
		"max_level": runtime_planet.max_level if runtime_planet != null else 0,
		"workers": runtime_planet.workers.clone() if runtime_planet != null else DigitMaster.zero(),
		"research_points": get_research_points(),
		"purchase_costs": get_planet_purchase_cost_entries(planet_id) if runtime_planet != null else [],
		"action_label": _get_planet_menu_action_label(planet_id),
		"action_enabled": can_purchase
	}

func get_planet_menu_moon_entry(moon_id: String) -> Dictionary:
	var config_entry: Dictionary = _planet_menu_moons.get(moon_id, {})
	var parent_planet_id := str(config_entry.get("parent_planet_id", ""))
	return {
		"id": moon_id,
		"label": str(config_entry.get("label", moon_id)),
		"color": str(config_entry.get("color", "#4A7F78")),
		"parent_planet_id": parent_planet_id,
		"parent_owned": is_planet_owned(parent_planet_id),
		"visible": _is_moon_visible_in_stage(moon_id, get_planet_menu_stage())
	}

func get_moon_upgrade_entries(moon_id: String) -> Array[Dictionary]:
	var moon_entry: Dictionary = _planet_menu_moons.get(moon_id, {})
	if moon_entry.is_empty():
		return []

	var parent_planet_id := str(moon_entry.get("parent_planet_id", ""))
	var parent_owned := is_planet_owned(parent_planet_id)
	var purchased_ids := _get_purchased_moon_upgrade_ids(moon_id)
	var upgrade_entries: Array[Dictionary] = []
	for upgrade_variant in moon_entry.get("upgrades", []):
		if typeof(upgrade_variant) != TYPE_DICTIONARY:
			continue
		var upgrade_entry: Dictionary = upgrade_variant.duplicate(true)
		var upgrade_id := str(upgrade_entry.get("id", ""))
		var rp_cost := DigitMaster.from_variant(upgrade_entry.get("rp_cost", 0))
		var purchased := purchased_ids.has(upgrade_id)
		var can_purchase := parent_owned and not purchased and research_points.compare(rp_cost) >= 0
		upgrade_entry["rp_cost"] = rp_cost
		upgrade_entry["moon_id"] = moon_id
		upgrade_entry["parent_planet_id"] = parent_planet_id
		upgrade_entry["locked"] = not parent_owned
		upgrade_entry["purchased"] = purchased
		upgrade_entry["can_purchase"] = can_purchase
		upgrade_entries.append(upgrade_entry)
	return upgrade_entries

func can_purchase_moon_upgrade(moon_id: String, upgrade_id: String) -> bool:
	if upgrade_id.is_empty():
		return false
	for upgrade_entry in get_moon_upgrade_entries(moon_id):
		if str(upgrade_entry.get("id", "")) != upgrade_id:
			continue
		return bool(upgrade_entry.get("can_purchase", false))
	return false

func purchase_moon_upgrade(moon_id: String, upgrade_id: String) -> bool:
	if not can_purchase_moon_upgrade(moon_id, upgrade_id):
		return false

	for upgrade_entry in get_moon_upgrade_entries(moon_id):
		if str(upgrade_entry.get("id", "")) != upgrade_id:
			continue
		var cost: DigitMaster = upgrade_entry["rp_cost"]
		research_points = research_points.subtract(cost)
		var purchased_ids := _get_purchased_moon_upgrade_ids(moon_id)
		purchased_ids.append(upgrade_id)
		moon_upgrade_purchases[moon_id] = purchased_ids
		return true
	return false

func has_adjacent_owned_planet(direction: int) -> bool:
	return not _find_adjacent_owned_planet_id(direction).is_empty()

func select_adjacent_owned_planet(direction: int) -> bool:
	var target_planet_id := _find_adjacent_owned_planet_id(direction)
	if target_planet_id.is_empty():
		return false
	current_planet_id = target_planet_id
	return true

func _get_planet_menu_action_label(planet_id: String) -> String:
	if is_planet_owned(planet_id):
		return "Unlocked"
	if can_purchase_planet(planet_id):
		return "Unlock"
	return "Locked"

func _get_planet_menu_stage_entry(stage_index: int) -> Dictionary:
	if _planet_menu_stage_by_index.has(stage_index):
		return (_planet_menu_stage_by_index[stage_index] as Dictionary).duplicate(true)
	return {}

func _is_planet_visible_in_stage(planet_id: String, stage_index: int) -> bool:
	var stage_entry := _get_planet_menu_stage_entry(stage_index)
	for stage_planet_id_variant in stage_entry.get("visible_planets", []):
		if str(stage_planet_id_variant) == planet_id:
			return true
	return false

func _is_moon_visible_in_stage(moon_id: String, stage_index: int) -> bool:
	var stage_entry := _get_planet_menu_stage_entry(stage_index)
	for stage_moon_id_variant in stage_entry.get("visible_moons", []):
		if str(stage_moon_id_variant) == moon_id:
			return true
	return false

func _get_planet_menu_progress_rank(milestone_id: String) -> int:
	match milestone_id:
		"planet_a_5":
			return 1
		"planet_b_5":
			return 2
		"planet_c_5":
			return 3
		"planet_d_5":
			return 4
		_:
			return 0

func _get_purchased_moon_upgrade_ids(moon_id: String) -> Array[String]:
	var purchased_ids: Array[String] = []
	for upgrade_id_variant in moon_upgrade_purchases.get(moon_id, []):
		purchased_ids.append(str(upgrade_id_variant))
	return purchased_ids

func _find_adjacent_owned_planet_id(direction: int) -> String:
	if direction == 0:
		return ""

	var owned_planet_ids: Array[String] = []
	for planet_id in planet_ids_in_order:
		if is_planet_owned(planet_id):
			owned_planet_ids.append(planet_id)
	if owned_planet_ids.is_empty():
		return ""

	var current_index := owned_planet_ids.find(current_planet_id)
	if current_index < 0:
		return ""

	var target_index := current_index + direction
	if target_index < 0 or target_index >= owned_planet_ids.size():
		return ""
	return owned_planet_ids[target_index]

func get_current_planet_workers() -> DigitMaster:
	var planet := get_current_planet_state()
	if planet == null:
		return DigitMaster.zero()
	return planet.workers.clone()

func get_current_planet_worker_cost() -> DigitMaster:
	var planet := get_current_planet_state()
	if planet == null:
		return DigitMaster.zero()

	var worker_count: float = _digit_master_to_float(planet.workers)
	var raw_cost: float = PLANET_WORKER_BASE_COST * pow(PLANET_WORKER_COST_RATIO, worker_count)
	var rounded_cost: float = ceil(raw_cost / PLANET_WORKER_COST_ROUND_TO) * PLANET_WORKER_COST_ROUND_TO
	return DigitMaster.new(rounded_cost)

func can_buy_current_planet_worker() -> bool:
	var planet := get_current_planet_state()
	if planet == null or not planet.unlocked:
		return false
	return can_afford_resource(DUST_RESOURCE_ID, get_current_planet_worker_cost())

func buy_current_planet_worker() -> bool:
	if not can_buy_current_planet_worker():
		return false
	if not spend_resource(DUST_RESOURCE_ID, get_current_planet_worker_cost()):
		return false

	var planet := get_current_planet_state()
	if planet == null:
		return false
	planet.workers = planet.workers.add(DigitMaster.one())
	return true

func set_current_planet_worker_allocation_to_xp(allocation_ratio: float) -> void:
	var planet := get_current_planet_state()
	if planet == null:
		return
	planet.worker_allocation_to_xp = clampf(allocation_ratio, 0.0, 1.0)

func get_current_planet_worker_allocation_to_xp() -> float:
	var planet := get_current_planet_state()
	if planet == null:
		return 1.0
	return clampf(planet.worker_allocation_to_xp, 0.0, 1.0)

func process_planet_production(delta_seconds: float) -> void:
	if delta_seconds <= 0.0:
		return

	for planet_id in planet_ids_in_order:
		var planet := get_planet_state(planet_id)
		if planet == null or not planet.unlocked or planet.workers.is_zero():
			continue

		var total_production := planet.workers.multiply_scalar(delta_seconds)
		var allocation_to_xp := clampf(planet.worker_allocation_to_xp, 0.0, 1.0)
		if allocation_to_xp > 0.0:
			_apply_planet_xp(planet, total_production.multiply_scalar(allocation_to_xp))
		if allocation_to_xp < 1.0:
			_apply_research_progress(total_production.multiply_scalar((1.0 - allocation_to_xp) * RESEARCH_POINTS_PER_PRODUCTION))

func get_current_planet_level_progress_ratio() -> float:
	var planet := get_current_planet_state()
	if planet == null:
		return 0.0
	return _get_digit_ratio(planet.xp, planet.xp_to_next_level)

func get_research_progress_ratio() -> float:
	return clampf(research_progress, 0.0, 1.0)

func get_current_planet_xp() -> DigitMaster:
	var planet := get_current_planet_state()
	if planet == null:
		return DigitMaster.zero()
	return planet.xp.clone()

func get_current_planet_xp_to_next_level() -> DigitMaster:
	var planet := get_current_planet_state()
	if planet == null:
		return DigitMaster.one()
	return planet.xp_to_next_level.clone()

func get_research_points() -> DigitMaster:
	return research_points.clone()

func get_research_progress_display() -> String:
	return "%.1f%%" % (get_research_progress_ratio() * 100.0)

func get_upgrade_state(upgrade_id: String) -> UpgradeState:
	if not upgrades.has(upgrade_id):
		return null
	return upgrades[upgrade_id]

func get_upgrade_ids() -> Array[String]:
	return upgrade_ids_in_order.duplicate()

func has_blessing(blessing_id: String) -> bool:
	return blessings.has(blessing_id)

func get_blessing_state(blessing_id: String):
	if not has_blessing(blessing_id):
		return null
	return blessings[blessing_id]

func get_blessing_ids() -> Array[String]:
	var blessing_ids: Array[String] = []
	for blessing_id in blessing_ids_in_order:
		blessing_ids.append(blessing_id)
	return blessing_ids

func get_blessing_ids_for_rarity(rarity: String) -> Array[String]:
	if not blessing_ids_by_rarity.has(rarity):
		return []
	var blessing_ids: Array[String] = []
	for blessing_id in blessing_ids_by_rarity[rarity]:
		blessing_ids.append(str(blessing_id))
	return blessing_ids

func get_blessing_rarity_order() -> Array[String]:
	var rarity_order: Array[String] = []
	for rarity in BLESSING_RARITY_ORDER:
		rarity_order.append(rarity)
	return rarity_order

func get_blessing_rarity_roll_display(rarity: String) -> String:
	return str(blessing_rarity_roll_displays.get(rarity, ""))

func get_blessing_rarity_color(rarity: String) -> Color:
	var color_hex := str(blessing_rarity_colors.get(rarity, "ffffff"))
	return Color.from_string("#%s" % color_hex, Color.WHITE)

func get_discovered_blessing_count() -> int:
	var discovered := 0
	for blessing_id in blessing_ids_in_order:
		var blessing = get_blessing_state(blessing_id)
		if blessing != null and blessing.level > 0:
			discovered += 1
	return discovered

func get_unopened_blessings_count() -> int:
	return maxi(0, unopened_blessings_count)

func can_open_blessings() -> bool:
	return get_unopened_blessings_count() > 0

func get_resource_name(resource_id: String) -> String:
	if resource_id.to_lower() == DUST_RESOURCE_ID:
		return "Dust"
	var element := get_element_state(resource_id)
	if element != null:
		return element.name
	return resource_id

func get_resource_amount(resource_id: String) -> DigitMaster:
	if resource_id.to_lower() == DUST_RESOURCE_ID:
		return dust.clone()
	var element := get_element_state(resource_id)
	if element == null:
		return DigitMaster.zero()
	return element.amount.clone()

func can_afford_resource(resource_id: String, cost: DigitMaster) -> bool:
	return get_resource_amount(resource_id).compare(cost) >= 0

func add_resource(resource_id: String, amount: DigitMaster) -> void:
	if resource_id.to_lower() == DUST_RESOURCE_ID:
		dust = dust.add(amount)
		return
	var element := get_element_state(resource_id)
	if element == null:
		return
	element.amount = element.amount.add(amount)

func spend_resource(resource_id: String, amount: DigitMaster) -> bool:
	if not can_afford_resource(resource_id, amount):
		return false

	if resource_id.to_lower() == DUST_RESOURCE_ID:
		dust = dust.subtract(amount)
		return true

	var element := get_element_state(resource_id)
	if element == null:
		return false
	element.amount = element.amount.subtract(amount)
	return true

func produce_resource(resource_id: String, amount: DigitMaster) -> void:
	if resource_id.is_empty():
		return

	var normalized_id := resource_id.to_lower()
	if normalized_id == DUST_RESOURCE_ID:
		dust = dust.add(amount.multiply_scalar(get_prestige_dust_multiplier()))
		return

	var element := get_element_state(resource_id)
	if element == null:
		return

	element.amount = element.amount.add(amount)
	element.show_in_counter = true
	_apply_blessing_progress_for_generated_element(element, amount)

func is_blessings_menu_unlocked() -> bool:
	return blessings_menu_unlocked

func get_blessing_critical_smasher_bonus_percent() -> float:
	return _get_blessing_effect_total(BlessingStateScript.EFFECT_CRITICAL_SMASHER_CHANCE)

func get_blessing_fission_bonus_percent() -> float:
	return _get_blessing_effect_total(BlessingStateScript.EFFECT_FISSION_CHANCE)

func get_foil_spawn_chance_percent() -> float:
	return _get_blessing_effect_total(BlessingStateScript.EFFECT_FOIL_SPAWN_CHANCE)

func get_holographic_spawn_chance_percent() -> float:
	return _get_blessing_effect_total(BlessingStateScript.EFFECT_HOLOGRAPHIC_SPAWN_CHANCE)

func get_polychrome_spawn_chance_percent() -> float:
	return _get_blessing_effect_total(BlessingStateScript.EFFECT_POLYCHROME_SPAWN_CHANCE)

func open_earned_blessings() -> int:
	var blessings_to_open := get_unopened_blessings_count()
	if blessings_to_open <= 0:
		return 0

	for _i in range(blessings_to_open):
		_award_random_blessing()
	unopened_blessings_count = 0
	_invalidate_blessing_effect_cache()
	return blessings_to_open

func reset_blessings() -> bool:
	var changed := get_unopened_blessings_count() > 0
	unopened_blessings_count = blessings_count
	for blessing_id in blessing_ids_in_order:
		var blessing = get_blessing_state(blessing_id)
		if blessing == null:
			continue
		if blessing.level > 0:
			changed = true
		blessing.level = 0
	if changed:
		_invalidate_blessing_effect_cache()
	return changed

func get_next_blessing_cost() -> DigitMaster:
	var blessing_index := float(maxi(0, blessings_count))
	var cost := (
		BLESSING_COST_QUADRATIC_A * blessing_index * blessing_index
		+ BLESSING_COST_QUADRATIC_B * blessing_index
		+ BLESSING_COST_QUADRATIC_C
	)
	return DigitMaster.new(cost)

func get_blessing_progress_mass() -> DigitMaster:
	return blessings_progress_mass.clone()

func get_remaining_blessing_mass() -> DigitMaster:
	var remaining := get_next_blessing_cost().subtract(blessings_progress_mass)
	return remaining

func has_unlocked_element_count(required_count: int) -> bool:
	if required_count <= 0:
		return true
	return get_unlocked_element_ids().size() >= required_count

func is_era_menu_unlocked() -> bool:
	return is_element_unlocked(ERA_MENU_UNLOCK_ELEMENT_ID) or has_unlocked_era(1)

func get_unlocked_era_index() -> int:
	return clampi(unlocked_era_index, 0, ERA_NAMES.size() - 1)

func has_unlocked_era(era_index: int) -> bool:
	return get_unlocked_era_index() >= era_index

func get_era_name(era_index: int) -> String:
	if era_index < 0 or era_index >= ERA_NAMES.size():
		return ""
	return str(ERA_NAMES[era_index])

func get_next_implemented_era_index() -> int:
	if not is_era_menu_unlocked():
		return -1
	var next_era_index := get_unlocked_era_index() + 1
	if next_era_index > MAX_IMPLEMENTED_ERA_INDEX:
		return -1
	return next_era_index

func get_next_implemented_era_name() -> String:
	var next_era_index := get_next_implemented_era_index()
	if next_era_index < 0:
		return ""
	return get_era_name(next_era_index)

func get_next_era_requirements() -> Array[Dictionary]:
	var next_era_index := get_next_implemented_era_index()
	if next_era_index != 1:
		return []

	var requirements: Array[Dictionary] = []
	for resource_id in PLANETARY_ERA_RESOURCE_IDS:
		requirements.append({
			"resource_id": resource_id,
			"resource_name": get_resource_name(resource_id),
			"required_amount": DigitMaster.new(PLANETARY_ERA_RESOURCE_COST),
			"is_orb_requirement": false
		})

	requirements.append({
		"resource_id": DUST_RESOURCE_ID,
		"resource_name": "Dust",
		"required_amount": DigitMaster.new(PLANETARY_ERA_RESOURCE_COST),
		"is_orb_requirement": false
	})

	requirements.append({
		"resource_id": "orbs",
		"resource_name": "Orbs",
		"required_amount": PLANETARY_ERA_ORB_COST,
		"is_orb_requirement": true
	})

	return requirements

func can_unlock_next_era() -> bool:
	var requirements := get_next_era_requirements()
	if requirements.is_empty():
		return false

	for requirement in requirements:
		if bool(requirement.get("is_orb_requirement", false)):
			if orbs < int(requirement.get("required_amount", 0)):
				return false
			continue

		var resource_id := str(requirement.get("resource_id", ""))
		var required_amount: DigitMaster = requirement["required_amount"]
		if not can_afford_resource(resource_id, required_amount):
			return false
	return true

func unlock_next_era() -> bool:
	if not can_unlock_next_era():
		return false

	var next_era_index := get_next_implemented_era_index()
	if next_era_index < 0:
		return false

	for requirement in get_next_era_requirements():
		if bool(requirement.get("is_orb_requirement", false)):
			orbs -= int(requirement.get("required_amount", 0))
			continue

		var resource_id := str(requirement.get("resource_id", ""))
		var required_amount: DigitMaster = requirement["required_amount"]
		if not spend_resource(resource_id, required_amount):
			return false

	unlocked_era_index = max(unlocked_era_index, next_era_index)
	if next_era_index == 1:
		planet_owned_flags[DEFAULT_PLANET_ID] = true
		var starting_planet := get_planet_state(DEFAULT_PLANET_ID)
		if starting_planet != null:
			starting_planet.unlocked = true
			starting_planet.level = maxi(1, starting_planet.level)
			starting_planet.xp_to_next_level = _calculate_planet_xp_requirement(starting_planet.level)
	refresh_progression_state()
	return true

func select_element(element_id: String) -> bool:
	if not is_element_unlocked(element_id):
		return false
	current_element_id = element_id
	return true

func has_adjacent_unlocked_element(direction: int) -> bool:
	return not _find_adjacent_unlocked_element_id(direction).is_empty()

func has_next_selectable_element_in_visible_sections() -> bool:
	if current_element_id.is_empty():
		return false

	var current_element := get_current_element_state()
	if current_element == null:
		return false

	var max_visible_index := get_max_unlockable_element_index()
	if current_element.index >= max_visible_index:
		return false

	return has_adjacent_unlocked_element(1)

func select_adjacent_unlocked(direction: int) -> bool:
	var target_id := _find_adjacent_unlocked_element_id(direction)
	if target_id.is_empty():
		return false
	current_element_id = target_id
	return true

func _find_adjacent_unlocked_element_id(direction: int) -> String:
	if current_element_id.is_empty() or direction == 0:
		return ""

	var current_element := get_current_element_state()
	if current_element == null:
		return ""

	var cursor := current_element.index + direction
	while true:
		var candidate := get_element_state_by_index(cursor)
		if candidate == null:
			return ""
		if candidate.unlocked:
			return candidate.id
		cursor += direction

	return ""

func can_unlock_next() -> bool:
	var next_element := get_next_unlock_element_state()
	if next_element == null:
		return false
	if not is_next_unlock_within_visible_sections():
		return false
	return can_afford_resource(next_unlock_id, next_element.cost)

func unlock_next_element() -> bool:
	var next_element := get_next_unlock_element_state()
	if next_element == null or not can_unlock_next():
		return false
	if not spend_resource(next_unlock_id, next_element.cost):
		return false

	next_element.unlocked = true
	current_element_id = next_unlock_id
	refresh_progression_state()
	return true

func set_upgrade_level(upgrade_id: String, level: int) -> void:
	var upgrade := get_upgrade_state(upgrade_id)
	if upgrade == null:
		return
	upgrade.current_level = level

func set_upgrade_current_cost(upgrade_id: String, cost: DigitMaster) -> void:
	var upgrade := get_upgrade_state(upgrade_id)
	if upgrade == null:
		return
	upgrade.current_cost = cost.clone()

func set_upgrade_secondary_current_cost(upgrade_id: String, cost: DigitMaster) -> void:
	var upgrade := get_upgrade_state(upgrade_id)
	if upgrade == null:
		return
	upgrade.secondary_current_cost = cost.clone()

func to_save_dict() -> Dictionary:
	var serialized_elements := {}
	for element_id in element_ids_in_order:
		var element := get_element_state(element_id)
		if element == null:
			continue
		serialized_elements[element_id] = element.to_save_dict()

	var serialized_upgrades := {}
	for upgrade_id in upgrade_ids_in_order:
		var upgrade := get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue
		serialized_upgrades[upgrade_id] = upgrade.to_save_dict()

	var serialized_blessings := {}
	for blessing_id in blessing_ids_in_order:
		var blessing = get_blessing_state(blessing_id)
		if blessing == null:
			continue
		serialized_blessings[blessing_id] = blessing.to_save_dict()

	return {
		"save_version": SAVE_VERSION,
		"orbs": orbs,
		"dust": dust.to_save_data(),
		"elements": serialized_elements,
		"upgrades": serialized_upgrades,
		"current_element_id": current_element_id,
		"player_level": player_level,
		"prestige_count": prestige_count,
		"global_multiplier": global_multiplier.to_save_data(),
		"tick_count": tick_count,
		"total_played_seconds": total_played_seconds,
		"last_save_tick": last_save_tick,
		"total_manual_smashes": total_manual_smashes,
		"total_auto_smashes": total_auto_smashes,
		"blessings_count": blessings_count,
		"unopened_blessings_count": unopened_blessings_count,
		"blessings_progress_mass": blessings_progress_mass.to_save_data(),
		"blessings_menu_unlocked": blessings_menu_unlocked,
		"blessings": serialized_blessings,
		"unlocked_era_index": unlocked_era_index,
		"research_points": research_points.to_save_data(),
		"research_progress": research_progress,
		"current_planet_id": current_planet_id,
		"planets": _serialize_planets(),
		"completed_milestones": completed_milestones.duplicate(),
		"next_milestone_id": next_milestone_id,
		"prestige_points_total": prestige_points_total,
		"prestige_points_unspent": prestige_points_unspent,
		"prestige_nodes_claimed": prestige_nodes_claimed.duplicate(),
		"best_planet_levels_this_run": best_planet_levels_this_run.duplicate(true),
		"planet_purchase_unlocks": planet_purchase_unlocks.duplicate(true),
		"planet_owned_flags": planet_owned_flags.duplicate(true),
		"moon_upgrade_purchases": moon_upgrade_purchases.duplicate(true)
	}

func apply_save_dict(save_data: Dictionary) -> void:
	orbs = int(save_data.get("orbs", 0))
	dust = DigitMaster.from_variant(save_data.get("dust", 0))
	player_level = int(save_data.get("player_level", 1))
	prestige_count = clampi(int(save_data.get("prestige_count", save_data.get("world_level", 0))), 0, get_max_prestige_count())
	global_multiplier = DigitMaster.from_variant(save_data.get("global_multiplier", 1))
	tick_count = int(save_data.get("tick_count", 0))
	total_played_seconds = float(save_data.get("total_played_seconds", 0.0))
	last_save_tick = int(save_data.get("last_save_tick", 0))
	total_manual_smashes = int(save_data.get("total_manual_smashes", 0))
	total_auto_smashes = int(save_data.get("total_auto_smashes", 0))
	blessings_count = maxi(0, int(save_data.get("blessings_count", 0)))
	unopened_blessings_count = maxi(0, int(save_data.get("unopened_blessings_count", 0)))
	blessings_progress_mass = DigitMaster.from_variant(save_data.get("blessings_progress_mass", 0))
	blessings_menu_unlocked = bool(save_data.get("blessings_menu_unlocked", false))
	unlocked_era_index = int(save_data.get("unlocked_era_index", unlocked_era_index))
	research_points = DigitMaster.from_variant(save_data.get("research_points", 0))
	research_progress = clampf(float(save_data.get("research_progress", 0.0)), 0.0, 1.0)
	completed_milestones.clear()
	for milestone_id_variant in save_data.get("completed_milestones", []):
		completed_milestones.append(str(milestone_id_variant))
	next_milestone_id = str(save_data.get("next_milestone_id", next_milestone_id))
	prestige_points_total = maxi(0, int(save_data.get("prestige_points_total", 0)))
	prestige_points_unspent = maxi(0, int(save_data.get("prestige_points_unspent", 0)))
	prestige_nodes_claimed.clear()
	for node_id_variant in save_data.get("prestige_nodes_claimed", []):
		prestige_nodes_claimed.append(str(node_id_variant))
	best_planet_levels_this_run.clear()
	var saved_best_levels: Dictionary = save_data.get("best_planet_levels_this_run", {})
	for planet_id_variant in saved_best_levels.keys():
		best_planet_levels_this_run[str(planet_id_variant)] = maxi(0, int(saved_best_levels[planet_id_variant]))
	planet_purchase_unlocks.clear()
	var saved_purchase_unlocks: Dictionary = save_data.get("planet_purchase_unlocks", {})
	for planet_id_variant in saved_purchase_unlocks.keys():
		planet_purchase_unlocks[str(planet_id_variant)] = bool(saved_purchase_unlocks[planet_id_variant])
	planet_owned_flags.clear()
	var saved_owned_flags: Dictionary = save_data.get("planet_owned_flags", {})
	for planet_id_variant in saved_owned_flags.keys():
		planet_owned_flags[str(planet_id_variant)] = bool(saved_owned_flags[planet_id_variant])
	moon_upgrade_purchases.clear()
	var saved_moon_upgrades: Dictionary = save_data.get("moon_upgrade_purchases", {})
	for moon_id_variant in saved_moon_upgrades.keys():
		var moon_id := str(moon_id_variant)
		var saved_upgrade_ids: Array[String] = []
		for upgrade_id_variant in saved_moon_upgrades[moon_id_variant]:
			saved_upgrade_ids.append(str(upgrade_id_variant))
		moon_upgrade_purchases[moon_id] = saved_upgrade_ids
	_ensure_planet_meta_defaults()

	var saved_elements: Dictionary = save_data.get("elements", {})
	for element_id_variant in saved_elements.keys():
		var element_id := str(element_id_variant)
		var element := get_element_state(element_id)
		if element == null:
			continue
		var element_save: Dictionary = saved_elements[element_id]
		element.apply_save_dict(element_save)

	var saved_upgrades: Dictionary = save_data.get("upgrades", {})
	for upgrade_id_variant in saved_upgrades.keys():
		var upgrade_id := str(upgrade_id_variant)
		var upgrade := get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue
		var upgrade_save: Dictionary = saved_upgrades[upgrade_id]
		upgrade.apply_save_dict(upgrade_save)

	var saved_blessings: Dictionary = save_data.get("blessings", {})
	for blessing_id_variant in saved_blessings.keys():
		var blessing_id := str(blessing_id_variant)
		var blessing = get_blessing_state(blessing_id)
		if blessing == null:
			continue
		var blessing_save: Dictionary = saved_blessings[blessing_id]
		blessing.apply_save_dict(blessing_save)
	if not save_data.has("unopened_blessings_count") and blessings_count > 0:
		var opened_blessings := get_discovered_blessing_count()
		unopened_blessings_count = maxi(0, blessings_count - opened_blessings)
	if saved_blessings.is_empty() and blessings_count > 0 and unopened_blessings_count <= 0:
		unopened_blessings_count = blessings_count
	_invalidate_blessing_effect_cache()

	current_element_id = str(save_data.get("current_element_id", current_element_id))
	var saved_planets: Dictionary = save_data.get("planets", {})
	for planet_id_variant in saved_planets.keys():
		var planet_id := str(planet_id_variant)
		var planet := get_planet_state(planet_id)
		if planet == null:
			continue
		var planet_save: Dictionary = saved_planets[planet_id]
		var saved_level := maxi(1, int(planet_save.get("level", planet.level)))
		planet.apply_save_dict(planet_save, _calculate_planet_xp_requirement(saved_level))

	current_planet_id = str(save_data.get("current_planet_id", current_planet_id))
	if next_milestone_id.is_empty():
		next_milestone_id = _get_next_pending_milestone_id()
	refresh_progression_state()

func _reset_run_state() -> void:
	dust = DigitMaster.zero()
	current_element_id = ""
	next_unlock_id = ""
	max_unlocked_element_id = ""
	player_level = 1
	global_multiplier = DigitMaster.one()
	tick_count = 0
	total_played_seconds = 0.0
	last_save_tick = 0
	total_manual_smashes = 0
	total_auto_smashes = 0
	research_points = DigitMaster.zero()
	research_progress = 0.0
	best_planet_levels_this_run.clear()
	moon_upgrade_purchases.clear()
	_reset_elements_to_defaults()
	_reset_upgrades_to_defaults()
	_reset_planets_to_owned_defaults()
	current_planet_id = DEFAULT_PLANET_ID

func _reset_elements_to_defaults() -> void:
	for element_id in element_ids_in_order:
		var element := get_element_state(element_id)
		if element == null:
			continue
		element.reset_to_default()

func _reset_upgrades_to_defaults() -> void:
	for upgrade_id in upgrade_ids_in_order:
		var upgrade := get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue
		upgrade.reset_to_default()

func _reset_planets_to_owned_defaults() -> void:
	_ensure_planet_meta_defaults()
	if has_unlocked_era(1):
		planet_owned_flags[DEFAULT_PLANET_ID] = true

	for planet_id in planet_ids_in_order:
		var planet := get_planet_state(planet_id)
		if planet == null:
			continue
		planet.reset_to_default(_calculate_planet_xp_requirement(planet.default_level))
		planet.unlocked = bool(planet_owned_flags.get(planet_id, false))
		if planet.unlocked:
			planet.level = maxi(1, planet.level)
			planet.xp_to_next_level = _calculate_planet_xp_requirement(planet.level)

func _serialize_planets() -> Dictionary:
	var serialized_planets := {}
	for planet_id in planet_ids_in_order:
		var planet := get_planet_state(planet_id)
		if planet == null:
			continue
		serialized_planets[planet_id] = planet.to_save_dict()
	return serialized_planets

func _calculate_planet_xp_requirement(level: int) -> DigitMaster:
	if level <= 1:
		return DigitMaster.new(PLANET_XP_LEVEL_TWO_REQUIREMENT)

	var growth_steps := float(maxi(1, PLANET_A_MAX_LEVEL - 2))
	var growth_ratio := pow(
		PLANET_XP_LEVEL_TWENTY_FIVE_REQUIREMENT / PLANET_XP_LEVEL_TWO_REQUIREMENT,
		1.0 / growth_steps
	)
	var requirement_float := PLANET_XP_LEVEL_TWO_REQUIREMENT * pow(growth_ratio, float(level - 1))
	return DigitMaster.new(round(requirement_float))

func _apply_planet_xp(planet: PlanetState, xp_amount: DigitMaster) -> void:
	if xp_amount.is_zero():
		return

	var level := planet.level
	_update_best_planet_level(planet.id, level)
	if level >= planet.max_level:
		return

	var current_xp := planet.xp.add(xp_amount)
	var xp_to_next := planet.xp_to_next_level
	while level < planet.max_level and current_xp.compare(xp_to_next) >= 0:
		current_xp = current_xp.subtract(xp_to_next)
		level += 1
		planet.level = level
		if level >= planet.max_level:
			current_xp = DigitMaster.zero()
			break
		xp_to_next = _calculate_planet_xp_requirement(level)

	planet.xp = current_xp
	planet.xp_to_next_level = DigitMaster.one() if level >= planet.max_level else xp_to_next
	_update_best_planet_level(planet.id, planet.level)

func _apply_research_progress(rp_amount: DigitMaster) -> void:
	if rp_amount.is_zero():
		return

	var amount_float := _digit_master_to_float(rp_amount)
	if is_inf(amount_float):
		research_points = research_points.add(rp_amount)
		research_progress = 0.0
		return

	var total_progress := research_progress + amount_float
	var whole_rp: float = floor(total_progress)
	if whole_rp >= 1.0:
		research_points = research_points.add(DigitMaster.new(whole_rp))
	research_progress = fmod(total_progress, 1.0)

func _apply_blessing_progress_for_generated_element(element: ElementState, amount: DigitMaster) -> void:
	if element == null or amount == null or amount.is_zero():
		return
	if element.index <= 0:
		return

	var generated_mass := amount.multiply_scalar(float(element.index))
	if generated_mass.is_zero():
		return

	blessings_progress_mass = blessings_progress_mass.add(generated_mass)
	while blessings_progress_mass.compare(get_next_blessing_cost()) >= 0:
		var next_cost := get_next_blessing_cost()
		blessings_progress_mass = blessings_progress_mass.subtract(next_cost)
		blessings_count += 1
		unopened_blessings_count += 1

func _award_random_blessing() -> void:
	var blessing_id := _roll_random_blessing_id()
	if blessing_id.is_empty():
		return
	var blessing = get_blessing_state(blessing_id)
	if blessing == null:
		return
	blessing.level += 1

func _roll_random_blessing_id() -> String:
	var rarity := _roll_blessing_rarity()
	if rarity.is_empty():
		return ""

	var rarity_ids := _get_rollable_blessing_ids_for_rarity(rarity)
	if rarity_ids.is_empty():
		return ""

	var chosen_index := _blessing_rng.randi_range(0, rarity_ids.size() - 1)
	return str(rarity_ids[chosen_index])

func _roll_blessing_rarity() -> String:
	var total_weight := 0.0
	var rollable_rarities := _get_rollable_rarities()
	for rarity in rollable_rarities:
		total_weight += float(blessing_rarity_roll_weights.get(rarity, 0.0))
	if total_weight <= 0.0:
		return ""

	var roll := _blessing_rng.randf() * total_weight
	var cursor := 0.0
	for rarity in rollable_rarities:
		cursor += float(blessing_rarity_roll_weights.get(rarity, 0.0))
		if roll <= cursor:
			return rarity
	return "" if rollable_rarities.is_empty() else str(rollable_rarities.back())

func _get_rollable_rarities() -> Array[String]:
	var rollable_rarities: Array[String] = []
	for rarity in BLESSING_RARITY_ORDER:
		if _get_rollable_blessing_ids_for_rarity(rarity).is_empty():
			continue
		rollable_rarities.append(rarity)
	return rollable_rarities

func _get_rollable_blessing_ids_for_rarity(rarity: String) -> Array[String]:
	var rollable_ids: Array[String] = []
	for blessing_id in get_blessing_ids_for_rarity(rarity):
		var blessing = get_blessing_state(blessing_id)
		if blessing == null or blessing.placeholder:
			continue
		rollable_ids.append(blessing_id)
	return rollable_ids

func _get_blessing_effect_total(effect_type: String) -> float:
	if effect_type.is_empty():
		return 0.0

	_ensure_blessing_effect_cache()
	return float(_cached_blessing_effect_totals.get(effect_type, 0.0))

func _invalidate_blessing_effect_cache() -> void:
	_cached_blessing_effect_totals.clear()
	_blessing_effect_cache_dirty = true

func _ensure_blessing_effect_cache() -> void:
	if not _blessing_effect_cache_dirty:
		return

	_cached_blessing_effect_totals.clear()
	for blessing_id in blessing_ids_in_order:
		var blessing = get_blessing_state(blessing_id)
		if blessing == null or blessing.effect_type.is_empty():
			continue
		var current_total := float(_cached_blessing_effect_totals.get(blessing.effect_type, 0.0))
		_cached_blessing_effect_totals[blessing.effect_type] = current_total + blessing.get_effect_value()
	_blessing_effect_cache_dirty = false

func _get_digit_ratio(current: DigitMaster, maximum: DigitMaster) -> float:
	var max_float := _digit_master_to_float(maximum)
	if max_float <= 0.0:
		return 0.0
	return clampf(_digit_master_to_float(current) / max_float, 0.0, 1.0)

func _digit_master_to_float(value: DigitMaster) -> float:
	if value.is_infinite:
		return INF
	if value.is_zero():
		return 0.0
	return value.mantissa * pow(10.0, value.exponent)

func _clamp_current_element_to_visible_sections() -> void:
	var current_element := get_current_element_state()
	if current_element != null and current_element.index <= get_max_unlockable_element_index():
		return

	var max_visible_index := get_max_unlockable_element_index()
	var fallback_element_id := ""
	for element_id in element_ids_in_order:
		var element := get_element_state(element_id)
		if element == null or not element.unlocked or element.index > max_visible_index:
			continue
		fallback_element_id = element.id

	if not fallback_element_id.is_empty():
		current_element_id = fallback_element_id
