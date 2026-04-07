extends RefCounted

class_name GameIconCache

const ELEMENT_SHEET_FRAME_SIZE := Vector2i(32, 32)
const ERA_SHEET_FRAME_SIZE := Vector2i(540, 750)
const PLANET_SHEET_FRAME_SIZE := Vector2i(100, 100)
const VARIANT_NORMAL := "normal"
const VARIANT_FOIL := "foil"
const VARIANT_HOLOGRAPHIC := "holographic"
const VARIANT_POLYCHROME := "polychrome"

const ELEMENT_SHEET = preload("res://assests/sprites/elements_01_strip119.png")
const PLANET_SHEET = preload("res://assests/sprites/planet_A_split25.png")
const ERA_SHEET = preload("res://assests/sprites/spr_era_strip4.png")
const ELEMENT_FOIL_SHEET_PATH := "res://assests/sprites/elements_foil_strip119.png"
const ELEMENT_HOLO_SHEET_PATH := "res://assests/sprites/elements_holo_strip119.png"
const ELEMENT_POLY_SHEET_PATH := "res://assests/sprites/elements_poly_strip119.png"

var _element_icon_cache: Dictionary = {}
var _planet_icon_cache: Dictionary = {}
var _era_frame_cache: Dictionary = {}
var _variant_sheet_cache: Dictionary = {}

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

func _normalize_variant(variant: String) -> String:
	match variant:
		VARIANT_FOIL, VARIANT_HOLOGRAPHIC, VARIANT_POLYCHROME:
			return variant
		_:
			return VARIANT_NORMAL

func _get_element_sheet_for_variant(variant: String) -> Texture2D:
	match variant:
		VARIANT_FOIL:
			return _load_variant_sheet(ELEMENT_FOIL_SHEET_PATH)
		VARIANT_HOLOGRAPHIC:
			return _load_variant_sheet(ELEMENT_HOLO_SHEET_PATH)
		VARIANT_POLYCHROME:
			return _load_variant_sheet(ELEMENT_POLY_SHEET_PATH)
		_:
			return ELEMENT_SHEET

func _load_variant_sheet(path: String) -> Texture2D:
	if _variant_sheet_cache.has(path):
		return _variant_sheet_cache[path]

	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty():
		_variant_sheet_cache[path] = ELEMENT_SHEET
		return ELEMENT_SHEET

	var texture := ImageTexture.create_from_image(image)
	_variant_sheet_cache[path] = texture
	return texture
