extends RefCounted

class_name AtomEffectsController

const OFFSCREEN_MARGIN := 96.0
const PRODUCT_PARTICLE_SIZE := 52.0
const PRODUCT_PARTICLE_MAX_SCALE := 2.6
const PRODUCT_SPEED_MIN := 210.0
const PRODUCT_SPEED_MAX := 320.0
const PRODUCT_MAX_AGE := 2.3
const PRODUCT_FADE_START_RATIO := 0.93
const PROTON_BASE_SIZE := 56.0
const PROTON_MAX_SCALE := 2.8
const PROTON_SPEED_MIN := 260.0
const PROTON_SPEED_MAX := 360.0
const PROTON_SPEED_VARIATION := 0.15
const AUTO_SMASH_SOFT_VISUAL_CAP := 250
const TOTAL_VISUAL_HARD_CAP := 300
const MAX_PRODUCT_VISUALS_PER_RESOURCE := 4
const OVERFLOW_NEW_VISUAL_CHANCE_MAX := 0.30
const OVERFLOW_NEW_VISUAL_CHANCE_MIN := 0.12
const MERGE_CANDIDATE_SAMPLE_SIZE := 3

class EffectCanvas extends Control:
	var controller: AtomEffectsController

	func _draw() -> void:
		if controller != null:
			controller._draw_effects(self)

var _game_state: GameState
var _element_system: ElementSystem
var _upgrades_system: UpgradesSystem
var _effects_layer: Control
var _fuse_button: TextureButton
var _icon_cache: GameIconCache
var _canvas: EffectCanvas
var _proton_texture: Texture2D
var _proton_batches: Array[Dictionary] = []
var _product_particles: Array[Dictionary] = []
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
	_proton_texture = _icon_cache.get_element_icon(0)
	_ensure_canvas()
	_queue_redraw()

func clear() -> void:
	_proton_batches.clear()
	_product_particles.clear()
	_queue_redraw()

func flush_pending_hits() -> int:
	var resolved_count := 0
	for batch in _proton_batches:
		for result_variant in _extract_pending_results(batch):
			var result: Dictionary = result_variant
			if result.is_empty():
				continue
			_element_system.apply_deferred_auto_smash_result(_game_state, result)
			resolved_count += 1
	_proton_batches.clear()
	_product_particles.clear()
	_queue_redraw()
	return resolved_count

func spawn_manual_result(result: Dictionary) -> void:
	if result.is_empty():
		return
	var spawn_target := _random_offscreen_point()
	var spawn_direction := (spawn_target - _fuse_center()).normalized()
	if spawn_direction == Vector2.ZERO:
		spawn_direction = Vector2.RIGHT
	var spawn_point := _fuse_center() + (_fuse_radius() * spawn_direction)
	var manual_results: Array[Dictionary] = [result]
	_spawn_result_particles(manual_results, spawn_point)
	_queue_redraw()

func queue_auto_smash_results(results: Array[Dictionary]) -> void:
	for result_variant in results:
		var result: Dictionary = result_variant
		if result.is_empty():
			continue
		_queue_auto_smash_result(result)
	_queue_redraw()

func update(delta: float) -> int:
	if _effects_layer == null or _fuse_button == null:
		return 0
	if _proton_batches.is_empty() and _product_particles.is_empty():
		return 0

	var viewport_size := _effects_layer.get_viewport_rect().size
	var resolved_count := 0

	for i in range(_proton_batches.size() - 1, -1, -1):
		var batch := _proton_batches[i]
		var position: Vector2 = batch.get("position", Vector2.ZERO)
		var velocity: Vector2 = batch.get("velocity", Vector2.ZERO)
		position += velocity * delta
		batch["position"] = position
		_proton_batches[i] = batch

		if _has_proton_hit_fuse(batch):
			var collision_point := _get_proton_collision_point(batch)
			resolved_count += _resolve_proton_batch(batch, collision_point)
			_proton_batches.remove_at(i)

	for i in range(_product_particles.size() - 1, -1, -1):
		var particle := _product_particles[i]
		var position: Vector2 = particle.get("position", Vector2.ZERO)
		var velocity: Vector2 = particle.get("velocity", Vector2.ZERO)
		var age := float(particle.get("age", 0.0)) + delta
		position += velocity * delta
		particle["position"] = position
		particle["age"] = age
		if age >= float(particle.get("max_age", PRODUCT_MAX_AGE)) or _is_offscreen(position, float(particle.get("size", PRODUCT_PARTICLE_SIZE)), viewport_size):
			_product_particles.remove_at(i)
			continue
		_product_particles[i] = particle

	_queue_redraw()
	return resolved_count

