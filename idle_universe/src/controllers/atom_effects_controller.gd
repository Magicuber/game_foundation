extends RefCounted

class_name AtomEffectsController

const OFFSCREEN_MARGIN := 96.0
const PRODUCT_PARTICLE_SIZE := 52.0
const PROTON_PARTICLE_SIZE := 56.0
const PRODUCT_SPEED_MIN := 210.0
const PRODUCT_SPEED_MAX := 320.0
const PROTON_SPEED_MIN := 260.0
const PROTON_SPEED_MAX := 360.0
const PROTON_SPEED_VARIATION := 0.15

var _game_state: GameState
var _element_system: ElementSystem
var _upgrades_system: UpgradesSystem
var _effects_layer: Control
var _fuse_button: TextureButton
var _icon_cache: GameIconCache
var _visual_particles: Array[Dictionary] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _init() -> void:
	_rng.randomize()

func configure(
	effects_layer: Control,
	fuse_button: TextureButton,
	game_state: GameState,
	element_system: ElementSystem,
	upgrades_system: UpgradesSystem,
	icon_cache: GameIconCache
) -> void:
	_effects_layer = effects_layer
	_fuse_button = fuse_button
	_game_state = game_state
	_element_system = element_system
	_upgrades_system = upgrades_system
	_icon_cache = icon_cache

func clear() -> void:
	for particle in _visual_particles:
		var node: TextureRect = particle.get("node", null)
		if is_instance_valid(node):
			node.queue_free()
	_visual_particles.clear()

func spawn_manual_result(result: Dictionary) -> void:
	var spawn_target := _random_offscreen_point()
	var spawn_direction := (spawn_target - _fuse_center()).normalized()
	if spawn_direction == Vector2.ZERO:
		spawn_direction = Vector2.RIGHT
	var spawn_point := _fuse_center() + (_fuse_radius() * spawn_direction)
	_spawn_result_particles(result, spawn_point)

func spawn_auto_smashes(target_element_id: String, spawn_count: int) -> void:
	for _i in range(spawn_count):
		_spawn_proton(target_element_id)

func update(delta: float) -> int:
	if _visual_particles.is_empty():
		return 0

	var viewport_size := _effects_layer.get_viewport_rect().size
	var resolved_count := 0
	for i in range(_visual_particles.size() - 1, -1, -1):
		var particle: Dictionary = _visual_particles[i]
		var node: TextureRect = particle["node"]
		var velocity: Vector2 = particle["velocity"]
		node.position += velocity * delta

		if str(particle.get("kind", "")) == "proton":
			var collision_point := _get_particle_collision_point(node)
			if collision_point != Vector2.INF:
				var result: Dictionary = _element_system.resolve_auto_smash(
					_game_state,
					_upgrades_system,
					str(particle.get("target_element_id", ""))
				)
				if not result.is_empty():
					_spawn_result_particles(result, collision_point)
					resolved_count += 1
				_remove_particle_at(i)
				continue

		if _is_offscreen(node, viewport_size):
			_remove_particle_at(i)

	return resolved_count

func _spawn_result_particles(result: Dictionary, spawn_center: Vector2) -> void:
	for resource_id in _get_result_resource_ids(result):
		_spawn_outgoing_element(resource_id, spawn_center)

func _spawn_outgoing_element(resource_id: String, spawn_center: Vector2) -> void:
	if not _game_state.is_element_id(resource_id):
		return

	var element := _game_state.get_element_state(resource_id)
	if element == null:
		return
	var element_index := element.index
	var target := _random_offscreen_point()
	var direction := (target - spawn_center).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var speed := _rng.randf_range(PRODUCT_SPEED_MIN, PRODUCT_SPEED_MAX)
	_spawn_particle(_icon_cache.get_element_icon(element_index), spawn_center, direction * speed, PRODUCT_PARTICLE_SIZE, "product", "")

func _spawn_proton(target_element_id: String) -> void:
	var proton_start := _random_offscreen_point()
	var center := _fuse_center()
	var direction := (center - proton_start).normalized()
	var speed_variation := _rng.randf_range(1.0 - PROTON_SPEED_VARIATION, 1.0 + PROTON_SPEED_VARIATION)
	var speed := _rng.randf_range(PROTON_SPEED_MIN, PROTON_SPEED_MAX) * speed_variation
	_spawn_particle(_icon_cache.get_element_icon(0), proton_start, direction * speed, PROTON_PARTICLE_SIZE, "proton", target_element_id)

func _spawn_particle(texture: Texture2D, center_position: Vector2, velocity: Vector2, icon_size: float, kind: String, target_element_id: String) -> void:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.size = Vector2(icon_size, icon_size)
	rect.position = center_position - (rect.size * 0.5)
	_effects_layer.add_child(rect)

	_visual_particles.append({
		"node": rect,
		"velocity": velocity,
		"kind": kind,
		"target_element_id": target_element_id
	})

func _fuse_center() -> Vector2:
	return _fuse_button.position + (_fuse_button.size * 0.5)

func _fuse_radius() -> float:
	return minf(_fuse_button.size.x, _fuse_button.size.y) * 0.5 * _fuse_button.scale.x

func _random_offscreen_point() -> Vector2:
	var viewport_size := _effects_layer.get_viewport_rect().size
	var edge := _rng.randi_range(0, 3)
	match edge:
		0:
			return Vector2(_rng.randf_range(0.0, viewport_size.x), -OFFSCREEN_MARGIN)
		1:
			return Vector2(_rng.randf_range(0.0, viewport_size.x), viewport_size.y + OFFSCREEN_MARGIN)
		2:
			return Vector2(-OFFSCREEN_MARGIN, _rng.randf_range(0.0, viewport_size.y))
		_:
			return Vector2(viewport_size.x + OFFSCREEN_MARGIN, _rng.randf_range(0.0, viewport_size.y))

func _get_particle_collision_point(node: TextureRect) -> Vector2:
	var particle_center := node.position + (node.size * 0.5)
	var fuse_center := _fuse_center()
	var offset := particle_center - fuse_center
	var distance := offset.length()
	var particle_radius: float = minf(node.size.x, node.size.y) * 0.5
	var fuse_radius: float = _fuse_radius()
	if distance > fuse_radius + particle_radius:
		return Vector2.INF
	if distance == 0.0:
		return fuse_center + Vector2.RIGHT * fuse_radius
	return fuse_center + offset.normalized() * fuse_radius

func _is_offscreen(node: TextureRect, viewport_size: Vector2) -> bool:
	return node.position.x > viewport_size.x + OFFSCREEN_MARGIN \
		or node.position.x + node.size.x < -OFFSCREEN_MARGIN \
		or node.position.y > viewport_size.y + OFFSCREEN_MARGIN \
		or node.position.y + node.size.y < -OFFSCREEN_MARGIN

func _remove_particle_at(index: int) -> void:
	var particle: Dictionary = _visual_particles[index]
	var node: TextureRect = particle["node"]
	if is_instance_valid(node):
		node.queue_free()
	_visual_particles.remove_at(index)

func _get_result_resource_ids(result: Dictionary) -> Array[String]:
	var resource_ids: Array[String] = []
	var raw_ids: Variant = result.get("produced_resource_ids", [])
	if typeof(raw_ids) == TYPE_ARRAY:
		for raw_id in raw_ids:
			resource_ids.append(str(raw_id))
	if resource_ids.is_empty():
		var fallback_id := str(result.get("produced_resource_id", ""))
		if not fallback_id.is_empty():
			resource_ids.append(fallback_id)
	return resource_ids
