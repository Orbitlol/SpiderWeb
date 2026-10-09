extends Node3D
class_name CityChunk

var coord: Vector2i = Vector2i.ZERO
var ready_visual: bool = false
var _jobs: Array[Dictionary] = []


func build(chunk_coord: Vector2i) -> void:
	coord = chunk_coord
	name = "Chunk_%d_%d" % [coord.x, coord.y]
	var origin := CityLayout.chunk_origin(coord)
	_jobs.append({"op": "sidewalk", "origin": origin})
	for x in CityLayout.CHUNK_BLOCKS:
		for z in CityLayout.CHUNK_BLOCKS:
			var ix := coord.x * CityLayout.CHUNK_BLOCKS + x
			var iz := coord.y * CityLayout.CHUNK_BLOCKS + z
			for building in CityLayout.buildings_for_block(ix, iz):
				_jobs.append({"op": "building", "data": building})
	for prop in CityLayout.props_for_chunk(coord):
		_jobs.append({"op": "prop", "data": prop})
	for token in CityLayout.tokens_for_chunk(coord):
		if not _collected(str(token.id)):
			_jobs.append({"op": "token", "data": token})
	if coord == Vector2i(0, 0):
		_jobs.append({"op": "bridge"})
	set_process(true)


func _process(_delta: float) -> void:
	var budget := 8
	while budget > 0 and not _jobs.is_empty():
		_run_job(_jobs.pop_front())
		budget -= 1
	if _jobs.is_empty():
		ready_visual = true
		set_process(false)


func _collected(id: String) -> bool:
	var collected: Array = SaveManager.get_value("world/collected", [])
	return id in collected


func _run_job(job: Dictionary) -> void:
	match str(job.op):
		"sidewalk":
			_sidewalk(job.origin)
		"building":
			_building(job.data)
		"prop":
			_prop(job.data)
		"token":
			_token(job.data)
		"bridge":
			_bridge()


func _sidewalk(origin: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = PhysLayers.WORLD
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	shape.size = Vector3(CityLayout.CHUNK_SIZE, 0.4, CityLayout.STREET)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = origin + Vector3(CityLayout.CHUNK_SIZE * 0.5, 0.2, CityLayout.STREET * 0.5)
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	mesh.mesh = MaterialLibrary.box_mesh(shape.size)
	mesh.position = col.position
	mesh.material_override = MaterialLibrary.sidewalk_material
	body.add_child(mesh)
	add_child(body)


func _building(data: Dictionary) -> void:
	var size: Vector3 = data.size
	var pos: Vector3 = data.position
	var body := StaticBody3D.new()
	body.collision_layer = PhysLayers.WORLD
	body.collision_mask = 0
	body.add_to_group("web_anchor")
	body.set_meta("anchor_kind", str(data.kind))
	body.set_meta("anchor_priority", 1.6 if str(data.kind) != "tower" else 0.3)
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	mesh.mesh = MaterialLibrary.box_mesh(size)
	mesh.position = col.position
	mesh.material_override = MaterialLibrary.building_material(str(data.district), _wall(str(data.district)), _accent(str(data.district)))
	mesh.visibility_range_end = 420.0
	mesh.visibility_range_end_margin = 24.0
	body.add_child(mesh)
	if size.y > 24.0 and str(data.kind) == "tower":
		var occ := OccluderInstance3D.new()
		var box := BoxOccluder3D.new()
		box.size = size
		occ.occluder = box
		occ.position = col.position
		body.add_child(occ)
	body.position = pos
	add_child(body)


func _prop(data: Dictionary) -> void:
	if str(data.kind) != "streetlight":
		return
	var pos: Vector3 = data.position
	var root := StaticBody3D.new()
	root.collision_layer = PhysLayers.WORLD
	root.collision_mask = 0
	root.add_to_group("web_anchor")
	root.set_meta("anchor_kind", "streetlight")
	root.set_meta("anchor_priority", 1.4)
	root.position = pos
	var pole := CollisionShape3D.new()
	var pole_shape := BoxShape3D.new()
	pole_shape.size = Vector3(0.25, 12.0, 0.25)
	pole.shape = pole_shape
	pole.position = Vector3(0, 6.0, 0)
	root.add_child(pole)
	var arm := CollisionShape3D.new()
	var arm_shape := BoxShape3D.new()
	arm_shape.size = Vector3(2.4, 0.28, 0.35)
	arm.shape = arm_shape
	arm.position = Vector3(0.8, 11.6, 0)
	root.add_child(arm)
	var pole_mesh := MeshInstance3D.new()
	pole_mesh.mesh = MaterialLibrary.box_mesh(pole_shape.size)
	pole_mesh.position = pole.position
	pole_mesh.material_override = MaterialLibrary.metal_material
	root.add_child(pole_mesh)
	var arm_mesh := MeshInstance3D.new()
	arm_mesh.mesh = MaterialLibrary.box_mesh(arm_shape.size)
	arm_mesh.position = arm.position
	arm_mesh.material_override = MaterialLibrary.metal_material
	root.add_child(arm_mesh)
	add_child(root)


func _token(data: Dictionary) -> void:
	var token := Area3D.new()
	token.collision_layer = PhysLayers.TRIGGER
	token.collision_mask = PhysLayers.PLAYER
	token.monitoring = true
	token.set_script(preload("res://scenes/city/Collectible.gd"))
	token.set_meta("token_id", str(data.id))
	token.position = data.position
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.1
	shape.shape = sphere
	token.add_child(shape)
	var mesh := MeshInstance3D.new()
	var octa := SphereMesh.new()
	octa.radius = 0.35
	octa.height = 0.9
	mesh.mesh = octa
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.25, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.35, 0.25)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = mat
	token.add_child(mesh)
	add_child(token)


