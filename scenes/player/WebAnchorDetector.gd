extends Node
class_name WebAnchorDetector

const MIN_SWING_DIST := 7.0
const MAX_SWING_DIST := 56.0
const MIN_ZIP_DIST := 4.0

var swing_target: Dictionary = {}
var zip_target: Dictionary = {}
var yank_target: Dictionary = {}

var _scratch := SwingSolver.new()


func update_scan(body: CharacterBody3D, aim: Vector3, velocity: Vector3) -> void:
	swing_target = {}
	zip_target = {}
	yank_target = {}
	var world := body.get_world_3d()
	if world == null:
		return
	var space := world.direct_space_state
	var origin := body.global_position + Vector3.UP * 1.2
	var exclude: Array[RID] = [body.get_rid()]
	var assist := clampf(SettingsManager.swing_assist, 0.0, 1.0)
	var aim_dir := aim.normalized() if aim.length_squared() > 0.001 else Vector3.FORWARD
	var best_swing := -1.0e9
	var best_zip := -1.0e9
	var best_yank := -1.0e9
	for dir in _candidate_dirs(aim_dir, velocity, assist):
		var hit := _ray(space, origin, origin + dir * zip_range(), exclude)
		if not is_valid_hit(hit):
			continue
		var considered := _consider(body, origin, aim_dir, velocity, hit, best_swing, best_zip, best_yank)
		best_swing = considered.x
		best_zip = considered.y
		best_yank = considered.z


func zip_range() -> float:
	return 64.0 * GameState.skill_multiplier("zip_range")


