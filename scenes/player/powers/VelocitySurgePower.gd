extends Node

var time_left: float = 0.0


func activate(body: CharacterBody3D) -> void:
	time_left = 4.0
	var flat := Vector3(body.velocity.x, 0.0, body.velocity.z)
	if flat.length() < 8.0:
		var cam := body.get_node("CameraRig")
		flat = Vector3(-cam.global_transform.basis.z.x, 0.0, -cam.global_transform.basis.z.z) * 8.0
	body.velocity += flat.normalized() * 14.0
	body.velocity.y = maxf(body.velocity.y, 6.0)
	Haptics.pulse(30, 0.4)


func tick(body: CharacterBody3D, delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left -= delta
	var flat := Vector3(body.velocity.x, 0.0, body.velocity.z)
	if flat.length() > 0.5 and flat.length() < 22.0:
		body.velocity += flat.normalized() * 8.0 * delta
