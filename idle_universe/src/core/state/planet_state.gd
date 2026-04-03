extends RefCounted

class_name PlanetState

var id: String = ""
var name: String = ""
var unlocked := false
var level := 1
var max_level := 1
var workers: DigitMaster = DigitMaster.zero()
var xp: DigitMaster = DigitMaster.zero()
var xp_to_next_level: DigitMaster = DigitMaster.one()
var worker_allocation_to_xp := 1.0

static func from_content(raw_planet: Dictionary, xp_to_next_level_value: DigitMaster) -> PlanetState:
	var state := PlanetState.new()
	state.id = str(raw_planet.get("id", ""))
	state.name = str(raw_planet.get("name", state.id))
	state.unlocked = bool(raw_planet.get("unlocked", false))
	state.level = maxi(1, int(raw_planet.get("level", 1)))
	state.max_level = maxi(1, int(raw_planet.get("max_level", 1)))
	state.workers = DigitMaster.from_variant(raw_planet.get("workers", 0))
	state.xp = DigitMaster.from_variant(raw_planet.get("xp", 0))
	state.xp_to_next_level = xp_to_next_level_value
	state.worker_allocation_to_xp = clampf(float(raw_planet.get("worker_allocation_to_xp", 1.0)), 0.0, 1.0)
	return state

func to_view_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"unlocked": unlocked,
		"level": level,
		"max_level": max_level,
		"workers": workers.clone(),
		"xp": xp.clone(),
		"xp_to_next_level": xp_to_next_level.clone(),
		"worker_allocation_to_xp": worker_allocation_to_xp
	}

func to_save_dict() -> Dictionary:
	return {
		"unlocked": unlocked,
		"level": level,
		"workers": workers.to_save_data(),
		"xp": xp.to_save_data(),
		"worker_allocation_to_xp": worker_allocation_to_xp
	}

func apply_save_dict(save_data: Dictionary, xp_to_next_level_value: DigitMaster) -> void:
	unlocked = bool(save_data.get("unlocked", unlocked))
	level = maxi(1, int(save_data.get("level", level)))
	workers = DigitMaster.from_variant(save_data.get("workers", workers))
	xp = DigitMaster.from_variant(save_data.get("xp", xp))
	worker_allocation_to_xp = clampf(float(save_data.get("worker_allocation_to_xp", worker_allocation_to_xp)), 0.0, 1.0)
	xp_to_next_level = xp_to_next_level_value
