extends RefCounted

class_name UIFont

const UI_FONT_PATH := "res://assests/fonts/JetBrainsMono-Regular.ttf"

static var _cached_ui_font: FontFile
static var _did_attempt_load := false

static func load_ui_font() -> FontFile:
	if not _did_attempt_load:
		_did_attempt_load = true
		if ResourceLoader.exists(UI_FONT_PATH, "FontFile"):
			var font_resource: Resource = ResourceLoader.load(UI_FONT_PATH)
			_cached_ui_font = font_resource as FontFile
	return _cached_ui_font
