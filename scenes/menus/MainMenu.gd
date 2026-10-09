extends Control

var page: Control
var backdrop: Node3D


func _ready() -> void:
	theme = UIThemeBuilder.build()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	backdrop = Node3D.new()
	backdrop.set_script(preload("res://scenes/menus/MenuBackdrop.gd"))
	add_child(backdrop)
	_build_chrome()


func _build_chrome() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	panel.offset_right = 460
	panel.offset_left = 24
	panel.offset_top = 24
	panel.offset_bottom = -24
	add_child(panel)
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(400, 0)
	scroll.add_child(box)
	var title := Label.new()
	title.text = "SPIDERWEB"
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Unofficial fan project. Not affiliated with Marvel."
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub)
	_button(box, "CONTINUE", _continue_game, SaveManager.has_save())
	_button(box, "NEW GAME", _new_game, true)
	_button(box, "SUITS & SKINS", func() -> void: _go("res://scenes/workshops/SuitDesigner.tscn"), true)
	_button(box, "WEB WORKSHOP", func() -> void: _go("res://scenes/workshops/WebWorkshop.tscn"), true)
	_button(box, "MISSIONS", func() -> void: _show_missions(), true)
	_button(box, "FREE ROAM", func() -> void: _launch("free_roam", ""), true)
	_button(box, "CHALLENGES", func() -> void: _launch("challenge", "time_trial"), true)
	_button(box, "SKILLS", _show_skills, true)
	_button(box, "TRAINING", func() -> void: _launch("training", "first_flight"), true)
	_button(box, "COLLECTION", _show_collection, true)
	_button(box, "SETTINGS", _show_settings, true)
	_button(box, "CREDITS", _show_credits, true)
	page = PanelContainer.new()
	page.visible = false
	page.set_anchors_preset(Control.PRESET_CENTER)
	page.custom_minimum_size = Vector2(520, 420)
	page.theme = theme
	add_child(page)


func _button(parent: Node, text: String, callback: Callable, enabled: bool) -> void:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.custom_minimum_size = Vector2(380, 64)
	button.pressed.connect(func() -> void:
		AudioManager.play("ui")
		callback.call()
	)
	parent.add_child(button)


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)


func _launch(mode: String, mission: String) -> void:
	GameState.launch_mode = mode
	GameState.mission_id = mission
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _continue_game() -> void:
	GameState.launch_mode = "continue"
	GameState.mission_id = str(SaveManager.get_value("missions/active", ""))
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _new_game() -> void:
	SaveManager.reset_save()
	GameState.equipped_suit_id = "classic"
	GameState.launch_mode = "new_game"
	GameState.mission_id = "first_flight"
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")


func _open_page(title: String) -> VBoxContainer:
	for child in page.get_children():
		child.queue_free()
	page.visible = true
	var box := VBoxContainer.new()
	page.add_child(box)
	var label := Label.new()
	label.text = title
	box.add_child(label)
	var close := Button.new()
	close.text = "BACK"
	close.custom_minimum_size = Vector2(200, 56)
	close.pressed.connect(func() -> void: page.visible = false)
	box.add_child(close)
	return box


func _show_missions() -> void:
	var box := _open_page("MISSIONS")
	var ids := ["first_flight", "street_trouble", "king_of_the_sky", "lab_escape", "time_trial", "token_hunt"]
	var done: Array = SaveManager.get_value("missions/completed", [])
	for id in ids:
		var data := load("res://resources/missions/%s.tres" % id) as MissionData
		if data == null:
			continue
		var button := Button.new()
		var mark := "DONE" if id in done else "START"
		button.text = "%s  [%s]" % [data.title, mark]
		button.custom_minimum_size = Vector2(460, 60)
		button.pressed.connect(_launch.bind("mission", id))
		box.add_child(button)


