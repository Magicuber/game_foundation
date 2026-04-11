extends RefCounted

class_name UpgradeManager

var _game_state_ref: WeakRef = null
var game_state:
	get:
		return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func load_upgrades(upgrades_data: Array) -> void:
	game_state.upgrades.clear()
	game_state.upgrade_ids_in_order.clear()

	for raw_upgrade_variant in upgrades_data:
		if typeof(raw_upgrade_variant) != TYPE_DICTIONARY:
			continue

		var raw_upgrade: Dictionary = raw_upgrade_variant
		var upgrade := UpgradeState.from_content(raw_upgrade)
		if upgrade.id.is_empty():
			continue

		game_state.upgrades[upgrade.id] = upgrade
		game_state.upgrade_ids_in_order.append(upgrade.id)

func get_upgrade_state(upgrade_id: String) -> UpgradeState:
	if not game_state.upgrades.has(upgrade_id):
		return null
	return game_state.upgrades[upgrade_id]

func get_upgrade_ids() -> Array[String]:
	return game_state.upgrade_ids_in_order.duplicate()

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

func set_upgrade_secondary_current_cost(upgrade_id: String, cost: DigitMaster) -> void:
	var upgrade := get_upgrade_state(upgrade_id)
	if upgrade == null:
		return
	upgrade.secondary_current_cost = cost.clone()

func reset_upgrades_to_defaults() -> void:
	for upgrade_id in game_state.upgrade_ids_in_order:
		var upgrade := get_upgrade_state(upgrade_id)
		if upgrade == null:
			continue
		upgrade.reset_to_default()
