extends Node

const SETTINGS_PATH := "user://settings.cfg"

var look_sensitivity: float = 1.0
var invert_y: bool = false
var left_handed: bool = false
var haptics_enabled: bool = true
var camera_shake: bool = true
var touch_controls: int = 0
var swing_assist: float = 0.65
var fov: float = 70.0
var quality: int = 1
var subtitles: bool = true
var music_volume: float = 0.45
var sfx_volume: float = 0.85
var reduced_flash: bool = false
var button_scale: float = 1.0
var web_toggle: bool = false
var subtitle_scale: float = 1.0


func _ready() -> void:
	load_settings()
	_ensure_actions()
	apply_audio()


func touch_controls_visible() -> bool:
	if touch_controls == 1:
		return true
	if touch_controls == 2:
		return false
	return OS.has_feature("mobile") or OS.has_feature("android") or DisplayServer.is_touchscreen_available()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	look_sensitivity = float(cfg.get_value("controls", "look_sensitivity", look_sensitivity))
	invert_y = bool(cfg.get_value("controls", "invert_y", invert_y))
	left_handed = bool(cfg.get_value("controls", "left_handed", left_handed))
	haptics_enabled = bool(cfg.get_value("controls", "haptics", haptics_enabled))
	camera_shake = bool(cfg.get_value("controls", "camera_shake", camera_shake))
	touch_controls = int(cfg.get_value("controls", "touch_controls", touch_controls))
	swing_assist = float(cfg.get_value("controls", "swing_assist", swing_assist))
	fov = float(cfg.get_value("controls", "fov", fov))
	quality = int(cfg.get_value("graphics", "quality", quality))
	subtitles = bool(cfg.get_value("accessibility", "subtitles", subtitles))
	subtitle_scale = float(cfg.get_value("accessibility", "subtitle_scale", subtitle_scale))
	reduced_flash = bool(cfg.get_value("accessibility", "reduced_flash", reduced_flash))
	button_scale = float(cfg.get_value("accessibility", "button_scale", button_scale))
	web_toggle = bool(cfg.get_value("controls", "web_toggle", web_toggle))
	music_volume = float(cfg.get_value("audio", "music", music_volume))
	sfx_volume = float(cfg.get_value("audio", "sfx", sfx_volume))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "look_sensitivity", look_sensitivity)
	cfg.set_value("controls", "invert_y", invert_y)
	cfg.set_value("controls", "left_handed", left_handed)
	cfg.set_value("controls", "haptics", haptics_enabled)
	cfg.set_value("controls", "camera_shake", camera_shake)
	cfg.set_value("controls", "touch_controls", touch_controls)
	cfg.set_value("controls", "swing_assist", swing_assist)
	cfg.set_value("controls", "fov", fov)
	cfg.set_value("controls", "web_toggle", web_toggle)
	cfg.set_value("graphics", "quality", quality)
	cfg.set_value("accessibility", "subtitles", subtitles)
	cfg.set_value("accessibility", "subtitle_scale", subtitle_scale)
	cfg.set_value("accessibility", "reduced_flash", reduced_flash)
	cfg.set_value("accessibility", "button_scale", button_scale)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS_PATH)
	apply_audio()
	EventBus.settings_changed.emit()


func apply_audio() -> void:
	_bus("Music")
	_bus("SFX")
	var music := AudioServer.get_bus_index("Music")
	var sfx := AudioServer.get_bus_index("SFX")
	if music >= 0:
		AudioServer.set_bus_volume_db(music, linear_to_db(clampf(music_volume, 0.0, 1.0)))
	if sfx >= 0:
		AudioServer.set_bus_volume_db(sfx, linear_to_db(clampf(sfx_volume, 0.0, 1.0)))


func _bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _ensure_actions() -> void:
	InputSetup.ensure_actions()
