extends CharacterBody3D
class_name EnemyActor

signal defeated(id: String)

@export var data: EnemyData
var health: float = 70.0
var max_health: float = 70.0
var stun: float = 0.0
var alive: bool = true
var enemy_id: String = "thug"
var home: Vector3 = Vector3.ZERO


func _ready() -> void:
	add_to_group("enemy")
	add_to_group("web_anchor_character")
	collision_layer = PhysLayers.CHARACTER
	collision_mask = PhysLayers.WORLD | PhysLayers.CHARACTER
	if data == null:
		data = load("res://resources/enemies/thug.tres")
	if data:
		enemy_id = data.enemy_id
		max_health = data.max_health
		health = max_health
		set_meta("can_swing_anchor", data.can_swing_anchor)
		set_meta("anchor_kind", data.enemy_id)
	else:
		set_meta("can_swing_anchor", false)
	_build_visual()
	home = global_position


func _build_visual() -> void:
	if get_node_or_null("Visual"):
		return
	var visual := Node3D.new()
	visual.name = "Visual"
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.38
	cap.height = 1.7
	mesh.mesh = cap
	mesh.position = Vector3(0, 0.95, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = data.color if data else Color(0.3, 0.3, 0.32)
	mesh.material_override = mat
	visual.add_child(mesh)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	head.mesh = sphere
	head.position = Vector3(0, 1.75, 0)
	head.material_override = mat
	visual.add_child(head)
	add_child(visual)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.38
	shape.height = 1.7
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.95, 0)
	add_child(col)


func health_ratio() -> float:
	return health / maxf(max_health, 1.0)


func take_damage(amount: float, from: Vector3, heavy: bool) -> void:
	if not alive:
		return
	health -= amount
	stun = 0.35 if not heavy else 0.7
	var push := global_position - from
	push.y = 0.0
	velocity += push.normalized() * (4.0 if not heavy else 8.0) + Vector3.UP * 2.0
	if health <= 0.0:
		die()


func apply_web_yank(from: Vector3) -> void:
	stun = 1.3
	var pull := from - global_position
	velocity += pull.normalized() * 9.0 + Vector3.UP * 2.5


func die() -> void:
	if not alive:
		return
	alive = false
	defeated.emit(enemy_id)
	EventBus.enemy_defeated.emit(enemy_id)
	GameState.add_xp(data.score_value if data else 8)
	queue_free()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	stun = maxf(0.0, stun - delta)
	if not is_on_floor():
		velocity.y -= 32.0 * delta
	move_and_slide()
