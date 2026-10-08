extends Area3D

var velocity: Vector3 = Vector3.ZERO
var life: float = 4.0


func _ready() -> void:
	velocity = get_meta("velocity", Vector3.FORWARD * 12.0)
	body_entered.connect(_hit)


func _physics_process(delta: float) -> void:
	var scale := 1.0
	var player := get_tree().get_first_node_in_group("player")
	if player and player.get_node_or_null("FocusSystem"):
		scale = player.get_node("FocusSystem").enemy_scale()
	life -= delta
	global_position += velocity * delta * scale
	if life <= 0.0:
		_explode(false)


func _hit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("apply_damage"):
		body.apply_damage(12.0, global_position)
		_explode(true)
	elif body is StaticBody3D:
		_explode(false)


func _explode(hit_player: bool) -> void:
	AudioManager.play_at("explode", global_position, -4.0)
	queue_free()