func _bridge() -> void:
	var deck := StaticBody3D.new()
	deck.collision_layer = PhysLayers.WORLD
	deck.collision_mask = 0
	deck.add_to_group("web_anchor")
	deck.set_meta("anchor_kind", "bridge")
	deck.set_meta("anchor_priority", 1.2)
	var size := Vector3(70.0, 2.0, 16.0)
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	deck.add_child(col)
	var mesh := MeshInstance3D.new()
	mesh.mesh = MaterialLibrary.box_mesh(size)
	mesh.material_override = MaterialLibrary.metal_material
	deck.add_child(mesh)
	deck.position = Vector3(CityLayout.CITY_ORIGIN + 40.0, 14.0, CityLayout.CITY_ORIGIN + 8.0)
	add_child(deck)
	for side in [-1.0, 1.0]:
		var tower := StaticBody3D.new()
		tower.collision_layer = PhysLayers.WORLD
		tower.add_to_group("web_anchor")
		tower.set_meta("anchor_kind", "bridge_tower")
		tower.set_meta("anchor_priority", 2.0)
		var tsize := Vector3(4.0, 36.0, 4.0)
		var tshape := BoxShape3D.new()
		tshape.size = tsize
		var tcol := CollisionShape3D.new()
		tcol.shape = tshape
		tcol.position = Vector3(0, 18.0, 0)
		tower.add_child(tcol)
		var tmesh := MeshInstance3D.new()
		tmesh.mesh = MaterialLibrary.box_mesh(tsize)
		tmesh.position = tcol.position
		tmesh.material_override = MaterialLibrary.metal_material
		tower.add_child(tmesh)
		tower.position = deck.position + Vector3(side * 28.0, 0.0, 0.0)
		add_child(tower)


func _wall(district: String) -> Color:
	match district:
		"skyline":
			return Color(0.16, 0.18, 0.22)
		"yards":
			return Color(0.22, 0.18, 0.14)
		"harbor":
			return Color(0.15, 0.2, 0.24)
		_:
			return Color(0.2, 0.21, 0.24)


func _accent(district: String) -> Color:
	match district:
		"skyline":
			return Color(0.35, 0.4, 0.5)
		"yards":
			return Color(0.45, 0.32, 0.18)
		"harbor":
			return Color(0.25, 0.4, 0.45)
		_:
			return Color(0.32, 0.34, 0.38)