func _ensure_canvas() -> void:
	if _effects_layer == null:
		return
	if is_instance_valid(_canvas):
		if _canvas.get_parent() != _effects_layer:
			if _canvas.get_parent() != null:
				_canvas.get_parent().remove_child(_canvas)
			_effects_layer.add_child(_canvas)
	else:
		_canvas = EffectCanvas.new()
		_canvas.name = "BatchedEffectsCanvas"
		_canvas.controller = self
		_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_effects_layer.add_child(_canvas)
	_canvas.visible = true

func _queue_auto_smash_result(result: Dictionary) -> void:
	if _should_spawn_new_proton_visual():
		_ensure_visual_capacity(1)
		_spawn_proton_batch(result)
		return
	_merge_auto_smash_into_existing_batch(result)

func _should_spawn_new_proton_visual() -> bool:
	if _proton_batches.is_empty():
		return true

	var active_count := _active_visual_count()
	if active_count < AUTO_SMASH_SOFT_VISUAL_CAP:
		return true
	if active_count >= TOTAL_VISUAL_HARD_CAP:
		return false

	var overflow_ratio := float(active_count - AUTO_SMASH_SOFT_VISUAL_CAP) / float(maxi(1, TOTAL_VISUAL_HARD_CAP - AUTO_SMASH_SOFT_VISUAL_CAP))
	var spawn_chance := lerpf(OVERFLOW_NEW_VISUAL_CHANCE_MAX, OVERFLOW_NEW_VISUAL_CHANCE_MIN, clampf(overflow_ratio, 0.0, 1.0))
	return _rng.randf() < spawn_chance

func _spawn_proton_batch(result: Dictionary) -> void:
	var proton_start := _random_offscreen_point()
	var center := _fuse_center()
	var direction := (center - proton_start).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	var speed_variation := _rng.randf_range(1.0 - PROTON_SPEED_VARIATION, 1.0 + PROTON_SPEED_VARIATION)
	var speed := _rng.randf_range(PROTON_SPEED_MIN, PROTON_SPEED_MAX) * speed_variation
	_proton_batches.append({
		"position": proton_start,
		"velocity": direction * speed,
		"size": _get_proton_visual_size(1),
		"weight": 1,
		"pending_results": _wrap_result(result)
	})

func _merge_auto_smash_into_existing_batch(result: Dictionary) -> void:
	if _proton_batches.is_empty():
		_ensure_visual_capacity(1)
		_spawn_proton_batch(result)
		return

	var target_index := _pick_merge_target_index()
	var batch := _proton_batches[target_index]
	var pending_results := _extract_pending_results(batch)
	pending_results.append(result)
	var new_weight := maxi(1, int(batch.get("weight", 1)) + 1)
	batch["pending_results"] = pending_results
	batch["weight"] = new_weight
	_proton_batches[target_index] = batch

func _pick_merge_target_index() -> int:
	var best_index := 0
	var best_weight := INF
	for _sample_index in range(mini(MERGE_CANDIDATE_SAMPLE_SIZE, _proton_batches.size())):
		var candidate_index := _rng.randi_range(0, _proton_batches.size() - 1)
		var candidate_batch: Dictionary = _proton_batches[candidate_index]
		var candidate_weight := float(candidate_batch.get("weight", 1))
		if candidate_weight < best_weight:
			best_index = candidate_index
			best_weight = candidate_weight
	return best_index

