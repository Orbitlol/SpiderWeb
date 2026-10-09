extends Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if "--test" in args or OS.get_environment("SPIDERWEB_TEST") == "1":
		get_tree().change_scene_to_file("res://tests/run_tests.tscn")
		return
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
