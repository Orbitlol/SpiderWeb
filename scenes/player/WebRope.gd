extends Node3D
class_name WebRope

var mesh_instance: MeshInstance3D
var immediate: ImmediateMesh
var material: ShaderMaterial
var style: WebStyleData
var _release_trails: Array[Dictionary] = []


func _ready() -> void:
	immediate = ImmediateMesh.new()
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = immediate
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh_instance)
	material = MaterialLibrary.web_material(_current_style())
	mesh_instance.material_override = material
	EventBus.web_style_changed.connect(_on_style)


func _current_style() -> WebStyleData:
	if GameState.web_style:
		return GameState.web_style
	return WebStyleData.new()


func _on_style(next: WebStyleData) -> void:
	style = next
	MaterialLibrary.apply_web_style(material, next)


func update_visual(swing: WebSwingController, hand: Vector3) -> void:
	if style == null:
		style = _current_style()
		MaterialLibrary.apply_web_style(material, style)
	var points := swing.rope_points(hand)
	if points.size() >= 2:
		_build(points, style.thickness, style.strands)
	else:
		immediate.clear_surfaces()
	_fade_trails()


func spawn_release_trail(points: PackedVector3Array) -> void:
	if points.size() < 2:
		return
	var trail := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	trail.mesh = mesh
	var mat := material.duplicate() as ShaderMaterial
	trail.material_override = mat
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail)
	_fill_mesh(mesh, points, style.thickness if style else 0.03, 1)
	_release_trails.append({"node": trail, "life": 0.35, "mat": mat})


func _fade_trails() -> void:
	var delta := get_process_delta_time()
	for i in range(_release_trails.size() - 1, -1, -1):
		var trail: Dictionary = _release_trails[i]
		trail.life = float(trail.life) - delta
		var mat: ShaderMaterial = trail.mat
		var life := float(trail.life)
		if mat:
			var color: Color = style.primary_color if style else Color.WHITE
			color.a = clampf(life / 0.35, 0.0, 1.0)
			mat.set_shader_parameter("web_color", color)
		if life <= 0.0:
			var node: Node = trail.node
			if is_instance_valid(node):
				node.queue_free()
			_release_trails.remove_at(i)


func _build(points: PackedVector3Array, radius: float, strands: int) -> void:
	_fill_mesh(immediate, points, radius, clampi(strands, 1, 3))


func _fill_mesh(mesh: ImmediateMesh, points: PackedVector3Array, radius: float, strands: int) -> void:
	mesh.clear_surfaces()
	if points.size() < 2:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 6
	var frames := _frames(points)
	var length_acc := 0.0
	for strand in strands:
		var side := Vector3.ZERO
		if strands > 1:
			var binormal: Vector3 = frames[0].y
			side = binormal * (float(strand) - float(strands - 1) * 0.5) * radius * 2.4
		for i in points.size() - 1:
			var a: Vector3 = points[i] + side
			var b: Vector3 = points[i + 1] + side
			var seg := b - a
			var seg_len := maxf(seg.length(), 0.001)
			var right_a: Vector3 = frames[i].x
			var up_a: Vector3 = frames[i].y
			var right_b: Vector3 = frames[i + 1].x
			var up_b: Vector3 = frames[i + 1].y
			for s in sides:
				var t0 := float(s) / float(sides)
				var t1 := float(s + 1) / float(sides)
				var a0 := cos(t0 * TAU)
				var a1 := sin(t0 * TAU)
				var b0 := cos(t1 * TAU)
				var b1 := sin(t1 * TAU)
				var p00 := a + (right_a * a0 + up_a * a1) * radius
				var p01 := a + (right_a * b0 + up_a * b1) * radius
				var p10 := b + (right_b * a0 + up_b * a1) * radius
				var p11 := b + (right_b * b0 + up_b * b1) * radius
				var u0 := length_acc
				var u1 := length_acc + seg_len
				_tri(mesh, p00, p10, p11, u0, u1, t0, t1)
				_tri(mesh, p00, p11, p01, u0, u1, t0, t1)
			length_acc += seg_len
	mesh.surface_end()


func _tri(mesh: ImmediateMesh, p0: Vector3, p1: Vector3, p2: Vector3, u0: float, u1: float, v0: float, v1: float) -> void:
	var normal := (p1 - p0).cross(p2 - p0)
	if normal.length_squared() > 0.000001:
		normal = normal.normalized()
	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(Vector2(u0, v0))
	mesh.surface_add_vertex(p0)
	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(Vector2(u1, v0))
	mesh.surface_add_vertex(p1)
	mesh.surface_set_normal(normal)
	mesh.surface_set_uv(Vector2(u1, v1))
	mesh.surface_add_vertex(p2)


func _frames(points: PackedVector3Array) -> Array:
	var frames: Array = []
	var forward := (points[1] - points[0]).normalized()
	var up := Vector3.UP
	if absf(forward.dot(up)) > 0.92:
		up = Vector3.RIGHT
	var right := forward.cross(up).normalized()
	up = right.cross(forward).normalized()
	frames.append(Vector3(right.x, up.x, forward.x)) # placeholder overwritten below
	frames.clear()
	frames.append({"x": right, "y": up, "z": forward})
	for i in range(1, points.size()):
		var prev: Vector3 = points[i - 1]
		var curr: Vector3 = points[i]
		forward = curr - prev
		if forward.length_squared() < 0.0001:
			forward = frames[i - 1].z
		else:
			forward = forward.normalized()
		var prev_right: Vector3 = frames[i - 1].x
		right = prev_right - forward * prev_right.dot(forward)
		if right.length_squared() < 0.0001:
			right = forward.cross(Vector3.UP)
			if right.length_squared() < 0.0001:
				right = forward.cross(Vector3.RIGHT)
		right = right.normalized()
		up = right.cross(forward).normalized()
		frames.append({"x": right, "y": up, "z": forward})
	return frames
