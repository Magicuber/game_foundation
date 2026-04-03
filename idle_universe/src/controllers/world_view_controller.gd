extends RefCounted

class_name WorldViewController

const UIMetrics = preload("res://src/ui/ui_metrics.gd")

const WORLD_WORKER_VISUAL_CAP := 1000
const WORLD_ORBIT_MIN_RADIUS := 168.0
const WORLD_ORBIT_MAX_RADIUS := 240.0
const WORLD_ORBIT_SPEED_MIN := 0.35
const WORLD_ORBIT_SPEED_MAX := 1.15

signal worker_purchase_requested
signal worker_allocation_changed(value: float)

var _root: Control
var _title: Label
var _planet_sprite: TextureRect
var _info: Label
var _particle_layer: Control
var _action_stack: VBoxContainer
var _worker_slider: HSlider
var _worker_button: TextureButton
var _worker_button_label: Label
var _progress_margin: MarginContainer
var _progress_vbox: VBoxContainer
var _level_panel: PanelContainer
var _level_bar_back: ColorRect
var _level_progress_fill: ColorRect
var _level_progress_label: Label
var _level_progress_value: Label
var _rp_panel: PanelContainer
var _rp_bar_back: ColorRect
var _rp_progress_fill: ColorRect
var _rp_progress_label: Label
var _rp_progress_value: Label
var _icon_cache: GameIconCache
var _enabled_button_modulate := Color(1, 1, 1, 1)
var _disabled_button_modulate := Color(0.45, 0.45, 0.45, 1.0)
var _worker_particles: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func configure(
	root: Control,
	icon_cache: GameIconCache,
	worker_button_texture: Texture2D,
	enabled_button_modulate: Color,
	disabled_button_modulate: Color
) -> void:
	_root = root
	_title = root.get_node("WorldTitle")
	_planet_sprite = root.get_node("PlanetSprite")
	_info = root.get_node("WorldInfo")
	_particle_layer = root.get_node("WorldParticleLayer")
	_action_stack = root.get_node("WorldActionStack")
	_worker_slider = root.get_node("WorldActionStack/WorldWorkerSlider")
	_worker_button = root.get_node("WorldActionStack/WorldWorkerButton")
	_worker_button_label = root.get_node("WorldActionStack/WorldWorkerButton/WorldWorkerButtonLabel")
	_progress_margin = root.get_node("WorldProgressMargin")
	_progress_vbox = root.get_node("WorldProgressMargin/WorldProgressVBox")
	_level_panel = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldLevelPanel")
	_level_bar_back = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldLevelPanel/WorldLevelBox/WorldLevelBarBack")
	_level_progress_fill = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldLevelPanel/WorldLevelBox/WorldLevelBarBack/WorldLevelProgressFill")
	_level_progress_label = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldLevelPanel/WorldLevelBox/WorldLevelProgressLabel")
	_level_progress_value = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldLevelPanel/WorldLevelBox/WorldLevelProgressValue")
	_rp_panel = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldRPPanel")
	_rp_bar_back = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldRPPanel/WorldRPBox/WorldRPBarBack")
	_rp_progress_fill = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldRPPanel/WorldRPBox/WorldRPBarBack/WorldRPProgressFill")
	_rp_progress_label = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldRPPanel/WorldRPBox/WorldRPProgressLabel")
	_rp_progress_value = root.get_node("WorldProgressMargin/WorldProgressVBox/WorldRPPanel/WorldRPBox/WorldRPProgressValue")
	_icon_cache = icon_cache
	_enabled_button_modulate = enabled_button_modulate
	_disabled_button_modulate = disabled_button_modulate

	_particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_particle_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.move_child(_particle_layer, 1)

	_planet_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_planet_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_planet_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	_action_stack.visible = false
	_action_stack.mouse_filter = Control.MOUSE_FILTER_STOP
	_action_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	_action_stack.add_theme_constant_override("separation", UIMetrics.WORLD_ACTION_STACK_SEPARATION)

	_worker_slider.custom_minimum_size = UIMetrics.WORLD_WORKER_SLIDER_SIZE
	_worker_slider.min_value = 0.0
	_worker_slider.max_value = 100.0
	_worker_slider.value = 100.0
	_worker_slider.step = 100.0
	_worker_slider.value_changed.connect(_on_worker_slider_changed)

	_worker_button.custom_minimum_size = UIMetrics.WORLD_WORKER_BUTTON_SIZE
	_worker_button.stretch_mode = TextureButton.STRETCH_SCALE
	_configure_texture_button(_worker_button, worker_button_texture)
	_worker_button.pressed.connect(_on_worker_button_pressed)

	_worker_button_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_worker_button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_worker_button_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_worker_button_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_progress_margin.visible = false
	_progress_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_vbox.add_theme_constant_override("separation", UIMetrics.WORLD_PROGRESS_STACK_SEPARATION)

	_configure_progress_panel(
		_level_panel,
		_level_bar_back,
		_level_progress_fill,
		_level_progress_label,
		_level_progress_value,
		"Planet Level Progress"
	)
	_configure_progress_panel(
		_rp_panel,
		_rp_bar_back,
		_rp_progress_fill,
		_rp_progress_label,
		_rp_progress_value,
		"RP Progress"
	)

	_apply_text_style()

