extends Node
class_name WallMovement

const RUN_SPEED := 11.5
const RUN_TIME := 1.7
const CRAWL_SPEED := 4.5
const STICK_DISTANCE := 0.55

var run_time_left: float = 0.0
var wall_normal: Vector3 = Vector3.RIGHT
var wall_point: Vector3 = Vector3.ZERO
var crawl_normal: Vector3 = Vector3.UP
var _last_run_normal: Vector3 = Vector3.ZERO


func can_wall_run(body: CharacterBody3D, wish: Vector3) -> bool:
	if body.velocity.length() < 6.5 and wish.length_squared() < 0.2:
		return false
	var hit := _probe(body, wish)
	if hit.is_empty():
		return false
	var normal: Vector3 = hit.normal
	if absf(normal.y) > 0.45:
		return false
	if normal.dot(_last_run_normal) > 0.85 and run_time_left <= 0.0:
		return false
	return true


func start_run(body: CharacterBody3D, wish: Vector3) -> void:
	var hit := _probe(body, wish)
	if hit.is_empty():
		return
	wall_normal = hit.normal
	wall_point = hit.position
	_last_run_normal = wall_normal
	run_time_left = RUN_TIME * GameState.skill_multiplier("wall_run")
	var along := MathUtil.flatten(body.velocity)
	if along.length() < 8.0:
		along = _along_wall(wish if wish.length_squared() > 0.01 else body.velocity, wall_normal) * 9.0
	body.velocity = along.normalized() * maxf(along.length(), 9.0)
	body.velocity.y = maxf(body.velocity.y, 1.5)
	Haptics.pulse(18, 0.3)


func apply_forces(body: CharacterBody3D, delta: float, state: TraversalStateMachine.State, wish: Vector3) -> void:
	if state == TraversalStateMachine.State.WALL_RUN:
		_run(body, delta, wish)
	elif state == TraversalStateMachine.State.WALL_CRAWL or state == TraversalStateMachine.State.PERCH:
		_crawl(body, delta, wish)


func move_crawl(body: CharacterBody3D, delta: float) -> void:
	var hit := _surface_probe(body, -crawl_normal)
	if hit.is_empty():
		return
	crawl_normal = hit.normal
	var target: Vector3 = hit.position + crawl_normal * STICK_DISTANCE
	body.global_position = body.global_position.lerp(target, 1.0 - exp(-18.0 * delta))
	body.velocity = body.velocity.slide(crawl_normal)


func can_crawl(body: CharacterBody3D) -> bool:
	var hit := _surface_probe(body, MathUtil.safe_normalize(wish_from_velocity(body), Vector3.FORWARD))
	if hit.is_empty():
		hit = _surface_probe(body, -body.global_transform.basis.z)
	if hit.is_empty():
		return false
	crawl_normal = hit.normal
	return true


func jump_off(body: CharacterBody3D, from_run: bool) -> void:
	var normal := wall_normal if from_run else crawl_normal
	var along := MathUtil.flatten(body.velocity)
	body.velocity = normal * (8.5 if from_run else 6.0) + Vector3.UP * (10.5 if from_run else 8.0)
	body.velocity += along * 0.35
	run_time_left = 0.0
	if not from_run:
		_last_run_normal = Vector3.ZERO


func _run(body: CharacterBody3D, delta: float, wish: Vector3) -> void:
	run_time_left -= delta
	var probe_dir := -wall_normal
	if wish.length_squared() > 0.04:
		probe_dir = (probe_dir + wish * 0.35).normalized()
	var hit := _ray(body.global_position + Vector3.UP * 1.0, body.global_position + Vector3.UP * 1.0 + probe_dir * 1.1, body)
	if hit.is_empty():
		run_time_left = 0.0
		return
	wall_normal = hit.normal
	wall_point = hit.position
	var along := _along_wall(wish if wish.length_squared() > 0.05 else body.velocity, wall_normal)
	if along.length_squared() < 0.01:
		along = _along_wall(body.velocity, wall_normal)
	var speed := maxf(MathUtil.flatten(body.velocity).length(), RUN_SPEED)
	body.velocity = along.normalized() * speed
	body.velocity.y = lerpf(body.velocity.y, 0.4, 1.0 - exp(-6.0 * delta))
	body.velocity += -wall_normal * 4.0 * delta


func _crawl(body: CharacterBody3D, delta: float, wish: Vector3) -> void:
	var hit := _surface_probe(body, -crawl_normal)
	if not hit.is_empty():
		crawl_normal = hit.normal
	var tangent := wish - crawl_normal * wish.dot(crawl_normal)
	if tangent.length_squared() < 0.01:
		body.velocity = body.velocity.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))
	else:
		body.velocity = tangent.normalized() * CRAWL_SPEED
	body.velocity += -crawl_normal * 3.0


func _along_wall(dir: Vector3, normal: Vector3) -> Vector3:
	var flat := MathUtil.flatten(dir)
	var n := MathUtil.flatten(normal).normalized()
	var tangent := flat - n * flat.dot(n)
	if tangent.length_squared() < 0.01:
		tangent = n.cross(Vector3.UP)
	return tangent


func _probe(body: CharacterBody3D, wish: Vector3) -> Dictionary:
	var origin := body.global_position + Vector3.UP * 1.0
	var dirs: Array[Vector3] = []
	if wish.length_squared() > 0.01:
		dirs.append(wish.normalized())
	var right := Basis(Vector3.UP, body.rotation.y) * Vector3.RIGHT
	dirs.append(right)
	dirs.append(-right)
	dirs.append(MathUtil.safe_normalize(MathUtil.flatten(body.velocity), wish))
	var best: Dictionary = {}
	var best_dist := 1.3
	for dir in dirs:
		if dir.length_squared() < 0.01:
			continue
		var hit := _ray(origin, origin + dir.normalized() * 1.15, body)
		if hit.is_empty():
			continue
		var dist: float = origin.distance_to(hit.position)
		if dist < best_dist and absf(hit.normal.y) < 0.5:
			best = hit
			best_dist = dist
	return best


func _surface_probe(body: CharacterBody3D, dir: Vector3) -> Dictionary:
	var origin := body.global_position + Vector3.UP * 0.9
	var direction := dir.normalized() if dir.length_squared() > 0.01 else Vector3.FORWARD
	return _ray(origin, origin + direction * 1.2, body)


func _ray(from: Vector3, to: Vector3, body: CharacterBody3D) -> Dictionary:
	var space := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PhysLayers.WORLD
	query.exclude = [body.get_rid()]
	return space.intersect_ray(query)


func wish_from_velocity(body: CharacterBody3D) -> Vector3:
	return MathUtil.flatten(body.velocity)
