extends PanelContainer

class_name BlessingCatalogRow

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

const CONTENT_PADDING_X := 14.0
const CONTENT_PADDING_TOP := 12.0
const CONTENT_PADDING_BOTTOM := 12.0
const SUMMARY_TOP_OFFSET := 44.0
const ROW_MIN_HEIGHT := 108.0
const LEVEL_TEXT_GAP := 16.0
const LEVEL_RESERVED_WIDTH := 190.0

var _ui_font: FontFile
var _name_text := ""
var _level_text := ""
var _summary_label: Label
var _title_color := Color.WHITE
var _panel_style := StyleBoxFlat.new()
var _state_signature := ""

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(0.0, ROW_MIN_HEIGHT)
	clip_contents = true

	_panel_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	_panel_style.border_color = Color.WHITE
	_panel_style.border_width_left = 2
	_panel_style.border_width_top = 2
	_panel_style.border_width_right = 2
	_panel_style.border_width_bottom = 2
	_panel_style.corner_radius_top_left = 10
	_panel_style.corner_radius_top_right = 10
	_panel_style.corner_radius_bottom_right = 10
	_panel_style.corner_radius_bottom_left = 10
	add_theme_stylebox_override("panel", _panel_style)

	_summary_label = Label.new()
	_summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_summary_label.add_theme_font_size_override("font_size", UIMetrics.CURRENCY_DISPLAY_FONT_SIZE)
	_summary_label.anchor_left = 0.0
	_summary_label.anchor_top = 0.0
	_summary_label.anchor_right = 1.0
	_summary_label.anchor_bottom = 1.0
	_summary_label.offset_left = CONTENT_PADDING_X
	_summary_label.offset_top = SUMMARY_TOP_OFFSET
	_summary_label.offset_right = -CONTENT_PADDING_X
	_summary_label.offset_bottom = -CONTENT_PADDING_BOTTOM
	add_child(_summary_label)

func configure(_blessing_id: String, ui_font: FontFile) -> void:
	_ui_font = ui_font
	if _ui_font != null:
		_summary_label.add_theme_font_override("font", _ui_font)
	queue_redraw()

func refresh_from_state(blessing) -> bool:
	if blessing == null:
		return false

	var accent: Color = blessing.get_color()
	var title_color: Color = Color.WHITE if blessing.level > 0 else accent.lightened(0.2)
	var detail_color := Color(1, 1, 1, 0.9) if blessing.level > 0 else Color(1, 1, 1, 0.72)
	var next_signature := "%s|%s|%s|%s|%s" % [
		blessing.name,
		blessing.get_level_label(),
		blessing.get_summary(),
		accent.to_html(),
		title_color.to_html()
	]
	if _state_signature == next_signature:
		return false

	_state_signature = next_signature
	_name_text = blessing.name
	_level_text = blessing.get_level_label()
	_summary_label.text = blessing.get_summary()
	_summary_label.add_theme_color_override("font_color", detail_color)
	_title_color = title_color
	_panel_style.bg_color = accent.darkened(0.7)
	_panel_style.bg_color.a = 1.0
	_panel_style.border_color = accent
	queue_redraw()
	return true

func _draw() -> void:
	if _ui_font == null:
		return

	var title_baseline := CONTENT_PADDING_TOP + float(UIMetrics.FONT_SIZE_BODY)
	var level_size := _ui_font.get_string_size(_level_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, UIMetrics.FONT_SIZE_BODY)
	var level_x := maxf(CONTENT_PADDING_X, size.x - CONTENT_PADDING_X - level_size.x)
	var name_width := maxf(0.0, level_x - CONTENT_PADDING_X - LEVEL_TEXT_GAP)
	draw_string(
		_ui_font,
		Vector2(CONTENT_PADDING_X, title_baseline),
		_name_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		name_width,
		UIMetrics.FONT_SIZE_BODY,
		_title_color
	)
	draw_string(
		_ui_font,
		Vector2(level_x, title_baseline),
		_level_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		LEVEL_RESERVED_WIDTH,
		UIMetrics.FONT_SIZE_BODY,
		_title_color
	)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
