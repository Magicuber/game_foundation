extends Control

const ELEMENTS_DATA_PATH := "res://src/data/elements.json"
const UPGRADES_DATA_PATH := "res://src/data/upgrades.json"
const AUTO_SAVE_INTERVAL_TICKS := 50
const ELEMENT_SHEET_FRAME_SIZE := Vector2i(32, 32)
const OFFSCREEN_MARGIN := 96.0
const PRODUCT_PARTICLE_SIZE := 52.0
const PROTON_PARTICLE_SIZE := 56.0
const PRODUCT_SPEED_MIN := 210.0
const PRODUCT_SPEED_MAX := 320.0
const PROTON_SPEED_MIN := 260.0
const PROTON_SPEED_MAX := 360.0
const FUSE_COLLISION_RADIUS := 68.0

const ELEMENT_SHEET = preload("res://assests/sprites/elements_01_strip119.png")
const PREV_BUTTON_TEXTURE = preload("res://assests/sprites/spr_prev_btn.png")
const NEXT_BUTTON_TEXTURE = preload("res://assests/sprites/spr_next_btn.png")
const MENU_BUTTON_TEXTURE = preload("res://assests/sprites/spr_menu_btn.png")
const MENU_BACKGROUND_TEXTURE = preload("res://assests/sprites/spr_eleupgds_background.png")

@onready var tick_system: TickSystem = $TickSystem
@onready var top_bar: ColorRect = $TopBar
@onready var effects_layer: Control = $EffectsLayer
@onready var resource_list: VBoxContainer = $TopBar/ResourceMargin/ResourceList
@onready var fuse_button: TextureButton = $FuseButton
@onready var prev_button: TextureButton = $PrevButton
@onready var next_button: TextureButton = $NextButton
@onready var menu_button: TextureButton = $MenuButton
@onready var menu_overlay: Control = $MenuOverlay
@onready var menu_background: TextureRect = $MenuOverlay/MenuBackground
@onready var menu_title: Label = $MenuOverlay/MenuContent/MenuVBox/MenuTitle
@onready var menu_info: Label = $MenuOverlay/MenuContent/MenuVBox/MenuInfo
@onready var unlock_button: Button = $MenuOverlay/MenuContent/MenuVBox/UnlockButton
@onready var upgrade_list: VBoxContainer = $MenuOverlay/MenuContent/MenuVBox/UpgradeList

var game_state: GameState
var element_system = ElementSystem.new()
var upgrades_system = UpgradesSystem.new()
var resource_displays: Dictionary = {}
var resource_display_ids: Array[String] = []
var upgrade_buttons: Dictionary = {}
var upgrade_button_ids: Array[String] = []
var visual_particles: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	set_process(true)
	rng.randomize()

	game_state = _build_default_state()
	SaveManager.load_into_state(game_state)

	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	fuse_button.pressed.connect(_on_smash_pressed)
	unlock_button.pressed.connect(_on_unlock_pressed)

	prev_button.texture_normal = PREV_BUTTON_TEXTURE
	prev_button.texture_pressed = PREV_BUTTON_TEXTURE
	prev_button.texture_hover = PREV_BUTTON_TEXTURE
	prev_button.texture_disabled = PREV_BUTTON_TEXTURE
	prev_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	next_button.texture_normal = NEXT_BUTTON_TEXTURE
	next_button.texture_pressed = NEXT_BUTTON_TEXTURE
	next_button.texture_hover = NEXT_BUTTON_TEXTURE
	next_button.texture_disabled = NEXT_BUTTON_TEXTURE
	next_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	menu_button.texture_normal = MENU_BUTTON_TEXTURE
	menu_button.texture_pressed = MENU_BUTTON_TEXTURE
	menu_button.texture_hover = MENU_BUTTON_TEXTURE
	menu_button.texture_disabled = MENU_BUTTON_TEXTURE
	menu_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	menu_background.texture = MENU_BACKGROUND_TEXTURE
	menu_background.modulate = Color(1, 1, 1, 0.7)
	menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_background.stretch_mode = TextureRect.STRETCH_SCALE
	menu_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	fuse_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	effects_layer.z_index = 1
	top_bar.z_index = 20
	fuse_button.z_index = 15
	prev_button.z_index = 20
	next_button.z_index = 20
	menu_button.z_index = 30
	menu_overlay.z_index = 40

	tick_system.configure(game_state, element_system, upgrades_system)
	tick_system.tick_processed.connect(_on_tick_processed)
	tick_system.manual_smash_resolved.connect(_on_manual_smash_resolved)
	tick_system.auto_smash_requested.connect(_on_auto_smash_requested)

	menu_overlay.visible = false
	_sync_resource_displays()
	_sync_upgrade_buttons()
	_refresh_ui()

func _process(delta: float) -> void:
	_update_particles(delta)

func _exit_tree() -> void:
	if game_state != null and SaveManager.save_state(game_state):
		game_state.last_save_tick = game_state.tick_count

