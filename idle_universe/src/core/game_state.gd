extends RefCounted

class_name GameState

const SAVE_VERSION := 1
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

var orbs: int
var dust: DigitMaster
var elements: Dictionary
var element_ids_in_order: Array[String]
var upgrades: Dictionary
var upgrade_ids_in_order: Array[String]
var current_element_id: String
var next_unlock_id: String
var max_unlocked_element_id: String
var player_level: int
var world_level: int
var global_multiplier: DigitMaster
var tick_count: int
var total_played_seconds: float
var last_save_tick: int
var total_manual_smashes: int
var total_auto_smashes: int
var unlocked_era_index: int
var planets: Dictionary
var current_planet_id: String

static func from_content(elements_content: Dictionary, upgrades_content: Dictionary) -> GameState:
	var state := GameState.new()
	state._load_elements(elements_content.get("elements", []))
	state._load_upgrades(upgrades_content.get("upgrades", []))
	state.refresh_progression_state()
	return state

func _init() -> void:
	orbs = 0
	dust = DigitMaster.zero()
	elements = {}
	element_ids_in_order = []
	upgrades = {}
	upgrade_ids_in_order = []
	current_element_id = ""
	next_unlock_id = ""
	max_unlocked_element_id = ""
	player_level = 1
	world_level = 0
	global_multiplier = DigitMaster.one()
	tick_count = 0
	total_played_seconds = 0.0
	last_save_tick = 0
	total_manual_smashes = 0
	total_auto_smashes = 0
	unlocked_era_index = 0
	planets = {
		DEFAULT_PLANET_ID: {
			"id": DEFAULT_PLANET_ID,
			"name": "Planet A",
			"unlocked": false,
			"level": 1,
			"max_level": 25
		}
	}
	current_planet_id = DEFAULT_PLANET_ID

func _load_elements(elements_data: Array) -> void:
	elements.clear()
	element_ids_in_order.clear()

	for raw_element in elements_data:
		if typeof(raw_element) != TYPE_DICTIONARY:
			continue

		var element_id := str(raw_element.get("id", ""))
		if element_id.is_empty():
			continue

		var element := {
			"id": element_id,
			"name": str(raw_element.get("name", element_id)),
			"index": int(raw_element.get("index", element_ids_in_order.size())),
			"unlocked": bool(raw_element.get("unlocked", false)),
			"cost": DigitMaster.from_variant(raw_element.get("cost", 0)),
			"amount": DigitMaster.from_variant(raw_element.get("amt", 0)),
			"produces": str(raw_element.get("produces", "")),
			"show_in_counter": bool(raw_element.get("show_in_counter", false))
		}

		elements[element_id] = element
		element_ids_in_order.append(element_id)

func _load_upgrades(upgrades_data: Array) -> void:
	upgrades.clear()
	upgrade_ids_in_order.clear()

	for raw_upgrade in upgrades_data:
		if typeof(raw_upgrade) != TYPE_DICTIONARY:
			continue

		var upgrade_id := str(raw_upgrade.get("id", ""))
		if upgrade_id.is_empty():
			continue

		var base_cost := DigitMaster.from_variant(raw_upgrade.get("base_cost", 0))
		var upgrade := {
			"id": upgrade_id,
			"name": str(raw_upgrade.get("name", upgrade_id)),
			"description": str(raw_upgrade.get("description", "")),
			"currency_id": str(raw_upgrade.get("currency_id", DUST_RESOURCE_ID)),
			"base_cost": base_cost,
			"current_cost": base_cost.clone(),
			"cost_mode": str(raw_upgrade.get("cost_mode", "additive_power")),
			"cost_scaling": float(raw_upgrade.get("cost_scaling", 1.0)),
			"max_level": int(raw_upgrade.get("max_level", 1)),
			"current_level": int(raw_upgrade.get("current_level", 0)),
			"effect_type": str(raw_upgrade.get("effect_type", "")),
			"effect_amount": float(raw_upgrade.get("effect_amount", 0.0))
		}

		upgrades[upgrade_id] = upgrade
		upgrade_ids_in_order.append(upgrade_id)

func refresh_progression_state() -> void:
	var highest_unlocked_id := ""
	for element_id in element_ids_in_order:
		var element: Dictionary = elements[element_id]
		if bool(element.get("unlocked", false)):
			highest_unlocked_id = element_id

	max_unlocked_element_id = highest_unlocked_id
	next_unlock_id = ""

	var found_highest := highest_unlocked_id.is_empty()
	for element_id in element_ids_in_order:
		if not found_highest:
			if element_id == highest_unlocked_id:
				found_highest = true
			continue

		var element: Dictionary = elements[element_id]
		if not bool(element.get("unlocked", false)):
			next_unlock_id = element_id
			break

	if current_element_id.is_empty() or not is_element_unlocked(current_element_id):
		if not highest_unlocked_id.is_empty():
			current_element_id = highest_unlocked_id
		elif not element_ids_in_order.is_empty():
			current_element_id = element_ids_in_order[0]

func has_element(element_id: String) -> bool:
	return elements.has(element_id)

