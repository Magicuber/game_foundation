extends RefCounted

class_name GameState

var dust: DigitMaster
var elements : Dictionary
var upgrades : Dictionary
var current_element_id : String
var next_unlock_id : String
var world_level : int
var global_multiplier : DigitMaster
var tick_count : int
var total_played_seconds : float
var last_save_tick : int

func _init() -> void:
	dust = DigitMaster.new(0.0)
	elements = {}
	upgrades = {}
	current_element_id = "ele_P"
	next_unlock_id = "ele_H"
	world_level = 0
	global_multiplier = DigitMaster.new(1.0, 0)
	tick_count = 0
	total_played_seconds = 0.0
	last_save_tick = 0
