extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal died
signal suit_applied(suit_id: String)



@onready var state_machine: TraversalStateMachine = $StateMachine
@onready var controller: PlayerController = $PlayerController
@onready var movement: PlayerMovement = $MovementSystem
@onready var swing: WebSwingController = $WebSystem/WebSwingController
@onready var anchors: WebAnchorDetector = $WebSystem/WebAnchorDetector
@onready var rope: WebRope = $WebSystem/WebRope
@onready var wall: WallMovement = $WallMovement
@onready var combat: PlayerCombat = $CombatSystem
@onready var sense: SpiderSense = $SpiderSense
@onready var camera_rig: CameraRig = $CameraRig
@onready var animator: WeaverAnimator = $VisualRoot
@onready var vfx: TraversalVFX = $VFX
@onready var interaction: InteractionSystem = $InteractionSystem
@onready var focus: FocusSystem = $FocusSystem
@onready var flow: FlowSystem = $FlowSystem

var health: float = 100.0
var max_health: float = 100.0
var hurt_invuln: float = 0.0
var regen_delay: float = 0.0
var last_safe_position: Vector3 = Vector3(0, 40, 0)
var last_safe_yaw: float = 0.0
var alive: bool = true
var suit_id: String = "classic"
var _save_timer: float = 8.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = PhysLayers.PLAYER
	collision_mask = PhysLayers.PLAYER_MASK_GROUND
	floor_snap_length = 0.28
	floor_max_angle = deg_to_rad(50.0)
	safe_margin = 0.02
	controller.setup(self)
	swing.setup(self)
	camera_rig.setup(self)
	combat.setup(self)
	swing.released.connect(_on_swing_released)
	EventBus.suit_changed.connect(func(id: String) -> void: apply_suit(id))
	EventBus.web_style_changed.connect(func(_style: WebStyleData) -> void: pass)
	apply_suit(GameState.equipped_suit_id)
	last_safe_position = global_position
	var whoosh := get_node_or_null("Audio/Whoosh") as AudioStreamPlayer
	if whoosh and AudioManager.streams.has("whoosh"):
		whoosh.stream = AudioManager.streams["whoosh"]


func _physics_process(delta: float) -> void:
	if not alive:
		return
	hurt_invuln = maxf(0.0, hurt_invuln - delta)
	regen_delay = maxf(0.0, regen_delay - delta)
	if regen_delay <= 0.0 and health < max_health and not combat.in_combat:
		health = minf(max_health, health + 8.0 * delta)
		health_changed.emit(health, max_health)
	controller.gather(delta)
	var aim := camera_rig.aim_direction()
	anchors.update_scan(self, aim, velocity)
	controller.update_state(delta)
	var st := state_machine.state
	_update_mask(st)
	floor_snap_length = 0.0 if swing.active or swing.zipping else 0.28
	match st:
		TraversalStateMachine.State.SWING, TraversalStateMachine.State.SLINGSHOT:
			swing.apply_forces(delta, controller.wish_dir(), controller.reel_axis())
		TraversalStateMachine.State.ZIP:
			swing.apply_zip(delta)
		TraversalStateMachine.State.WALL_RUN, TraversalStateMachine.State.WALL_CRAWL, TraversalStateMachine.State.PERCH:
			wall.apply_forces(self, delta, st, controller.wish_dir())
		TraversalStateMachine.State.DODGE:
			combat.apply_dodge_motion(self, delta)
		_:
			var jumped := movement.apply_forces(self, delta, st, controller.move, camera_rig.yaw, controller.jump_buffer, controller.coyote, InputRouter.is_pressed("jump"))
			if jumped:
				controller.jump_buffer = 0.0
				state_machine.transition(TraversalStateMachine.State.AIR)
	if st == TraversalStateMachine.State.WALL_CRAWL or st == TraversalStateMachine.State.PERCH:
		wall.move_crawl(self, delta)
	else:
		move_and_slide()
	if st == TraversalStateMachine.State.SWING or st == TraversalStateMachine.State.SLINGSHOT:
		swing.apply_constraint()
		swing.update_wrap()
	combat.tick(delta)
	sense.tick(delta)
	focus.tick(delta)
	flow.tick(delta, velocity.length(), st)
	interaction.tick(delta)
	if is_on_floor() and velocity.length() < 14.0 and global_position.y > 0.4:
		last_safe_position = global_position
		last_safe_yaw = camera_rig.yaw
	if global_position.y < -8.0:
		respawn()
	_save_timer -= delta
	if _save_timer <= 0.0:
		_save_timer = 20.0
		_write_progress()


