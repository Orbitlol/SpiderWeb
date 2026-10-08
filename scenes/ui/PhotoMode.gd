extends CanvasLayer

var camera: Camera3D
var panel: PanelContainer
var active: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _saved_current: Camera3D


func _ready() -> void:
	layer = 12
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open_from(current: Camera3D) -> void:
	_saved_current = current
	camera = Camera3D.new()
	camera.current = true
	camera.fov = current.fov
	camera.global_transform = current.global_transform
	add_child(camera)
	active = true
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.photo_mode_toggled.emit(true)


func close() -> void:
	active = false
	visible = false
	get_tree().paused = false
	if camera:
		camera.queue_free()
		camera = null
	if _saved_current:
		_saved_current.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	EventBus.photo_mode_toggled.emit(false)


func _build() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(24, 24)
	panel.theme = UIThemeBuilder.build()
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_slider("Time of day", 0.0, 1.0, 0.62, func(v: float) -> void:
		var cycle := get_tree().get_first_node_in_group("day_night")
		if cycle and cycle.has_method("set_time"):
			cycle.set_time(v)
	))
	box.add_child(_slider("FOV", 40.0, 100.0, 70.0, func(v: float) -> void:
		if camera:
			camera.fov = v
	))
	var capture := Button.new()
	capture.text = "SAVE PHOTO"
	capture.custom_minimum_size = Vector2(220, 64)
	capture.pressed.connect(_capture)
	box.add_child(capture)
	var exit := Button.new()
	exit.text = "EXIT"
	exit.custom_minimum_size = Vector2(220, 64)
	exit.pressed.connect(close)
	box.add_child(exit)
	add_child(panel)


func _slider(label_text: String, min_v: float, max_v: float, value: float, on_change: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.value = value
	slider.custom_minimum_size = Vector2(240, 36)
	slider.value_changed.connect(on_change)
	box.add_child(slider)
	return box


func _process(delta: float) -> void:
	if not active or camera == null:
		return
	var look := InputRouter.get_look()
	_yaw -= look.x * delta * 1.6
	_pitch = clampf(_pitch - look.y * delta, -1.2, 1.2)
	camera.rotation = Vector3(_pitch, _yaw, 0)
	var move := InputRouter.get_move()
	var basis := camera.global_transform.basis
	var motion := basis * Vector3(move.x, 0, -move.y)
	if InputRouter.is_pressed("jump"):
		motion.y += 1.0
	if InputRouter.is_pressed("dive"):
		motion.y -= 1.0
	camera.global_position += motion * 12.0 * delta


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("photo_mode"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * 0.004
		_pitch = clampf(_pitch - event.relative.y * 0.004, -1.2, 1.2)


func _capture() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("user://photos")
	var path := "user://photos/spiderweb_%d.png" % Time.get_unix_time_from_system()
	image.save_png(path)
	EventBus.dialogue_requested.emit("Photo", "Saved to the photos folder.")
