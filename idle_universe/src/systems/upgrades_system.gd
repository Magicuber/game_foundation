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

	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return false
	if upgrade.current_level >= upgrade.max_level:
		return false
	if not _is_upgrade_era_unlocked(game_state, upgrade):
		return false

	if _is_element_sequence_upgrade(upgrade) and not _can_purchase_sequence_upgrade(game_state, upgrade):
		return false

	var cost_entries := get_upgrade_purchase_cost_entries(game_state, upgrade_id)
	if cost_entries.is_empty():
		return false
	for cost_entry in cost_entries:
		var resource_id := str(cost_entry.get("resource_id", ""))
		var current_cost: DigitMaster = cost_entry["cost"]
		if resource_id.is_empty() or not game_state.can_afford_resource(resource_id, current_cost):
			return false
	return true

func purchase_upgrade(game_state: GameState, upgrade_id: String) -> bool:
	if not can_purchase_upgrade(game_state, upgrade_id):
		return false

	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return false

	for cost_entry in get_upgrade_purchase_cost_entries(game_state, upgrade_id):
		var resource_id := str(cost_entry.get("resource_id", ""))
		var current_cost: DigitMaster = cost_entry["cost"]
		if not game_state.spend_resource(resource_id, current_cost):
			return false

	game_state.set_upgrade_level(upgrade_id, upgrade.current_level + 1)
	if _is_element_sequence_upgrade(upgrade):
		game_state.set_upgrade_current_cost(upgrade_id, get_upgrade_purchase_cost(game_state, upgrade_id))
	else:
		game_state.set_upgrade_current_cost(upgrade_id, _calculate_next_cost(upgrade.current_cost, upgrade))
	if not upgrade.secondary_currency_id.is_empty():
		game_state.set_upgrade_secondary_current_cost(upgrade_id, _calculate_next_cost(upgrade.secondary_current_cost, upgrade))
	mark_cache_dirty()
	return true

func get_upgrade_level(game_state: GameState, upgrade_id: String) -> int:
	if game_state == null:
		return 0
	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return 0
	return upgrade.current_level

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
	return _cached_global_critical_smash_chance_percent + game_state.get_blessing_critical_smasher_bonus_percent()

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
	return maxf(0.0, _cached_fission_chance_percent + game_state.get_blessing_fission_bonus_percent())

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

	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return false
	if not _is_upgrade_era_unlocked(game_state, upgrade):
		return false

	var resource_id := get_upgrade_purchase_currency_id(game_state, upgrade_id)
	if resource_id.is_empty():
		return false
	if resource_id.to_lower() == GameState.DUST_RESOURCE_ID:
		return true
	return game_state.has_element(resource_id) and game_state.is_element_unlocked(resource_id)

func get_upgrade_purchase_currency_id(game_state: GameState, upgrade_id: String) -> String:
	if game_state == null:
		return ""

	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return ""

	if _is_element_sequence_upgrade(upgrade):
		var target_element := _get_next_sequence_target_element(game_state, upgrade)
		return "" if target_element == null else target_element.id

	return upgrade.currency_id

func get_upgrade_purchase_cost(game_state: GameState, upgrade_id: String) -> DigitMaster:
	if game_state == null:
		return DigitMaster.zero()

	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return DigitMaster.zero()

	if _is_element_sequence_upgrade(upgrade):
		return _calculate_sequence_cost(upgrade)

	return upgrade.current_cost.clone()

func get_upgrade_purchase_cost_entries(game_state: GameState, upgrade_id: String) -> Array[Dictionary]:
	if game_state == null:
		return []

	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return []

	var cost_entries: Array[Dictionary] = []
	var primary_cost := get_upgrade_purchase_cost(game_state, upgrade_id)
	var primary_currency_id := get_upgrade_purchase_currency_id(game_state, upgrade_id)
	if not primary_currency_id.is_empty() and not primary_cost.is_zero():
		cost_entries.append({
			"resource_id": primary_currency_id,
			"cost": primary_cost
		})

	if not upgrade.secondary_currency_id.is_empty() and not upgrade.secondary_current_cost.is_zero():
		cost_entries.append({
			"resource_id": upgrade.secondary_currency_id,
			"cost": upgrade.secondary_current_cost.clone()
		})

	return cost_entries

func get_upgrade_lock_reason(game_state: GameState, upgrade_id: String) -> String:
	if game_state == null:
		return ""

	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return ""

	if not _is_upgrade_era_unlocked(game_state, upgrade):
		return "Unlock %s to reveal this upgrade tier." % game_state.get_era_name(upgrade.required_era_index)

	if upgrade.current_level >= upgrade.max_level:
		return "Max level reached."

	if not _is_element_sequence_upgrade(upgrade):
		return ""

	var next_target := _get_next_sequence_target_element(game_state, upgrade)
	if next_target == null:
		return "No further resonance targets."

	if next_target.index > game_state.get_max_unlockable_element_index():
		return "Next resonance is in a locked element section."

	if upgrade.sequence_requires_unlock and not next_target.unlocked:
		return "Unlock %s to buy the next level." % next_target.name

	return ""

func get_dust_recipe_bonus_multiplier(game_state: GameState, selected_element_ids: Array[String]) -> float:
	if game_state == null or selected_element_ids.is_empty():
		return 1.0

	var bonus_multiplier := 1.0
	for upgrade_id in game_state.get_upgrade_ids():
		var upgrade := game_state.get_upgrade_state(upgrade_id)
		if upgrade == null or upgrade.effect_type != EFFECT_DUST_RESONANCE_SEQUENCE:
			continue

		var matched_count := _count_matched_resonance_elements(game_state, upgrade, selected_element_ids)
		if matched_count <= 0:
			continue

		bonus_multiplier += float(matched_count) * upgrade.effect_amount

	return bonus_multiplier