func _build_default_state() -> GameState:
	var elements_content: Dictionary = _load_json_dictionary(ELEMENTS_DATA_PATH)
	var upgrades_content: Dictionary = _load_json_dictionary(UPGRADES_DATA_PATH)
	return GameState.from_content(elements_content, upgrades_content)

func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Missing data file: %s" % path)
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Unable to read data file: %s" % path)
		return {}

	var parsed_value: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed_value) != TYPE_DICTIONARY:
		push_warning("Expected dictionary JSON at %s" % path)
		return {}

	var parsed: Dictionary = parsed_value
	return parsed

func _sync_resource_displays() -> void:
	var visible_ids: Array[String] = game_state.get_visible_counter_element_ids()
	if resource_display_ids != visible_ids:
		for child in resource_list.get_children():
			child.queue_free()

		resource_displays.clear()
		resource_display_ids = visible_ids.duplicate()

		for element_id in resource_display_ids:
			var display := CurrencyDisplay.new()
			display.configure(game_state, element_id)
			display.add_theme_font_size_override("font_size", 28)
			resource_list.add_child(display)
			resource_displays[element_id] = display

	for element_id in resource_display_ids:
		var display: CurrencyDisplay = resource_displays[element_id]
		display.refresh()

func _sync_upgrade_buttons() -> void:
	var upgrade_ids: Array[String] = game_state.get_upgrade_ids()
	if upgrade_button_ids != upgrade_ids:
		for child in upgrade_list.get_children():
			child.queue_free()

		upgrade_buttons.clear()
		upgrade_button_ids = upgrade_ids.duplicate()

		for upgrade_id in upgrade_button_ids:
			var button := UpgradeButton.new()
			button.configure(game_state, upgrades_system, upgrade_id)
			button.purchase_requested.connect(_on_upgrade_purchase_requested)
			upgrade_list.add_child(button)
			upgrade_buttons[upgrade_id] = button

	for upgrade_id in upgrade_button_ids:
		var button: UpgradeButton = upgrade_buttons[upgrade_id]
		button.refresh()

func _refresh_ui() -> void:
	_sync_resource_displays()
	_sync_upgrade_buttons()

	var current_element: Dictionary = game_state.get_current_element()
	var current_name := str(current_element.get("name", ""))
	var current_index := int(current_element.get("index", 0))
	var produced_name := game_state.get_resource_name(str(current_element.get("produces", "")))

	var current_icon := _make_element_icon(current_index)
	fuse_button.texture_normal = current_icon
	fuse_button.texture_pressed = current_icon
	fuse_button.texture_hover = current_icon
	fuse_button.texture_disabled = current_icon
	fuse_button.ignore_texture_size = true

	prev_button.disabled = not game_state.has_adjacent_unlocked_element(-1)
	next_button.disabled = not game_state.has_adjacent_unlocked_element(1)

	menu_title.text = "Upgrade Menu"
	menu_info.text = "Current: %s\nProduces: %s\nParticle Smasher: %.2f actions/sec" % [
		current_name,
		produced_name,
		upgrades_system.get_auto_smashes_per_second(game_state)
	]

	var next_unlock: Dictionary = game_state.get_next_unlock_element()
	if next_unlock.is_empty():
		unlock_button.text = "All elements unlocked"
		unlock_button.disabled = true
	else:
		var unlock_id := str(next_unlock.get("id", ""))
		var unlock_cost: DigitMaster = next_unlock["cost"]
		unlock_button.text = "Unlock %s for %s %s" % [
			str(next_unlock.get("name", unlock_id)),
			unlock_cost.big_to_short_string(),
			game_state.get_resource_name(unlock_id)
		]
		unlock_button.disabled = not game_state.can_unlock_next()

func _autosave_if_needed() -> void:
	if game_state.tick_count - game_state.last_save_tick < AUTO_SAVE_INTERVAL_TICKS:
		return
	if SaveManager.save_state(game_state):
		game_state.last_save_tick = game_state.tick_count

func _make_element_icon(element_index: int) -> AtlasTexture:
	var icon := AtlasTexture.new()
	icon.atlas = ELEMENT_SHEET
	icon.region = Rect2(
		Vector2(element_index * ELEMENT_SHEET_FRAME_SIZE.x, 0),
		Vector2(ELEMENT_SHEET_FRAME_SIZE.x, ELEMENT_SHEET_FRAME_SIZE.y)
	)
	return icon

func _fuse_center() -> Vector2:
	return fuse_button.position + (fuse_button.size * 0.5)

