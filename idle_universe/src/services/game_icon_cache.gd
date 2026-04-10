extends RefCounted

class_name GameIconCache

const ELEMENT_SHEET_FRAME_SIZE := Vector2i(32, 32)
const ERA_SHEET_FRAME_SIZE := Vector2i(540, 750)
const PLANET_SHEET_FRAME_SIZE := Vector2i(100, 100)
const PLANET_B_SHEET_FRAME_SIZE := Vector2i(100, 99)
const VARIANT_NORMAL := "normal"
const VARIANT_FOIL := "foil"
const VARIANT_HOLOGRAPHIC := "holographic"
const VARIANT_POLYCHROME := "polychrome"

const ELEMENT_SHEET = preload("res://assests/sprites/elements_01_strip119.png")
const ELEMENT_FOIL_SHEET = preload("res://assests/sprites/elements_foil_strip119.png")
const ELEMENT_HOLO_SHEET = preload("res://assests/sprites/elements_holo_strip119.png")
const ELEMENT_POLY_SHEET = preload("res://assests/sprites/elements_poly_strip119.png")
const PLANET_SHEET = preload("res://assests/sprites/planet_A_split25.png")
const PLANET_B_SHEET = preload("res://assests/sprites/spr_planet_B_001.png")
const ERA_SHEET = preload("res://assests/sprites/spr_era_strip4.png")

var _element_icon_cache: Dictionary = {}
var _planet_icon_cache: Dictionary = {}
var _era_frame_cache: Dictionary = {}

func get_element_icon(element_index: int) -> AtlasTexture:
	return get_element_icon_for_variant(element_index, VARIANT_NORMAL)

func get_element_icon_for_variant(element_index: int, variant: String) -> AtlasTexture:
	var normalized_variant := _normalize_variant(variant)
	if not _element_icon_cache.has(normalized_variant):
		_element_icon_cache[normalized_variant] = {}
	var variant_cache: Dictionary = _element_icon_cache[normalized_variant]
	if not variant_cache.has(element_index):
		var icon := AtlasTexture.new()
		icon.atlas = _get_element_sheet_for_variant(normalized_variant)
		icon.region = Rect2(
			Vector2(element_index * ELEMENT_SHEET_FRAME_SIZE.x, 0),
			Vector2(ELEMENT_SHEET_FRAME_SIZE.x, ELEMENT_SHEET_FRAME_SIZE.y)
		)
		variant_cache[element_index] = icon
	return variant_cache[element_index]

func get_planet_icon(planet_id: String, planet_level: int) -> Texture2D:
	var frame_index := clampi(planet_level - 1, 0, 24)
	var cache_key := "%s:%d" % [planet_id, frame_index]
	if not _planet_icon_cache.has(cache_key):
		var icon := AtlasTexture.new()
		var sheet: Texture2D = PLANET_SHEET
		var frame_size := PLANET_SHEET_FRAME_SIZE
		if planet_id == "planet_b":
			sheet = PLANET_B_SHEET
			frame_size = PLANET_B_SHEET_FRAME_SIZE
		icon.atlas = sheet
		icon.region = Rect2(
			Vector2(frame_index * frame_size.x, 0),
			Vector2(frame_size.x, frame_size.y)
		)
		_planet_icon_cache[cache_key] = icon
	return _planet_icon_cache[cache_key]

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

func _normalize_variant(variant: String) -> String:
	match variant:
		VARIANT_FOIL, VARIANT_HOLOGRAPHIC, VARIANT_POLYCHROME:
			return variant
		_:
			return VARIANT_NORMAL

func _get_element_sheet_for_variant(variant: String) -> Texture2D:
	match variant:
		VARIANT_FOIL:
			return ELEMENT_FOIL_SHEET
		VARIANT_HOLOGRAPHIC:
			return ELEMENT_HOLO_SHEET
		VARIANT_POLYCHROME:
			return ELEMENT_POLY_SHEET
		_:
			return ELEMENT_SHEET
