extends Node3D

var player: CharacterBody3D
var city: Node3D
var started: bool = false
var _wait: float = 0.0


func _ready() -> void:
	_build_environment()
	city = preload("res://scenes/city/City.tscn").instantiate()
	add_child(city)
	player = preload("res://scenes/player/Weaver.tscn").instantiate()
	player.visible = false
	player.set_physics_process(false)
	add_child(player)
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(preload("res://scenes/ui/HUD.gd"))
	add_child(hud)
	var pause := CanvasLayer.new()
	pause.name = "PauseMenu"
	pause.set_script(preload("res://scenes/menus/PauseMenu.gd"))
	add_child(pause)
	var photo := CanvasLayer.new()
	photo.name = "PhotoMode"
	photo.set_script(preload("res://scenes/ui/PhotoMode.gd"))
	add_child(photo)
	var missions := Node.new()
	missions.name = "MissionManager"
	missions.set_script(preload("res://scenes/missions/MissionManager.gd"))
	add_child(missions)
	_spawn_allies()
	_show_loading()
	city.bind_player(player)
	city.day_night.bind(get_node("Sun"), get_node("WorldEnvironment").environment)
	if GameState.launch_mode == "continue":
		var saved: Array = SaveManager.get_value("player/position", [0, 40, 0])
		player.global_position = Vector3(float(saved[0]), float(saved[1]), float(saved[2]))
		player.camera_rig.yaw = float(SaveManager.get_value("player/yaw", 0.0))
		city.day_night.set_time(float(SaveManager.get_value("weather/time", 0.62)))
		city.weather.set_rain(float(SaveManager.get_value("weather/rain", 0.0)))
	else:
		player.global_position = city.spawn_point
	city.ready_for_player.connect(_begin)
	if city.streaming.is_ready_around(player.global_position):
		_begin()


func _process(delta: float) -> void:
	if started:
		return
	_wait += delta
	if _wait > 8.0:
		_begin()


func _show_loading() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Loading"
	var label := Label.new()
	label.text = "Spinning the city..."
	label.position = Vector2(28, 28)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 28)
	layer.add_child(label)
	add_child(layer)


func _begin() -> void:
	if started:
		return
	started = true
	var loading := get_node_or_null("Loading")
	if loading:
		loading.queue_free()
	player.visible = true
	player.set_physics_process(true)
	player.last_safe_position = player.global_position
	get_node("HUD").bind_player(player)
	get_node("MissionManager").bind_player(player)
	if not SettingsManager.touch_controls_visible():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	EventBus.dialogue_requested.emit("Weaver", "Hold WEB, aim high, release on the rise.")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		SettingsManager.touch_controls = 2 if SettingsManager.touch_controls_visible() else 1
		SettingsManager.save_settings()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not SettingsManager.touch_controls_visible() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_environment() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.42, 0.72)
	sky_mat.sky_horizon_color = Color(0.72, 0.62, 0.5)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	sky_mat.ground_bottom_color = Color(0.08, 0.08, 0.09)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 70.0
	env.fog_depth_end = 360.0
	env.fog_density = 0.002
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = SettingsManager.quality > 0
	sun.directional_shadow_max_distance = 180.0 if SettingsManager.quality > 1 else 120.0
	sun.light_energy = 1.05
	add_child(sun)


func _spawn_allies() -> void:
	_ally("Miles", Color(0.08, 0.08, 0.1), "The skyline's restless tonight.", CityLayout.block_center(4, 5) + Vector3(0, CityLayout.height_for(4, 5, CityLayout.district_id(4, 5)) + 1.5, 4))
	_ally("Gwen", Color(0.9, 0.9, 0.92), "Race you to the bridge.", CityLayout.block_center(3, 4) + Vector3(4, CityLayout.height_for(3, 4, CityLayout.district_id(3, 4)) + 1.5, 0))


func _ally(display: String, color: Color, line: String, pos: Vector3) -> void:
	var path := "res://scenes/npcs/%s.tscn" % display
	var ally := load(path).instantiate() if ResourceLoader.exists(path) else preload("res://scenes/npcs/Ally.tscn").instantiate()
	ally.display_name = display
	ally.color = color
	ally.line = line
	ally.position = pos
	add_child(ally)
