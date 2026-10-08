extends Node

var building_shader: Shader
var water_shader: Shader
var wind_shader: Shader
var web_shader: Shader
var building_materials: Dictionary = {}
var street_material: StandardMaterial3D
var sidewalk_material: StandardMaterial3D
var metal_material: StandardMaterial3D
var water_material: ShaderMaterial
var cloud_material: ShaderMaterial
var unit_sphere: SphereMesh
var unit_cylinder: CylinderMesh
var _boxes: Dictionary = {}


func _ready() -> void:
	building_shader = load("res://shaders/building.gdshader")
	water_shader = load("res://shaders/water.gdshader")
	wind_shader = load("res://shaders/wind.gdshader")
	web_shader = load("res://shaders/web.gdshader")
	street_material = StandardMaterial3D.new()
	street_material.albedo_color = Color(0.08, 0.085, 0.09)
	street_material.roughness = 0.96
	sidewalk_material = StandardMaterial3D.new()
	sidewalk_material.albedo_color = Color(0.16, 0.16, 0.17)
	sidewalk_material.roughness = 0.9
	metal_material = StandardMaterial3D.new()
	metal_material.albedo_color = Color(0.45, 0.47, 0.5)
	metal_material.metallic = 0.75
	metal_material.roughness = 0.35
	unit_sphere = SphereMesh.new()
	unit_sphere.radius = 0.5
	unit_sphere.height = 1.0
	unit_sphere.radial_segments = 12
	unit_sphere.rings = 6
	unit_cylinder = CylinderMesh.new()
	unit_cylinder.top_radius = 0.5
	unit_cylinder.bottom_radius = 0.5
	unit_cylinder.height = 1.0
	unit_cylinder.radial_segments = 8
	_make_water()
	_make_cloud()
	for id in ["skyline", "midtown", "yards", "harbor"]:
		building_material(id, Color(0.2, 0.22, 0.26), Color(0.4, 0.45, 0.5))


func building_material(district_id: String, wall: Color, accent: Color) -> ShaderMaterial:
	if building_materials.has(district_id):
		return building_materials[district_id]
	var mat := ShaderMaterial.new()
	mat.shader = building_shader
	mat.set_shader_parameter("wall_color", wall)
	mat.set_shader_parameter("accent_color", accent)
	mat.set_shader_parameter("window_color", Color(1.0, 0.82, 0.55, 1.0))
	mat.set_shader_parameter("time_of_day", 0.62)
	mat.set_shader_parameter("wetness", 0.0)
	building_materials[district_id] = mat
	return mat


func box_mesh(size: Vector3) -> BoxMesh:
	var key := "%d_%d_%d" % [int(size.x * 10.0), int(size.y * 10.0), int(size.z * 10.0)]
	if _boxes.has(key):
		return _boxes[key]
	var mesh := BoxMesh.new()
	mesh.size = size
	_boxes[key] = mesh
	return mesh


func web_material(style: WebStyleData) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = web_shader
	apply_web_style(mat, style)
	return mat


func apply_web_style(mat: ShaderMaterial, style: WebStyleData) -> void:
	if mat == null or style == null:
		return
	mat.set_shader_parameter("web_color", style.primary_color)
	mat.set_shader_parameter("accent_color", style.accent_color)
	mat.set_shader_parameter("glow", style.glow)
	mat.set_shader_parameter("braid_scale", style.braid_scale)
	mat.set_shader_parameter("scroll_speed", style.scroll_speed)
	mat.set_shader_parameter("strands", style.strands)


func set_time_of_day(t: float, wetness: float) -> void:
	for mat in building_materials.values():
		mat.set_shader_parameter("time_of_day", t)
		mat.set_shader_parameter("wetness", wetness)


func _make_water() -> void:
	water_material = ShaderMaterial.new()
	water_material.shader = water_shader
	water_material.set_shader_parameter("deep_color", Color(0.02, 0.08, 0.12, 0.92))
	water_material.set_shader_parameter("shallow_color", Color(0.05, 0.22, 0.28, 0.8))


func _make_cloud() -> void:
	cloud_material = ShaderMaterial.new()
	cloud_material.shader = wind_shader
	cloud_material.set_shader_parameter("cloud_color", Color(1, 1, 1, 0.35))
