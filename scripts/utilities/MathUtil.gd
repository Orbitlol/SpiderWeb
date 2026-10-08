extends RefCounted
class_name MathUtil

static func exp_decay(current: float, target: float, speed: float, delta: float) -> float:
	return lerpf(current, target, 1.0 - exp(-speed * delta))


static func exp_decay_v(current: Vector3, target: Vector3, speed: float, delta: float) -> Vector3:
	var t := 1.0 - exp(-speed * delta)
	return current.lerp(target, t)


static func camera_relative(move: Vector2, yaw: float) -> Vector3:
	var basis := Basis(Vector3.UP, yaw)
	var flat := Vector3(move.x, 0.0, -move.y)
	return (basis * flat).normalized() if flat.length_squared() > 0.0001 else Vector3.ZERO


static func flatten(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


static func safe_normalize(v: Vector3, fallback: Vector3 = Vector3.FORWARD) -> Vector3:
	if v.length_squared() < 0.0001:
		return fallback
	return v.normalized()
