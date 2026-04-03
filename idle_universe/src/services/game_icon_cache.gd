extends RefCounted

class_name GameIconCache

const ELEMENT_SHEET_FRAME_SIZE := Vector2i(32, 32)
const ERA_SHEET_FRAME_SIZE := Vector2i(540, 750)
const PLANET_SHEET_FRAME_SIZE := Vector2i(100, 100)

const ELEMENT_SHEET = preload("res://assests/sprites/elements_01_strip119.png")
const PLANET_SHEET = preload("res://assests/sprites/planet_A_split25.png")
const ERA_SHEET = preload("res://assests/sprites/spr_era_strip4.png")

var _element_icon_cache: Dictionary = {}
var _planet_icon_cache: Dictionary = {}
var _era_frame_cache: Dictionary = {}

func get_element_icon(element_index: int) -> AtlasTexture:
	if not _element_icon_cache.has(element_index):
		var icon := AtlasTexture.new()
		icon.atlas = ELEMENT_SHEET
		icon.region = Rect2(
			Vector2(element_index * ELEMENT_SHEET_FRAME_SIZE.x, 0),
			Vector2(ELEMENT_SHEET_FRAME_SIZE.x, ELEMENT_SHEET_FRAME_SIZE.y)
		)
		_element_icon_cache[element_index] = icon
	return _element_icon_cache[element_index]

func get_planet_icon(planet_level: int) -> AtlasTexture:
	var frame_index := clampi(planet_level - 1, 0, 24)
	if not _planet_icon_cache.has(frame_index):
		var icon := AtlasTexture.new()
		icon.atlas = PLANET_SHEET
		icon.region = Rect2(
			Vector2(frame_index * PLANET_SHEET_FRAME_SIZE.x, 0),
			Vector2(PLANET_SHEET_FRAME_SIZE.x, PLANET_SHEET_FRAME_SIZE.y)
		)
		_planet_icon_cache[frame_index] = icon
	return _planet_icon_cache[frame_index]

func get_era_frame(frame_index: int) -> AtlasTexture:
	var clamped_index := clampi(frame_index, 0, 3)
	if not _era_frame_cache.has(clamped_index):
		var icon := AtlasTexture.new()
		icon.atlas = ERA_SHEET
		icon.region = Rect2(
			Vector2(clamped_index * ERA_SHEET_FRAME_SIZE.x, 0),
			Vector2(ERA_SHEET_FRAME_SIZE.x, ERA_SHEET_FRAME_SIZE.y)
		)
		_era_frame_cache[clamped_index] = icon
	return _era_frame_cache[clamped_index]
