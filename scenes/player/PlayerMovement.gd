extends Node
class_name PlayerMovement

const RUN_SPEED := 10.5
const GROUND_ACCEL := 48.0
const AIR_ACCEL := 14.0
const JUMP_SPEED := 15.5
const JUMP_HOLD_GRAVITY := 18.0
const FALL_GRAVITY := 32.0
const DIVE_GRAVITY := 52.0
const MAX_FALL := 62.0
const DIVE_MAX_FALL := 74.0

var jump_held_time: float = 0.0
var slide_time: float = 0.0
var was_on_floor: bool = false


func apply_forces(body: CharacterBody3D, delta: float, state: TraversalStateMachine.State, move: Vector2, yaw: float, jump_buffer: float, coyote: float, jump_held: bool) -> bool:
	var wish := MathUtil.camera_relative(move, yaw)
	var grounded := body.is_on_floor() or coyote > 0.0
	var jumped := false
	if state == TraversalStateMachine.State.DIVE:
		body.velocity.y -= DIVE_GRAVITY * delta
		var flat := MathUtil.flatten(body.velocity)
		if wish.length_squared() > 0.01:
			flat = flat.lerp(wish * maxf(flat.length(), 16.0), 1.0 - exp(-2.2 * delta))
		body.velocity.x = flat.x
		body.velocity.z = flat.z
		if body.velocity.y < -DIVE_MAX_FALL:
			body.velocity.y = -DIVE_MAX_FALL
		return false

	if grounded and jump_buffer > 0.0 and state != TraversalStateMachine.State.WALL_CRAWL:
		body.velocity.y = JUMP_SPEED
		jump_held_time = 0.16
		jumped = true
		slide_time = 0.0
		AudioManager.play("jump", -4.0)
	elif jump_held and jump_held_time > 0.0 and body.velocity.y > 0.0:
		jump_held_time -= delta
		body.velocity.y -= JUMP_HOLD_GRAVITY * delta
	else:
		var grav := FALL_GRAVITY
		if body.velocity.y < 0.0:
			grav = FALL_GRAVITY * 1.08
		if not body.is_on_floor():
			body.velocity.y -= grav * delta
		elif body.velocity.y < 0.0:
			body.velocity.y = -0.8

	if body.velocity.y < -MAX_FALL:
		body.velocity.y = -MAX_FALL

	var speed := RUN_SPEED
	if slide_time > 0.0:
		slide_time -= delta
		speed = maxf(RUN_SPEED, MathUtil.flatten(body.velocity).length())
	var accel := GROUND_ACCEL if body.is_on_floor() else AIR_ACCEL
	var flat_vel := MathUtil.flatten(body.velocity)
	var target := wish * speed
	if wish.length_squared() < 0.01:
		if body.is_on_floor() and slide_time <= 0.0:
			flat_vel = flat_vel.move_toward(Vector3.ZERO, 38.0 * delta)
		else:
			flat_vel = flat_vel.lerp(Vector3.ZERO, 1.0 - exp(-0.7 * delta))
	else:
		flat_vel = flat_vel.move_toward(target, accel * delta)
		if not body.is_on_floor():
			flat_vel += wish * 6.0 * delta
	body.velocity.x = flat_vel.x
	body.velocity.z = flat_vel.z
	return jumped


func notify_land(horizontal_speed: float) -> void:
	if horizontal_speed > 16.0:
		slide_time = clampf(horizontal_speed / 40.0, 0.25, 0.7)
	AudioManager.play("land", lerpf(-8.0, -1.0, clampf(horizontal_speed / 30.0, 0.0, 1.0)))
	if horizontal_speed > 10.0:
		Haptics.pulse(16, 0.3)
