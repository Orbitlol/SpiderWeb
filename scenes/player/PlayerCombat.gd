extends Node
class_name PlayerCombat

var cooldown: float = 0.0
var combo_step: int = 0
var combo_timer: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_time: float = 0.0
var dodge_dir: Vector3 = Vector3.FORWARD
var gadget_cooldown: float = 0.0
var power_cooldown: float = 0.0
var in_combat: bool = false
var combat_timer: float = 0.0
var invulnerable: bool = false

var _attack_queued: bool = false
var _heavy_queued: bool = false
var _body: CharacterBody3D
var _power: Node


func setup(body: CharacterBody3D) -> void:
	_body = body


func request_attack(heavy: bool) -> void:
	if heavy:
		_heavy_queued = true
	else:
		_attack_queued = true


func request_gadget() -> void:
	if gadget_cooldown > 0.0 or GameState.gadget == null or _body == null:
		return
	gadget_cooldown = GameState.gadget.cooldown
	var origin := _body.global_position + Vector3.UP * 1.2
	var aim := _body.get_node("CameraRig").aim_direction()
	var bomb := _spawn_bomb(origin, aim)
	if bomb:
		_body.get_parent().add_child(bomb)
	AudioManager.play("web_thwip", -2.0)


func request_power() -> void:
	if power_cooldown > 0.0 or _power == null or _body == null:
		return
	if _power.has_method("activate"):
		_power.activate(_body)
		power_cooldown = 8.0
		AudioManager.play("power", -2.0)


func set_power(node: Node) -> void:
	if _power and is_instance_valid(_power):
		_power.queue_free()
	_power = node
	if _power:
		add_child(_power)


func begin_dodge(wish: Vector3) -> bool:
	if dodge_cooldown > 0.0 or _body == null:
		return false
	dodge_dir = wish if wish.length_squared() > 0.05 else MathUtil.safe_normalize(MathUtil.flatten(_body.velocity), -_body.get_node("CameraRig").global_transform.basis.z)
	dodge_time = 0.28
	dodge_cooldown = 0.55
	invulnerable = true
	var sense: SpiderSense = _body.get_node("SpiderSense")
	if sense.in_perfect_window():
		_body.get_node("FocusSystem").add(28.0)
		_body.get_node("FlowSystem").bump(12.0)
		AudioManager.play("dodge", 1.0)
		sense.clear()
	else:
		AudioManager.play("dodge", -4.0)
	return true


func apply_dodge_motion(body: CharacterBody3D, delta: float) -> void:
	dodge_time -= delta
	body.velocity.x = dodge_dir.x * 16.0
	body.velocity.z = dodge_dir.z * 16.0
	body.velocity.y = maxf(body.velocity.y, 0.5)
	if dodge_time <= 0.0:
		invulnerable = false


func tick(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	gadget_cooldown = maxf(0.0, gadget_cooldown - delta)
	power_cooldown = maxf(0.0, power_cooldown - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0:
		combo_step = 0
	combat_timer = maxf(0.0, combat_timer - delta)
	in_combat = combat_timer > 0.0
	if dodge_time > 0.0:
		dodge_time -= delta
		if dodge_time <= 0.0:
			invulnerable = false
	if _power and _power.has_method("tick"):
		_power.tick(_body, delta)
	if _attack_queued or _heavy_queued:
		_do_attack(_heavy_queued)
		_attack_queued = false
		_heavy_queued = false


func yank(target: Dictionary) -> void:
	var collider: Object = target.get("collider")
	if collider == null:
		return
	var point: Vector3 = target.point
	if collider.has_method("apply_web_yank"):
		collider.apply_web_yank(_body.global_position)
	elif collider is RigidBody3D:
		var body := collider as RigidBody3D
		var pull := (_body.global_position - body.global_position).normalized()
		body.apply_central_impulse(pull * 7.0 + Vector3.UP * 2.0)
	AudioManager.play_at("web_thwip", point, -4.0)
	Haptics.pulse(20, 0.3)
	combat_timer = 3.0
	in_combat = true


func _do_attack(heavy: bool) -> void:
	if _body == null or cooldown > 0.0:
		return
	var origin := _body.global_position + Vector3.UP * 1.1
	var forward := MathUtil.safe_normalize(MathUtil.flatten(_body.get_node("CameraRig").aim_direction()), Vector3.FORWARD)
	var reach := 2.5 if not heavy else 2.9
	var swinging := _body.get_node("StateMachine").state == TraversalStateMachine.State.SWING
	if swinging:
		reach = 3.4
		forward = MathUtil.safe_normalize(MathUtil.flatten(_body.velocity), forward)
	var hits := _overlap(origin + forward * (reach * 0.6), 1.15 if not heavy else 1.45)
	var flow: FlowSystem = _body.get_node("FlowSystem")
	var base := 14.0 if not heavy else 26.0
	if swinging:
		base += clampf(_body.velocity.length() * 0.35, 0.0, 18.0)
	var dealt := false
	for hit in hits:
		var node: Object = hit.collider
		if node == null or not node.is_in_group("enemy"):
			continue
		var ratio := 1.0
		if node.has_method("health_ratio"):
			ratio = node.health_ratio()
		var dist := _body.global_position.distance_to(node.global_position)
		if CombatRules.finisher_ready(ratio, flow.value, dist) and not heavy:
			node.take_damage(999.0, _body.global_position, true)
			flow.bump(18.0)
			_body.get_node("FocusSystem").add(15.0)
			dealt = true
			continue
		var dmg := CombatRules.combo_damage(base, combo_step, flow.value, GameState.damage_multiplier())
		if node.has_method("take_damage"):
			node.take_damage(dmg, _body.global_position, heavy or swinging)
			dealt = true
	if dealt:
		combo_step = mini(combo_step + 1, 3)
		combo_timer = 0.85
		combat_timer = 4.0
		in_combat = true
		flow.bump(6.0 if not heavy else 10.0)
		AudioManager.play("hit", -2.0)
		Haptics.pulse(30, 0.55)
		cooldown = 0.34 if not heavy else 0.62
	else:
		cooldown = 0.22


func _overlap(center: Vector3, radius: float) -> Array:
	var space := _body.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = PhysLayers.CHARACTER
	query.exclude = [_body.get_rid()]
	return space.intersect_shape(query, 8)


func _spawn_bomb(origin: Vector3, aim: Vector3) -> Node3D:
	var bomb := Area3D.new()
	bomb.collision_layer = PhysLayers.PROJECTILE
	bomb.collision_mask = PhysLayers.WORLD | PhysLayers.CHARACTER
	bomb.monitorable = false
	bomb.monitoring = true
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GameState.gadget.color
	mat.emission_enabled = true
	mat.emission = GameState.gadget.color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	bomb.add_child(mesh)
	bomb.set_meta("velocity", aim.normalized() * 28.0 + Vector3.UP * 4.0)
	bomb.set_meta("life", 1.6)
	bomb.set_script(preload("res://scenes/player/WebBomb.gd"))
	bomb.global_position = origin + aim.normalized() * 0.8
	return bomb
