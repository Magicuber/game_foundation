extends RefCounted

class_name BlessingState

const EFFECT_CRITICAL_SMASHER_CHANCE := "critical_smasher_chance"
const EFFECT_FISSION_CHANCE := "fission_chance"
const EFFECT_FOIL_SPAWN_CHANCE := "foil_spawn_chance"
const EFFECT_HOLOGRAPHIC_SPAWN_CHANCE := "holographic_spawn_chance"
const EFFECT_POLYCHROME_SPAWN_CHANCE := "polychrome_spawn_chance"

var id: String = ""
var name: String = ""
var description: String = ""
var rarity: String = ""
var color_hex: String = "ffffff"
var slot_index := 0
var level := 0
var max_level := 0
var effect_type: String = ""
var effect_amount := 0.0
var effect_cap := 0.0
var placeholder := false

static func from_content(raw_blessing: Dictionary) -> BlessingState:
	var blessing := BlessingState.new()
	blessing.id = str(raw_blessing.get("id", ""))
	blessing.name = str(raw_blessing.get("name", blessing.id))
	blessing.description = str(raw_blessing.get("description", ""))
	blessing.rarity = str(raw_blessing.get("rarity", ""))
	blessing.color_hex = str(raw_blessing.get("color", blessing.color_hex))
	blessing.slot_index = int(raw_blessing.get("slot_index", 0))
	blessing.level = maxi(0, int(raw_blessing.get("level", 0)))
	blessing.max_level = maxi(0, int(raw_blessing.get("max_level", 0)))
	blessing.effect_type = str(raw_blessing.get("effect_type", ""))
	blessing.effect_amount = float(raw_blessing.get("effect_amount", 0.0))
	blessing.effect_cap = maxf(0.0, float(raw_blessing.get("effect_cap", 0.0)))
	blessing.placeholder = bool(raw_blessing.get("placeholder", false))
	return blessing

func to_save_dict() -> Dictionary:
	return {
		"level": level
	}

func apply_save_dict(save_data: Dictionary) -> void:
	level = maxi(0, int(save_data.get("level", level)))

func get_effect_value() -> float:
	var value := effect_amount * float(level)
	if effect_cap > 0.0:
		return minf(effect_cap, value)
	return value

func get_level_label() -> String:
	return "Lv. %d" % level

func get_summary() -> String:
	if placeholder or effect_type.is_empty():
		return description

	match effect_type:
		EFFECT_CRITICAL_SMASHER_CHANCE:
			return "+%.2f%% critical smasher chance. Current bonus: +%.2f%%." % [
				effect_amount,
				get_effect_value()
			]
		EFFECT_FISSION_CHANCE:
			return "+%.2f%% fission chance. Current bonus: +%.2f%%." % [
				effect_amount,
				get_effect_value()
			]
		EFFECT_FOIL_SPAWN_CHANCE:
			return "+%.0f%% foil spawn chance per level. Foil smashes grant 2x base rewards. Current chance: %.0f%%." % [
				effect_amount,
				get_effect_value()
			]
		EFFECT_HOLOGRAPHIC_SPAWN_CHANCE:
			return "+%.0f%% holographic spawn chance per level. Holographic smashes grant 5x base rewards. Current chance: %.0f%%." % [
				effect_amount,
				get_effect_value()
			]
		EFFECT_POLYCHROME_SPAWN_CHANCE:
			return "+%.0f%% polychrome spawn chance per level. Polychrome smashes grant 10x base rewards. Current chance: %.0f%%." % [
				effect_amount,
				get_effect_value()
			]
		_:
			return description

func get_color() -> Color:
	return Color.from_string("#%s" % color_hex, Color.WHITE)
