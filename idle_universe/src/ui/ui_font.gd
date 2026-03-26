extends RefCounted

class_name UIFont

const UI_FONT_PATH := "res://assests/fonts/JetBrainsMono-Regular.ttf"

static func load_ui_font() -> FontFile:
	if not ResourceLoader.exists(UI_FONT_PATH, "FontFile"):
		return null

	var font_resource: Resource = ResourceLoader.load(UI_FONT_PATH)
	if font_resource == null:
		return null

	return font_resource as FontFile
