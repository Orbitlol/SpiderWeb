extends "res://scenes/bosses/Boss.gd"

var tentacles: Array[Node3D] = []
var swipe: float = 0.0


func _ready() -> void:
	data = load("res://resources/enemies/doctor_octopus.tres")
	super._ready()
	enemy_id = "doctor_octopus"
	for i in 4:
		var tentacle := Node3D.new()
		var mesh := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.12
		cap.height = 3.2
		mesh.mesh = cap
		mesh.position = Vector3(0, 1.4, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.42, 0.28)
		mat.metallic = 0.7
		mesh.material_override = mat
		tentacle.add_child(mesh)
		tentacle.position = Vector3(cos(float(i) * TAU / 4.0) * 0.5, 1.0, sin(float(i) * TAU / 4.0) * 0.5)
		add_child(tentacle)
		tentacles.append(tentacle)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not alive:
		return
	swipe += delta
	var player := get_tree().get_first_node_in_group("player")
	for i in tentacles.size():
		var tentacle := tentacles[i]
		tentacle.rotation.z = sin(swipe * 2.0 + float(i)) * 0.8
		if player and global_position.distance_to(player.global_position) < 4.5 and swipe > 1.4:
			player.apply_damage(9.0, global_position)
			swipe = 0.0
			var sense := player.get_node_or_null("SpiderSense")
			if sense:
				sense.warn(0.4)