func is_element_unlocked(element_id: String) -> bool:
	if not has_element(element_id):
		return false
	return bool(elements[element_id].get("unlocked", false))

func is_element_id(resource_id: String) -> bool:
	return elements.has(resource_id)

func get_element(element_id: String) -> Dictionary:
	return elements.get(element_id, {})

func get_element_by_index(index: int) -> Dictionary:
	for element_id in element_ids_in_order:
		var element: Dictionary = elements[element_id]
		if int(element.get("index", -1)) == index:
			return element
	return {}

func get_current_element() -> Dictionary:
	return get_element(current_element_id)

func get_next_unlock_element() -> Dictionary:
	if next_unlock_id.is_empty():
		return {}
	return get_element(next_unlock_id)

func get_max_unlockable_element_index() -> int:
	var section_index := clampi(world_level, 0, UNLOCK_SECTION_ENDS.size() - 1)
	return int(UNLOCK_SECTION_ENDS[section_index])

func is_next_unlock_within_visible_sections() -> bool:
	var next_element := get_next_unlock_element()
	if next_element.is_empty():
		return false
	return int(next_element.get("index", 0)) <= get_max_unlockable_element_index()

func get_unlocked_element_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	for element_id in element_ids_in_order:
		if is_element_unlocked(element_id):
			unlocked_ids.append(element_id)
	return unlocked_ids

func get_unlocked_real_element_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	for element_id in element_ids_in_order:
		if not is_element_unlocked(element_id):
			continue
		var element: Dictionary = elements[element_id]
		if int(element.get("index", 0)) <= 0:
			continue
		unlocked_ids.append(element_id)
	return unlocked_ids

func get_visible_counter_element_ids() -> Array[String]:
	var visible_ids: Array[String] = []
	for element_id in element_ids_in_order:
		var element: Dictionary = elements[element_id]
		if bool(element.get("show_in_counter", false)):
			visible_ids.append(element_id)
	return visible_ids

func has_planet(planet_id: String) -> bool:
	return planets.has(planet_id)

func get_planet(planet_id: String) -> Dictionary:
	return planets.get(planet_id, {})

func get_current_planet() -> Dictionary:
	return get_planet(current_planet_id)

func is_planet_unlocked(planet_id: String) -> bool:
	if not has_planet(planet_id):
		return false
	return bool(planets[planet_id].get("unlocked", false))

func get_upgrade(upgrade_id: String) -> Dictionary:
	return upgrades.get(upgrade_id, {})

func get_upgrade_ids() -> Array[String]:
	return upgrade_ids_in_order.duplicate()

func get_resource_name(resource_id: String) -> String:
	if resource_id.to_lower() == DUST_RESOURCE_ID:
		return "Dust"
	if has_element(resource_id):
		return str(elements[resource_id].get("name", resource_id))
	return resource_id

func get_resource_amount(resource_id: String) -> DigitMaster:
	if resource_id.to_lower() == DUST_RESOURCE_ID:
		return dust.clone()
	if not has_element(resource_id):
		return DigitMaster.zero()
	var element: Dictionary = elements[resource_id]
	var amount: DigitMaster = element["amount"]
	return amount.clone()

func can_afford_resource(resource_id: String, cost: DigitMaster) -> bool:
	return get_resource_amount(resource_id).compare(cost) >= 0

func add_resource(resource_id: String, amount: DigitMaster) -> void:
	if resource_id.to_lower() == DUST_RESOURCE_ID:
		dust = dust.add(amount)
		return
	if not has_element(resource_id):
		return
	var element: Dictionary = elements[resource_id]
	var current_amount: DigitMaster = element["amount"]
	element["amount"] = current_amount.add(amount)

func spend_resource(resource_id: String, amount: DigitMaster) -> bool:
	if not can_afford_resource(resource_id, amount):
		return false

	if resource_id.to_lower() == DUST_RESOURCE_ID:
		dust = dust.subtract(amount)
		return true

	if not has_element(resource_id):
		return false

	var element: Dictionary = elements[resource_id]
	var current_amount: DigitMaster = element["amount"]
	element["amount"] = current_amount.subtract(amount)
	return true

func produce_resource(resource_id: String, amount: DigitMaster) -> void:
	if resource_id.is_empty():
		return

	var normalized_id := resource_id.to_lower()
	if normalized_id == DUST_RESOURCE_ID:
		dust = dust.add(amount)
		return

	if not has_element(resource_id):
		return

	var element: Dictionary = elements[resource_id]
	var current_amount: DigitMaster = element["amount"]
	element["amount"] = current_amount.add(amount)
	element["show_in_counter"] = true

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
	if next_era_index == 1 and has_planet(DEFAULT_PLANET_ID):
		var starting_planet: Dictionary = planets[DEFAULT_PLANET_ID]
		starting_planet["unlocked"] = true
		starting_planet["level"] = maxi(1, int(starting_planet.get("level", 1)))
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

	var current_element := get_current_element()
	if current_element.is_empty():
		return false

	var current_index := int(current_element.get("index", 0))
	var max_visible_index := get_max_unlockable_element_index()
	if current_index >= max_visible_index:
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

	var current_element := get_current_element()
	if current_element.is_empty():
		return ""

	var cursor := int(current_element.get("index", 0)) + direction
	while true:
		var candidate := get_element_by_index(cursor)
		if candidate.is_empty():
			return ""
		if bool(candidate.get("unlocked", false)):
			return str(candidate.get("id", ""))
		cursor += direction

	return ""

