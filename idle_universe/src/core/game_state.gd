extends RefCounted

class_name GameState

const SAVE_VERSION := 1
const DUST_RESOURCE_ID := "dust"

var dust: DigitMaster
var elements: Dictionary
var element_ids_in_order: Array[String]
var upgrades: Dictionary
var upgrade_ids_in_order: Array[String]
var current_element_id: String
var next_unlock_id: String
var max_unlocked_element_id: String
var world_level: int
var global_multiplier: DigitMaster
var tick_count: int
var total_played_seconds: float
var last_save_tick: int
var total_manual_smashes: int
var total_auto_smashes: int

static func from_content(elements_content: Dictionary, upgrades_content: Dictionary) -> GameState:
	var state := GameState.new()
	state._load_elements(elements_content.get("elements", []))
	state._load_upgrades(upgrades_content.get("upgrades", []))
	state.refresh_progression_state()
	return state

func _init() -> void:
	dust = DigitMaster.zero()
	elements = {}
	element_ids_in_order = []
	upgrades = {}
	upgrade_ids_in_order = []
	current_element_id = ""
	next_unlock_id = ""
	max_unlocked_element_id = ""
	world_level = 0
	global_multiplier = DigitMaster.one()
	tick_count = 0
	total_played_seconds = 0.0
	last_save_tick = 0
	total_manual_smashes = 0
	total_auto_smashes = 0

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

	if not next_unlock_id.is_empty():
		var next_unlock_element: Dictionary = elements[next_unlock_id]
		next_unlock_element["show_in_counter"] = true

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

func get_unlocked_element_ids() -> Array[String]:
	var unlocked_ids: Array[String] = []
	for element_id in element_ids_in_order:
		if is_element_unlocked(element_id):
			unlocked_ids.append(element_id)
	return unlocked_ids

func get_visible_counter_element_ids() -> Array[String]:
	var visible_ids: Array[String] = []
	for element_id in element_ids_in_order:
		var element: Dictionary = elements[element_id]
		if bool(element.get("show_in_counter", false)):
			visible_ids.append(element_id)
	return visible_ids

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
	if bool(element.get("unlocked", false)):
		element["show_in_counter"] = true

func select_element(element_id: String) -> bool:
	if not is_element_unlocked(element_id):
		return false
	current_element_id = element_id
	return true

func has_adjacent_unlocked_element(direction: int) -> bool:
	return not _find_adjacent_unlocked_element_id(direction).is_empty()

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
	next_element["show_in_counter"] = true
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
		"dust": dust.to_save_data(),
		"elements": serialized_elements,
		"upgrades": serialized_upgrades,
		"current_element_id": current_element_id,
		"world_level": world_level,
		"global_multiplier": global_multiplier.to_save_data(),
		"tick_count": tick_count,
		"total_played_seconds": total_played_seconds,
		"last_save_tick": last_save_tick,
		"total_manual_smashes": total_manual_smashes,
		"total_auto_smashes": total_auto_smashes
	}

func apply_save_dict(save_data: Dictionary) -> void:
	dust = DigitMaster.from_variant(save_data.get("dust", 0))
	world_level = int(save_data.get("world_level", 0))
	global_multiplier = DigitMaster.from_variant(save_data.get("global_multiplier", 1))
	tick_count = int(save_data.get("tick_count", 0))
	total_played_seconds = float(save_data.get("total_played_seconds", 0.0))
	last_save_tick = int(save_data.get("last_save_tick", 0))
	total_manual_smashes = int(save_data.get("total_manual_smashes", 0))
	total_auto_smashes = int(save_data.get("total_auto_smashes", 0))

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
	refresh_progression_state()