func _resolve_proton_batch(batch: Dictionary, collision_point: Vector2) -> int:
	var resolved_count := 0
	var pending_results := _extract_pending_results(batch)
	for result_variant in pending_results:
		var result: Dictionary = result_variant
		if result.is_empty():
			continue
		_element_system.apply_deferred_auto_smash_result(_game_state, result)
		resolved_count += 1
	_spawn_result_particles(pending_results, collision_point)
	return resolved_count

func _spawn_result_particles(results: Array[Dictionary], spawn_center: Vector2) -> void:
	var grouped_results := {}
	for result_variant in results:
		var result: Dictionary = result_variant
		if result.is_empty():
			continue
		var variant := str(result.get("variant", GameIconCache.VARIANT_NORMAL))
		var resource_counts: Dictionary = result.get("resource_counts", {})
		for resource_id_variant in resource_counts.keys():
			var resource_id := str(resource_id_variant)
			var count := maxi(0, int(resource_counts[resource_id_variant]))
			if resource_id.is_empty() or count <= 0:
				continue
			var key := "%s::%s" % [resource_id, variant]
			if not grouped_results.has(key):
				grouped_results[key] = {
					"resource_id": resource_id,
					"variant": variant,
					"count": 0
				}
			var grouped_entry: Dictionary = grouped_results[key]
			grouped_entry["count"] = int(grouped_entry.get("count", 0)) + count
			grouped_results[key] = grouped_entry

	for grouped_entry_variant in grouped_results.values():
		var grouped_entry: Dictionary = grouped_entry_variant
		_spawn_outgoing_elements_from_count(
			str(grouped_entry.get("resource_id", "")),
			spawn_center,
			str(grouped_entry.get("variant", GameIconCache.VARIANT_NORMAL)),
			maxi(0, int(grouped_entry.get("count", 0)))
		)

func _spawn_outgoing_elements_from_count(resource_id: String, spawn_center: Vector2, variant: String, count: int) -> void:
	if count <= 0 or not _game_state.is_element_id(resource_id):
		return

	var element := _game_state.get_element_state(resource_id)
	if element == null:
		return

	var available_slots := maxi(0, TOTAL_VISUAL_HARD_CAP - _active_visual_count())
	if available_slots <= 0:
		return

	var visual_count := mini(count, MAX_PRODUCT_VISUALS_PER_RESOURCE)
	visual_count = mini(visual_count, available_slots)
	if visual_count <= 0:
		return

	var texture := _icon_cache.get_element_icon_for_variant(element.index, variant)
	var weight_per_visual := float(count) / float(visual_count)
	for _i in range(visual_count):
		var target := _random_offscreen_point()
		var direction := (target - spawn_center).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var speed := _rng.randf_range(PRODUCT_SPEED_MIN, PRODUCT_SPEED_MAX)
		var size := clampf(
			PRODUCT_PARTICLE_SIZE * sqrt(maxf(1.0, weight_per_visual)),
			PRODUCT_PARTICLE_SIZE,
			PRODUCT_PARTICLE_SIZE * PRODUCT_PARTICLE_MAX_SCALE
		)
		_product_particles.append({
			"position": spawn_center,
			"velocity": direction * speed,
			"size": size,
			"age": 0.0,
			"max_age": PRODUCT_MAX_AGE,
			"texture": texture
		})

