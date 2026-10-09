extends Node


func activate(body: CharacterBody3D) -> void:
	if body.has_method("heal"):
		body.heal(28.0)
	var space := body.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 5.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, body.global_position)
	query.collision_mask = PhysLayers.CHARACTER
	query.exclude = [body.get_rid()]
	for hit in space.intersect_shape(query, 8):
		var node: Object = hit.collider
		if node and node.is_in_group("enemy") and node.has_method("take_damage"):
			node.take_damage(16.0, body.global_position, true)
	Haptics.pulse(36, 0.5)


func tick(_body: CharacterBody3D, _delta: float) -> void:
	pass