func get_upgrade_effect_summary(game_state: GameState, upgrade_id: String) -> String:
	var upgrade := game_state.get_upgrade_state(upgrade_id)
	if upgrade == null:
		return ""

	match upgrade.effect_type:
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
			return upgrade.description

func _is_element_sequence_upgrade(upgrade: UpgradeState) -> bool:
	return upgrade.cost_mode == COST_MODE_ELEMENT_SEQUENCE_LINEAR

func _is_upgrade_era_unlocked(game_state: GameState, upgrade: UpgradeState) -> bool:
	if game_state == null or upgrade == null:
		return false
	return game_state.has_unlocked_era(upgrade.required_era_index)

func _calculate_sequence_cost(upgrade: UpgradeState) -> DigitMaster:
	return upgrade.base_cost.add(DigitMaster.new(upgrade.cost_step * float(upgrade.current_level)))

func _get_next_sequence_target_index(upgrade: UpgradeState) -> int:
	return upgrade.sequence_start_index + upgrade.current_level

func _get_next_sequence_target_element(game_state: GameState, upgrade: UpgradeState) -> ElementState:
	if game_state == null:
		return null
	return game_state.get_element_state_by_index(_get_next_sequence_target_index(upgrade))

func _can_purchase_sequence_upgrade(game_state: GameState, upgrade: UpgradeState) -> bool:
	var next_target := _get_next_sequence_target_element(game_state, upgrade)
	if next_target == null:
		return false

	if next_target.index > game_state.get_max_unlockable_element_index():
		return false

	if upgrade.sequence_requires_unlock and not next_target.unlocked:
		return false

	return true

func _count_matched_resonance_elements(game_state: GameState, upgrade: UpgradeState, selected_element_ids: Array[String]) -> int:
	if game_state == null:
		return 0

	if upgrade.current_level <= 0 or upgrade.sequence_start_index <= 0:
		return 0

	var matched_count := 0
	var max_resonant_index := upgrade.sequence_start_index + upgrade.current_level - 1
	for element_id in selected_element_ids:
		var element := game_state.get_element_state(element_id)
		if element == null:
			continue
		if element.index >= upgrade.sequence_start_index and element.index <= max_resonant_index:
			matched_count += 1

	return matched_count

func _get_dust_resonance_summary(game_state: GameState, upgrade: UpgradeState) -> String:
	var effect_amount_percent := upgrade.effect_amount * 100.0
	var next_target := _get_next_sequence_target_element(game_state, upgrade)
	var next_target_name := "" if next_target == null else next_target.name
	var next_currency_id := "" if next_target == null else next_target.id
	var next_cost := _calculate_sequence_cost(upgrade)
	var lock_reason := get_upgrade_lock_reason(game_state, upgrade.id)

	if upgrade.current_level <= 0:
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

	var last_index := upgrade.sequence_start_index + upgrade.current_level - 1
	var first_name := ""
	var first_element := game_state.get_element_state_by_index(upgrade.sequence_start_index)
	if first_element != null:
		first_name = first_element.name
	var last_name := ""
	var last_element := game_state.get_element_state_by_index(last_index)
	if last_element != null:
		last_name = last_element.name

	var resonance_label := first_name
	if upgrade.current_level > 1 and not last_name.is_empty():
		resonance_label = "%s-%s" % [first_name, last_name]

	var current_max_bonus_percent := effect_amount_percent * float(upgrade.current_level)
	var summary := "Resonance: %s. Dust recipes gain +%.0f%% per resonant element used. Current max bonus: +%.0f%%." % [
		resonance_label,
		effect_amount_percent,
		current_max_bonus_percent
	]
	if upgrade.current_level < upgrade.max_level and not next_target_name.is_empty():
		summary += " Next level: %s %s." % [
			next_cost.big_to_short_string(),
			game_state.get_resource_name(next_currency_id)
		]
	if not lock_reason.is_empty():
		summary += " %s" % lock_reason
	return summary

func _get_upgrade_scaled_effect(upgrade: UpgradeState) -> float:
	return upgrade.effect_amount * float(upgrade.current_level)

func _calculate_next_cost(current_cost: DigitMaster, upgrade: UpgradeState) -> DigitMaster:
	match upgrade.cost_mode:
		"additive_power":
			var increment := DigitMaster.new(pow(upgrade.cost_scaling, float(upgrade.current_level)))
			return current_cost.add(increment)
		"multiplicative":
			return current_cost.multiply_scalar(upgrade.cost_scaling)
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
		var upgrade := game_state.get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue

		match upgrade.effect_type:
			EFFECT_AUTO_SMASH_SPEED_BONUS:
				var reduction := clampf(1.0 - upgrade.effect_amount, 0.01, 1.0)
				_cached_auto_smash_interval_multiplier *= pow(reduction, float(upgrade.current_level))
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

	_cached_fission_chance_percent = maxf(0.0, _cached_fission_chance_percent)
	_cached_manual_double_hit_chance = maxf(0.0, _cached_manual_double_hit_chance)
	_cached_critical_payload_chance_percent = maxf(0.0, _cached_critical_payload_chance_percent)
	_cached_resonant_yield_chance = maxf(0.0, _cached_resonant_yield_chance)
	_aggregate_cache_dirty = false
