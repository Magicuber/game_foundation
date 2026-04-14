extends RefCounted

class_name ResourceManager

var _game_state_ref: WeakRef = null
var game_state:
	get:
		return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func get_research_progress_ratio() -> float:
	return clampf(game_state.research_progress, 0.0, 1.0)

func get_research_points() -> DigitMaster:
	return game_state.research_points.clone()

func get_research_progress_display() -> String:
	return "%.1f%%" % (get_research_progress_ratio() * 100.0)

func get_resource_name(resource_id: String) -> String:
	if resource_id.to_lower() == game_state.DUST_RESOURCE_ID:
		return "Dust"
	var element: ElementState = game_state.get_element_state(resource_id)
	if element != null:
		return element.name
	return resource_id

func get_resource_amount(resource_id: String) -> DigitMaster:
	if resource_id.to_lower() == game_state.DUST_RESOURCE_ID:
		return game_state.dust.clone()
	var element: ElementState = game_state.get_element_state(resource_id)
	if element == null:
		return DigitMaster.zero()
	return element.amount.clone()

func can_afford_resource(resource_id: String, cost: DigitMaster) -> bool:
	return get_resource_amount(resource_id).compare(cost) >= 0

func can_afford_cost_entries(cost_entries: Array[Dictionary]) -> bool:
	if cost_entries.is_empty():
		return false

	var orb_total := 0
	var resource_totals: Dictionary = {}
	for cost_entry in cost_entries:
		if bool(cost_entry.get("is_orb_requirement", false)):
			orb_total += int(cost_entry.get("required_amount", 0))
			continue

		var resource_id := str(cost_entry.get("resource_id", ""))
		var amount: DigitMaster = get_cost_entry_amount(cost_entry)
		if resource_id.is_empty() or amount == null:
			return false
		if resource_totals.has(resource_id):
			var existing_total: DigitMaster = resource_totals[resource_id]
			resource_totals[resource_id] = existing_total.add(amount)
		else:
			resource_totals[resource_id] = amount.clone()

	if game_state.orbs < orb_total:
		return false

	for resource_id in resource_totals.keys():
		var total_cost: DigitMaster = resource_totals[resource_id]
		if not can_afford_resource(str(resource_id), total_cost):
			return false
	return true

func add_resource(resource_id: String, amount: DigitMaster) -> void:
	if resource_id.to_lower() == game_state.DUST_RESOURCE_ID:
		game_state.dust = game_state.dust.add(amount)
		return
	var element: ElementState = game_state.get_element_state(resource_id)
	if element == null:
		return
	element.amount = element.amount.add(amount)

func spend_resource(resource_id: String, amount: DigitMaster) -> bool:
	if not can_afford_resource(resource_id, amount):
		return false

	if resource_id.to_lower() == game_state.DUST_RESOURCE_ID:
		game_state.dust = game_state.dust.subtract(amount)
		return true

	var element: ElementState = game_state.get_element_state(resource_id)
	if element == null:
		return false
	element.amount = element.amount.subtract(amount)
	return true

func spend_cost_entries_atomic(cost_entries: Array[Dictionary]) -> bool:
	if not can_afford_cost_entries(cost_entries):
		return false

	var orb_total := 0
	var resource_totals: Dictionary = {}
	for cost_entry in cost_entries:
		if bool(cost_entry.get("is_orb_requirement", false)):
			orb_total += int(cost_entry.get("required_amount", 0))
			continue

		var resource_id := str(cost_entry.get("resource_id", ""))
		var amount: DigitMaster = get_cost_entry_amount(cost_entry)
		if resource_id.is_empty() or amount == null:
			return false
		if resource_totals.has(resource_id):
			var existing_total: DigitMaster = resource_totals[resource_id]
			resource_totals[resource_id] = existing_total.add(amount)
		else:
			resource_totals[resource_id] = amount.clone()

	var previous_orbs: int = game_state.orbs
	var previous_resources: Dictionary = {}
	for resource_id in resource_totals.keys():
		previous_resources[resource_id] = get_resource_amount(str(resource_id))

	if orb_total > 0:
		game_state.orbs -= orb_total
		if game_state.orbs < 0:
			game_state.orbs = previous_orbs
			return false

	for resource_id_variant in resource_totals.keys():
		var resource_id := str(resource_id_variant)
		var total_cost: DigitMaster = resource_totals[resource_id_variant]
		if not spend_resource(resource_id, total_cost):
			game_state.orbs = previous_orbs
			for restore_id_variant in previous_resources.keys():
				var restore_id := str(restore_id_variant)
				var restore_amount: DigitMaster = previous_resources[restore_id_variant]
				set_resource_amount(restore_id, restore_amount)
			return false

	return true

func get_cost_entry_amount(cost_entry: Dictionary) -> DigitMaster:
	if cost_entry.has("cost") and cost_entry["cost"] is DigitMaster:
		return cost_entry["cost"]
	if cost_entry.has("required_amount") and cost_entry["required_amount"] is DigitMaster:
		return cost_entry["required_amount"]
	return null

func set_resource_amount(resource_id: String, amount: DigitMaster) -> void:
	if amount == null:
		return
	if resource_id.to_lower() == game_state.DUST_RESOURCE_ID:
		game_state.dust = amount.clone()
		return
	var element: ElementState = game_state.get_element_state(resource_id)
	if element == null:
		return
	element.amount = amount.clone()

func produce_resource(resource_id: String, amount: DigitMaster) -> void:
	if resource_id.is_empty():
		return

	var normalized_id := resource_id.to_lower()
	if normalized_id == game_state.DUST_RESOURCE_ID:
		game_state.dust = game_state.dust.add(amount.multiply_scalar(game_state.get_dust_gain_multiplier()))
		return

	var element: ElementState = game_state.get_element_state(resource_id)
	if element == null:
		return

	element.amount = element.amount.add(amount)
	element.show_in_counter = true
	game_state._apply_blessing_progress_for_generated_element(element, amount)

func apply_research_progress(rp_amount: DigitMaster) -> void:
	if rp_amount.is_zero():
		return
	rp_amount = rp_amount.multiply_scalar(game_state.get_research_gain_multiplier())

	var amount_float := rp_amount.to_float()
	if is_inf(amount_float):
		game_state.research_points = game_state.research_points.add(rp_amount)
		game_state.research_progress = 0.0
		return

	var total_progress: float = game_state.research_progress + amount_float
	var whole_rp: float = floor(total_progress)
	if whole_rp >= 1.0:
		game_state.research_points = game_state.research_points.add(DigitMaster.new(whole_rp))
	game_state.research_progress = fmod(total_progress, 1.0)
