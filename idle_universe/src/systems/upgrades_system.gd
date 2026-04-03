extends RefCounted

class_name UpgradesSystem

const PARTICLE_SMASHER_ID := "particle_smasher"
const CRITICAL_SMASHER_ID := "critical_smasher_chance"
const FISSION_ID := "fission_1"
const COST_MODE_ELEMENT_SEQUENCE_LINEAR := "element_sequence_linear"
const EFFECT_AUTO_SMASH := "auto_smash"
const EFFECT_AUTO_SMASH_SPEED_BONUS := "auto_smash_speed_bonus"
const EFFECT_CRITICAL_AUTO_SMASH := "critical_auto_smash"
const EFFECT_CRITICAL_PAYLOAD_BONUS := "critical_spawn_bonus"
const EFFECT_FISSION_SPLIT := "fission_split"
const EFFECT_BONUS_ELEMENT_OUTPUT := "bonus_element_output"
const EFFECT_MANUAL_BONUS_OUTPUT := "manual_bonus_output"
const EFFECT_DUST_RESONANCE_SEQUENCE := "dust_resonance_sequence"
const FISSION_MAX_CHANCE_PERCENT := 25.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _aggregate_cache_dirty := true
var _cached_auto_smash_interval_multiplier := 1.0
var _cached_global_critical_smash_chance_percent := 0.0
var _cached_fission_chance_percent := 0.0
var _cached_manual_double_hit_chance := 0.0
var _cached_critical_payload_chance_percent := 0.0
var _cached_resonant_yield_chance := 0.0

func _init() -> void:
	rng.randomize()

func mark_cache_dirty() -> void:
	_aggregate_cache_dirty = true

func can_purchase_upgrade(game_state: GameState, upgrade_id: String) -> bool:
	if game_state == null:
		return false

	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return false
	if int(upgrade.get("current_level", 0)) >= int(upgrade.get("max_level", 0)):
		return false

	if _is_element_sequence_upgrade(upgrade):
		if not _can_purchase_sequence_upgrade(game_state, upgrade):
			return false

	var resource_id := get_upgrade_purchase_currency_id(game_state, upgrade_id)
	var current_cost := get_upgrade_purchase_cost(game_state, upgrade_id)
	return not resource_id.is_empty() and game_state.can_afford_resource(resource_id, current_cost)

func purchase_upgrade(game_state: GameState, upgrade_id: String) -> bool:
	if not can_purchase_upgrade(game_state, upgrade_id):
		return false

	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
	var resource_id := get_upgrade_purchase_currency_id(game_state, upgrade_id)
	var current_cost := get_upgrade_purchase_cost(game_state, upgrade_id)
	if not game_state.spend_resource(resource_id, current_cost):
		return false

	upgrade["current_level"] = int(upgrade.get("current_level", 0)) + 1
	if _is_element_sequence_upgrade(upgrade):
		upgrade["current_cost"] = get_upgrade_purchase_cost(game_state, upgrade_id)
	else:
		upgrade["current_cost"] = _calculate_next_cost(upgrade)
	mark_cache_dirty()
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
	return max(0.1, (5.0 / float(level)) * get_auto_smash_interval_multiplier(game_state))

func get_auto_smashes_per_second(game_state: GameState) -> float:
	var interval := get_auto_smash_interval_seconds(game_state)
	if is_inf(interval) or interval <= 0.0:
		return 0.0
	return 1.0 / interval

func get_auto_smash_interval_multiplier(game_state: GameState) -> float:
	if game_state == null:
		return 1.0
	_ensure_aggregate_cache(game_state)
	return _cached_auto_smash_interval_multiplier

func get_global_critical_smash_chance_percent(game_state: GameState) -> float:
	if game_state == null:
		return 0.0
	_ensure_aggregate_cache(game_state)
	return _cached_global_critical_smash_chance_percent

func get_auto_smash_spawn_count(game_state: GameState) -> int:
	var crit_chance := get_global_critical_smash_chance_percent(game_state)
	var spawn_count := 1 + int(floor(crit_chance / 100.0))
	var remainder := fmod(crit_chance, 100.0)
	if rng.randf() * 100.0 < remainder:
		spawn_count += 1
	return spawn_count