func apply_reference_layout() -> void:
	_set_fill_rect(_root, 0.0, 0.0, 0.0, 0.0)
	_set_fill_rect(_particle_layer, 0.0, 0.0, 0.0, 0.0)
	_set_top_wide_rect(_title, UIMetrics.WORLD_TITLE_TOP_MARGIN, UIMetrics.WORLD_TITLE_HEIGHT)
	_set_center_anchor_rect(_planet_sprite, UIMetrics.WORLD_PLANET_SIZE)
	_set_center_anchor_rect(_info, UIMetrics.WORLD_INFO_SIZE, UIMetrics.WORLD_INFO_CENTER_OFFSET)
	_set_bottom_center_rect(_action_stack, UIMetrics.WORLD_ACTION_STACK_SIZE, UIMetrics.WORLD_ACTION_STACK_BOTTOM_MARGIN)
	_set_left_column_rect(
		_progress_margin,
		UIMetrics.COUNTER_MARGIN_LEFT,
		UIMetrics.WORLD_PROGRESS_TOP_MARGIN,
		UIMetrics.WORLD_PROGRESS_WIDTH,
		UIMetrics.WORLD_PROGRESS_BOTTOM_MARGIN
	)

func set_navigation_state(is_world_view: bool, show_planetary_controls: bool) -> void:
	_root.visible = is_world_view
	_progress_margin.visible = is_world_view and show_planetary_controls
	_action_stack.visible = is_world_view and show_planetary_controls

func refresh(game_state: GameState, is_world_view: bool) -> void:
	if not is_world_view:
		return

	var planet := game_state.get_current_planet_state()
	if planet == null:
		_title.text = "World"
		_info.text = "No planets available."
		_planet_sprite.texture = null
		_worker_slider.editable = false
		_worker_button.disabled = true
		_worker_button.modulate = _disabled_button_modulate
		_sync_worker_particles(0)
		return

	var planet_level := planet.level
	var max_level := planet.max_level
	var workers := planet.workers
	var worker_cost := game_state.get_current_planet_worker_cost()
	var can_buy_worker := game_state.can_buy_current_planet_worker()
	var level_ratio := 1.0 if planet_level >= max_level else game_state.get_current_planet_level_progress_ratio()
	var current_xp: DigitMaster = game_state.get_current_planet_xp()
	var xp_to_next: DigitMaster = game_state.get_current_planet_xp_to_next_level()
	var allocation_ratio := game_state.get_current_planet_worker_allocation_to_xp()
	var worker_count_float := _digit_master_to_float(workers)
	var slider_step := 100.0 if worker_count_float <= 0.0 else (100.0 / worker_count_float)
	slider_step = clampf(slider_step, 0.001, 100.0)

	_title.text = "World"
	_info.text = "%s\nLv. %d/%d\nWorkers: %s\nRP: %s" % [
		planet.name,
		planet_level,
		max_level,
		workers.big_to_short_string(),
		game_state.get_research_points().big_to_short_string()
	]
	_info.text += "\nAllocation XP/RP: %d%% / %d%%" % [
		int(round(allocation_ratio * 100.0)),
		int(round((1.0 - allocation_ratio) * 100.0))
	]
	_planet_sprite.texture = _icon_cache.get_planet_icon(planet_level)
	_worker_slider.set_block_signals(true)
	_worker_slider.step = slider_step
	_worker_slider.value = allocation_ratio * 100.0
	_worker_slider.set_block_signals(false)
	_worker_slider.editable = planet.unlocked
	_worker_button.disabled = not can_buy_worker
	_worker_button.modulate = _enabled_button_modulate if can_buy_worker else _disabled_button_modulate
	_worker_button_label.text = "BUY WORKER\n%s Dust" % worker_cost.big_to_short_string()
	_set_progress_fill_ratio(_level_progress_fill, level_ratio)
	_set_progress_fill_ratio(_rp_progress_fill, game_state.get_research_progress_ratio())
	if planet_level >= max_level:
		_level_progress_value.text = "MAX LEVEL"
	else:
		_level_progress_value.text = "%s / %s" % [
			current_xp.big_to_short_string(),
			xp_to_next.big_to_short_string()
		]
	_rp_progress_value.text = "%s RP\n%s" % [
		game_state.get_research_points().big_to_short_string(),
		game_state.get_research_progress_display()
	]
	_sync_worker_particles(_estimate_visible_worker_particle_count(workers))

