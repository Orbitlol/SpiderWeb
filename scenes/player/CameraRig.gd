extends Node3D
class_name CameraRig

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var yaw: float = 0.0
var pitch: float = -0.18
var roll: float = 0.0
var fov_kick: float = 0.0
var shake: float = 0.0
var look_sensitivity_mult: float = 1.0

var _body: CharacterBody3D
var _mouse_delta: Vector2 = Vector2.ZERO


func setup(body: CharacterBody3D) -> void:
	_body = body
	top_level = true
	global_position = body.global_position + Vector3.UP * 1.5
	spring_arm.collision_mask = PhysLayers.WORLD | PhysLayers.VEHICLE
	spring_arm.spring_length = 5.2
	camera.current = true
	camera.fov = SettingsManager.fov
	camera.near = 0.08
	camera.far = 800.0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_delta += event.relative


func aim_direction() -> Vector3:
	if camera:
		return -camera.global_transform.basis.z
	return -global_transform.basis.z


func add_fov_kick(amount: float) -> void:
	fov_kick = maxf(fov_kick, amount)


func add_shake(amount: float) -> void:
	if SettingsManager.camera_shake:
		shake = maxf(shake, amount)


func _process(delta: float) -> void:
	if _body == null:
		return
	var sens := 0.0026 * SettingsManager.look_sensitivity * look_sensitivity_mult
	var stick := InputRouter.get_look()
	var invert := -1.0 if SettingsManager.invert_y else 1.0
	yaw -= stick.x * 1.8 * SettingsManager.look_sensitivity * delta
	pitch -= stick.y * 1.4 * SettingsManager.look_sensitivity * invert * delta
	yaw -= _mouse_delta.x * sens
	pitch -= _mouse_delta.y * sens * invert
	yaw -= InputRouter.look_delta.x * sens * 1.15
	pitch -= InputRouter.look_delta.y * sens * invert * 1.15
	_mouse_delta = Vector2.ZERO
	pitch = clampf(pitch, deg_to_rad(-58.0), deg_to_rad(62.0))

	var speed := _body.velocity.length()
	var speed_ratio := clampf(speed / 52.0, 0.0, 1.0)
	var lead := _body.velocity * lerpf(0.04, 0.2, speed_ratio)
	lead.y *= 0.35
	var pivot := _body.global_position + Vector3.UP * 1.45 + lead
	global_position = MathUtil.exp_decay_v(global_position, pivot, 10.0, delta)

	var local_vel := global_transform.basis.inverse() * _body.velocity
	var roll_target := clampf(-local_vel.x / 28.0, -1.0, 1.0) * deg_to_rad(7.5)
	roll = MathUtil.exp_decay(roll, roll_target, 6.0, delta)
	rotation = Vector3(pitch, yaw, roll)

	var desired_len := lerpf(4.7, 8.0, speed_ratio)
	spring_arm.spring_length = MathUtil.exp_decay(spring_arm.spring_length, desired_len, 4.0, delta)
	fov_kick = move_toward(fov_kick, 0.0, delta * 18.0)
	var desired_fov := SettingsManager.fov + speed_ratio * 16.0 + fov_kick
	camera.fov = MathUtil.exp_decay(camera.fov, desired_fov, 5.0, delta)

	shake = move_toward(shake, 0.0, delta * 2.2)
	if shake > 0.01 and SettingsManager.camera_shake:
		camera.h_offset = randf_range(-1.0, 1.0) * shake * 0.08
		camera.v_offset = randf_range(-1.0, 1.0) * shake * 0.05
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
