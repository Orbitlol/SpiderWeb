extends CharacterBody3D

@export var display_name: String = "Ally"
@export var line: String = "The city looks better from up here."
@export var color: Color = Color(0.8, 0.8, 0.8)


func _ready() -> void:
	add_to_group("web_anchor_character")
	add_to_group("ally")
	set_meta("can_swing_anchor", true)
	set_meta("anchor_kind", "ally")
	set_meta("anchor_priority", 0.8)
	collision_layer = PhysLayers.CHARACTER
	collision_mask = PhysLayers.WORLD
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.7
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.95, 0)
	add_child(col)
	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 1.7
	mesh.mesh = cap
	mesh.position = col.position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	add_child(mesh)


func interact_prompt() -> String:
	return "Talk to %s" % display_name


func interact(_player: Node) -> void:
	EventBus.dialogue_requested.emit(display_name, line)


func apply_web_yank(from: Vector3) -> void:
	var pull := from - global_position
	velocity += Vector3(pull.x, 0, pull.z).normalized() * 3.0
	EventBus.dialogue_requested.emit(display_name, "I felt that.")


func _physics_process(delta: float) -> void:
	velocity.y -= 32.0 * delta
	move_and_slide()
