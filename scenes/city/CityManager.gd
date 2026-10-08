extends Node3D

signal ready_for_player

@onready var streaming: StreamingManager = $StreamingManager
@onready var districts: DistrictManager = $DistrictManager
@onready var traffic: Node = $Traffic
@onready var weather: WeatherManager = $Weather
@onready var day_night: DayNightCycle = $DayNight

var spawn_point: Vector3 = Vector3.ZERO
var _player: Node3D
var _announced: bool = false
var _heli: AnimatableBody3D
var _drone: AnimatableBody3D


func _ready() -> void:
	add_to_group("city")
	spawn_point = CityLayout.spawn_rooftop()
	_build_ground()
	_build_water()
	_build_clouds()
	_build_movers()
	_build_pigeons()


func bind_player(player: Node3D) -> void:
	_player = player
	streaming.bind_player(player)
	weather.bind_player(player)
	_spawn_pedestrians()


func _process(delta: float) -> void:
	if _player:
		districts.update_player(_player.global_position)
		var probe := _player.global_position if _player else spawn_point
		if not _announced and streaming.is_ready_around(probe):
			_announced = true
			ready_for_player.emit()
	_orbit(_heli, 90.0, 0.15, delta, Vector3(0, 78, 0))
	_orbit(_drone, 40.0, 0.45, delta, Vector3(30, 32, -20))


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysLayers.WORLD
	body.collision_mask = 0
	body.add_to_group("web_ground")
	body.set_meta("anchor_kind", "ground")
	var shape := BoxShape3D.new()
	shape.size = Vector3(2200, 2, 2200)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, -1.0, 0)
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	mesh.mesh = MaterialLibrary.box_mesh(Vector3(900, 0.2, 900))
	mesh.position = Vector3(0, 0.0, 0)
	mesh.material_override = MaterialLibrary.street_material
	body.add_child(mesh)
	add_child(body)


func _build_water() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(280, 220)
	mesh.mesh = plane
	mesh.material_override = MaterialLibrary.water_material
	mesh.position = Vector3(CityLayout.CITY_ORIGIN + 80.0, 0.15, CityLayout.CITY_ORIGIN + 40.0)
	add_child(mesh)


func _build_clouds() -> void:
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1600, 1600)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	mesh.mesh = plane
	mesh.material_override = MaterialLibrary.cloud_material
	mesh.position = Vector3(0, 190, 0)
	add_child(mesh)


func _build_movers() -> void:
	_heli = _flyer(Vector3(6, 2.2, 10), Color(0.45, 0.47, 0.5), "helicopter", 2.2)
	_drone = _flyer(Vector3(1.4, 0.4, 1.4), Color(0.7, 0.2, 0.2), "drone", 1.3)
	add_child(_heli)
	add_child(_drone)


func _flyer(size: Vector3, color: Color, kind: String, priority: float) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.sync_to_physics = true
	body.collision_layer = PhysLayers.VEHICLE
	body.collision_mask = 0
	body.add_to_group("web_anchor")
	body.add_to_group("web_anchor_dynamic")
	body.set_meta("anchor_kind", kind)
	body.set_meta("anchor_priority", priority)
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	mesh.mesh = MaterialLibrary.box_mesh(size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.6
	mesh.material_override = mat
	body.add_child(mesh)
	if kind == "helicopter":
		var rotor := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(9, 0.08, 0.35)
		rotor.mesh = box
		rotor.position = Vector3(0, 1.3, 0)
		rotor.material_override = MaterialLibrary.metal_material
		body.add_child(rotor)
		rotor.set_meta("spin", true)
	return body


func _orbit(body: AnimatableBody3D, radius: float, rate: float, delta: float, center: Vector3) -> void:
	if body == null:
		return
	var ang := Time.get_ticks_msec() / 1000.0 * rate
	body.global_position = center + Vector3(cos(ang) * radius, 0, sin(ang) * radius)
	body.rotation.y = -ang
	for child in body.get_children():
		if child is MeshInstance3D and child.get_meta("spin", false):
			child.rotate_y(delta * 18.0)


func _build_pigeons() -> void:
	for i in 6:
		var bird := Node3D.new()
		bird.set_script(preload("res://scenes/city/Pigeon.gd"))
		bird.phase = float(i)
		bird.radius = 24.0 + float(i) * 6.0
		bird.height = 30.0 + float(i % 3) * 8.0
		bird.center = Vector3(float(i) * 12.0, 0, float(i) * -8.0)
		add_child(bird)


func _spawn_pedestrians() -> void:
	for i in 10:
		var person := CharacterBody3D.new()
		person.set_script(preload("res://scenes/city/Pedestrian.gd"))
		var ix := 2 + (i % 4)
		var iz := 2 + int(i / 4)
		var center := CityLayout.block_center(ix, iz)
		person.position = center + Vector3(18, 1, float(i) * 2.0)
		person.home = person.position
		add_child(person)