func get_fission_chance_percent(game_state: GameState) -> float:
	if game_state == null:
		return 0.0
	_ensure_aggregate_cache(game_state)
	return _cached_fission_chance_percent

func should_trigger_fission(game_state: GameState) -> bool:
	var chance := get_fission_chance_percent(game_state)
	if chance <= 0.0:
		return false
	return rng.randf() * 100.0 < chance

func get_manual_double_hit_chance(game_state: GameState) -> float:
	if game_state == null:
		return 0.0
	_ensure_aggregate_cache(game_state)
	return _cached_manual_double_hit_chance

func should_trigger_manual_double_hit(game_state: GameState) -> bool:
	var chance := minf(1.0, get_manual_double_hit_chance(game_state))
	if chance <= 0.0:
		return false
	return rng.randf() < chance

func get_critical_payload_chance_percent(game_state: GameState) -> float:
	if game_state == null:
		return 0.0
	_ensure_aggregate_cache(game_state)
	return _cached_critical_payload_chance_percent

func should_trigger_critical_payload(game_state: GameState) -> bool:
	var chance := get_critical_payload_chance_percent(game_state)
	if chance <= 0.0:
		return false
	return rng.randf() * 100.0 < chance

func get_resonant_yield_chance(game_state: GameState) -> float:
	if game_state == null:
		return 0.0
	_ensure_aggregate_cache(game_state)
	return _cached_resonant_yield_chance

func should_trigger_resonant_yield(game_state: GameState) -> bool:
	var chance := minf(1.0, get_resonant_yield_chance(game_state))
	if chance <= 0.0:
		return false
	return rng.randf() < chance

func should_show_upgrade(game_state: GameState, upgrade_id: String) -> bool:
	if game_state == null:
		return false

	var resource_id := get_upgrade_purchase_currency_id(game_state, upgrade_id)
	if resource_id.is_empty():
		return false
	if resource_id.to_lower() == GameState.DUST_RESOURCE_ID:
		return true
	if not game_state.has_element(resource_id):
		return false
	return game_state.is_element_unlocked(resource_id)

func get_upgrade_purchase_currency_id(game_state: GameState, upgrade_id: String) -> String:
	if game_state == null:
		return ""

	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return ""

	if _is_element_sequence_upgrade(upgrade):
		var target_element := _get_next_sequence_target_element(game_state, upgrade)
		return str(target_element.get("id", ""))

	return str(upgrade.get("currency_id", ""))

func get_upgrade_purchase_cost(game_state: GameState, upgrade_id: String) -> DigitMaster:
	if game_state == null:
		return DigitMaster.zero()

	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return DigitMaster.zero()

	if _is_element_sequence_upgrade(upgrade):
		return _calculate_sequence_cost(upgrade)

	var current_cost: DigitMaster = upgrade["current_cost"]
	return current_cost.clone()

func get_upgrade_lock_reason(game_state: GameState, upgrade_id: String) -> String:
	if game_state == null:
		return ""

	var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		return ""

	var level := int(upgrade.get("current_level", 0))
	var max_level := int(upgrade.get("max_level", 0))
	if level >= max_level:
		return "Max level reached."

	if not _is_element_sequence_upgrade(upgrade):
		return ""

	var next_target := _get_next_sequence_target_element(game_state, upgrade)
	if next_target.is_empty():
		return "No further resonance targets."

	var next_target_index := int(next_target.get("index", 0))
	if next_target_index > game_state.get_max_unlockable_element_index():
		return "Next resonance is in a locked element section."

	if bool(upgrade.get("sequence_requires_unlock", false)) and not bool(next_target.get("unlocked", false)):
		return "Unlock %s to buy the next level." % str(next_target.get("name", ""))

	return ""

