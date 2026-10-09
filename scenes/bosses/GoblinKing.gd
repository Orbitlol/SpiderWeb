extends "res://scenes/bosses/Boss.gd"

var angle: float = 0.0
var center: Vector3 = Vector3.ZERO
var shot_cooldown: float = 1.6


func _ready() -> void:
	data = load("res://resources/enemies/goblin_king.tres")
	super._ready()
	enemy_id = "goblin_king"
	center = global_position
	set_meta("anchor_kind", "glider")
	set_meta("anchor_priority", 2.4)


func _physics_process(delta: float) -> void:
	if not alive:
		return
	var focus := get_tree().get_first_node_in_group("player")
	var scale := 1.0
	if focus and focus.get_node_or_null("FocusSystem"):
		scale = focus.get_node("FocusSystem").enemy_scale()
	angle += delta * lerpf(0.45, 0.8, float(phase - 1)) * scale
	var radius := 16.0 if phase == 1 else 12.0
	var hover := 10.0 if phase == 1 else 7.0
	global_position = center + Vector3(cos(angle) * radius, hover + sin(angle * 2.0) * 1.5, sin(angle) * radius)
	velocity = Vector3.ZERO
	shot_cooldown -= delta * scale
	if shot_cooldown <= 0.0:
		shot_cooldown = 1.5 if phase == 1 else 0.9
		_shoot()


func _shoot() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var bomb := Area3D.new()
	bomb.collision_layer = PhysLayers.PROJECTILE
	bomb.collision_mask = PhysLayers.PLAYER | PhysLayers.WORLD
	bomb.monitoring = true
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 1.0, 0.2)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	bomb.add_child(mesh)
	var dir := (player.global_position - global_position).normalized()
	bomb.set_meta("velocity", dir * 18.0)
	bomb.set_script(preload("res://scenes/bosses/GliderBomb.gd"))
	bomb.global_position = global_position
	get_parent().add_child(bomb)
	var sense := player.get_node_or_null("SpiderSense")
	if sense:
		sense.warn(0.45)