func update(delta: float, is_world_view: bool) -> void:
	if not is_world_view or _worker_particles.is_empty():
		return

	var center := _planet_sprite.global_position + (_planet_sprite.size * 0.5)
	for i in range(_worker_particles.size()):
		var particle: Dictionary = _worker_particles[i]
		var node: ColorRect = particle["node"]
		var angle := float(particle.get("angle", 0.0)) + (float(particle.get("speed", 0.0)) * delta)
		particle["angle"] = fmod(angle, TAU)
		_worker_particles[i] = particle
		var radius := float(particle.get("radius", WORLD_ORBIT_MIN_RADIUS))
		var phase := float(particle.get("phase", 1.0))
		var offset := Vector2.RIGHT.rotated(angle) * radius
		offset.y *= phase
		node.global_position = center + offset - (node.size * 0.5)

func clear_particles() -> void:
	for particle in _worker_particles:
		var node: ColorRect = particle.get("node", null)
		if is_instance_valid(node):
			node.queue_free()
	_worker_particles.clear()

func _configure_texture_button(button: TextureButton, texture: Texture2D) -> void:
	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture
	button.texture_disabled = texture
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.ignore_texture_size = true
	button.focus_mode = Control.FOCUS_NONE

func _configure_progress_panel(
	panel: PanelContainer,
	bar_back: ColorRect,
	fill: ColorRect,
	title_label: Label,
	value_label: Label,
	title: String
) -> void:
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style := StyleBoxFlat.new()
	style.bg_color = Color8(32, 32, 32, 210)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color8(16, 16, 16)
	style.content_margin_left = UIMetrics.WORLD_PROGRESS_PANEL_PADDING
	style.content_margin_top = UIMetrics.WORLD_PROGRESS_PANEL_PADDING
	style.content_margin_right = UIMetrics.WORLD_PROGRESS_PANEL_PADDING
	style.content_margin_bottom = UIMetrics.WORLD_PROGRESS_PANEL_PADDING
	panel.add_theme_stylebox_override("panel", style)

	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	bar_back.custom_minimum_size = UIMetrics.WORLD_PROGRESS_BAR_SIZE
	bar_back.color = Color8(18, 18, 18)

	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_right = 0.0
	fill.anchor_bottom = 1.0
	fill.offset_left = 0.0
	fill.offset_top = 0.0
	fill.offset_right = 0.0
	fill.offset_bottom = 0.0
	fill.color = Color8(84, 201, 124)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func _apply_text_style() -> void:
	var ui_font: FontFile = UIFont.load_ui_font()
	if ui_font != null:
		_title.add_theme_font_override("font", ui_font)
		_info.add_theme_font_override("font", ui_font)
		_worker_button_label.add_theme_font_override("font", ui_font)
		_level_progress_label.add_theme_font_override("font", ui_font)
		_level_progress_value.add_theme_font_override("font", ui_font)
		_rp_progress_label.add_theme_font_override("font", ui_font)
		_rp_progress_value.add_theme_font_override("font", ui_font)

	_title.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_XL)
	_info.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_LARGE)
	_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_info.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_worker_button_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	_worker_button_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_level_progress_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	_level_progress_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_level_progress_value.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_SMALL)
	_level_progress_value.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_rp_progress_label.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_MEDIUM)
	_rp_progress_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_rp_progress_value.add_theme_font_size_override("font_size", UIMetrics.LABEL_FONT_SIZE_SMALL)
	_rp_progress_value.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _set_progress_fill_ratio(fill: ColorRect, ratio: float) -> void:
	if not is_instance_valid(fill) or fill.get_parent() == null:
		return
	var parent_rect := fill.get_parent()
	var width := maxf(0.0, parent_rect.size.x * clampf(ratio, 0.0, 1.0))
	fill.offset_right = width