func _draw_effects(canvas: Control) -> void:
	for batch in _proton_batches:
		_draw_particle(
			canvas,
			_proton_texture,
			Vector2(batch.get("position", Vector2.ZERO)),
			float(batch.get("size", PROTON_BASE_SIZE)),
			Color.WHITE
		)

	for particle in _product_particles:
		var age := float(particle.get("age", 0.0))
		var max_age := maxf(0.001, float(particle.get("max_age", PRODUCT_MAX_AGE)))
		var fade_start_age := max_age * PRODUCT_FADE_START_RATIO
		var alpha := 1.0
		if age > fade_start_age:
			alpha = 1.0 - clampf((age - fade_start_age) / maxf(0.001, max_age - fade_start_age), 0.0, 1.0)
		var texture: Texture2D = particle.get("texture", _proton_texture)
		_draw_particle(
			canvas,
			texture,
			Vector2(particle.get("position", Vector2.ZERO)),
			float(particle.get("size", PRODUCT_PARTICLE_SIZE)),
			Color(1, 1, 1, clampf(alpha, 0.0, 1.0))
		)

func _draw_particle(canvas: Control, texture: Texture2D, center_position: Vector2, size: float, modulate: Color) -> void:
	if canvas == null or texture == null or size <= 0.0:
		return

	var rect := Rect2(center_position - (Vector2.ONE * size * 0.5), Vector2.ONE * size)
	var atlas_texture := texture as AtlasTexture
	if atlas_texture != null:
		canvas.draw_texture_rect_region(atlas_texture.atlas, rect, atlas_texture.region, modulate, false)
		return
	canvas.draw_texture_rect(texture, rect, false, modulate)

func _active_visual_count() -> int:
	return _proton_batches.size() + _product_particles.size()

func _wrap_result(result: Dictionary) -> Array[Dictionary]:
	var wrapped_results: Array[Dictionary] = []
	if not result.is_empty():
		wrapped_results.append(result)
	return wrapped_results

func _extract_pending_results(batch: Dictionary) -> Array[Dictionary]:
	var pending_results: Array[Dictionary] = []
	var raw_results: Array = batch.get("pending_results", [])
	for result_variant in raw_results:
		if typeof(result_variant) != TYPE_DICTIONARY:
			continue
		pending_results.append(result_variant)
	return pending_results

func _ensure_visual_capacity(slots_needed: int) -> void:
	while _active_visual_count() + slots_needed > TOTAL_VISUAL_HARD_CAP and not _product_particles.is_empty():
		_product_particles.remove_at(0)

func _get_proton_visual_size(weight: int) -> float:
	var scaled_size := PROTON_BASE_SIZE * sqrt(float(maxi(1, weight)))
	return clampf(scaled_size, PROTON_BASE_SIZE, PROTON_BASE_SIZE * PROTON_MAX_SCALE)

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

func _get_proton_collision_point(batch: Dictionary) -> Vector2:
	var particle_center: Vector2 = batch.get("position", Vector2.ZERO)
	var fuse_center := _fuse_center()
	var offset := particle_center - fuse_center
	var distance := offset.length()
	var particle_radius := float(batch.get("size", PROTON_BASE_SIZE)) * 0.5
	var fuse_radius := _fuse_radius()
	if distance == 0.0:
		return fuse_center + Vector2.RIGHT * fuse_radius
	return fuse_center + offset.normalized() * fuse_radius

func _has_proton_hit_fuse(batch: Dictionary) -> bool:
	var particle_center: Vector2 = batch.get("position", Vector2.ZERO)
	var fuse_center := _fuse_center()
	var distance := (particle_center - fuse_center).length()
	var particle_radius := float(batch.get("size", PROTON_BASE_SIZE)) * 0.5
	return distance <= _fuse_radius() + particle_radius

func _is_offscreen(center_position: Vector2, size: float, viewport_size: Vector2) -> bool:
	var half_size := size * 0.5
	return center_position.x - half_size > viewport_size.x + OFFSCREEN_MARGIN \
		or center_position.x + half_size < -OFFSCREEN_MARGIN \
		or center_position.y - half_size > viewport_size.y + OFFSCREEN_MARGIN \
		or center_position.y + half_size < -OFFSCREEN_MARGIN

func _queue_redraw() -> void:
	if is_instance_valid(_canvas):
		_canvas.queue_redraw()
