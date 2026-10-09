extends Node
class_name DayNightCycle

var time_of_day: float = 0.62
var cycle_minutes: float = 12.0
var sun: DirectionalLight3D
var environment: Environment
var running: bool = true


func _ready() -> void:
	add_to_group("day_night")
	time_of_day = float(SaveManager.get_value("weather/time", 0.62))


func bind(light: DirectionalLight3D, env: Environment) -> void:
	sun = light
	environment = env
	_apply()


func set_time(value: float) -> void:
	time_of_day = fposmod(value, 1.0)
	_apply()


func _process(delta: float) -> void:
	if not running:
		return
	time_of_day = fposmod(time_of_day + delta / (cycle_minutes * 60.0), 1.0)
	_apply()


func _apply() -> void:
	var sun_angle := (time_of_day - 0.25) * TAU
	if sun:
		sun.rotation = Vector3(sun_angle, deg_to_rad(35.0), 0.0)
		var daylight := clampf(sin(time_of_day * TAU), 0.0, 1.0)
		sun.light_energy = lerpf(0.05, 1.15, daylight)
		sun.light_color = Color(1.0, 0.78, 0.55).lerp(Color(1.0, 0.97, 0.92), daylight)
		sun.shadow_enabled = SettingsManager.quality > 0 and daylight > 0.08
	if environment:
		var day := clampf(sin(time_of_day * PI), 0.0, 1.0)
		var sky := environment.sky
		if sky and sky.sky_material is ProceduralSkyMaterial:
			var mat := sky.sky_material as ProceduralSkyMaterial
			mat.sky_top_color = Color(0.02, 0.03, 0.08).lerp(Color(0.28, 0.48, 0.78), day)
			mat.sky_horizon_color = Color(0.18, 0.1, 0.16).lerp(Color(0.72, 0.62, 0.5), day)
			mat.ground_horizon_color = mat.sky_horizon_color
			mat.ground_bottom_color = Color(0.04, 0.04, 0.05)
		environment.ambient_light_energy = lerpf(0.18, 0.72, day)
		environment.fog_light_color = Color(0.08, 0.08, 0.1).lerp(Color(0.62, 0.66, 0.7), day)
	MaterialLibrary.set_time_of_day(clampf(sin(time_of_day * PI), 0.0, 1.0), float(SaveManager.get_value("weather/rain", 0.0)))
