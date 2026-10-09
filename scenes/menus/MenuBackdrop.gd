extends Node3D

var _time: float = 0.0
var hero: Node3D
var cars: Array[Node3D] = []


func _ready() -> void:
	_environment()
	_skyline()
	_hero()
	_traffic()
	_pigeons()
	var cam := Camera3D.new()
	cam.position = Vector3(18, 28, 34)
	cam.look_at(Vector3(0, 18, 0))
	cam.current = true
	cam.fov = 58
	add_child(cam)


func _process(delta: float) -> void:
	_time += delta
	if hero:
		hero.position.y = 22.2 + sin(_time * 0.8) * 0.08
	for i in cars.size():
		var car := cars[i]
		car.position.x += delta * (6.0 + float(i))
		if car.position.x > 40.0:
			car.position.x = -40.0


func _environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var mat := ProceduralSkyMaterial.new()
	mat.sky_top_color = Color(0.18, 0.28, 0.48)
	mat.sky_horizon_color = Color(0.85, 0.45, 0.28)
	mat.ground_horizon_color = mat.sky_horizon_color
	mat.ground_bottom_color = Color(0.05, 0.05, 0.06)
	sky.sky_material = mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28, 40, 0)
	sun.light_color = Color(1.0, 0.78, 0.55)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(120, 1, 80)
	ground.mesh = box
	ground.position = Vector3(0, -0.5, 0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.08, 0.08, 0.09)
	ground.material_override = gmat
	add_child(ground)


func _skyline() -> void:
	var shader: Shader = load("res://shaders/building.gdshader")
	for i in 14:
		var height := 12.0 + float((i * 17) % 28)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(6.0 + float(i % 3), height, 6.0)
		mesh.mesh = box
		mesh.position = Vector3(-30.0 + float(i) * 5.2, height * 0.5, -8.0 - float(i % 4) * 4.0)
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("wall_color", Color(0.14, 0.16, 0.2))
		mat.set_shader_parameter("accent_color", Color(0.3, 0.34, 0.4))
		mat.set_shader_parameter("time_of_day", 0.35)
		mesh.material_override = mat
		add_child(mesh)


func _hero() -> void:
	hero = Node3D.new()
	hero.position = Vector3(-4, 22.2, -2)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.5
	body.mesh = cap
	body.position = Vector3(0, 0.8, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.08, 0.1)
	body.material_override = mat
	hero.add_child(body)
	var web := MeshInstance3D.new()
	var line := BoxMesh.new()
	line.size = Vector3(0.04, 0.04, 8)
	web.mesh = line
	web.position = Vector3(0.4, 1.4, 3.5)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.85, 0.92, 1)
	wmat.emission_enabled = true
	wmat.emission = Color(0.7, 0.85, 1)
	wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	web.material_override = wmat
	hero.add_child(web)
	add_child(hero)


func _traffic() -> void:
	for i in 5:
		var car := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.8, 1.0, 3.6)
		car.mesh = box
		car.position = Vector3(-30.0 + float(i) * 12.0, 0.6, 8.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.3, 0.7).lerp(Color(0.8, 0.2, 0.15), float(i) / 4.0)
		car.material_override = mat
		add_child(car)
		cars.append(car)


func _pigeons() -> void:
	for i in 4:
		var bird := Node3D.new()
		bird.set_script(preload("res://scenes/city/Pigeon.gd"))
		bird.center = Vector3(0, 0, -4)
		bird.radius = 10.0 + float(i) * 3.0
		bird.height = 16.0
		bird.phase = float(i) * 1.3
		add_child(bird)
