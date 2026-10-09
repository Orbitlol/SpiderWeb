extends Node
class_name InteractionSystem

var prompt: String = ""
var _target: Node


func tick(delta: float) -> void:
	prompt = ""
	_target = null
	var body := get_parent() as CharacterBody3D
	if body == null:
		return
	var origin := body.global_position + Vector3.UP * 1.2
	var forward := -body.get_node("CameraRig").global_transform.basis.z
	var space := body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * 3.2)
	query.collision_mask = PhysLayers.CHARACTER | PhysLayers.TRIGGER
	query.exclude = [body.get_rid()]
	query.collide_with_areas = true
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var collider: Object = hit.collider
	if collider is Node and collider.has_method("interact_prompt"):
		_target = collider
		prompt = collider.interact_prompt()


func try_interact() -> void:
	if _target and is_instance_valid(_target) and _target.has_method("interact"):
		_target.interact(get_parent())