func _estimate_visible_worker_particle_count(workers: DigitMaster) -> int:
	if workers.is_infinite or workers.exponent >= 4:
		return WORLD_WORKER_VISUAL_CAP
	return mini(int(floor(_digit_master_to_float(workers))), WORLD_WORKER_VISUAL_CAP)

func _sync_worker_particles(target_count: int) -> void:
	target_count = clampi(target_count, 0, WORLD_WORKER_VISUAL_CAP)
	while _worker_particles.size() < target_count:
		_add_worker_particle()
	while _worker_particles.size() > target_count:
		_remove_worker_particle_at(_worker_particles.size() - 1)

func _add_worker_particle() -> void:
	var node := ColorRect.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.color = Color8(238, 240, 255, 220)
	node.custom_minimum_size = UIMetrics.WORLD_PARTICLE_SIZE
	node.size = UIMetrics.WORLD_PARTICLE_SIZE
	_particle_layer.add_child(node)

	_worker_particles.append({
		"node": node,
		"angle": _rng.randf_range(0.0, TAU),
		"radius": _rng.randf_range(WORLD_ORBIT_MIN_RADIUS, WORLD_ORBIT_MAX_RADIUS),
		"speed": _rng.randf_range(WORLD_ORBIT_SPEED_MIN, WORLD_ORBIT_SPEED_MAX),
		"phase": _rng.randf_range(0.6, 1.4)
	})

func _remove_worker_particle_at(index: int) -> void:
	var particle: Dictionary = _worker_particles[index]
	var node: ColorRect = particle["node"]
	if is_instance_valid(node):
		node.queue_free()
	_worker_particles.remove_at(index)

func _digit_master_to_float(value: DigitMaster) -> float:
	if value.is_infinite:
		return INF
	if value.is_zero():
		return 0.0
	return value.mantissa * pow(10.0, value.exponent)

func _on_worker_button_pressed() -> void:
	worker_purchase_requested.emit()

func _on_worker_slider_changed(value: float) -> void:
	worker_allocation_changed.emit(value)

func _set_fill_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = -right
	control.offset_bottom = -bottom

func _set_top_wide_rect(control: Control, top: float, height: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = top
	control.offset_right = 0.0
	control.offset_bottom = top + height

func _set_center_anchor_rect(control: Control, size_value: Vector2, center_offset: Vector2 = Vector2.ZERO) -> void:
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.offset_left = center_offset.x - (size_value.x * 0.5)
	control.offset_top = center_offset.y - (size_value.y * 0.5)
	control.offset_right = center_offset.x + (size_value.x * 0.5)
	control.offset_bottom = center_offset.y + (size_value.y * 0.5)

func _set_bottom_center_rect(control: Control, size_value: Vector2, bottom: float) -> void:
	control.anchor_left = 0.5
	control.anchor_top = 1.0
	control.anchor_right = 0.5
	control.anchor_bottom = 1.0
	control.offset_left = -(size_value.x * 0.5)
	control.offset_top = -(bottom + size_value.y)
	control.offset_right = size_value.x * 0.5
	control.offset_bottom = -bottom

func _set_left_column_rect(control: Control, left: float, top: float, width: float, bottom: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 1.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = left + width
	control.offset_bottom = -bottom
