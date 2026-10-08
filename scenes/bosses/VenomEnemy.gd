extends "res://scenes/bosses/Boss.gd"

var pounce: float = 2.0


func _ready() -> void:
	data = load("res://resources/enemies/venom.tres")
	super._ready()
	enemy_id = "venom"
	scale = Vector3(1.25, 1.25, 1.25)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not alive:
		return
	pounce -= delta
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null or pounce > 0.0:
		return
	if global_position.distance_to(player.global_position) < 14.0:
		var leap := (player.global_position - global_position).normalized()
		velocity = leap * 16.0 + Vector3.UP * 6.0
		pounce = 2.4
		var sense := player.get_node_or_null("SpiderSense")
		if sense:
			sense.warn(0.35)
