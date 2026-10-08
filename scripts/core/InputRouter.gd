extends Node

var touch_pressed: Dictionary = {}
var touch_just: Dictionary = {}
var touch_released: Dictionary = {}
var move_vector: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO


func _ready() -> void:
	process_priority = 100


func _process(_delta: float) -> void:
	touch_just.clear()
	touch_released.clear()
	look_delta = Vector2.ZERO


func set_touch(action: StringName, pressed: bool) -> void:
	var was: bool = bool(touch_pressed.get(action, false))
	touch_pressed[action] = pressed
	if pressed and not was:
		touch_just[action] = true
	if not pressed and was:
		touch_released[action] = true


func is_pressed(action: StringName) -> bool:
	return Input.is_action_pressed(action) or bool(touch_pressed.get(action, false))


func just_pressed(action: StringName) -> bool:
	return Input.is_action_just_pressed(action) or bool(touch_just.get(action, false))


func just_released(action: StringName) -> bool:
	return Input.is_action_just_released(action) or bool(touch_released.get(action, false))


func get_move() -> Vector2:
	var hardware := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	return (hardware + move_vector).limit_length(1.0)


func get_look() -> Vector2:
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	return stick


func pointer_over_ui() -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null and not hovered.is_in_group("gameplay_catcher")
