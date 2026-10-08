extends Control

var primary: Color = Color(0.72, 0.08, 0.1)
var secondary: Color = Color(0.08, 0.12, 0.32)
var accent: Color = Color(0.9, 0.82, 0.55)
var mannequin_meshes: Array[MeshInstance3D] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UIThemeBuilder.build()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var stored := GameState.custom_colors()
	primary = stored.primary
	secondary = stored.secondary
	accent = stored.accent
	_build()


func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05, 0.94)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(32, 32)
	box.custom_minimum_size = Vector2(460, 400)
	add_child(box)
	var title := Label.new()
	title.text = "SUITS & SKINS"
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 360)
	box.add_child(scroll)
	var list := VBoxContainer.new()
	scroll.add_child(list)
	for id in GameState.suits.keys():
		var suit: SuitData = GameState.suits[id]
		var button := Button.new()
		var owned := GameState.owns_suit(id)
		button.text = suit.suit_name if owned else "%s (locked)" % suit.suit_name
		button.disabled = not owned
		button.custom_minimum_size = Vector2(400, 64)
		button.pressed.connect(_equip.bind(id))
		list.add_child(button)
	box.add_child(_picker("Primary", primary, func(c: Color) -> void: primary = c; _paint()))
	box.add_child(_picker("Secondary", secondary, func(c: Color) -> void: secondary = c; _paint()))
	box.add_child(_picker("Accent", accent, func(c: Color) -> void: accent = c; _paint()))
	var apply := Button.new()
	apply.text = "SAVE CUSTOM SUIT"
	apply.custom_minimum_size = Vector2(400, 68)
	apply.pressed.connect(func() -> void:
		GameState.set_custom_colors(primary, secondary, accent)
		GameState.equip_suit("custom")
		AudioManager.play("ui")
	)
	box.add_child(apply)
	var close := Button.new()
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(400, 68)
	close.pressed.connect(_close)
	box.add_child(close)
	_build_preview()


func _equip(id: String) -> void:
	GameState.equip_suit(id)
	var suit: SuitData = GameState.get_suit(id)
	if suit and id != "custom":
		primary = suit.primary_color
		secondary = suit.secondary_color
		accent = suit.accent_color
		_paint()
	AudioManager.play("ui")


func _picker(label_text: String, color: Color, on_change: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(140, 40)
	row.add_child(label)
	var picker := ColorPickerButton.new()
	picker.color = color
	picker.custom_minimum_size = Vector2(160, 48)
	picker.color_changed.connect(on_change)
	row.add_child(picker)
	return row


func _build_preview() -> void:
	var container := SubViewportContainer.new()
	container.position = Vector2(520, 40)
	container.custom_minimum_size = Vector2(360, 480)
	add_child(container)
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.size = Vector2i(360, 480)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.6, 3.2)
	cam.look_at(Vector3(0, 1.1, 0))
	viewport.add_child(cam)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, 20, 0)
	viewport.add_child(light)
	var root := Node3D.new()
	viewport.add_child(root)
	mannequin_meshes.append(_part(root, Vector3(0, 1.15, 0), Vector3(0.5, 0.7, 0.32), "primary"))
	mannequin_meshes.append(_part(root, Vector3(0, 0.55, 0), Vector3(0.42, 0.6, 0.3), "secondary"))
	mannequin_meshes.append(_part(root, Vector3(0, 1.65, 0), Vector3(0.28, 0.28, 0.28), "primary"))
	_paint()


func _part(parent: Node3D, pos: Vector3, size: Vector3, slot: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.set_meta("slot", slot)
	var mat := StandardMaterial3D.new()
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh


func _paint() -> void:
	for mesh in mannequin_meshes:
		var mat := mesh.material_override as StandardMaterial3D
		var slot := str(mesh.get_meta("slot"))
		mat.albedo_color = primary if slot == "primary" else secondary
		if slot == "accent":
			mat.albedo_color = accent


func _close() -> void:
	if name == "Overlay":
		queue_free()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/MainMenu.tscn")
