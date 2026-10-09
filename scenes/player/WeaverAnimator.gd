extends Node3D
class_name WeaverAnimator

var skeleton: Skeleton3D
var web_muzzle: Node3D
var palette := {
	"primary": Color(0.72, 0.08, 0.1),
	"secondary": Color(0.08, 0.12, 0.32),
	"accent": Color(0.9, 0.82, 0.55),
	"eye": Color(1.0, 0.95, 0.85),
}
var _bones: Dictionary = {}
var _meshes: Array[MeshInstance3D] = []
var anim_player: AnimationPlayer
var anim_tree: AnimationTree
var _bob: float = 0.0


func _ready() -> void:
	_build_rig()
	_build_animations()


func web_muzzle_position() -> Vector3:
	if web_muzzle:
		return web_muzzle.global_position
	return global_position + Vector3.UP * 1.3


func apply_palette(primary: Color, secondary: Color, accent: Color, eye: Color) -> void:
	palette.primary = primary
	palette.secondary = secondary
	palette.accent = accent
	palette.eye = eye
	for mesh in _meshes:
		if mesh == null or mesh.material_override == null:
			continue
		var slot := str(mesh.get_meta("slot", "primary"))
		var mat := mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = palette.get(slot, primary)


func update_pose(delta: float, body: CharacterBody3D) -> void:
	if skeleton == null:
		return
	_bob += delta
	var state_node: TraversalStateMachine = body.get_node_or_null("StateMachine")
	var state := TraversalStateMachine.State.AIR
	if state_node:
		state = state_node.state
	var speed := body.velocity.length()
	if anim_tree:
		anim_tree.set("parameters/blend_position", clampf(speed / 10.0, 0.0, 1.0))
	var swing: WebSwingController = body.get_node_or_null("WebSystem/WebSwingController")
	var anchor := swing.anchor_point if swing and swing.active else body.global_position + Vector3.UP * 3.0
	var lean := MathUtil.flatten(body.velocity)
	if lean.length() > 0.4:
		var yaw := atan2(lean.x, lean.z)
		rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-8.0 * delta))
	elif state == TraversalStateMachine.State.GROUNDED:
		var cam: CameraRig = body.get_node_or_null("CameraRig")
		if cam:
			rotation.y = lerp_angle(rotation.y, cam.yaw, 1.0 - exp(-6.0 * delta))
	_pose_for(state, body, anchor, delta)


func _pose_for(state: TraversalStateMachine.State, body: CharacterBody3D, anchor: Vector3, delta: float) -> void:
	var hips := Vector3(0, 0.95, 0)
	var chest := Vector3(0, 1.35, 0)
	var head := Vector3(0, 1.62, 0)
	var hand_r := Vector3(0.32, 1.25, 0.1)
	var hand_l := Vector3(-0.32, 1.25, 0.1)
	var foot_r := Vector3(0.16, 0.12, 0.05)
	var foot_l := Vector3(-0.16, 0.12, -0.05)
	var t := _bob
	match state:
		TraversalStateMachine.State.GROUNDED:
			var step := sin(t * clampf(body.velocity.length() * 1.3, 2.0, 14.0))
			foot_r.z = step * 0.28
			foot_l.z = -step * 0.28
			foot_r.y = 0.12 + maxf(step, 0.0) * 0.18
			foot_l.y = 0.12 + maxf(-step, 0.0) * 0.18
			hand_r.z = -step * 0.18
			hand_l.z = step * 0.18
			hips.y += sin(t * 8.0) * 0.02
		TraversalStateMachine.State.SWING, TraversalStateMachine.State.SLINGSHOT:
			var to_anchor := anchor - body.global_position
			var local_anchor := global_transform.affine_inverse() * anchor
			hand_r = local_anchor.normalized() * 0.72 + Vector3(0.1, 1.2, 0)
			hand_l = Vector3(-0.28, 1.05, -0.2)
			chest += to_anchor.normalized() * 0.05
			foot_r = Vector3(0.18, 0.35, -0.35)
			foot_l = Vector3(-0.16, 0.42, -0.42)
		TraversalStateMachine.State.ZIP:
			hand_r = Vector3(0.2, 1.35, -0.55)
			hand_l = Vector3(-0.15, 1.2, -0.2)
			foot_r = Vector3(0.12, 0.4, 0.25)
			foot_l = Vector3(-0.12, 0.45, 0.3)
		TraversalStateMachine.State.DIVE:
			head = Vector3(0, 1.35, -0.25)
			hand_r = Vector3(0.4, 1.15, 0.35)
			hand_l = Vector3(-0.4, 1.15, 0.35)
			foot_r = Vector3(0.14, 0.55, 0.2)
			foot_l = Vector3(-0.14, 0.5, 0.15)
		TraversalStateMachine.State.WALL_RUN:
			hand_r = Vector3(0.45, 1.2, 0.1)
			foot_r = Vector3(0.2, 0.2 + absf(sin(t * 14.0)) * 0.25, sin(t * 14.0) * 0.2)
			foot_l = Vector3(-0.05, 0.2 + absf(cos(t * 14.0)) * 0.25, cos(t * 14.0) * 0.2)
		TraversalStateMachine.State.WALL_CRAWL, TraversalStateMachine.State.PERCH:
			hips = Vector3(0, 0.7, 0.1)
			chest = Vector3(0, 1.05, 0.15)
			head = Vector3(0, 1.35, 0.2)
			hand_r = Vector3(0.45, 1.15, 0.35)
			hand_l = Vector3(-0.45, 1.15, 0.35)
			foot_r = Vector3(0.22, 0.35, -0.15)
			foot_l = Vector3(-0.22, 0.35, -0.15)
		_:
			hand_r = Vector3(0.42, 1.35, -0.05)
			hand_l = Vector3(-0.42, 1.32, -0.02)
			foot_r = Vector3(0.14, 0.28, 0.08)
			foot_l = Vector3(-0.12, 0.22, -0.02)
	_set_bone("hips", hips)
	_set_bone("chest", chest)
	_set_bone("head", head)
	_set_bone("hand_r", hand_r)
	_set_bone("hand_l", hand_l)
	_set_bone("foot_r", foot_r)
	_set_bone("foot_l", foot_l)
	if web_muzzle:
		web_muzzle.position = hand_r


