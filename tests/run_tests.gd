extends Node

func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := PackedStringArray()
	failed.append_array(preload("res://tests/traversal/test_swing.gd").run())
	failed.append_array(preload("res://tests/save/test_save.gd").run())
	failed.append_array(preload("res://tests/combat/test_combat.gd").run())
	failed.append_array(preload("res://tests/performance/test_budget.gd").run())
	failed.append_array(preload("res://tests/resources/test_catalog.gd").run())
	if failed.is_empty():
		print("SPIDERWEB TESTS PASSED")
		get_tree().quit(0)
		return
	for item in failed:
		push_error(item)
		print("FAIL ", item)
	get_tree().quit(1)
