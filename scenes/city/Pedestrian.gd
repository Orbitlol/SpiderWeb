extends CharacterBody3D

var walk_dir: Vector3 = Vector3.FORWARD
var home: Vector3 = Vector3.ZERO
var fear: float = 0.0


func _ready() -> void:
	collision_layer = PhysLayers.CHARACTER
	collision_mask = PhysLayers.WORLD | PhysLayers.CHARACTER
	add_to_group("web_anchor_character")
	add_to_group("civilian")
	set_meta("anchor_kind", "civilian")
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.5
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.85, 0)
	add_child(col)
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.5
	mesh.mesh = cap
	mesh.position = col.position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.4, 0.48).lerp(Color(0.55, 0.32, 0.28), randf())
	mesh.material_override = mat
	add_child(mesh)


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var away: Vector3 = global_position - player.global_position
		if away.length() < 8.0 and player.velocity.length() > 12.0:
			fear = 1.4
			walk_dir = Vector3(away.x, 0, away.z).normalized()
	fear = maxf(0.0, fear - delta)
	if fear <= 0.0 and global_position.distance_to(home) > 18.0:
		walk_dir = Vector3(home.x - global_position.x, 0, home.z - global_position.z).normalized()
	velocity.x = walk_dir.x * (3.4 if fear > 0.0 else 1.3)
	velocity.z = walk_dir.z * (3.4 if fear > 0.0 else 1.3)
	velocity.y -= 32.0 * delta
	move_and_slide()
	if is_on_wall():
		walk_dir = -walk_dir


func apply_web_yank(from: Vector3) -> void:
	var pull := (from - global_position)
	pull.y = 0.0
	velocity += pull.normalized() * 6.0 + Vector3.UP * 3.0
	fear = 2.0
	EventBus.dialogue_requested.emit("Civilian", "Hey! Watch the webs!")