func get_dust_recipe_bonus_multiplier(game_state: GameState, selected_element_ids: Array[String]) -> float:
	if game_state == null or selected_element_ids.is_empty():
		return 1.0

	var bonus_multiplier := 1.0
	for upgrade_id in game_state.get_upgrade_ids():
		var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
		if str(upgrade.get("effect_type", "")) != EFFECT_DUST_RESONANCE_SEQUENCE:
			continue

		var matched_count := _count_matched_resonance_elements(game_state, upgrade, selected_element_ids)
		if matched_count <= 0:
			continue

		bonus_multiplier += float(matched_count) * float(upgrade.get("effect_amount", 0.0))

	return bonus_multiplier

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
		EFFECT_AUTO_SMASH_SPEED_BONUS:
			return "Particle Smasher interval multiplier: x%.2f. Current rate: %.2f actions/sec." % [
				get_auto_smash_interval_multiplier(game_state),
				get_auto_smashes_per_second(game_state)
			]
		EFFECT_CRITICAL_AUTO_SMASH:
			return "Global crit chance: %.0f%%. Crits spawn extra Protons." % get_global_critical_smash_chance_percent(game_state)
		EFFECT_CRITICAL_PAYLOAD_BONUS:
			return "Auto smashes have a %.0f%% chance per final output to grant 3x output after fission." % get_critical_payload_chance_percent(game_state)
		EFFECT_FISSION_SPLIT:
			return "Fission chance: %.0f%%. Splits output into two unlocked atoms." % get_fission_chance_percent(game_state)
		EFFECT_BONUS_ELEMENT_OUTPUT:
			return "Manual and auto smashes have a %.0f%% chance per final output to create one extra copy after fission." % (get_resonant_yield_chance(game_state) * 100.0)
		EFFECT_MANUAL_BONUS_OUTPUT:
			return "Manual smashes have a %.0f%% chance per final output to create one extra copy after fission." % (get_manual_double_hit_chance(game_state) * 100.0)
		EFFECT_DUST_RESONANCE_SEQUENCE:
			return _get_dust_resonance_summary(game_state, upgrade)
		_:
			return str(upgrade.get("description", ""))

func _is_element_sequence_upgrade(upgrade: Dictionary) -> bool:
	return str(upgrade.get("cost_mode", "")) == COST_MODE_ELEMENT_SEQUENCE_LINEAR

func _calculate_sequence_cost(upgrade: Dictionary) -> DigitMaster:
	var base_cost: DigitMaster = upgrade["base_cost"]
	var level := int(upgrade.get("current_level", 0))
	var cost_step := float(upgrade.get("cost_step", 0.0))
	return base_cost.add(DigitMaster.new(cost_step * float(level)))

func _get_next_sequence_target_index(upgrade: Dictionary) -> int:
	var start_index := int(upgrade.get("sequence_start_index", 0))
	var level := int(upgrade.get("current_level", 0))
	return start_index + level

func _get_next_sequence_target_element(game_state: GameState, upgrade: Dictionary) -> Dictionary:
	if game_state == null:
		return {}
	return game_state.get_element_by_index(_get_next_sequence_target_index(upgrade))

func _can_purchase_sequence_upgrade(game_state: GameState, upgrade: Dictionary) -> bool:
	var next_target := _get_next_sequence_target_element(game_state, upgrade)
	if next_target.is_empty():
		return false

	var next_target_index := int(next_target.get("index", 0))
	if next_target_index > game_state.get_max_unlockable_element_index():
		return false

	if bool(upgrade.get("sequence_requires_unlock", false)) and not bool(next_target.get("unlocked", false)):
		return false

	return true

func _count_matched_resonance_elements(game_state: GameState, upgrade: Dictionary, selected_element_ids: Array[String]) -> int:
	if game_state == null:
		return 0

	var matched_count := 0
	var current_level := int(upgrade.get("current_level", 0))
	var start_index := int(upgrade.get("sequence_start_index", 0))
	if current_level <= 0 or start_index <= 0:
		return 0

	var max_resonant_index := start_index + current_level - 1
	for element_id in selected_element_ids:
		var element: Dictionary = game_state.get_element(element_id)
		if element.is_empty():
			continue
		var element_index := int(element.get("index", 0))
		if element_index >= start_index and element_index <= max_resonant_index:
			matched_count += 1

	return matched_count

