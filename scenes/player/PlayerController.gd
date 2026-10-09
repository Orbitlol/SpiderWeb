extends Node
class_name PlayerController

var move: Vector2 = Vector2.ZERO
var jump_buffer: float = 0.0
var coyote: float = 0.0
var web_buffer: float = 0.0
var _mouse_attack: bool = false

var _body: CharacterBody3D
var _state: TraversalStateMachine
var _swing: WebSwingController
var _anchors: WebAnchorDetector
var _movement: PlayerMovement
var _wall: WallMovement
var _camera: CameraRig
var _combat: PlayerCombat
var _vfx: TraversalVFX


func setup(body: CharacterBody3D) -> void:
	_body = body
	_state = body.get_node("StateMachine")
	_swing = body.get_node("WebSystem/WebSwingController")
	_anchors = body.get_node("WebSystem/WebAnchorDetector")
	_movement = body.get_node("MovementSystem")
	_wall = body.get_node("WallMovement")
	_camera = body.get_node("CameraRig")
	_combat = body.get_node("CombatSystem")
	_vfx = body.get_node("VFX")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_mouse_attack = true


func gather(delta: float) -> void:
	move = InputRouter.get_move()
	if InputRouter.just_pressed("jump"):
		jump_buffer = 0.14
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	if _body.is_on_floor():
		coyote = 0.12
	else:
		coyote = maxf(0.0, coyote - delta)
	if _web_just_pressed():
		web_buffer = 0.12
	else:
		web_buffer = maxf(0.0, web_buffer - delta)


func update_state(delta: float) -> void:
	_state.tick(delta)
	var st := _state.state
	if st == TraversalStateMachine.State.HITSTUN and _state.state_time > 0.32:
		_state.transition(TraversalStateMachine.State.GROUNDED if _body.is_on_floor() else TraversalStateMachine.State.AIR)
	if st == TraversalStateMachine.State.ZIP and not _swing.zipping:
		_state.transition(TraversalStateMachine.State.AIR)
	if st == TraversalStateMachine.State.DODGE and _state.state_time > 0.38:
		_state.transition(TraversalStateMachine.State.GROUNDED if _body.is_on_floor() else TraversalStateMachine.State.AIR)

	_handle_web()
	_handle_zip()
	_handle_slingshot()
	_handle_jump_cancel()
	_handle_dive()
	_handle_walls()
	_handle_dodge()
	_handle_floor_transitions()
	if _mouse_attack or InputRouter.just_pressed("attack"):
		_combat.request_attack(false)
	if InputRouter.just_pressed("heavy_attack"):
		_combat.request_attack(true)
	if InputRouter.just_pressed("gadget"):
		_combat.request_gadget()
	if InputRouter.just_pressed("suit_power"):
		_combat.request_power()
	if InputRouter.just_pressed("focus"):
		_body.get_node("FocusSystem").try_activate()
	if InputRouter.just_pressed("interact"):
		_body.get_node("InteractionSystem").try_interact()
	_mouse_attack = false


func wish_dir() -> Vector3:
	return MathUtil.camera_relative(move, _camera.yaw)


func reel_axis() -> float:
	var reel := 0.0
	if InputRouter.is_pressed("reel_in"):
		reel += 1.0
	if InputRouter.is_pressed("reel_out"):
		reel -= 1.0
	return reel


func release_swing(bonus: bool) -> void:
	var points := _swing.rope_points(_body.global_position + Vector3.UP * 1.2)
	_swing.release(bonus)
	if points.size() >= 2:
		_body.get_node("WebSystem/WebRope").spawn_release_trail(points)
	if _state.state == TraversalStateMachine.State.SWING or _state.state == TraversalStateMachine.State.SLINGSHOT:
		_state.transition(TraversalStateMachine.State.AIR)
	_camera.add_fov_kick(4.0)


func _handle_web() -> void:
	var st := _state.state
	var toggle := SettingsManager.web_toggle
	if toggle:
		if web_buffer <= 0.0:
			return
		if st == TraversalStateMachine.State.SWING or st == TraversalStateMachine.State.SLINGSHOT:
			release_swing(true)
			web_buffer = 0.0
			return
	else:
		if _web_released() and (st == TraversalStateMachine.State.SWING or st == TraversalStateMachine.State.SLINGSHOT):
			release_swing(true)
			return
		if not _web_held() and web_buffer <= 0.0:
			return
		if st == TraversalStateMachine.State.SWING or st == TraversalStateMachine.State.ZIP or st == TraversalStateMachine.State.SLINGSHOT:
			return
	if not _anchors.swing_target.is_empty():
		if _body.is_on_floor():
			_body.velocity.y = maxf(_body.velocity.y, 9.0)
		if _swing.try_attach(_anchors.swing_target):
			_state.transition(TraversalStateMachine.State.SWING)
			web_buffer = 0.0
			_camera.add_fov_kick(-3.0)
			return
	if _web_just_pressed() and not _anchors.yank_target.is_empty():
		_combat.yank(_anchors.yank_target)
		web_buffer = 0.0
		return
	if _web_just_pressed():
		_vfx.whiff(_camera.aim_direction(), _body.global_position + Vector3.UP * 1.2)
		web_buffer = 0.0


