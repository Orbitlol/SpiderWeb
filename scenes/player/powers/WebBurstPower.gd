extends Node

var time_left: float = 0.0


func activate(body: CharacterBody3D) -> void:
	time_left = 0.4
	var space := body.get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = 7.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, body.global_position)
	query.collision_mask = PhysLayers.CHARACTER
	query.exclude = [body.get_rid()]
	for hit in space.intersect_shape(query, 10):
		var node: Object = hit.collider
		if node and node.has_method("apply_web_yank"):
			node.apply_web_yank(body.global_position)
		if node and node.is_in_group("enemy") and node.has_method("take_damage"):
			node.take_damage(10.0 * GameState.damage_multiplier(), body.global_position, false)
	Haptics.pulse(40, 0.6)


func tick(_body: CharacterBody3D, delta: float) -> void:
	time_left = maxf(0.0, time_left - delta)