func _get_dust_resonance_summary(game_state: GameState, upgrade: Dictionary) -> String:
	var level := int(upgrade.get("current_level", 0))
	var effect_amount_percent := float(upgrade.get("effect_amount", 0.0)) * 100.0
	var next_target := _get_next_sequence_target_element(game_state, upgrade)
	var next_target_name := str(next_target.get("name", ""))
	var next_currency_id := str(next_target.get("id", ""))
	var next_cost := _calculate_sequence_cost(upgrade)
	var lock_reason := get_upgrade_lock_reason(game_state, str(upgrade.get("id", "")))

	if level <= 0:
		var inactive_summary := "Inactive. Dust recipes gain +%.0f%% per resonant element used." % effect_amount_percent
		if not next_target_name.is_empty():
			inactive_summary += " Next resonance: %s (%s %s)." % [
				next_target_name,
				next_cost.big_to_short_string(),
				game_state.get_resource_name(next_currency_id)
			]
		if not lock_reason.is_empty():
			inactive_summary += " %s" % lock_reason
		return inactive_summary

	var start_index := int(upgrade.get("sequence_start_index", 0))
	var last_index := start_index + level - 1
	var first_name := str(game_state.get_element_by_index(start_index).get("name", ""))
	var last_name := str(game_state.get_element_by_index(last_index).get("name", ""))
	var resonance_label := first_name
	if level > 1 and not last_name.is_empty():
		resonance_label = "%s-%s" % [first_name, last_name]

	var current_max_bonus_percent := effect_amount_percent * float(level)
	var summary := "Resonance: %s. Dust recipes gain +%.0f%% per resonant element used. Current max bonus: +%.0f%%." % [
		resonance_label,
		effect_amount_percent,
		current_max_bonus_percent
	]
	if level < int(upgrade.get("max_level", 0)) and not next_target_name.is_empty():
		summary += " Next level: %s %s." % [
			next_cost.big_to_short_string(),
			game_state.get_resource_name(next_currency_id)
		]
	if not lock_reason.is_empty():
		summary += " %s" % lock_reason
	return summary

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

func _ensure_aggregate_cache(game_state: GameState) -> void:
	if game_state == null or not _aggregate_cache_dirty:
		return

	_cached_auto_smash_interval_multiplier = 1.0
	_cached_global_critical_smash_chance_percent = 0.0
	_cached_fission_chance_percent = 0.0
	_cached_manual_double_hit_chance = 0.0
	_cached_critical_payload_chance_percent = 0.0
	_cached_resonant_yield_chance = 0.0

	for upgrade_id in game_state.get_upgrade_ids():
		var upgrade: Dictionary = game_state.get_upgrade(upgrade_id)
		match str(upgrade.get("effect_type", "")):
			EFFECT_AUTO_SMASH_SPEED_BONUS:
				var level := int(upgrade.get("current_level", 0))
				var reduction := clampf(1.0 - float(upgrade.get("effect_amount", 0.0)), 0.01, 1.0)
				_cached_auto_smash_interval_multiplier *= pow(reduction, float(level))
			EFFECT_CRITICAL_AUTO_SMASH:
				_cached_global_critical_smash_chance_percent += _get_upgrade_scaled_effect(upgrade)
			EFFECT_FISSION_SPLIT:
				_cached_fission_chance_percent += _get_upgrade_scaled_effect(upgrade)
			EFFECT_MANUAL_BONUS_OUTPUT:
				_cached_manual_double_hit_chance += _get_upgrade_scaled_effect(upgrade)
			EFFECT_CRITICAL_PAYLOAD_BONUS:
				_cached_critical_payload_chance_percent += _get_upgrade_scaled_effect(upgrade)
			EFFECT_BONUS_ELEMENT_OUTPUT:
				_cached_resonant_yield_chance += _get_upgrade_scaled_effect(upgrade)

	_cached_fission_chance_percent = minf(FISSION_MAX_CHANCE_PERCENT, _cached_fission_chance_percent)
	_cached_manual_double_hit_chance = maxf(0.0, _cached_manual_double_hit_chance)
	_cached_critical_payload_chance_percent = maxf(0.0, _cached_critical_payload_chance_percent)
	_cached_resonant_yield_chance = maxf(0.0, _cached_resonant_yield_chance)
	_aggregate_cache_dirty = false