func _random_offscreen_point() -> Vector2:
	var viewport_size := get_viewport_rect().size
	var edge := rng.randi_range(0, 3)
	match edge:
		0:
			return Vector2(rng.randf_range(0.0, viewport_size.x), -OFFSCREEN_MARGIN)
		1:
			return Vector2(rng.randf_range(0.0, viewport_size.x), viewport_size.y + OFFSCREEN_MARGIN)
		2:
			return Vector2(-OFFSCREEN_MARGIN, rng.randf_range(0.0, viewport_size.y))
		_:
			return Vector2(viewport_size.x + OFFSCREEN_MARGIN, rng.randf_range(0.0, viewport_size.y))

func _spawn_outgoing_element(resource_id: String) -> void:
	if not game_state.is_element_id(resource_id):
		return

	var element: Dictionary = game_state.get_element(resource_id)
	var element_index := int(element.get("index", 0))
	var target := _random_offscreen_point()
	var center := _fuse_center()
	var direction := (target - center).normalized()
	var speed := rng.randf_range(PRODUCT_SPEED_MIN, PRODUCT_SPEED_MAX)
	_spawn_particle(_make_element_icon(element_index), center, direction * speed, PRODUCT_PARTICLE_SIZE, "product", "")

func _spawn_proton(target_element_id: String) -> void:
	var proton_start := _random_offscreen_point()
	var center := _fuse_center()
	var direction := (center - proton_start).normalized()
	var speed := rng.randf_range(PROTON_SPEED_MIN, PROTON_SPEED_MAX)
	_spawn_particle(_make_element_icon(0), proton_start, direction * speed, PROTON_PARTICLE_SIZE, "proton", target_element_id)

func _spawn_particle(texture: Texture2D, center_position: Vector2, velocity: Vector2, icon_size: float, kind: String, target_element_id: String) -> void:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.size = Vector2(icon_size, icon_size)
	rect.position = center_position - (rect.size * 0.5)
	effects_layer.add_child(rect)

	visual_particles.append({
		"node": rect,
		"velocity": velocity,
		"kind": kind,
		"target_element_id": target_element_id
	})

func _update_particles(delta: float) -> void:
	if visual_particles.is_empty():
		return

	var viewport_size := get_viewport_rect().size
	for i in range(visual_particles.size() - 1, -1, -1):
		var particle: Dictionary = visual_particles[i]
		var node: TextureRect = particle["node"]
		var velocity: Vector2 = particle["velocity"]
		node.position += velocity * delta

		if str(particle.get("kind", "")) == "proton" and _is_particle_colliding_with_fuse(node):
			var result: Dictionary = element_system.resolve_auto_smash(game_state, str(particle.get("target_element_id", "")))
			if not result.is_empty():
				_pulse_fuse_element()
				_spawn_outgoing_element(str(result.get("produced_resource_id", "")))
				_refresh_ui()
			_remove_particle_at(i)
			continue

		if _is_offscreen(node, viewport_size):
			_remove_particle_at(i)

func _is_particle_colliding_with_fuse(node: TextureRect) -> bool:
	var particle_center := node.position + (node.size * 0.5)
	return particle_center.distance_to(_fuse_center()) <= FUSE_COLLISION_RADIUS

func _is_offscreen(node: TextureRect, viewport_size: Vector2) -> bool:
	return node.position.x > viewport_size.x + OFFSCREEN_MARGIN \
		or node.position.x + node.size.x < -OFFSCREEN_MARGIN \
		or node.position.y > viewport_size.y + OFFSCREEN_MARGIN \
		or node.position.y + node.size.y < -OFFSCREEN_MARGIN

func _remove_particle_at(index: int) -> void:
	var particle: Dictionary = visual_particles[index]
	var node: TextureRect = particle["node"]
	if is_instance_valid(node):
		node.queue_free()
	visual_particles.remove_at(index)

func _on_tick_processed(_tick_count: int) -> void:
	_refresh_ui()
	_autosave_if_needed()

func _on_manual_smash_resolved(result: Dictionary) -> void:
	_pulse_fuse_element()
	_spawn_outgoing_element(str(result.get("produced_resource_id", "")))
	_refresh_ui()

func _on_auto_smash_requested(target_element_id: String) -> void:
	_spawn_proton(target_element_id)

func _on_prev_pressed() -> void:
	tick_system.enqueue_action("select_adjacent", {"direction": -1})

func _on_smash_pressed() -> void:
	tick_system.enqueue_action("manual_smash")

func _on_next_pressed() -> void:
	tick_system.enqueue_action("select_adjacent", {"direction": 1})

func _on_menu_pressed() -> void:
	menu_overlay.visible = not menu_overlay.visible
	_refresh_ui()

func _on_unlock_pressed() -> void:
	tick_system.enqueue_action("unlock_next")

func _on_upgrade_purchase_requested(upgrade_id: String) -> void:
	tick_system.enqueue_action("purchase_upgrade", {"id": upgrade_id})

func _pulse_fuse_element() -> void:
	if not is_instance_valid(fuse_button):
		return

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(fuse_button, "scale", Vector2(0.9, 0.9), 0.06)
	tween.tween_property(fuse_button, "scale", Vector2.ONE, 0.08)
