extends CanvasLayer

var health_bar: ProgressBar
var focus_bar: ProgressBar
var flow_bar: ProgressBar
var speed_label: Label
var objective_label: Label
var district_label: Label
var dialogue_label: Label
var prompt_label: Label
var combo_label: Label
var sense_rect: ColorRect
var anchor_marker: MeshInstance3D
var zip_marker: MeshInstance3D
var mobile: Control
var _player: CharacterBody3D
var _dialogue_time: float = 0.0


func _ready() -> void:
	layer = 2
	_build()
	EventBus.mission_updated.connect(func(text: String, _p: float) -> void: objective_label.text = text)
	EventBus.district_entered.connect(func(id: String) -> void: district_label.text = id.capitalize())
	EventBus.dialogue_requested.connect(_show_dialogue)


func bind_player(player: CharacterBody3D) -> void:
	_player = player
	player.health_changed.connect(_on_health)
	player.get_node("FocusSystem").changed.connect(_on_focus)
	player.get_node("FlowSystem").changed.connect(_on_flow)
	player.get_node("SpiderSense").danger.connect(_on_sense)
	_on_health(player.health, player.max_health)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	health_bar = _bar(root, Vector2(24, 24), Color(0.85, 0.15, 0.18))
	focus_bar = _bar(root, Vector2(24, 58), Color(0.35, 0.7, 1.0))
	flow_bar = _bar(root, Vector2(24, 92), Color(0.95, 0.7, 0.25))
	speed_label = _label(root, Vector2(0, -36), "0 m/s")
	speed_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label = _label(root, Vector2(24, 130), "")
	district_label = _label(root, Vector2(-220, 24), "")
	district_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dialogue_label = _label(root, Vector2(0, -120), "")
	dialogue_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size = Vector2(640, 80)
	prompt_label = _label(root, Vector2(0, 80), "")
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label = _label(root, Vector2(0, -80), "")
	combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sense_rect = ColorRect.new()
	sense_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	sense_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sense_rect.color = Color(1, 1, 1, 0)
	var sense_mat := ShaderMaterial.new()
	sense_mat.shader = load("res://shaders/sense.gdshader")
	sense_rect.material = sense_mat
	root.add_child(sense_rect)
	var lines := ColorRect.new()
	lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line_mat := ShaderMaterial.new()
	line_mat.shader = load("res://shaders/speed_lines.gdshader")
	lines.material = line_mat
	root.add_child(lines)
	mobile = preload("res://scenes/ui/MobileControls.gd").new()
	# MobileControls is a Control script; instantiate via a node.
	var controls := Control.new()
	controls.set_script(preload("res://scenes/ui/MobileControls.gd"))
	controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(controls)
	mobile = controls
	_player_ready_lines(lines)


func _player_ready_lines(lines: ColorRect) -> void:
	# The player VFX node is bound after the player exists.
	set_meta("speed_lines", lines)


func _bar(parent: Control, pos: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.custom_minimum_size = Vector2(280, 22)
	bar.size = Vector2(280, 22)
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.45)
	bg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", bg)
	parent.add_child(bar)
	return bar


func _label(parent: Control, pos: Vector2, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _process(delta: float) -> void:
	if _player == null:
		return
	speed_label.text = "%d m/s" % int(_player.velocity.length())
	var swing: WebSwingController = _player.get_node("WebSystem/WebSwingController")
	var anchors: WebAnchorDetector = _player.get_node("WebSystem/WebAnchorDetector")
	if anchor_marker == null:
		anchor_marker = _make_marker(Color(0.4, 0.9, 1.0))
	if zip_marker == null:
		zip_marker = _make_marker(Color(1.0, 0.8, 0.3))
	_place_marker(anchor_marker, anchors.swing_target)
	_place_marker(zip_marker, anchors.zip_target)
	var interaction: InteractionSystem = _player.get_node("InteractionSystem")
	prompt_label.text = interaction.prompt
	if not SettingsManager.subtitles:
		dialogue_label.visible = false
	_dialogue_time -= delta
	if _dialogue_time <= 0.0:
		dialogue_label.text = ""
	var combat: PlayerCombat = _player.get_node("CombatSystem")
	combo_label.text = "COMBO x%d" % combat.combo_step if combat.combo_step > 1 else ""
	var lines: ColorRect = get_meta("speed_lines")
	if _player.get_node("VFX").has_method("attach_speed_lines") and _player.get_node("VFX").speed_lines == null:
		_player.get_node("VFX").attach_speed_lines(lines)
	if swing.charging:
		prompt_label.text = "SLINGSHOT %d%%" % int(swing.charge * 100.0)


func _place_marker(marker: MeshInstance3D, target: Dictionary) -> void:
	if target.is_empty():
		marker.visible = false
		return
	marker.visible = true
	marker.global_position = target.point + target.normal * 0.25


func _make_marker(color: Color) -> MeshInstance3D:
	var marker := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.28
	mesh.height = 0.56
	marker.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = mat
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(marker)
	return marker


func _on_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


func _on_focus(value: float, _active: bool) -> void:
	focus_bar.value = value


func _on_flow(value: float) -> void:
	flow_bar.value = value


func _on_sense(amount: float) -> void:
	if sense_rect.material is ShaderMaterial:
		var flash := 0.0 if SettingsManager.reduced_flash else amount
		sense_rect.material.set_shader_parameter("danger", flash if not SettingsManager.reduced_flash else amount * 0.35)


func _show_dialogue(speaker: String, line: String) -> void:
	if not SettingsManager.subtitles:
		return
	dialogue_label.visible = true
	dialogue_label.add_theme_font_size_override("font_size", int(22 * SettingsManager.subtitle_scale))
	dialogue_label.text = "%s: %s" % [speaker, line]
	_dialogue_time = 4.2
