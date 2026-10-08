extends Node
class_name WebSwingController

signal attached(point: Vector3)
signal released(speed: float)
signal caught
signal web_snapped
signal zip_started
signal zip_finished
signal slingshot_launched(speed: float)

var solver := SwingSolver.new()
var active: bool = false
var zipping: bool = false
var charging: bool = false
var charge: float = 0.0
var anchor_point: Vector3 = Vector3.ZERO
var anchor_normal: Vector3 = Vector3.UP
var anchor_body: Node3D
var anchor_local: Vector3 = Vector3.ZERO
var wrap_points: PackedVector3Array = PackedVector3Array()
var zip_point: Vector3 = Vector3.ZERO
var zip_normal: Vector3 = Vector3.UP
var hand_offset: Vector3 = Vector3(0.35, 1.15, 0.2)

var _body: CharacterBody3D


func setup(body: CharacterBody3D) -> void:
	_body = body
	solver.configure(GameState.pump_multiplier(), GameState.reel_multiplier())


func try_attach(target: Dictionary) -> bool:
	if _body == null or target.is_empty() or target.get("collider") == null:
		return false
	if str(target.get("mode", "")) != "swing":
		return false
	if not _confirm_hit(target.point, target.collider):
		return false
	_set_anchor(target)
	wrap_points = PackedVector3Array()
	solver.anchor = anchor_point
	solver.rope_length = SwingSolver.catch_rope(_body.global_position, anchor_point, _body.velocity)
	solver.taut = false
	active = true
	zipping = false
	charging = false
	charge = 0.0
	attached.emit(anchor_point)
	AudioManager.play_at("web_thwip", anchor_point, -2.0)
	Haptics.pulse(36, 0.55)
	_pin_chunk(anchor_point)
	return true


func start_zip(target: Dictionary) -> bool:
	if _body == null or target.is_empty() or target.get("collider") == null:
		return false
	if not _confirm_hit(target.point, target.collider):
		return false
	if active:
		release(false)
	zip_point = target.point + target.normal * 1.35
	zip_normal = target.normal
	zipping = true
	active = false
	zip_started.emit()
	AudioManager.play_at("web_thwip", _body.global_position, -4.0)
	Haptics.pulse(28, 0.4)
	return true


func release(perfect_bonus: bool) -> void:
	if _body == null:
		active = false
		zipping = false
		charging = false
		return
	if not active and not zipping and not charging:
		return
	var speed := _body.velocity.length()
	if perfect_bonus and active and _body.velocity.y > 0.4 and speed > 18.0:
		var boost_dir := _body.velocity.normalized()
		_body.velocity += boost_dir * speed * 0.06
		_body.velocity.y += 0.7
	active = false
	zipping = false
	charging = false
	charge = 0.0
	anchor_body = null
	wrap_points = PackedVector3Array()
	solver.taut = false
	released.emit(_body.velocity.length())
	AudioManager.play("web_release", -6.0)
	Haptics.pulse(18, 0.25)
	_pin_chunk(Vector3.ZERO)


func begin_slingshot() -> void:
	if not active:
		return
	charging = true
	charge = 0.0


func launch_slingshot(aim: Vector3) -> void:
	if _body == null or not active:
		return
	var speed := _body.velocity.length()
	var dir := aim
	if dir.length_squared() < 0.01:
		dir = MathUtil.safe_normalize(_body.velocity, -_body.global_transform.basis.z)
	dir.y = maxf(dir.y, 0.18)
	dir = dir.normalized()
	var launch := 26.0 + charge * 24.0 + speed * 0.35
	release(false)
	_body.velocity = dir * launch
	slingshot_launched.emit(launch)
	Haptics.pulse(50, 0.8)
	AudioManager.play("web_release", 1.0)


func apply_forces(delta: float, wish: Vector3, reel: float) -> void:
	if _body == null or not active:
		return
	_refresh_anchor()
	if not active:
		return
	solver.configure(GameState.pump_multiplier(), GameState.reel_multiplier())
	if charging:
		reel = 1.0
		charge = minf(1.0, charge + delta / 0.72)
		_body.velocity *= 1.0 - delta * 0.4
	solver.anchor = _effective_anchor()
	_body.velocity = solver.integrate_velocity(_body.global_position, _body.velocity, delta, wish, reel)


func apply_constraint() -> void:
	if _body == null or not active:
		return
	solver.anchor = _effective_anchor()
	var result := solver.constrain(_body.global_position, _body.velocity)
	_body.global_position = result.position
	_body.velocity = result.velocity
	if solver.caught_this_step:
		caught.emit()
		AudioManager.play_at("web_catch", anchor_point, -3.0)
		Haptics.pulse(26, 0.5)
	if _body.global_position.distance_to(solver.anchor) > solver.rope_length * 1.55:
		web_snapped.emit()
		release(false)


