extends RefCounted

class_name DigitMaster

var mantissa: float
var exponent: int
var is_infinite: bool

static func zero() -> DigitMaster:
	return DigitMaster.new(0.0)

static func one() -> DigitMaster:
	return DigitMaster.new(1.0)

static func infinity() -> DigitMaster:
	return DigitMaster.new(0.0, 0, true)

static func from_variant(value: Variant) -> DigitMaster:
	match typeof(value):
		TYPE_DICTIONARY:
			var dictionary_value: Dictionary = value
			if bool(dictionary_value.get("is_infinite", false)):
				return DigitMaster.infinity()
			return DigitMaster.new(
				float(dictionary_value.get("mantissa", 0.0)),
				int(dictionary_value.get("exponent", 0))
			)
		TYPE_INT, TYPE_FLOAT:
			return DigitMaster.new(float(value))
		TYPE_STRING:
			var string_value := str(value).strip_edges().to_lower()
			if string_value == "infinity":
				return DigitMaster.infinity()
			if string_value.is_valid_float():
				return DigitMaster.new(string_value.to_float())
			return DigitMaster.zero()
		_:
			return DigitMaster.zero()

func _init(value: float = 0.0, exp: int = 0, infinite: bool = false) -> void:
	mantissa = 0.0
	exponent = 0
	is_infinite = infinite

	if is_infinite:
		mantissa = 1.0
		return

	if exp == 0 and value != 0.0:
		var exp_float := floor(log(abs(value)) / log(10.0))
		exponent = int(exp_float)
		mantissa = value / pow(10.0, exponent)
	else:
		mantissa = value
		exponent = exp

	normalize()

func clone() -> DigitMaster:
	return DigitMaster.new(mantissa, exponent, is_infinite)

func normalize() -> void:
	if is_infinite:
		mantissa = 1.0
		exponent = 0
		return

	if mantissa == 0.0:
		exponent = 0
		return

	if abs(mantissa) >= 10.0:
		var extra_exponent := floor(log(abs(mantissa)) / log(10.0))
		exponent += int(extra_exponent)
		mantissa = mantissa / pow(10.0, extra_exponent)
	elif abs(mantissa) < 1.0:
		var extra_exponent := floor(log(abs(mantissa)) / log(10.0))
		exponent += int(extra_exponent)
		mantissa = mantissa / pow(10.0, extra_exponent)

func is_zero() -> bool:
	return not is_infinite and mantissa == 0.0

func add(other: DigitMaster) -> DigitMaster:
	if is_infinite or other.is_infinite:
		return DigitMaster.infinity()
	if is_zero():
		return other.clone()
	if other.is_zero():
		return clone()
	if exponent == other.exponent:
		return DigitMaster.new(mantissa + other.mantissa, exponent)
	if exponent > other.exponent:
		var diff := exponent - other.exponent
		var other_scaled := other.mantissa / pow(10.0, diff)
		return DigitMaster.new(mantissa + other_scaled, exponent)

	var reverse_diff := other.exponent - exponent
	var self_scaled := mantissa / pow(10.0, reverse_diff)
	return DigitMaster.new(self_scaled + other.mantissa, other.exponent)

func subtract(other: DigitMaster) -> DigitMaster:
	if is_infinite and not other.is_infinite:
		return DigitMaster.infinity()
	if other.is_infinite:
		return DigitMaster.zero()
	if other.is_zero():
		return clone()
	if is_zero():
		return DigitMaster.zero()
	if compare(other) < 0:
		return DigitMaster.zero()
	if exponent == other.exponent:
		return DigitMaster.new(mantissa - other.mantissa, exponent)
	if exponent > other.exponent:
		var diff := exponent - other.exponent
		var other_scaled := other.mantissa / pow(10.0, diff)
		return DigitMaster.new(mantissa - other_scaled, exponent)

	var reverse_diff := other.exponent - exponent
	var self_scaled := mantissa / pow(10.0, reverse_diff)
	return DigitMaster.new(self_scaled - other.mantissa, other.exponent)

func multiply_scalar(scalar: float) -> DigitMaster:
	if scalar == 0.0 or is_zero():
		return DigitMaster.zero()
	if is_infinite:
		return DigitMaster.infinity()
	return DigitMaster.new(mantissa * scalar, exponent)

func power(exp: float) -> DigitMaster:
	if is_zero():
		return DigitMaster.zero()
	if is_infinite:
		return DigitMaster.infinity()
	var result := DigitMaster.new()
	result.mantissa = pow(mantissa, exp)
	result.exponent = int(exponent * exp)
	result.normalize()
	return result

func compare(other: DigitMaster) -> int:
	if is_infinite and other.is_infinite:
		return 0
	if is_infinite:
		return 1
	if other.is_infinite:
		return -1
	if exponent != other.exponent:
		return 1 if exponent > other.exponent else -1
	if mantissa < other.mantissa:
		return -1
	if mantissa > other.mantissa:
		return 1
	return 0

func to_save_data() -> Dictionary:
	return {
		"mantissa": mantissa,
		"exponent": exponent,
		"is_infinite": is_infinite
	}

func big_to_string() -> String:
	if is_infinite:
		return "Infinity"
	if is_zero():
		return "0"
	return "%.2fe%d" % [mantissa, exponent]

func big_to_short_string() -> String:
	if is_infinite:
		return "Infinity"
	if is_zero():
		return "0"

	if exponent < 5:
		var full_value := mantissa * pow(10.0, exponent)
		return "%d" % int(round(full_value))

	var suffixes := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var exponent_idx := int(floor(float(exponent) / 3.0))
	if exponent_idx < 0 or exponent_idx >= suffixes.size():
		return big_to_string()

	var display_val := mantissa * pow(10.0, exponent - (exponent_idx * 3))
	if exponent_idx == 0:
		return "%.0f" % display_val
	return "%.1f%s" % [display_val, suffixes[exponent_idx]]
