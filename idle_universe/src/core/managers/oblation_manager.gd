extends RefCounted

class_name OblationManager

var _game_state_ref: WeakRef = null
var game_state:
	get:
		return null if _game_state_ref == null else _game_state_ref.get_ref()

func _init(owner = null) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func configure(owner) -> void:
	_game_state_ref = weakref(owner) if owner != null else null

func load_oblations(oblations_content: Dictionary) -> void:
	game_state.oblation_recipe_ids_in_order.clear()
	game_state._oblation_recipes_by_id.clear()
	for recipe_variant in oblations_content.get("recipes", []):
		if typeof(recipe_variant) != TYPE_DICTIONARY:
			continue
		var recipe: Dictionary = recipe_variant.duplicate(true)
		var recipe_id := str(recipe.get("id", ""))
		if recipe_id.is_empty():
			continue
		game_state.oblation_recipe_ids_in_order.append(recipe_id)
		game_state._oblation_recipes_by_id[recipe_id] = recipe

func get_recipe_by_id(recipe_id: String) -> Dictionary:
	return (game_state._oblation_recipes_by_id.get(recipe_id, {}) as Dictionary).duplicate(true)

func get_oblation_recipe_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var completed_rank: int = game_state.get_completed_planet_rank()
	for recipe_id in game_state.oblation_recipe_ids_in_order:
		var recipe: Dictionary = get_recipe_by_id(recipe_id)
		var required_rank: int = int(recipe.get("required_milestone_rank", 1))
		var claimed: bool = game_state.oblation_claimed_recipe_ids.has(recipe_id)
		recipe["claimed"] = claimed
		recipe["visible"] = completed_rank >= required_rank or claimed
		recipe["available"] = recipe["visible"] and not claimed and not bool(recipe.get("placeholder", false))
		recipe["locked_reason"] = _get_recipe_locked_reason(recipe, claimed, completed_rank)
		recipe["effect_text"] = _build_effect_text(recipe)
		entries.append(recipe)
	return entries

func get_oblation_slot_options(recipe_id: String, slot_id: String) -> Array[Dictionary]:
	var recipe: Dictionary = get_recipe_by_id(recipe_id)
	if recipe.is_empty() or bool(recipe.get("placeholder", false)):
		return []
	for slot_variant in recipe.get("slots", []):
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		if str(slot.get("id", "")) != slot_id:
			continue
		return _build_slot_options(slot)
	return []

func get_oblation_preview(recipe_id: String, selected_inputs: Dictionary) -> Dictionary:
	var recipe: Dictionary = get_recipe_by_id(recipe_id)
	var issues: Array[String] = []
	if recipe.is_empty():
		issues.append("Recipe missing.")
	elif game_state.oblation_claimed_recipe_ids.has(recipe_id):
		issues.append("Already claimed.")
	elif bool(recipe.get("placeholder", false)):
		issues.append("Future content.")
	elif game_state.get_completed_planet_rank() < int(recipe.get("required_milestone_rank", 1)):
		issues.append("Milestone tier not unlocked.")

	var selected_summary: Array[String] = []
	for slot_variant in recipe.get("slots", []):
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		var slot_id := str(slot.get("id", ""))
		var selected_id := str(selected_inputs.get(slot_id, ""))
		if selected_id.is_empty():
			issues.append("Select %s." % str(slot.get("label", slot_id)))
			continue
		if not _slot_allows_id(slot, selected_id):
			issues.append("Invalid %s selection." % str(slot.get("label", slot_id)))
			continue
		if not _is_selection_currently_available(slot, selected_id):
			issues.append("%s is not available." % _get_selection_label(str(slot.get("kind", "")), selected_id))
			continue
		selected_summary.append("%s: %s" % [str(slot.get("label", slot_id)), _get_selection_label(str(slot.get("kind", "")), selected_id)])

	return {
		"recipe": recipe,
		"selected_summary": selected_summary,
		"effect_text": _build_effect_text(recipe),
		"issues": issues,
		"can_confirm": issues.is_empty()
	}

func can_confirm_oblation(recipe_id: String, selected_inputs: Dictionary) -> bool:
	return bool(get_oblation_preview(recipe_id, selected_inputs).get("can_confirm", false))

func confirm_oblation(recipe_id: String, selected_inputs: Dictionary) -> bool:
	if not can_confirm_oblation(recipe_id, selected_inputs):
		return false
	var recipe: Dictionary = get_recipe_by_id(recipe_id)
	for slot_variant in recipe.get("slots", []):
		if typeof(slot_variant) != TYPE_DICTIONARY:
			continue
		var slot: Dictionary = slot_variant
		var slot_id := str(slot.get("id", ""))
		var selected_id := str(selected_inputs.get(slot_id, ""))
		match str(slot.get("kind", "")):
			"element":
				_sacrifice_element(selected_id)
			"planet":
				_sacrifice_planet(selected_id)
			_:
				return false
	for effect_variant in recipe.get("effects", []):
		if typeof(effect_variant) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_variant
		if str(effect.get("type", "")) == "unlock_section":
			game_state._clamp_current_element_to_visible_sections()
	if not game_state.oblation_claimed_recipe_ids.has(recipe_id):
		game_state.oblation_claimed_recipe_ids.append(recipe_id)
	game_state.refresh_progression_state()
	return true

