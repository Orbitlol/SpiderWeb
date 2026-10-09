extends AnimatableBody3D

var speed: float = 8.0
var direction: Vector3 = Vector3.FORWARD
var lane_y: float = 0.7
var color: Color = Color(0.2, 0.35, 0.7)
var _bounds: float = 320.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = PhysLayers.VEHICLE
	collision_mask = PhysLayers.WORLD
	add_to_group("web_anchor")
	add_to_group("web_anchor_vehicle")
	set_meta("anchor_kind", "vehicle")
	set_meta("anchor_priority", 1.1)
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.1, 1.3, 4.4)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, 0.7, 0)
	add_child(col)
	var mesh := MeshInstance3D.new()
	mesh.mesh = MaterialLibrary.box_mesh(shape.size)
	mesh.position = col.position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.4
	mat.roughness = 0.35
	mesh.material_override = mat
	add_child(mesh)


func _physics_process(delta: float) -> void:
	var motion := direction * speed * delta
	var next := global_position + motion
	if absf(next.x) > _bounds or absf(next.z) > _bounds:
		direction = -direction
		rotation.y = atan2(direction.x, direction.z)
		return
	global_position = next
