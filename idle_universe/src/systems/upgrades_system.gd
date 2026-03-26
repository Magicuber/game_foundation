extends RefCounted

class_name UpgradesSystem

const PARTICLE_SMASHER_ID := "particle_smasher"
const CRITICAL_SMASHER_ID := "critical_smasher_chance"
const FISSION_ID := "fission_1"
const EFFECT_AUTO_SMASH := "auto_smash"
const EFFECT_CRITICAL_AUTO_SMASH := "critical_auto_smash"
const EFFECT_FISSION_SPLIT := "fission_split"
const FISSION_MAX_CHANCE_PERCENT := 25.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()

func can_purchase_upgrade(game_state: GameState, upgrade_id: String) -> bool:
	if game_state == null:
		return false

	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
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

	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
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
	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return 0
	return int(upgrade.get("current_level", 0))

func get_auto_smash_interval_seconds(game_state: GameState) -> float:
	var level := get_upgrade_level(game_state, PARTICLE_SMASHER_ID)
	if level <= 0:
		return INF
	return max(0.1, 5.0 / float(level))

func get_auto_smashes_per_second(game_state: GameState) -> float:
	var interval := get_auto_smash_interval_seconds(game_state)
	if is_inf(interval) or interval <= 0.0:
		return 0.0
	return 1.0 / interval

func get_global_critical_smash_chance_percent(game_state: GameState) -> float:
	var total_chance := 0.0
	for upgrade_id in game_state.get_upgrade_ids():
		var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
		if str(upgrade.get("effect_type", "")) != EFFECT_CRITICAL_AUTO_SMASH:
			continue
		total_chance += _get_upgrade_scaled_effect(upgrade)
	return total_chance

func get_auto_smash_spawn_count(game_state: GameState) -> int:
	var crit_chance := get_global_critical_smash_chance_percent(game_state)
	var spawn_count := 1 + int(floor(crit_chance / 100.0))
	var remainder := fmod(crit_chance, 100.0)
	if rng.randf() * 100.0 < remainder:
		spawn_count += 1
	return spawn_count

func get_fission_chance_percent(game_state: GameState) -> float:
	var total_chance := 0.0
	for upgrade_id in game_state.get_upgrade_ids():
		var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
		if str(upgrade.get("effect_type", "")) != EFFECT_FISSION_SPLIT:
			continue
		total_chance += minf(FISSION_MAX_CHANCE_PERCENT, _get_upgrade_scaled_effect(upgrade))
	return total_chance

func should_trigger_fission(game_state: GameState) -> bool:
	var chance := get_fission_chance_percent(game_state)
	if chance <= 0.0:
		return false
	return rng.randf() * 100.0 < chance

func get_upgrade_effect_summary(game_state: GameState, upgrade_id: String) -> String:
	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return ""

	match str(upgrade.get("effect_type", "")):
		EFFECT_AUTO_SMASH:
			var level := get_upgrade_level(game_state, upgrade_id)
			if level <= 0:
				return "Inactive. Buy a level to start automated smashing."
			return "Automates smashing at %.2f actions/sec." % get_auto_smashes_per_second(game_state)
		EFFECT_CRITICAL_AUTO_SMASH:
			return "Global crit chance: %.0f%%. Crits spawn extra Protons." % get_global_critical_smash_chance_percent(game_state)
		EFFECT_FISSION_SPLIT:
			return "Fission chance: %.0f%%. Splits output into two unlocked atoms." % get_fission_chance_percent(game_state)
		_:
			return str(upgrade.get("description", ""))

func _get_upgrade_scaled_effect(upgrade: Dictionary) -> float:
	return float(upgrade.get("effect_amount", 0.0)) * float(int(upgrade.get("current_level", 0)))

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