static func is_valid_hit(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	if not hit.has("position") or not hit.has("collider"):
		return false
	return hit.get("collider") != null


static func score_swing(point: Vector3, origin: Vector3, aim: Vector3, velocity: Vector3, normal: Vector3, priority: float) -> float:
	var delta := point - origin
	var dist := delta.length()
	if dist < 0.001:
		return -1000.0
	var dir := delta / dist
	var aim_n := aim.normalized() if aim.length_squared() > 0.001 else dir
	var score := dir.dot(aim_n) * 5.0
	score += dir.dot(Vector3.UP) * 2.4
	if velocity.length() > 8.0:
		score += dir.dot(velocity.normalized()) * 2.2
	score += priority * 0.45
	var up := dir.dot(Vector3.UP)
	if up > 0.88:
		score -= 1.6
	if up < 0.12:
		score -= 2.2
	if normal.dot(-dir) < 0.0:
		score -= 1.2
	score += (1.0 - absf(dist - 28.0) / 40.0) * 1.5
	return score


func _consider(body: CharacterBody3D, origin: Vector3, aim: Vector3, velocity: Vector3, hit: Dictionary, best_swing: float, best_zip: float, best_yank: float) -> Vector3:
	var collider: Object = hit.collider
	if _is_ground(collider):
		return Vector3(best_swing, best_zip, best_yank)
	var point: Vector3 = hit.position
	var normal: Vector3 = hit.normal
	var dist := origin.distance_to(point)
	var mode := _mode_for(collider)
	if mode.is_empty():
		return Vector3(best_swing, best_zip, best_yank)
	var to_point := (point - origin).normalized()
	var aim_align := to_point.dot(aim)
	if mode == "yank" and dist <= 34.0 and aim_align > 0.45:
		var yank_score := aim_align * 4.0 - dist * 0.02
		if yank_score > best_yank:
			best_yank = yank_score
			yank_target = _pack(hit, "yank", yank_score)
	if dist >= MIN_ZIP_DIST and dist <= zip_range() and aim_align > 0.15:
		var zip_score := aim_align * 6.0 - absf(dist - 24.0) * 0.03
		if mode == "yank":
			zip_score += 0.4
		if zip_score > best_zip:
			best_zip = zip_score
			zip_target = _pack(hit, "zip", zip_score)
	if mode == "swing" and dist >= MIN_SWING_DIST and dist <= MAX_SWING_DIST and aim_align > -0.15:
		var rope := SwingSolver.catch_rope(body.global_position, point, velocity)
		if _clears_ground(body.global_position, velocity, point, rope, aim):
			var priority := 0.0
			if collider.has_method("get_meta") and collider.has_meta("anchor_priority"):
				priority = float(collider.get_meta("anchor_priority"))
			var swing_score := score_swing(point, origin, aim, velocity, normal, priority)
			if swing_score > best_swing:
				best_swing = swing_score
				swing_target = _pack(hit, "swing", swing_score)
	return Vector3(best_swing, best_zip, best_yank)


func _clears_ground(position: Vector3, velocity: Vector3, point: Vector3, rope: float, aim: Vector3) -> bool:
	_scratch.anchor = point
	_scratch.rope_length = rope
	_scratch.taut = false
	var wish := Vector3(velocity.x, 0.0, velocity.z)
	if wish.length() < 2.0:
		wish = Vector3(aim.x, 0.0, aim.z)
	if wish.length() < 0.2:
		wish = Vector3(point.x - position.x, 0.0, point.z - position.z)
	wish = wish.normalized() if wish.length() > 0.1 else Vector3.FORWARD
	var min_y := _scratch.predict_min_height(position, velocity, 36, wish)
	return min_y >= 1.2


func _candidate_dirs(aim: Vector3, velocity: Vector3, assist: float) -> Array[Vector3]:
	var dirs: Array[Vector3] = [aim]
	var yaw_spread := lerpf(0.1, 0.42, assist)
	var pitches: Array[float] = [0.0, 0.16, 0.34]
	if assist > 0.4:
		pitches.append(0.52)
	var yaws: Array[float] = [-1.0, 0.0, 1.0]
	if assist > 0.55:
		yaws = [-1.0, -0.5, 0.0, 0.5, 1.0]
	for pitch in pitches:
		for yaw_i in yaws:
			if is_zero_approx(pitch) and is_zero_approx(yaw_i):
				continue
			dirs.append(_offset_dir(aim, yaw_i * yaw_spread, pitch))
	if velocity.length() > 7.0:
		var vel_dir := velocity.normalized()
		dirs.append((vel_dir + Vector3.UP * 0.45).normalized())
		dirs.append((vel_dir + Vector3.UP * 0.85).normalized())
	return dirs


func _offset_dir(forward: Vector3, yaw: float, pitch: float) -> Vector3:
	var flat := Vector3(forward.x, 0.0, forward.z)
	if flat.length_squared() < 0.0001:
		flat = Vector3(0.0, 0.0, -1.0)
	flat = flat.normalized()
	var yawed := Basis(Vector3.UP, yaw) * flat
	var right := yawed.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = Vector3.RIGHT
	right = right.normalized()
	return (Basis(right, pitch) * yawed).normalized()


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PhysLayers.ANCHOR_MASK
	query.exclude = exclude
	query.collide_with_areas = false
	query.hit_from_inside = false
	return space.intersect_ray(query)


func _mode_for(collider: Object) -> String:
	if collider == null or _is_ground(collider):
		return ""
	if collider.is_in_group("web_anchor_character"):
		if collider.has_meta("can_swing_anchor") and bool(collider.get_meta("can_swing_anchor")):
			return "swing"
		return "yank"
	if collider is RigidBody3D and (collider as RigidBody3D).mass < 90.0:
		return "yank"
	return "swing"


func _is_ground(collider: Object) -> bool:
	return collider != null and collider.is_in_group("web_ground")


func _pack(hit: Dictionary, mode: String, score: float) -> Dictionary:
	var collider: Object = hit.collider
	var point: Vector3 = hit.position
	var local_point := Vector3.ZERO
	if collider is Node3D and not collider is StaticBody3D:
		local_point = (collider as Node3D).global_transform.affine_inverse() * point
	var kind := "geometry"
	var priority := 0.0
	if collider.has_meta("anchor_kind"):
		kind = str(collider.get_meta("anchor_kind"))
	if collider.has_meta("anchor_priority"):
		priority = float(collider.get_meta("anchor_priority"))
	return {
		"point": point,
		"normal": hit.normal,
		"collider": collider,
		"mode": mode,
		"kind": kind,
		"score": score,
		"local_point": local_point,
		"priority": priority,
	}
