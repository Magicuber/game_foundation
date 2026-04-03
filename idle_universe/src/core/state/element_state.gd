extends RefCounted

class_name ElementState

var id: String = ""
var name: String = ""
var index: int = 0
var unlocked := false
var cost: DigitMaster = DigitMaster.zero()
var amount: DigitMaster = DigitMaster.zero()
var produces: String = ""
var show_in_counter := false

static func from_content(raw_element: Dictionary, fallback_index: int) -> ElementState:
	var state := ElementState.new()
	state.id = str(raw_element.get("id", ""))
	state.name = str(raw_element.get("name", state.id))
	state.index = int(raw_element.get("index", fallback_index))
	state.unlocked = bool(raw_element.get("unlocked", false))
	state.cost = DigitMaster.from_variant(raw_element.get("cost", 0))
	state.amount = DigitMaster.from_variant(raw_element.get("amt", 0))
	state.produces = str(raw_element.get("produces", ""))
	state.show_in_counter = bool(raw_element.get("show_in_counter", false))
	return state

func to_view_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"index": index,
		"unlocked": unlocked,
		"cost": cost.clone(),
		"amount": amount.clone(),
		"produces": produces,
		"show_in_counter": show_in_counter
	}

func to_save_dict() -> Dictionary:
	return {
		"unlocked": unlocked,
		"show_in_counter": show_in_counter,
		"amount": amount.to_save_data()
	}

func apply_save_dict(save_data: Dictionary) -> void:
	unlocked = bool(save_data.get("unlocked", unlocked))
	show_in_counter = bool(save_data.get("show_in_counter", show_in_counter))
	amount = DigitMaster.from_variant(save_data.get("amount", amount))
