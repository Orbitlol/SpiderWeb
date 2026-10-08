extends RefCounted
class_name SwingSolver

## Pendulum constraint used by the web.
## integrate_velocity() is applied before CharacterBody3D.move_and_slide().
## constrain() runs after the slide so buildings still block the body.
## Prediction and tests use step(), which does both plus a free integration.

var gravity: float = 32.0
var spring_stiffness: float = 160.0
var spring_damping: float = 26.0
var max_stretch_ratio: float = 0.10
var max_spring_accel: float = 70.0
var max_correction: float = 0.36
var pump_accel: float = 14.0
var arc_assist: float = 2.8
var quadratic_drag: float = 0.0085
var linear_drag: float = 0.01
var reel_in_speed: float = 16.0
var reel_out_speed: float = 13.0
var min_rope: float = 5.5
var max_rope: float = 62.0
var angular_conservation: float = 0.8
var speed_cap: float = 58.0
var slack_margin: float = 0.55

var anchor: Vector3 = Vector3.ZERO
var rope_length: float = 20.0
var taut: bool = false
var caught_this_step: bool = false
var stretch: float = 0.0


func configure(pump_mult: float, reel_mult: float) -> void:
	pump_accel = 14.0 * pump_mult
	reel_in_speed = 16.0 * reel_mult
	arc_assist = 2.8 * lerpf(1.0, pump_mult, 0.35)


static func catch_rope(player_pos: Vector3, anchor_pos: Vector3, velocity: Vector3) -> float:
	var dist := player_pos.distance_to(anchor_pos)
	var shorten := minf(2.4, dist * 0.07)
	if player_pos.y < 12.0 or velocity.y < -6.0:
		shorten = clampf(dist * 0.15, 2.4, 6.5)
	return clampf(dist - shorten, 5.5, dist)


func integrate_velocity(position: Vector3, velocity: Vector3, delta: float, wish_dir: Vector3, reel_axis: float) -> Vector3:
	caught_this_step = false
	if delta <= 0.0:
		return velocity
	velocity.y -= gravity * delta
	var to_anchor := anchor - position
	var dist := maxf(to_anchor.length(), 0.001)
	var toward := to_anchor / dist
	stretch = dist - rope_length

	if wish_dir.length_squared() > 0.0025:
		var wish := wish_dir.normalized()
		var tangential_input := wish - toward * wish.dot(toward)
		if tangential_input.length_squared() > 0.0025:
			tangential_input = tangential_input.normalized()
			var radial_speed := velocity.dot(toward)
			var tangential_vel := velocity - toward * radial_speed
			var align := 0.5
			if tangential_vel.length() > 2.5:
				align = 0.3 + 0.7 * maxf(tangential_input.dot(tangential_vel.normalized()), 0.0)
			velocity += tangential_input * pump_accel * align * delta

	if taut:
		var gravity_dir := Vector3(0.0, -1.0, 0.0)
		var gravity_tangent := gravity_dir - toward * gravity_dir.dot(toward)
		if gravity_tangent.length_squared() > 0.0025:
			velocity += gravity_tangent.normalized() * arc_assist * delta

	var speed := velocity.length()
	if speed > 0.2:
		var drag_force := quadratic_drag * speed * speed + linear_drag * speed
		velocity -= velocity / speed * drag_force * delta

	var previous_rope := rope_length
	if reel_axis > 0.0:
		rope_length = maxf(min_rope, rope_length - reel_in_speed * reel_axis * delta)
	elif reel_axis < 0.0:
		rope_length = minf(max_rope, rope_length + reel_out_speed * (-reel_axis) * delta)
	if taut and rope_length < previous_rope - 0.0001:
		var radial_component := velocity.dot(toward)
		var tangential_vel := velocity - toward * radial_component
		var tangential_speed := tangential_vel.length()
		if tangential_speed > 0.3 and rope_length > 0.1:
			var gain := minf((previous_rope / rope_length - 1.0) * angular_conservation, 0.02)
			velocity = toward * radial_component + tangential_vel.normalized() * tangential_speed * (1.0 + gain)

	if stretch > 0.0:
		var outward_speed := -velocity.dot(toward)
		var accel := minf(spring_stiffness * stretch + spring_damping * maxf(outward_speed, 0.0), max_spring_accel)
		velocity += toward * accel * delta

	speed = velocity.length()
	if speed > speed_cap:
		velocity *= speed_cap / speed
	return velocity


func constrain(position: Vector3, velocity: Vector3) -> Dictionary:
	var to_anchor := anchor - position
	var dist := maxf(to_anchor.length(), 0.001)
	var toward := to_anchor / dist
	stretch = dist - rope_length
	if stretch > 0.0:
		if not taut:
			caught_this_step = true
		taut = true
		var max_stretch := maxf(rope_length * max_stretch_ratio, 1.4)
		if stretch > max_stretch:
			var correct := minf(stretch - max_stretch * 0.5, max_correction)
			position += toward * correct
		var outward_speed := -velocity.dot(toward)
		if outward_speed > 0.0:
			velocity += toward * minf(outward_speed, 12.0)
	elif stretch < -slack_margin:
		taut = false
	return {"position": position, "velocity": velocity}


func step(position: Vector3, velocity: Vector3, delta: float, wish_dir: Vector3, reel_axis: float) -> Dictionary:
	velocity = integrate_velocity(position, velocity, delta, wish_dir, reel_axis)
	position += velocity * delta
	return constrain(position, velocity)


func predict_min_height(position: Vector3, velocity: Vector3, frames: int, wish_dir: Vector3) -> float:
	var saved_anchor := anchor
	var saved_rope := rope_length
	var saved_taut := taut
	var min_y := position.y
	var pos := position
	var vel := velocity
	for _i in frames:
		var result := step(pos, vel, 1.0 / 60.0, wish_dir, 0.0)
		pos = result.position
		vel = result.velocity
		min_y = minf(min_y, pos.y)
		if min_y < 0.8:
			break
	anchor = saved_anchor
	rope_length = saved_rope
	taut = saved_taut
	stretch = 0.0
	caught_this_step = false
	return min_y
