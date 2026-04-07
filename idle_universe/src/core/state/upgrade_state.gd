extends RefCounted

class_name UpgradeState

var id: String = ""
var name: String = ""
var description: String = ""
var tier := 1
var required_era_index := 0
var currency_id: String = "dust"
var base_cost: DigitMaster = DigitMaster.zero()
var current_cost: DigitMaster = DigitMaster.zero()
var secondary_currency_id: String = ""
var secondary_base_cost: DigitMaster = DigitMaster.zero()
var secondary_current_cost: DigitMaster = DigitMaster.zero()
var cost_mode: String = "additive_power"
var cost_scaling := 1.0
var cost_step := 0.0
var max_level := 1
var current_level := 0
var effect_type: String = ""
var effect_amount := 0.0
var sequence_start_index := 0
var sequence_requires_unlock := false

static func from_content(raw_upgrade: Dictionary) -> UpgradeState:
	var state := UpgradeState.new()
	var base_cost := DigitMaster.from_variant(raw_upgrade.get("base_cost", 0))
	var secondary_base_cost := DigitMaster.from_variant(raw_upgrade.get("secondary_base_cost", 0))
	state.id = str(raw_upgrade.get("id", ""))
	state.name = str(raw_upgrade.get("name", state.id))
	state.description = str(raw_upgrade.get("description", ""))
	state.tier = int(raw_upgrade.get("tier", 1))
	state.required_era_index = int(raw_upgrade.get("required_era_index", 0))
	state.currency_id = str(raw_upgrade.get("currency_id", "dust"))
	state.base_cost = base_cost
	state.current_cost = base_cost.clone()
	state.secondary_currency_id = str(raw_upgrade.get("secondary_currency_id", ""))
	state.secondary_base_cost = secondary_base_cost
	state.secondary_current_cost = secondary_base_cost.clone()
	state.cost_mode = str(raw_upgrade.get("cost_mode", "additive_power"))
	state.cost_scaling = float(raw_upgrade.get("cost_scaling", 1.0))
	state.cost_step = float(raw_upgrade.get("cost_step", 0.0))
	state.max_level = int(raw_upgrade.get("max_level", 1))
	state.current_level = int(raw_upgrade.get("current_level", 0))
	state.effect_type = str(raw_upgrade.get("effect_type", ""))
	state.effect_amount = float(raw_upgrade.get("effect_amount", 0.0))
	state.sequence_start_index = int(raw_upgrade.get("sequence_start_index", 0))
	state.sequence_requires_unlock = bool(raw_upgrade.get("sequence_requires_unlock", false))
	return state

func to_view_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"tier": tier,
		"required_era_index": required_era_index,
		"currency_id": currency_id,
		"base_cost": base_cost.clone(),
		"current_cost": current_cost.clone(),
		"secondary_currency_id": secondary_currency_id,
		"secondary_base_cost": secondary_base_cost.clone(),
		"secondary_current_cost": secondary_current_cost.clone(),
		"cost_mode": cost_mode,
		"cost_scaling": cost_scaling,
		"cost_step": cost_step,
		"max_level": max_level,
		"current_level": current_level,
		"effect_type": effect_type,
		"effect_amount": effect_amount,
		"sequence_start_index": sequence_start_index,
		"sequence_requires_unlock": sequence_requires_unlock
	}

func to_save_dict() -> Dictionary:
	return {
		"current_level": current_level,
		"current_cost": current_cost.to_save_data(),
		"secondary_current_cost": secondary_current_cost.to_save_data()
	}

func apply_save_dict(save_data: Dictionary) -> void:
	current_level = int(save_data.get("current_level", current_level))
	current_cost = DigitMaster.from_variant(save_data.get("current_cost", base_cost))
	secondary_current_cost = DigitMaster.from_variant(save_data.get("secondary_current_cost", secondary_base_cost))
