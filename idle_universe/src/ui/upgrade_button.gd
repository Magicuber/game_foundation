extends Button

class_name UpgradeButton

signal purchase_requested(upgrade_id: String)

var game_state: GameState
var upgrades_system: UpgradesSystem
var upgrade_id := ""

func configure(new_game_state: GameState, new_upgrades_system: UpgradesSystem, new_upgrade_id: String) -> void:
	game_state = new_game_state
	upgrades_system = new_upgrades_system
	upgrade_id = new_upgrade_id
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	focus_mode = Control.FOCUS_NONE
	refresh()

func refresh() -> void:
	if game_state == null or upgrades_system == null or upgrade_id.is_empty():
		text = ""
		disabled = true
		return

	var upgrade := game_state.get_upgrade(upgrade_id)
	if upgrade.is_empty():
		text = ""
		disabled = true
		return

	var level := int(upgrade.get("current_level", 0))
	var max_level := int(upgrade.get("max_level", 0))
	var current_cost: DigitMaster = upgrade["current_cost"]
	var currency_name := game_state.get_resource_name(str(upgrade.get("currency_id", "")))
	var description := str(upgrade.get("description", ""))
	var effect_summary := upgrades_system.get_upgrade_effect_summary(game_state, upgrade_id)

	text = "%s Lv.%d/%d\n%s\n%s\nCost: %s %s" % [
		str(upgrade.get("name", upgrade_id)),
		level,
		max_level,
		description,
		effect_summary,
		current_cost.big_to_short_string(),
		currency_name
	]

	disabled = level >= max_level or not upgrades_system.can_purchase_upgrade(game_state, upgrade_id)

func _pressed() -> void:
	if not upgrade_id.is_empty():
		emit_signal("purchase_requested", upgrade_id)