func can_unlock_next() -> bool:
	if next_unlock_id.is_empty():
		return false
	if not is_next_unlock_within_visible_sections():
		return false
	var next_element := get_next_unlock_element()
	if next_element.is_empty():
		return false
	var unlock_cost: DigitMaster = next_element["cost"]
	return can_afford_resource(next_unlock_id, unlock_cost)

func unlock_next_element() -> bool:
	if not can_unlock_next():
		return false

	var next_element := get_next_unlock_element()
	var unlock_cost: DigitMaster = next_element["cost"]
	if not spend_resource(next_unlock_id, unlock_cost):
		return false

	next_element["unlocked"] = true
	current_element_id = next_unlock_id
	refresh_progression_state()
	return true

func to_save_dict() -> Dictionary:
	var serialized_elements := {}
	for element_id in element_ids_in_order:
		var element: Dictionary = elements[element_id]
		var amount: DigitMaster = element["amount"]
		serialized_elements[element_id] = {
			"unlocked": bool(element.get("unlocked", false)),
			"show_in_counter": bool(element.get("show_in_counter", false)),
			"amount": amount.to_save_data()
		}

	var serialized_upgrades := {}
	for upgrade_id in upgrade_ids_in_order:
		var upgrade: Dictionary = upgrades[upgrade_id]
		var current_cost: DigitMaster = upgrade["current_cost"]
		serialized_upgrades[upgrade_id] = {
			"current_level": int(upgrade.get("current_level", 0)),
			"current_cost": current_cost.to_save_data()
		}

	return {
		"save_version": SAVE_VERSION,
		"orbs": orbs,
		"dust": dust.to_save_data(),
		"elements": serialized_elements,
		"upgrades": serialized_upgrades,
		"current_element_id": current_element_id,
		"player_level": player_level,
		"world_level": world_level,
		"global_multiplier": global_multiplier.to_save_data(),
		"tick_count": tick_count,
		"total_played_seconds": total_played_seconds,
		"last_save_tick": last_save_tick,
		"total_manual_smashes": total_manual_smashes,
		"total_auto_smashes": total_auto_smashes,
		"unlocked_era_index": unlocked_era_index,
		"current_planet_id": current_planet_id,
		"planets": planets
	}

func apply_save_dict(save_data: Dictionary) -> void:
	orbs = int(save_data.get("orbs", 0))
	dust = DigitMaster.from_variant(save_data.get("dust", 0))
	player_level = int(save_data.get("player_level", 1))
	world_level = int(save_data.get("world_level", 0))
	global_multiplier = DigitMaster.from_variant(save_data.get("global_multiplier", 1))
	tick_count = int(save_data.get("tick_count", 0))
	total_played_seconds = float(save_data.get("total_played_seconds", 0.0))
	last_save_tick = int(save_data.get("last_save_tick", 0))
	total_manual_smashes = int(save_data.get("total_manual_smashes", 0))
	total_auto_smashes = int(save_data.get("total_auto_smashes", 0))
	unlocked_era_index = int(save_data.get("unlocked_era_index", unlocked_era_index))

	var saved_elements: Dictionary = save_data.get("elements", {})
	for element_id in saved_elements.keys():
		if not has_element(element_id):
			continue
		var element: Dictionary = elements[element_id]
		var element_save: Dictionary = saved_elements[element_id]
		element["unlocked"] = bool(element_save.get("unlocked", element.get("unlocked", false)))
		element["show_in_counter"] = bool(element_save.get("show_in_counter", element.get("show_in_counter", false)))
		element["amount"] = DigitMaster.from_variant(element_save.get("amount", 0))

	var saved_upgrades: Dictionary = save_data.get("upgrades", {})
	for upgrade_id in saved_upgrades.keys():
		if not upgrades.has(upgrade_id):
			continue
		var upgrade: Dictionary = upgrades[upgrade_id]
		var upgrade_save: Dictionary = saved_upgrades[upgrade_id]
		upgrade["current_level"] = int(upgrade_save.get("current_level", upgrade.get("current_level", 0)))
		upgrade["current_cost"] = DigitMaster.from_variant(upgrade_save.get("current_cost", upgrade["base_cost"]))

	current_element_id = str(save_data.get("current_element_id", current_element_id))
	var saved_planets: Dictionary = save_data.get("planets", {})
	for planet_id in saved_planets.keys():
		if not planets.has(planet_id):
			continue
		var planet: Dictionary = planets[planet_id]
		var planet_save: Dictionary = saved_planets[planet_id]
		planet["unlocked"] = bool(planet_save.get("unlocked", planet.get("unlocked", false)))
		planet["level"] = int(planet_save.get("level", planet.get("level", 1)))
	current_planet_id = str(save_data.get("current_planet_id", current_planet_id))
	refresh_progression_state()