func _handle_zip() -> void:
	if not InputRouter.just_pressed("web_zip"):
		return
	if _anchors.zip_target.is_empty():
		_vfx.whiff(_camera.aim_direction(), _body.global_position + Vector3.UP * 1.2)
		return
	if _swing.start_zip(_anchors.zip_target):
		_state.transition(TraversalStateMachine.State.ZIP)
		_camera.add_fov_kick(8.0)


func _handle_slingshot() -> void:
	var st := _state.state
	if InputRouter.just_pressed("slingshot"):
		if st != TraversalStateMachine.State.SWING and not _anchors.swing_target.is_empty():
			if _swing.try_attach(_anchors.swing_target):
				_state.transition(TraversalStateMachine.State.SLINGSHOT)
				_swing.begin_slingshot()
		elif st == TraversalStateMachine.State.SWING or st == TraversalStateMachine.State.SLINGSHOT:
			_state.transition(TraversalStateMachine.State.SLINGSHOT)
			_swing.begin_slingshot()
	if st == TraversalStateMachine.State.SLINGSHOT and InputRouter.just_released("slingshot"):
		_swing.launch_slingshot(_camera.aim_direction())
		_state.transition(TraversalStateMachine.State.AIR)
		_camera.add_fov_kick(10.0)


func _handle_jump_cancel() -> void:
	if not InputRouter.just_pressed("jump"):
		return
	var st := _state.state
	if st == TraversalStateMachine.State.SWING or st == TraversalStateMachine.State.SLINGSHOT:
		release_swing(true)
		_body.velocity.y = maxf(_body.velocity.y, 9.5)
	elif st == TraversalStateMachine.State.WALL_RUN:
		_wall.jump_off(_body, true)
		_state.transition(TraversalStateMachine.State.AIR)
	elif st == TraversalStateMachine.State.WALL_CRAWL or st == TraversalStateMachine.State.PERCH:
		_wall.jump_off(_body, false)
		_state.transition(TraversalStateMachine.State.AIR)


func _handle_dive() -> void:
	var st := _state.state
	if _body.is_on_floor():
		return
	var stick_down := move.y < -0.72
	if (InputRouter.just_pressed("dive") or stick_down) and (st == TraversalStateMachine.State.AIR or st == TraversalStateMachine.State.DIVE):
		_state.transition(TraversalStateMachine.State.DIVE)
		_body.velocity.y = minf(_body.velocity.y, -8.0)


func _handle_walls() -> void:
	var st := _state.state
	if st == TraversalStateMachine.State.WALL_RUN and _wall.run_time_left <= 0.0:
		_state.transition(TraversalStateMachine.State.AIR)
		return
	if st == TraversalStateMachine.State.AIR or st == TraversalStateMachine.State.DIVE:
		if _wall.can_wall_run(_body, wish_dir()):
			_wall.start_run(_body, wish_dir())
			_state.transition(TraversalStateMachine.State.WALL_RUN)
			return
	var want_crawl := InputRouter.is_pressed("crawl") or (st == TraversalStateMachine.State.ZIP and not _swing.zipping)
	if InputRouter.is_pressed("crawl") and st != TraversalStateMachine.State.WALL_CRAWL and _wall.can_crawl(_body):
		_state.transition(TraversalStateMachine.State.WALL_CRAWL)
	elif st == TraversalStateMachine.State.WALL_CRAWL and not InputRouter.is_pressed("crawl"):
		_state.transition(TraversalStateMachine.State.AIR)
	if want_crawl and false:
		pass


func _handle_dodge() -> void:
	if not InputRouter.just_pressed("dodge"):
		return
	if _state.state == TraversalStateMachine.State.SWING or _state.state == TraversalStateMachine.State.ZIP:
		return
	if _combat.begin_dodge(wish_dir()):
		_state.transition(TraversalStateMachine.State.DODGE)


func _handle_floor_transitions() -> void:
	var st := _state.state
	var airborne := st == TraversalStateMachine.State.AIR or st == TraversalStateMachine.State.DIVE or st == TraversalStateMachine.State.WALL_RUN or st == TraversalStateMachine.State.DODGE
	if _body.is_on_floor() and airborne and _body.velocity.y <= 0.5:
		_movement.notify_land(MathUtil.flatten(_body.velocity).length())
		_camera.add_shake(clampf(_body.velocity.length() / 40.0, 0.0, 0.4))
		_wall._last_run_normal = Vector3.ZERO
		_state.transition(TraversalStateMachine.State.GROUNDED)
	elif not _body.is_on_floor() and st == TraversalStateMachine.State.GROUNDED:
		_state.transition(TraversalStateMachine.State.AIR)
	if (st == TraversalStateMachine.State.SWING or st == TraversalStateMachine.State.SLINGSHOT) and _body.is_on_floor() and _body.velocity.y <= 0.2:
		if _body.global_position.y < _swing.anchor_point.y - 1.5:
			release_swing(false)
			_movement.slide_time = 0.45


func _web_held() -> bool:
	return InputRouter.is_pressed("web")


func _web_just_pressed() -> bool:
	return InputRouter.just_pressed("web")


func _web_released() -> bool:
	return InputRouter.just_released("web")
