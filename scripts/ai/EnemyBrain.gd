extends RefCounted
class_name EnemyBrain

static func steer(flat: Vector3, blocked: bool) -> Vector3:
	if flat.length_squared() < 0.001:
		return Vector3.ZERO
	var dir := flat.normalized()
	if blocked:
		dir = Vector3(-dir.z, 0.0, dir.x)
	return dir


static func detect_range(base: float, suit_multiplier: float, camouflaged: bool) -> float:
	if camouflaged:
		return 0.0
	return base * suit_multiplier
