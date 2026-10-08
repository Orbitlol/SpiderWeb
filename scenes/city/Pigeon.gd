extends Node3D

var phase: float = 0.0
var radius: float = 18.0
var height: float = 28.0
var center: Vector3 = Vector3.ZERO
var _wing: MeshInstance3D


func _ready() -> void:
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.28
	body.mesh = mesh
	body.rotation.z = PI * 0.5
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.36, 0.38)
	body.material_override = mat
	add_child(body)
	_wing = MeshInstance3D.new()
	var wing := BoxMesh.new()
	wing.size = Vector3(0.55, 0.02, 0.16)
	_wing.mesh = wing
	_wing.material_override = mat
	add_child(_wing)


func _process(delta: float) -> void:
	phase += delta
	var ang := phase * 0.7
	global_position = center + Vector3(cos(ang) * radius, height + sin(phase * 3.0) * 0.8, sin(ang) * radius)
	if _wing:
		_wing.rotation.z = sin(phase * 14.0) * 0.6
