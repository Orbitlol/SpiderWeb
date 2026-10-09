extends CanvasLayer

var panel: PanelContainer
var settings_box: VBoxContainer
var visible_menu: bool = false


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_node_or_null("../PhotoMode") and get_node("../PhotoMode").active:
			return
		toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("photo_mode") and not visible_menu:
		var player := get_tree().get_first_node_in_group("player")
		if player:
			get_node("../PhotoMode").open_from(player.get_node("CameraRig").camera)
			get_viewport().set_input_as_handled()


func toggle() -> void:
	visible_menu = not visible_menu
	visible = visible_menu
	get_tree().paused = visible_menu
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if visible_menu else _capture_mode()


func _capture_mode() -> Input.MouseMode:
	if SettingsManager.touch_controls_visible():
		return Input.MOUSE_MODE_VISIBLE
	return Input.MOUSE_MODE_CAPTURED


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	panel = PanelContainer.new()
	panel.theme = UIThemeBuilder.build()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 520)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_button(box, "RESUME", toggle)
	_button(box, "WEB WORKSHOP", func() -> void: _open_overlay("res://scenes/workshops/WebWorkshop.tscn"))
	_button(box, "SUITS", func() -> void: _open_overlay("res://scenes/workshops/SuitDesigner.tscn"))
	_button(box, "PHOTO MODE", func() -> void:
		toggle()
		var player := get_tree().get_first_node_in_group("player")
		if player:
			get_node("../PhotoMode").open_from(player.get_node("CameraRig").camera)
	)
	_button(box, "SAVE", func() -> void:
		var player := get_tree().get_first_node_in_group("player")
		if player and player.has_method("_write_progress"):
			player._write_progress()
		else:
			SaveManager.save_game()
		EventBus.dialogue_requested.emit("Save", "Progress saved.")
	)
	_button(box, "SETTINGS", func() -> void: settings_box.visible = not settings_box.visible)
	settings_box = VBoxContainer.new()
	settings_box.visible = false
	box.add_child(settings_box)
	_settings(settings_box)
	_button(box, "QUIT TO MENU", func() -> void:
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
	)
	add_child(panel)
	panel.position = Vector2(40, 40)


func _button(parent: Node, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(360, 64)
	button.pressed.connect(callback)
	parent.add_child(button)


func _settings(parent: Node) -> void:
	_slider(parent, "Look", 0.4, 2.2, SettingsManager.look_sensitivity, func(v: float) -> void:
		SettingsManager.look_sensitivity = v
		SettingsManager.save_settings()
	)
	_check(parent, "Left handed", SettingsManager.left_handed, func(v: bool) -> void:
		SettingsManager.left_handed = v
		SettingsManager.save_settings()
	)
	_check(parent, "Haptics", SettingsManager.haptics_enabled, func(v: bool) -> void:
		SettingsManager.haptics_enabled = v
		SettingsManager.save_settings()
	)
	_check(parent, "Touch controls", SettingsManager.touch_controls_visible(), func(v: bool) -> void:
		SettingsManager.touch_controls = 1 if v else 2
		SettingsManager.save_settings()
	)
	_check(parent, "Web toggle", SettingsManager.web_toggle, func(v: bool) -> void:
		SettingsManager.web_toggle = v
		SettingsManager.save_settings()
	)


func _slider(parent: Node, label_text: String, min_v: float, max_v: float, value: float, on_change: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(320, 36)
	slider.value_changed.connect(on_change)
	parent.add_child(slider)


func _check(parent: Node, label_text: String, value: bool, on_change: Callable) -> void:
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = value
	check.toggled.connect(on_change)
	parent.add_child(check)


func _open_overlay(path: String) -> void:
	var existing := get_node_or_null("Overlay")
	if existing:
		existing.queue_free()
	var packed := load(path) as PackedScene
	var node := packed.instantiate()
	node.name = "Overlay"
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(node)