func get_oblation_effect_totals() -> Dictionary:
	var totals: Dictionary = {
		"unlock_section": 0,
		"dust_multiplier": 0.0,
		"research_multiplier": 0.0,
		"planet_xp_multiplier": 0.0
	}
	for recipe_id in game_state.oblation_claimed_recipe_ids:
		var recipe: Dictionary = get_recipe_by_id(recipe_id)
		for effect_variant in recipe.get("effects", []):
			if typeof(effect_variant) != TYPE_DICTIONARY:
				continue
			var effect: Dictionary = effect_variant
			var effect_type := str(effect.get("type", ""))
			if effect_type.is_empty() or not totals.has(effect_type):
				continue
			if effect_type == "unlock_section":
				totals[effect_type] = int(totals[effect_type]) + int(effect.get("value", 0))
			else:
				totals[effect_type] = float(totals[effect_type]) + float(effect.get("value", 0.0))
	return totals

func get_dust_gain_multiplier() -> float:
	return 1.0 + float(get_oblation_effect_totals().get("dust_multiplier", 0.0))

func get_research_gain_multiplier() -> float:
	return 1.0 + float(get_oblation_effect_totals().get("research_multiplier", 0.0))

func get_planet_xp_gain_multiplier() -> float:
	return 1.0 + float(get_oblation_effect_totals().get("planet_xp_multiplier", 0.0))

func get_unlocked_section_bonus() -> int:
	return int(get_oblation_effect_totals().get("unlock_section", 0))

func _build_slot_options(slot: Dictionary) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for allowed_id_variant in slot.get("allowed_ids", []):
		var allowed_id: String = str(allowed_id_variant)
		options.append({
			"id": allowed_id,
			"label": _get_selection_label(str(slot.get("kind", "")), allowed_id),
			"available": _is_selection_currently_available(slot, allowed_id)
		})
	return options

func _slot_allows_id(slot: Dictionary, selected_id: String) -> bool:
	for allowed_id_variant in slot.get("allowed_ids", []):
		if str(allowed_id_variant) == selected_id:
			return true
	return false

func _is_selection_currently_available(slot: Dictionary, selected_id: String) -> bool:
	match str(slot.get("kind", "")):
		"element":
			var element = game_state.get_element_state(selected_id)
			return element != null and element.unlocked
		"planet":
			return game_state.can_oblate_planet(selected_id)
		_:
			return false

func _get_selection_label(kind: String, selected_id: String) -> String:
	match kind:
		"element":
			return game_state.get_resource_name(selected_id)
		"planet":
			var planet: PlanetState = game_state.get_planet_state(selected_id)
			return selected_id if planet == null else planet.name
		"solar_system":
			return "Future Solar System"
		_:
			return selected_id

func _get_recipe_locked_reason(recipe: Dictionary, claimed: bool, completed_rank: int) -> String:
	if claimed:
		return "Claimed"
	if bool(recipe.get("placeholder", false)):
		return "Future content"
	if completed_rank < int(recipe.get("required_milestone_rank", 1)):
		return "Locked by milestones"
	return ""

func _build_effect_text(recipe: Dictionary) -> String:
	var effects: Array[String] = []
	for effect_variant in recipe.get("effects", []):
		if typeof(effect_variant) != TYPE_DICTIONARY:
			continue
		var effect: Dictionary = effect_variant
		var text: String = str(effect.get("text", ""))
		if text.is_empty():
			continue
		effects.append(text)
	return "\n".join(effects)

func _sacrifice_element(element_id: String) -> void:
	var target = game_state.get_element_state(element_id)
	if target == null:
		return
	for ordered_id in game_state.element_ids_in_order:
		var element = game_state.get_element_state(ordered_id)
		if element == null or element.index < target.index:
			continue
		element.unlocked = false
		element.amount = DigitMaster.zero()
		element.show_in_counter = false

func _sacrifice_planet(planet_id: String) -> void:
	if not game_state.can_oblate_planet(planet_id):
		return
	var planet = game_state.get_planet_state(planet_id)
	if planet != null:
		planet.reset_to_default(game_state._calculate_planet_xp_requirement(planet.default_level))
		planet.unlocked = false
	game_state.planet_owned_flags[planet_id] = false
	game_state.sacrificed_planet_flags[planet_id] = true
	var fallback_planet_id: String = game_state.get_fallback_world_planet_id()
	if fallback_planet_id.is_empty():
		game_state.current_planet_id = planet_id
	else:
		game_state.current_planet_id = fallback_planet_id
