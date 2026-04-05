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
	_upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_label.visible = false
	_info_label.text = ""

func refresh(game_state: GameState, upgrades_system: UpgradesSystem) -> void:
	if not _panel.visible:
		return

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
