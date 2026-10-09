extends "res://scenes/enemies/Enemy.gd"

var phase: int = 1


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	set_meta("can_swing_anchor", true)


func take_damage(amount: float, from: Vector3, heavy: bool) -> void:
	super.take_damage(amount, from, heavy)
	if alive and health_ratio() < 0.5 and phase == 1:
		phase = 2
		EventBus.dialogue_requested.emit(enemy_id, "You are starting to annoy me.")
