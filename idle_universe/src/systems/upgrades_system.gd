extends RefCounted

class_name UpgradesSystem

func can_purchase_upgrade(game_state: GameState, upgrade_id: String) -> bool:
	if game_state == null:
		return false

	var upgrade := game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return false
	if int(upgrade.get("current_level", 0)) >= int(upgrade.get("max_level", 0)):
		return false

	var resource_id := str(upgrade.get("currency_id", ""))
	var current_cost: DigitMaster = upgrade["current_cost"]
	return game_state.can_afford_resource(resource_id, current_cost)

func purchase_upgrade(game_state: GameState, upgrade_id: String) -> bool:
	if not can_purchase_upgrade(game_state, upgrade_id):
		return false

	var upgrade := game_state.get_upgrade(upgrade_id)
	var resource_id := str(upgrade.get("currency_id", ""))
	var current_cost: DigitMaster = upgrade["current_cost"]
	if not game_state.spend_resource(resource_id, current_cost):
		return false

	upgrade["current_level"] = int(upgrade.get("current_level", 0)) + 1
	upgrade["current_cost"] = _calculate_next_cost(upgrade)
	return true

func get_upgrade_level(game_state: GameState, upgrade_id: String) -> int:
	if game_state == null:
		return 0
	var upgrade := game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return 0
	return int(upgrade.get("current_level", 0))

func get_auto_smash_interval_seconds(game_state: GameState) -> float:
	var level := get_upgrade_level(game_state, "particle_smasher")
	if level <= 0:
		return INF
	return max(0.1, 5.0 / float(level))

func get_auto_smashes_per_second(game_state: GameState) -> float:
	var interval := get_auto_smash_interval_seconds(game_state)
	if is_inf(interval) or interval <= 0.0:
		return 0.0
	return 1.0 / interval

func get_upgrade_effect_summary(game_state: GameState, upgrade_id: String) -> String:
	var upgrade := game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return ""

	match str(upgrade.get("effect_type", "")):
		"auto_smash":
			var level := get_upgrade_level(game_state, upgrade_id)
			if level <= 0:
				return "Inactive. Buy a level to start automated smashing."
			return "Automates smashing at %.2f actions/sec." % get_auto_smashes_per_second(game_state)
		_:
			return str(upgrade.get("description", ""))

func _calculate_next_cost(upgrade: Dictionary) -> DigitMaster:
	var current_cost: DigitMaster = upgrade["current_cost"]
	match str(upgrade.get("cost_mode", "additive_power")):
		"additive_power":
			var level := int(upgrade.get("current_level", 0))
			var scaling := float(upgrade.get("cost_scaling", 1.0))
			var increment := DigitMaster.new(pow(scaling, float(level)))
			return current_cost.add(increment)
		"multiplicative":
			return current_cost.multiply_scalar(float(upgrade.get("cost_scaling", 1.0)))
		_:
			return current_cost.clone()
