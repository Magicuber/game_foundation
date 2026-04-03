extends RefCounted

class_name UpgradesPanelController

signal purchase_requested(upgrade_id: String)

var _panel: VBoxContainer
var _info_label: Label
var _upgrade_list: VBoxContainer
var _upgrade_buttons: Dictionary = {}
var _upgrade_button_ids: Array[String] = []

func configure(panel: VBoxContainer, info_label: Label, upgrade_list: VBoxContainer) -> void:
	_panel = panel
	_info_label = info_label
	_upgrade_list = upgrade_list

func refresh(game_state: GameState, upgrades_system: UpgradesSystem) -> void:
	if not _panel.visible:
		return

	_info_label.text = "Particle Smasher: %.2f actions/sec\nCrit Chance: %.0f%% | Crit Payload: %.0f%%\nFission Chance: %.0f%% | Double Hit: %.0f%%\nResonant Yield: %.0f%%" % [
		upgrades_system.get_auto_smashes_per_second(game_state),
		upgrades_system.get_global_critical_smash_chance_percent(game_state),
		upgrades_system.get_critical_payload_chance_percent(game_state),
		upgrades_system.get_fission_chance_percent(game_state),
		upgrades_system.get_manual_double_hit_chance(game_state) * 100.0,
		upgrades_system.get_resonant_yield_chance(game_state) * 100.0
	]

	var upgrade_ids: Array[String] = []
	for upgrade_id in game_state.get_upgrade_ids():
		if upgrades_system.should_show_upgrade(game_state, upgrade_id):
			upgrade_ids.append(upgrade_id)

	if _upgrade_button_ids != upgrade_ids:
		for child in _upgrade_list.get_children():
			child.queue_free()

		_upgrade_buttons.clear()
		_upgrade_button_ids = upgrade_ids.duplicate()

		for upgrade_id in _upgrade_button_ids:
			var button := UpgradeButton.new()
			button.configure(game_state, upgrades_system, upgrade_id)
			button.purchase_requested.connect(_on_purchase_requested)
			_upgrade_list.add_child(button)
			_upgrade_buttons[upgrade_id] = button

	for upgrade_id in _upgrade_button_ids:
		var button: UpgradeButton = _upgrade_buttons[upgrade_id]
		button.refresh()

func _on_purchase_requested(upgrade_id: String) -> void:
	purchase_requested.emit(upgrade_id)
