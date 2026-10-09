extends Control

var stick_finger: int = -1
var camera_finger: int = -1
var stick_origin: Vector2 = Vector2.ZERO
var stick_radius: float = 78.0
var stick_visual: Control
var knob: Control
var buttons: Array[VirtualButton] = []
var swipe_origin: Vector2 = Vector2.ZERO
var swipe_time: float = 0.0


func _ready() -> void:
	add_to_group("gameplay_catcher")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_stick()
	_build_buttons()
	EventBus.settings_changed.connect(_apply_layout)
	_apply_layout()
	visibility_changed.connect(_clear_touch)


func _apply_layout() -> void:
	visible = SettingsManager.touch_controls_visible()
	var scale := SettingsManager.button_scale
	var left := SettingsManager.left_handed
	for button in buttons:
		_place(button, left, scale)
	stick_radius = 78.0 * scale


func _build_stick() -> void:
	stick_visual = Control.new()
	stick_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick_visual.custom_minimum_size = Vector2(150, 150)
	stick_visual.visible = false
	var base := ColorRect.new()
	base.color = Color(1, 1, 1, 0.12)
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick_visual.add_child(base)
	knob = ColorRect.new()
	knob.color = Color(0.9, 0.25, 0.28, 0.85)
	knob.custom_minimum_size = Vector2(64, 64)
	knob.size = Vector2(64, 64)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stick_visual.add_child(knob)
	add_child(stick_visual)


func _build_buttons() -> void:
	_add_button("WEB", "web", Vector2(150, 118), Vector2(210, 210), "web")
	_add_button("JUMP", "jump", Vector2(118, 118), Vector2(150, 36), "jump")
	_add_button("ZIP", "web_zip", Vector2(96, 84), Vector2(40, 230), "zip")
	_add_button("ATK", "attack", Vector2(96, 84), Vector2(40, 130), "attack")
	_add_button("DODGE", "dodge", Vector2(96, 72), Vector2(160, 160), "dodge")
	_add_button("REEL", "reel_in", Vector2(88, 64), Vector2(250, 250), "reel_in")
	_add_button("OUT", "reel_out", Vector2(88, 64), Vector2(250, 170), "reel_out")
	_add_button("SLING", "slingshot", Vector2(96, 64), Vector2(250, 90), "sling")
	_add_button("DIVE", "dive", Vector2(88, 64), Vector2(40, 40), "dive")
	_add_button("GEAR", "gadget", Vector2(84, 64), Vector2(360, 210), "gadget")
	_add_button("POWER", "suit_power", Vector2(96, 64), Vector2(360, 130), "power")
	_add_button("FOCUS", "focus", Vector2(96, 64), Vector2(360, 50), "focus")


func _add_button(label: String, action: String, size: Vector2, offset: Vector2, slot: String) -> void:
	var button := Button.new()
	button.set_script(preload("res://scenes/ui/VirtualButton.gd"))
	button.text = label
	button.action = StringName(action)
	button.custom_minimum_size = size
	button.set_meta("offset", offset)
	button.set_meta("slot", slot)
	button.set_meta("base_size", size)
	add_child(button)
	buttons.append(button)


func _place(button: VirtualButton, left_handed: bool, scale: float) -> void:
	var offset: Vector2 = button.get_meta("offset")
	var base: Vector2 = button.get_meta("base_size")
	button.custom_minimum_size = base * scale
	button.size = base * scale
	var margin := 28.0
	if left_handed:
		button.position = Vector2(margin + offset.y * 0.15, size.y - margin - offset.x) 
		# mirror: original offsets are from the right/bottom cluster. Place from left.
		button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		button.position = Vector2(margin + (360.0 - offset.x) * 0.25, -margin - offset.y * 0.35) 
	else:
		button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		button.position = Vector2(-margin - offset.x, -margin - offset.y)
	button.reset_size()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var stick_zone_right := SettingsManager.left_handed
	if event is InputEventScreenTouch:
		if event.pressed:
			if stick_finger < 0 and _in_stick_zone(event.position, stick_zone_right):
				stick_finger = event.index
				stick_origin = event.position
				_show_stick(event.position)
				get_viewport().set_input_as_handled()
			elif camera_finger < 0 and _in_camera_zone(event.position, stick_zone_right):
				camera_finger = event.index
				swipe_origin = event.position
				swipe_time = 0.0
				get_viewport().set_input_as_handled()
		else:
			if event.index == stick_finger:
				stick_finger = -1
				InputRouter.move_vector = Vector2.ZERO
				stick_visual.visible = false
			if event.index == camera_finger:
				camera_finger = -1
	elif event is InputEventScreenDrag:
		if event.index == stick_finger:
			var delta := event.position - stick_origin
			var clamped := Vector2(delta.x, -delta.y).limit_length(stick_radius)
			InputRouter.move_vector = clamped / stick_radius
			knob.position = Vector2(43, 43) + Vector2(clamped.x, -clamped.y) * 0.5
			get_viewport().set_input_as_handled()
		elif event.index == camera_finger:
			InputRouter.look_delta += event.relative
			swipe_time += get_process_delta_time()
			if event.relative.y > 28.0 and swipe_time < 0.28 and event.position.y - swipe_origin.y > 90.0:
				InputRouter.set_touch("dive", true)
				InputRouter.set_touch("dive", false)


func _in_stick_zone(pos: Vector2, stick_on_right: bool) -> bool:
	var width := size.x
	if stick_on_right:
		return pos.x > width * 0.58
	return pos.x < width * 0.42


func _in_camera_zone(pos: Vector2, stick_on_right: bool) -> bool:
	return not _in_stick_zone(pos, stick_on_right)


func _show_stick(pos: Vector2) -> void:
	stick_visual.visible = true
	stick_visual.position = pos - Vector2(75, 75)
	knob.position = Vector2(43, 43)


func _clear_touch() -> void:
	InputRouter.move_vector = Vector2.ZERO
	stick_finger = -1
	camera_finger = -1
