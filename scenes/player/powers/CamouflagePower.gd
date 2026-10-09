extends Node

var time_left: float = 0.0


func activate(_body: CharacterBody3D) -> void:
	time_left = 5.0
	get_tree().set_meta("weaver_camouflaged", true)


func tick(_body: CharacterBody3D, delta: float) -> void:
	if time_left <= 0.0:
		return
	time_left -= delta
	if time_left <= 0.0:
		get_tree().set_meta("weaver_camouflaged", false)
