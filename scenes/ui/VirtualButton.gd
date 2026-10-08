extends Button
class_name VirtualButton

@export var action: StringName = &"jump"
var fingers: Array[int] = []


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	button_down.connect(func() -> void: InputRouter.set_touch(action, true))
	button_up.connect(func() -> void: InputRouter.set_touch(action, false))


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and get_global_rect().has_point(event.position) and fingers.is_empty():
			fingers.append(event.index)
			InputRouter.set_touch(action, true)
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index in fingers:
			fingers.erase(event.index)
			if fingers.is_empty():
				InputRouter.set_touch(action, false)
			get_viewport().set_input_as_handled()
