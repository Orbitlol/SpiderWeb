extends Node3D
class_name TraversalVFX

var speed_lines: ColorRect
var _whiff_life: float = 0.0
var _whiff_mesh: ImmediateMesh
var _whiff_instance: MeshInstance3D


func _ready() -> void:
	_whiff_mesh = ImmediateMesh.new()
	_whiff_instance = MeshInstance3D.new()
	_whiff_instance.mesh = _whiff_mesh
	_whiff_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := MaterialLibrary.web_material(GameState.web_style if GameState.web_style else WebStyleData.new())
	_whiff_instance.material_override = mat
	add_child(_whiff_instance)


func attach_speed_lines(rect: ColorRect) -> void:
	speed_lines = rect


func update_speed(speed: float, delta: float) -> void:
	if speed_lines and speed_lines.material is ShaderMaterial:
		var amount := clampf((speed - 22.0) / 36.0, 0.0, 1.0)
		speed_lines.material.set_shader_parameter("speed", amount)
	if _whiff_life > 0.0:
		_whiff_life -= delta
		if _whiff_life <= 0.0:
			_whiff_mesh.clear_surfaces()


func whiff(direction: Vector3, origin: Vector3) -> void:
	var dir := direction.normalized() if direction.length_squared() > 0.001 else Vector3.FORWARD
	var end := origin + dir * 7.5
	_whiff_life = 0.18
	_whiff_mesh.clear_surfaces()
	_whiff_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_whiff_mesh.surface_add_vertex(origin)
	_whiff_mesh.surface_add_vertex(end)
	_whiff_mesh.surface_end()
	AudioManager.play("web_thwip", -10.0)
