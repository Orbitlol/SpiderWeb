extends Node

var distant: MultiMeshInstance3D
var _cars: Array[AnimatableBody3D] = []
var _time: float = 0.0


func _ready() -> void:
	_spawn_physics_cars()
	_spawn_distant()


func _spawn_physics_cars() -> void:
	var colors := [Color(0.7, 0.15, 0.12), Color(0.15, 0.25, 0.55), Color(0.85, 0.75, 0.3), Color(0.2, 0.2, 0.22), Color(0.9, 0.9, 0.92)]
	for i in 14:
		var car := preload("res://scenes/vehicles/Car.tscn").instantiate()
		var along := float(i) / 14.0
		var horizontal := CityLayout.CITY_ORIGIN + 20.0 + along * (CityLayout.GRID * CityLayout.BLOCK - 40.0)
		var street := CityLayout.CITY_ORIGIN + float((i % 4) + 1) * CityLayout.BLOCK + 6.0
		if i % 2 == 0:
			car.position = Vector3(horizontal, 0.0, street)
			car.direction = Vector3(1 if i % 4 == 0 else -1, 0, 0)
		else:
			car.position = Vector3(street, 0.0, horizontal)
			car.direction = Vector3(0, 0, 1 if i % 4 == 1 else -1)
		car.speed = lerpf(7.0, 13.0, float(i % 5) / 4.0)
		car.color = colors[i % colors.size()]
		car.rotation.y = atan2(car.direction.x, car.direction.z)
		add_child(car)
		_cars.append(car)


func _process(delta: float) -> void:
	if distant == null or distant.multimesh == null:
		return
	_time += delta
	var multi := distant.multimesh
	for i in mini(multi.instance_count, 12):
		multi.set_instance_transform(i, TrafficSim.distant_transform(i, _time))


func _spawn_distant() -> void:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.instance_count = 36
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.8, 1.1, 3.8)
	multi.mesh = mesh
	distant = MultiMeshInstance3D.new()
	distant.multimesh = multi
	distant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.28, 0.32)
	distant.material_override = mat
	add_child(distant)
	for i in multi.instance_count:
		multi.set_instance_transform(i, TrafficSim.distant_transform(i, 0.0))
