extends RefCounted
class_name DigitMaster

var mantissa: float
var exponent: int

func _init(value: float = 0.0, exp: int = 0) -> void:
	if exp == 0 and value >= 0.0:
		if value == 0.0:
			mantissa = 0.0
			exponent = 0
		else:
			var exp_float = floor(log(abs(value)) / log(10.0))
			exponent = int(exp_float)
			mantissa = value / pow(10.0,exponent)
	else:
		mantissa = value
		exponent = exp
	
	normalize()

func normalize() -> void:
	if mantissa == 0.0:
		exponent = 0
		return
	if abs(mantissa) >= 10.0:
		var extra_exponent = floor(log(abs(mantissa)) / log(10.0))
		exponent += int(extra_exponent)
		mantissa = mantissa / pow(10.0, extra_exponent)
	elif abs(mantissa) < 1.0 and mantissa != 0.0:
		var extra_exponent = floor(log(abs(mantissa)) / log(10.0))
		exponent += int(extra_exponent)
		mantissa = mantissa / pow(10.0, extra_exponent)

func add(other: DigitMaster) -> DigitMaster:
	if mantissa == 0.0:
		return DigitMaster.new(other.mantissa, other.exponent)
	if other.mantissa == 0.0:
		return DigitMaster.new(mantissa, exponent)
	if exponent == other.exponent:
		return DigitMaster.new(mantissa + other.mantissa, exponent)
	if exponent > other.exponent:
		var diff = exponent - other.exponent
		var other_scaled = other.mantissa / pow(10.0, diff)
		return DigitMaster.new(mantissa + other_scaled, exponent)
	else:
		var diff = other.exponent - exponent
		var self_scaled = mantissa / pow(10.0, diff)
		return DigitMaster.new(self_scaled + other.mantissa, other.exponent)
		
func power(exp: float) -> DigitMaster:
	"""Raise to a power: self^exp"""
	if mantissa == 0.0:
		return DigitMaster.new(0.0)
	var result = DigitMaster.new()
	# (a * 10^b)^e = a^e * 10^(b*e)
	result.mantissa = pow(mantissa, exp)
	result.exponent = int(exponent * exp)
	result.normalize()
	return result
	
func compare(other: DigitMaster) -> int:
	"""Returns: -1 if self < other, 0 if equal, 1 if self > other"""
	if exponent != other.exponent:
		return 1 if exponent > other.exponent else -1
	if mantissa < other.mantissa:
		return -1
	elif mantissa > other.mantissa:
		return 1
	else:
		return 0

func big_to_string() -> String:
	"""Format as 'X.XXXeYYY' for display."""
	if mantissa == 0.0:
		return "0"
	return "%.2fe%d" % [mantissa, exponent]
	
func big_to_short_string() -> String:
	"""Format with suffixes: 1.2K, 3.4M, 5.6B, etc."""
	if mantissa == 0.0:
		return "0"
	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "O"]
	var exponent_idx = (exponent / 3)
	if exponent_idx < 0 or exponent_idx >= suffixes.size():
		# Outside known suffix range, use scientific notation
		return to_string()
	var display_val = mantissa * pow(10.0, exponent - (exponent_idx * 3))
	return "%.1f%s" % [display_val, suffixes[exponent_idx]]