func _process(delta: float) -> void:
	if not alive:
		return
	var hand := animator.web_muzzle_position()
	rope.update_visual(swing, hand)
	animator.update_pose(delta, self)
	vfx.update_speed(velocity.length(), delta)
	_update_whoosh()


func apply_damage(amount: float, from: Vector3 = Vector3.ZERO) -> void:
	if not alive or hurt_invuln > 0.0 or combat.invulnerable:
		return
	if swing.active and amount < 18.0:
		amount *= 0.35
	health -= amount
	regen_delay = 4.5
	hurt_invuln = 0.35
	combat.combat_timer = 5.0
	combat.in_combat = true
	health_changed.emit(health, max_health)
	EventBus.player_damaged.emit(amount)
	AudioManager.play("hit", -1.0)
	camera_rig.add_shake(0.35)
	Haptics.pulse(40, 0.7)
	if not swing.active and amount >= 10.0:
		state_machine.transition(TraversalStateMachine.State.HITSTUN)
		if from != Vector3.ZERO:
			var push := (global_position - from)
			push.y = 0.0
			velocity += push.normalized() * 6.0 + Vector3.UP * 3.0
	if health <= 0.0:
		health = 0.0
		die()


func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)


func die() -> void:
	alive = false
	died.emit()
	if swing.active:
		swing.release(false)
	await get_tree().create_timer(0.7).timeout
	respawn()
	alive = true
	health = max_health * 0.45
	health_changed.emit(health, max_health)


func respawn() -> void:
	global_position = last_safe_position + Vector3.UP * 1.5
	velocity = Vector3.ZERO
	if swing.active or swing.zipping:
		swing.release(false)
	state_machine.transition(TraversalStateMachine.State.AIR)
	camera_rig.global_position = global_position + Vector3.UP * 2.0


func apply_suit(id: String) -> void:
	var suit := GameState.get_suit(id)
	if suit == null:
		return
	var preserved_velocity := velocity
	var preserved_anchor := swing.anchor_point
	var was_active := swing.active
	var preserved_state := state_machine.state
	suit_id = id
	max_health = 100.0 * GameState.health_multiplier()
	health = minf(health, max_health)
	var colors := GameState.custom_colors() if id == "custom" else {
		"primary": suit.primary_color,
		"secondary": suit.secondary_color,
		"accent": suit.accent_color,
	}
	animator.apply_palette(colors.primary, colors.secondary, colors.accent, suit.eye_color)
	var power := SuitManager.make_power(suit.suit_power_id)
	if power:
		combat.set_power(power)
	velocity = preserved_velocity
	swing.anchor_point = preserved_anchor
	swing.active = was_active
	state_machine.state = preserved_state
	health_changed.emit(health, max_health)
	suit_applied.emit(id)


func _update_mask(st: TraversalStateMachine.State) -> void:
	var fast := velocity.length() > 14.0 or swing.active or swing.zipping or st == TraversalStateMachine.State.DODGE
	collision_mask = PhysLayers.PLAYER_MASK_AIR if fast else PhysLayers.PLAYER_MASK_GROUND


func _on_swing_released(speed: float) -> void:
	if speed > 20.0:
		flow.bump(8.0)


func _update_whoosh() -> void:
	var player := get_node_or_null("Audio/Whoosh") as AudioStreamPlayer
	if player == null:
		return
	var amount := clampf((velocity.length() - 12.0) / 40.0, 0.0, 1.0)
	player.volume_db = lerpf(-40.0, -8.0, amount)
	if amount > 0.05 and not player.playing:
		player.play()
	elif amount <= 0.05 and player.playing:
		player.stop()


func _write_progress() -> void:
	SaveManager.set_value("player/position", [global_position.x, global_position.y, global_position.z])
	SaveManager.set_value("player/yaw", camera_rig.yaw)
	SaveManager.save_game()