func apply_zip(delta: float) -> void:
	if _body == null or not zipping:
		return
	var to_target := zip_point - _body.global_position
	var dist := to_target.length()
	if dist < 2.4:
		_finish_zip()
		return
	var dir := to_target / dist
	var desired_speed := clampf(maxf(_body.velocity.length(), 34.0), 34.0, 52.0)
	var desired := dir * desired_speed
	var blend := 1.0 - exp(-10.0 * delta)
	_body.velocity = _body.velocity.lerp(desired, blend)
	if _body.velocity.length() < 50.0:
		_body.velocity += dir * 42.0 * delta
	if dist < 8.0:
		_body.velocity = _body.velocity.lerp(dir * minf(_body.velocity.length(), dist / maxf(delta, 0.016)), 0.35)


func update_wrap() -> void:
	if _body == null or not active:
		return
	var world := _body.get_world_3d()
	if world == null:
		return
	var space := world.direct_space_state
	var player_pos := _body.global_position + Vector3.UP * 1.1
	var origin := _effective_anchor()
	var query := PhysicsRayQueryParameters3D.create(origin, player_pos)
	query.collision_mask = PhysLayers.WORLD
	query.exclude = [_body.get_rid()]
	query.hit_from_inside = false
	var hit := space.intersect_ray(query)
	if not hit.is_empty() and wrap_points.size() < 4:
		var hit_pos: Vector3 = hit.position + hit.normal * 0.18
		if hit_pos.distance_to(player_pos) > 1.25 and hit_pos.distance_to(origin) > 0.45:
			wrap_points.append(hit_pos)
			solver.anchor = hit_pos
			solver.rope_length = maxf(solver.min_rope, hit_pos.distance_to(_body.global_position))
			solver.taut = true
			return
	if wrap_points.is_empty():
		return
	var prev := anchor_point if wrap_points.size() == 1 else wrap_points[wrap_points.size() - 2]
	var clear := PhysicsRayQueryParameters3D.create(prev, player_pos)
	clear.collision_mask = PhysLayers.WORLD
	clear.exclude = [_body.get_rid()]
	if space.intersect_ray(clear).is_empty():
		wrap_points.resize(wrap_points.size() - 1)
		var restored := anchor_point if wrap_points.is_empty() else wrap_points[wrap_points.size() - 1]
		solver.anchor = restored
		solver.rope_length = maxf(solver.rope_length, restored.distance_to(_body.global_position))


func rope_points(hand: Vector3) -> PackedVector3Array:
	var points := PackedVector3Array()
	if active:
		points.append(anchor_point)
		for wrap in wrap_points:
			points.append(wrap)
		points.append(hand)
	elif zipping:
		points.append(hand)
		points.append(zip_point)
	return points


func _finish_zip() -> void:
	if _body == null:
		zipping = false
		return
	var incoming := _body.velocity.length()
	_body.velocity = zip_normal * 6.0 + MathUtil.flatten(_body.velocity).normalized() * minf(incoming * 0.35, 10.0)
	_body.velocity.y = maxf(_body.velocity.y, 4.0)
	zipping = false
	zip_finished.emit()
	Haptics.pulse(22, 0.35)


func _refresh_anchor() -> void:
	if anchor_body == null:
		return
	if not is_instance_valid(anchor_body):
		release(false)
		return
	anchor_point = anchor_body.global_transform * anchor_local
	if wrap_points.is_empty():
		solver.anchor = anchor_point


func _effective_anchor() -> Vector3:
	if wrap_points.is_empty():
		return anchor_point
	return wrap_points[wrap_points.size() - 1]


func _set_anchor(target: Dictionary) -> void:
	anchor_point = target.point
	anchor_normal = target.normal
	anchor_local = target.local_point
	var collider: Object = target.collider
	if collider is Node3D and not collider is StaticBody3D:
		anchor_body = collider
	else:
		anchor_body = null


func _confirm_hit(point: Vector3, collider: Object) -> bool:
	if _body == null or collider == null:
		return false
	var world := _body.get_world_3d()
	if world == null:
		return false
	var from := _body.global_position + Vector3.UP * 1.15
	var to := point + (point - from).normalized() * 0.35
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PhysLayers.ANCHOR_MASK
	query.exclude = [_body.get_rid()]
	query.collide_with_areas = false
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	if hit.collider == collider:
		return true
	return hit.position.distance_to(point) < 1.8


func _pin_chunk(pos: Vector3) -> void:
	var streaming := get_tree().get_first_node_in_group("streaming")
	if streaming and streaming.has_method("pin_world_position"):
		streaming.pin_world_position(pos)