func _show_skills() -> void:
	var box := _open_page("SKILLS")
	var points := Label.new()
	points.text = "Points %d   Level %d" % [int(SaveManager.get_value("skills/points", 0)), int(SaveManager.get_value("skills/level", 1))]
	box.add_child(points)
	for skill in GameState.skills:
		var button := Button.new()
		button.text = "%s  %d/%d" % [skill.display_name, GameState.skill_rank(skill.skill_id), skill.max_rank]
		button.custom_minimum_size = Vector2(460, 60)
		button.pressed.connect(func() -> void:
			if GameState.try_buy_skill(skill.skill_id):
				button.text = "%s  %d/%d" % [skill.display_name, GameState.skill_rank(skill.skill_id), skill.max_rank]
				points.text = "Points %d   Level %d" % [int(SaveManager.get_value("skills/points", 0)), int(SaveManager.get_value("skills/level", 1))]
				AudioManager.play("ui")
		)
		box.add_child(button)


func _show_collection() -> void:
	var box := _open_page("COLLECTION")
	var tokens := int(SaveManager.get_value("currencies/tokens", 0))
	var collected: Array = SaveManager.get_value("world/collected", [])
	var owned: Array = SaveManager.get_value("suits/owned", [])
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(460, 160)
	label.text = "Tokens %d\nCollected marks %d\nSuits %s\nReputation %s" % [tokens, collected.size(), ", ".join(owned), str(SaveManager.get_value("reputation", {}))]
	box.add_child(label)


func _show_settings() -> void:
	var box := _open_page("SETTINGS")
	_slider(box, "Sensitivity", SettingsManager.look_sensitivity, 0.4, 2.2, func(v: float) -> void:
		SettingsManager.look_sensitivity = v
		SettingsManager.save_settings()
	)
	_slider(box, "Swing assist", SettingsManager.swing_assist, 0.0, 1.0, func(v: float) -> void:
		SettingsManager.swing_assist = v
		SettingsManager.save_settings()
	)
	_slider(box, "FOV", SettingsManager.fov, 55.0, 95.0, func(v: float) -> void:
		SettingsManager.fov = v
		SettingsManager.save_settings()
	)
	_check(box, "Invert Y", SettingsManager.invert_y, func(v: bool) -> void: SettingsManager.invert_y = v; SettingsManager.save_settings())
	_check(box, "Left handed", SettingsManager.left_handed, func(v: bool) -> void: SettingsManager.left_handed = v; SettingsManager.save_settings())
	_check(box, "Haptics", SettingsManager.haptics_enabled, func(v: bool) -> void: SettingsManager.haptics_enabled = v; SettingsManager.save_settings())
	_check(box, "Subtitles", SettingsManager.subtitles, func(v: bool) -> void: SettingsManager.subtitles = v; SettingsManager.save_settings())
	_check(box, "Camera shake", SettingsManager.camera_shake, func(v: bool) -> void: SettingsManager.camera_shake = v; SettingsManager.save_settings())
	_check(box, "Reduced flash", SettingsManager.reduced_flash, func(v: bool) -> void: SettingsManager.reduced_flash = v; SettingsManager.save_settings())
	_check(box, "Web toggle", SettingsManager.web_toggle, func(v: bool) -> void: SettingsManager.web_toggle = v; SettingsManager.save_settings())
	_slider(box, "Music", SettingsManager.music_volume, 0.0, 1.0, func(v: float) -> void:
		SettingsManager.music_volume = v
		SettingsManager.save_settings()
	)
	_slider(box, "SFX", SettingsManager.sfx_volume, 0.0, 1.0, func(v: float) -> void:
		SettingsManager.sfx_volume = v
		SettingsManager.save_settings()
	)


func _show_credits() -> void:
	var box := _open_page("CREDITS")
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(460, 220)
	label.text = "SPIDERWEB\nA Godot 4 fan game about swinging through a grey-box city.\n\nWeaver, Miles, Gwen, and the city of this build are original implementations. Character archetypes are homages and are not official Marvel products.\n\nBuilt with Godot 4.7, GDScript, and the mobile renderer."
	box.add_child(label)


func _slider(parent: Node, label_text: String, value: float, min_v: float, max_v: float, on_change: Callable) -> void:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = 0.01
	slider.value = value
	slider.custom_minimum_size = Vector2(420, 36)
	slider.value_changed.connect(on_change)
	parent.add_child(slider)


func _check(parent: Node, label_text: String, value: bool, on_change: Callable) -> void:
	var check := CheckBox.new()
	check.text = label_text
	check.button_pressed = value
	check.toggled.connect(on_change)
	parent.add_child(check)
