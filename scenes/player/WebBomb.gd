extends Area3D

var velocity: Vector3 = Vector3.ZERO
var life: float = 1.6


func _ready() -> void:
	velocity = get_meta("velocity", Vector3.FORWARD * 20.0)
	life = float(get_meta("life", 1.6))
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	life -= delta
	velocity.y -= 12.0 * delta
	global_position += velocity * delta
	if life <= 0.0:
		_burst()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		return
	_burst()


func _burst() -> void:
	var radius := 6.5
	var damage := 12.0
	if GameState.gadget:
		radius = GameState.gadget.radius
		damage = GameState.gadget.damage
	var space := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = PhysLayers.CHARACTER
	for hit in space.intersect_shape(query, 12):
		var node: Object = hit.collider
		if node and node.has_method("apply_web_yank"):
			node.apply_web_yank(global_position)
		if node and node.has_method("take_damage") and node.is_in_group("enemy"):
			node.take_damage(damage, global_position, false)
	AudioManager.play_at("explode", global_position, -2.0)
	queue_free()