func _set_bone(bone_name: String, pos: Vector3) -> void:
	if not _bones.has(bone_name):
		return
	skeleton.set_bone_pose_position(_bones[bone_name], pos)


func _build_rig() -> void:
	skeleton = Skeleton3D.new()
	add_child(skeleton)
	var names := ["hips", "chest", "head", "hand_r", "hand_l", "foot_r", "foot_l"]
	var rests := {
		"hips": Vector3(0, 0.95, 0),
		"chest": Vector3(0, 1.35, 0),
		"head": Vector3(0, 1.62, 0),
		"hand_r": Vector3(0.32, 1.25, 0.1),
		"hand_l": Vector3(-0.32, 1.25, 0.1),
		"foot_r": Vector3(0.16, 0.12, 0.05),
		"foot_l": Vector3(-0.16, 0.12, -0.05),
	}
	for bone_name in names:
		var idx := skeleton.add_bone(bone_name)
		_bones[bone_name] = idx
		var rest := Transform3D(Basis.IDENTITY, rests[bone_name])
		skeleton.set_bone_rest(idx, rest)
		skeleton.set_bone_pose_position(idx, rests[bone_name])
	_add_mesh("hips", "secondary", _capsule(0.22, 0.42), rests.hips)
	_add_mesh("chest", "primary", _capsule(0.28, 0.48), rests.chest)
	_add_mesh("head", "primary", _sphere(0.16), rests.head)
	_add_mesh("eye_r", "eye", _sphere(0.035), rests.head + Vector3(0.06, 0.03, -0.12))
	_add_mesh("eye_l", "eye", _sphere(0.035), rests.head + Vector3(-0.06, 0.03, -0.12))
	_add_mesh("hand_r", "secondary", _sphere(0.07), rests.hand_r)
	_add_mesh("hand_l", "secondary", _sphere(0.07), rests.hand_l)
	_add_mesh("foot_r", "secondary", _capsule(0.08, 0.42), rests.foot_r + Vector3(0, 0.2, 0))
	_add_mesh("foot_l", "secondary", _capsule(0.08, 0.42), rests.foot_l + Vector3(0, 0.2, 0))
	web_muzzle = Marker3D.new()
	web_muzzle.name = "WebMuzzle"
	web_muzzle.position = rests.hand_r
	add_child(web_muzzle)


func _add_mesh(slot: String, color_slot: String, mesh: Mesh, pos: Vector3) -> void:
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	inst.set_meta("slot", color_slot)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = palette.get(color_slot, palette.primary)
	mat.roughness = 0.55
	if color_slot == "eye":
		mat.emission_enabled = true
		mat.emission = palette.eye
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	inst.material_override = mat
	add_child(inst)
	_meshes.append(inst)


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 4
	return mesh


func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	return mesh


func _build_animations() -> void:
	anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	add_child(anim_player)
	var library := AnimationLibrary.new()
	library.add_animation("idle", _bob_animation(0.03, 1.4))
	library.add_animation("run", _bob_animation(0.07, 0.42))
	anim_player.add_animation_library("", library)
	anim_tree = AnimationTree.new()
	anim_tree.name = "AnimationTree"
	var blend := AnimationNodeBlendSpace1D.new()
	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = "idle"
	var run_node := AnimationNodeAnimation.new()
	run_node.animation = "run"
	blend.add_blend_point(idle_node, 0.0)
	blend.add_blend_point(run_node, 1.0)
	anim_tree.tree_root = blend
	add_child(anim_tree)
	anim_tree.anim_player = NodePath("../AnimationPlayer")
	anim_tree.active = true


func _bob_animation(amount: float, length: float) -> Animation:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR
	var idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(idx, NodePath(".:position"))
	anim.track_insert_key(idx, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(idx, length * 0.5, Vector3(0, amount, 0))
	anim.track_insert_key(idx, length, Vector3(0, 0, 0))
	return anim
