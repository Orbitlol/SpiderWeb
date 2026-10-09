extends Node

var charges: int = 0


func activate(_body: CharacterBody3D) -> void:
	charges = 3


func tick(_body: CharacterBody3D, _delta: float) -> void:
	pass


func consume_bonus() -> float:
	if charges <= 0:
		return 1.0
	charges -= 1
	return 1.8
