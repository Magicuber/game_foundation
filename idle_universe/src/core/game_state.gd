extends RefCounted

class_name GameState

const SAVE_VERSION := 2
const DUST_RESOURCE_ID := "dust"
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
const PLANET_WORKER_BASE_COST := 1000.0
const PLANET_WORKER_COST_RATIO := 1.25
const PLANET_WORKER_COST_ROUND_TO := 25.0
const PLANET_XP_LEVEL_TWO_REQUIREMENT := 1500.0
const PLANET_XP_LEVEL_TWENTY_FIVE_REQUIREMENT := 10000000.0
const PLANET_A_MAX_LEVEL := 25
const RESEARCH_POINTS_PER_PRODUCTION := 0.001

var orbs: int
var dust: DigitMaster
var elements: Dictionary
var element_ids_in_order: Array[String]
var upgrades: Dictionary
var upgrade_ids_in_order: Array[String]
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
var unlocked_era_index: int
var planets: Dictionary
var current_planet_id: String
var research_points: DigitMaster
var research_progress: float

var _element_ids_by_index: Dictionary

static func from_content(elements_content: Dictionary, upgrades_content: Dictionary, planets_content: Dictionary) -> GameState:
	var state := GameState.new()
	state._load_elements(elements_content.get("elements", []))
	state._load_upgrades(upgrades_content.get("upgrades", []))
	state._load_planets(planets_content.get("planets", []))
	state.refresh_progression_state()
	return state

func _init() -> void:
	orbs = 0
	dust = DigitMaster.zero()
	elements = {}
	element_ids_in_order = []
	upgrades = {}
	upgrade_ids_in_order = []
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
	unlocked_era_index = 0
	planets = {}
	current_planet_id = DEFAULT_PLANET_ID
	research_points = DigitMaster.zero()
	research_progress = 0.0
	_element_ids_by_index = {}

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

	if current_planet_id.is_empty() and not planet_ids_in_order.is_empty():
		current_planet_id = planet_ids_in_order[0]

func refresh_progression_state() -> void:
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

func get_max_unlockable_element_index() -> int:
	var section_index := clampi(prestige_count, 0, UNLOCK_SECTION_ENDS.size() - 1)
	return int(UNLOCK_SECTION_ENDS[section_index])

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
		dust = dust.add(amount)
		return

	var element := get_element_state(resource_id)
	if element == null:
		return

	element.amount = element.amount.add(amount)
	element.show_in_counter = true

func has_unlocked_element_count(required_count: int) -> bool:
	if required_count <= 0:
		return true
	return get_unlocked_element_ids().size() >= required_count

func is_era_menu_unlocked() -> bool:
	return is_element_unlocked(ERA_MENU_UNLOCK_ELEMENT_ID)

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
		"unlocked_era_index": unlocked_era_index,
		"research_points": research_points.to_save_data(),
		"research_progress": research_progress,
		"current_planet_id": current_planet_id,
		"planets": _serialize_planets()
	}

func apply_save_dict(save_data: Dictionary) -> void:
	orbs = int(save_data.get("orbs", 0))
	dust = DigitMaster.from_variant(save_data.get("dust", 0))
	player_level = int(save_data.get("player_level", 1))
	prestige_count = int(save_data.get("prestige_count", save_data.get("world_level", 0)))
	global_multiplier = DigitMaster.from_variant(save_data.get("global_multiplier", 1))
	tick_count = int(save_data.get("tick_count", 0))
	total_played_seconds = float(save_data.get("total_played_seconds", 0.0))
	last_save_tick = int(save_data.get("last_save_tick", 0))
	total_manual_smashes = int(save_data.get("total_manual_smashes", 0))
	total_auto_smashes = int(save_data.get("total_auto_smashes", 0))
	unlocked_era_index = int(save_data.get("unlocked_era_index", unlocked_era_index))
	research_points = DigitMaster.from_variant(save_data.get("research_points", 0))
	research_progress = clampf(float(save_data.get("research_progress", 0.0)), 0.0, 1.0)

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

	current_element_id = str(save_data.get("current_element_id", current_element_id))
	var saved_planets: Dictionary = save_data.get("planets", {})
	for planet_id_variant in saved_planets.keys():
		var planet_id := str(planet_id_variant)
		var planet := get_planet_state(planet_id)
		if planet == null:
			continue
		var planet_save: Dictionary = saved_planets[planet_id]
		planet.apply_save_dict(planet_save, _calculate_planet_xp_requirement(planet.level))

	current_planet_id = str(save_data.get("current_planet_id", current_planet_id))
	refresh_progression_state()

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
