extends Area3D

var token_id: String = ""
var _spin: float = 0.0


func _ready() -> void:
	token_id = str(get_meta("token_id", name))
	body_entered.connect(_on_body)
	add_to_group("token")


func _process(delta: float) -> void:
	_spin += delta * 2.2
	rotation.y = _spin
	position.y += sin(_spin * 1.5) * 0.002


func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var collected: Array = SaveManager.get_value("world/collected", []).duplicate()
	if token_id in collected:
		queue_free()
		return
	collected.append(token_id)
	SaveManager.set_value("world/collected", collected)
	GameState.add_tokens(1)
	GameState.add_xp(5)
	AudioManager.play("pickup", -2.0)
	EventBus.token_collected.emit(token_id)
	queue_free()
