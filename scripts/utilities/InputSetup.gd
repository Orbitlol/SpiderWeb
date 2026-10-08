extends RefCounted
class_name InputSetup

static func ensure_actions() -> void:
	_action("move_forward", 0.2, [key(KEY_W), key(KEY_UP), joy_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_backward", 0.2, [key(KEY_S), key(KEY_DOWN), joy_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("move_left", 0.2, [key(KEY_A), key(KEY_LEFT), joy_axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", 0.2, [key(KEY_D), key(KEY_RIGHT), joy_axis(JOY_AXIS_LEFT_X, 1.0)])
	_action("look_left", 0.15, [joy_axis(JOY_AXIS_RIGHT_X, -1.0)])
	_action("look_right", 0.15, [joy_axis(JOY_AXIS_RIGHT_X, 1.0)])
	_action("look_up", 0.15, [joy_axis(JOY_AXIS_RIGHT_Y, -1.0)])
	_action("look_down", 0.15, [joy_axis(JOY_AXIS_RIGHT_Y, 1.0)])
	_action("jump", 0.3, [key(KEY_SPACE), joy_button(JOY_BUTTON_A)])
	_action("web", 0.3, [key(KEY_SHIFT), mouse(MOUSE_BUTTON_RIGHT), joy_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)])
	_action("web_zip", 0.3, [key(KEY_E), joy_button(JOY_BUTTON_RIGHT_SHOULDER)])
	_action("reel_in", 0.2, [key(KEY_R), mouse(MOUSE_BUTTON_WHEEL_UP), joy_button(JOY_BUTTON_DPAD_UP)])
	_action("reel_out", 0.2, [key(KEY_F), mouse(MOUSE_BUTTON_WHEEL_DOWN), joy_button(JOY_BUTTON_DPAD_DOWN)])
	_action("attack", 0.2, [key(KEY_G), joy_button(JOY_BUTTON_X)])
	_action("heavy_attack", 0.2, [key(KEY_H), joy_button(JOY_BUTTON_Y)])
	_action("dodge", 0.2, [key(KEY_CTRL), joy_button(JOY_BUTTON_B)])
	_action("gadget", 0.2, [key(KEY_V), joy_button(JOY_BUTTON_LEFT_SHOULDER)])
	_action("suit_power", 0.2, [key(KEY_X), joy_button(JOY_BUTTON_LEFT_STICK)])
	_action("focus", 0.2, [key(KEY_Q), joy_button(JOY_BUTTON_RIGHT_STICK)])
	_action("slingshot", 0.2, [key(KEY_Z), joy_button(JOY_BUTTON_DPAD_LEFT)])
	_action("dive", 0.2, [key(KEY_C), joy_button(JOY_BUTTON_DPAD_RIGHT)])
	_action("crawl", 0.2, [key(KEY_ALT)])
	_action("interact", 0.2, [key(KEY_T)])
	_action("pause", 0.3, [key(KEY_ESCAPE), joy_button(JOY_BUTTON_START)])
	_action("photo_mode", 0.3, [key(KEY_P), joy_button(JOY_BUTTON_BACK)])


static func _action(action: String, deadzone: float, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	else:
		InputMap.action_set_deadzone(action, deadzone)
	if InputMap.action_get_events(action).is_empty():
		for event in events:
			InputMap.action_add_event(action, event)


static func key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event


static func joy_button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.device = -1
	return event


static func joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	event.device = -1
	return event


static func mouse(button: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	return event
