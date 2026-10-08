extends Control

var style: WebStyleData
var preview_solver := SwingSolver.new()
var preview_pos := Vector3(0, 1.6, 0)
var preview_vel := Vector3(2.4, 0, 0)
var mannequin: Node3D
var rope_mesh: ImmediateMesh
var rope_mat: ShaderMaterial
var viewport: SubViewport


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UIThemeBuilder.build()
	style = GameState.web_style.duplicate_style() if GameState.web_style else WebStyleData.new()
	_build()
	process_mode = Node.PROCESS_MODE_ALWAYS


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var row := HBoxContainer.new()
	margin.add_child(row)
	var controls := VBoxContainer.new()
	controls.custom_minimum_size = Vector2(420, 0)
	row.add_child(controls)
	var title := Label.new()
	title.text = "WEB WORKSHOP"
	controls.add_child(title)
	var presets := OptionButton.new()
	presets.custom_minimum_size = Vector2(360, 56)
	var index := 0
	for id in GameState.web_styles.keys():
		presets.add_item(GameState.web_styles[id].style_name, index)
		presets.set_item_metadata(index, id)
		index += 1
	presets.item_selected.connect(func(i: int) -> void:
		var id := str(presets.get_item_metadata(i))
		style = GameState.web_styles[id].duplicate_style()
		_sync_material()
	)
	controls.add_child(presets)
	controls.add_child(_color("Web color", style.primary_color, func(c: Color) -> void:
		style.primary_color = c
		_sync_material()
	))
	controls.add_child(_color("Accent", style.accent_color, func(c: Color) -> void:
		style.accent_color = c
		_sync_material()
	))
	controls.add_child(_slider("Thickness", 0.012, 0.08, style.thickness, func(v: float) -> void: style.thickness = v))
	controls.add_child(_slider("Glow", 0.2, 4.0, style.glow, func(v: float) -> void:
		style.glow = v
		_sync_material()
	))
	controls.add_child(_slider("Braid", 4.0, 48.0, style.braid_scale, func(v: float) -> void:
		style.braid_scale = v
		_sync_material()
	))
	controls.add_child(_slider("Strands", 1, 3, style.strands, func(v: float) -> void: style.strands = int(v)))
	var apply := Button.new()
	apply.text = "APPLY"
	apply.custom_minimum_size = Vector2(360, 68)
	apply.pressed.connect(func() -> void:
		style.style_id = "custom"
		style.style_name = "Custom"
		GameState.apply_web_style(style)
		AudioManager.play("ui")
	)
	controls.add_child(apply)
	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(360, 68)
	close.pressed.connect(_close)
	controls.add_child(close)
	_build_preview(row)


func _build_preview(row: HBoxContainer) -> void:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = Vector2(480, 640)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.stretch = true
	row.add_child(container)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true
	viewport.size = Vector2i(480, 640)
	container.add_child(viewport)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.06, 0.09)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.6, 0.65, 0.75)
	env.environment = environment
	viewport.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, 30, 0)
	viewport.add_child(light)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 3.2, 7.5)
	cam.look_at(Vector3(0, 2.2, 0))
	viewport.add_child(cam)
	mannequin = Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.28
	cap.height = 1.5
	body.mesh = cap
	body.position = Vector3(0, 0.9, 0)
	mannequin.add_child(body)
	viewport.add_child(mannequin)
	var pole := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.2, 6, 0.2)
	pole.mesh = box
	pole.position = Vector3(0, 5.5, 0)
	viewport.add_child(pole)
	rope_mesh = ImmediateMesh.new()
	var rope := MeshInstance3D.new()
	rope.mesh = rope_mesh
	rope_mat = MaterialLibrary.web_material(style)
	rope.material_override = rope_mat
	viewport.add_child(rope)
	preview_solver.anchor = Vector3(0, 6.5, 0)
	preview_solver.rope_length = 5.2
	preview_solver.taut = true


func _process(delta: float) -> void:
	if viewport == null:
		return
	var result := preview_solver.step(preview_pos, preview_vel, delta, Vector3(0.2, 0, 0.4), 0.0)
	preview_pos = result.position
	preview_vel = result.velocity
	if preview_pos.y < 0.4:
		preview_pos = Vector3(0.2, 1.8, 0.4)
		preview_vel = Vector3(2.0, 1.0, 1.2)
		preview_solver.taut = false
	mannequin.global_position = preview_pos
	_draw_preview_rope()


func _draw_preview_rope() -> void:
	rope_mesh.clear_surfaces()
	rope_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	rope_mesh.surface_add_vertex(preview_solver.anchor)
	rope_mesh.surface_add_vertex(preview_pos + Vector3(0.3, 1.2, 0))
	rope_mesh.surface_end()


func _sync_material() -> void:
	if rope_mat:
		MaterialLibrary.apply_web_style(rope_mat, style)


func _color(label_text: String, color: Color, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(140, 40)
	row.add_child(label)
	var picker := ColorPickerButton.new()
	picker.color = color
	picker.custom_minimum_size = Vector2(180, 48)
	picker.color_changed.connect(on_change)
	row.add_child(picker)
	return row


func _slider(label_text: String, min_v: float, max_v: float, value: float, on_change: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.value = value
	slider.step = 0.01 if max_v <= 10.0 else 1.0
	slider.custom_minimum_size = Vector2(340, 36)
	slider.value_changed.connect(on_change)
	box.add_child(slider)
	return box


func _close() -> void:
	if name == "Overlay":
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
