extends Node
class_name WeatherManager

var rain_amount: float = 0.0
var _particles: GPUParticles3D
var _player: Node3D
var _audio: AudioStreamPlayer


func _ready() -> void:
	rain_amount = float(SaveManager.get_value("weather/rain", 0.0))
	_particles = GPUParticles3D.new()
	_particles.amount = 280 if SettingsManager.quality > 0 else 80
	_particles.lifetime = 1.1
	_particles.visibility_aabb = AABB(Vector3(-30, -10, -30), Vector3(60, 40, 60))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(22, 1, 22)
	process.direction = Vector3(0.1, -1, 0.05)
	process.spread = 8.0
	process.initial_velocity_min = 18.0
	process.initial_velocity_max = 26.0
	process.gravity = Vector3(0, -8, 0)
	_particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.04, 0.45)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.75, 0.82, 0.9, 0.35)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = mat
	_particles.draw_pass_1 = quad
	_particles.emitting = rain_amount > 0.05
	add_child(_particles)
	_audio = AudioManager.make_loop("rain")
	add_child(_audio)
	if rain_amount > 0.05:
		_audio.play()


func bind_player(player: Node3D) -> void:
	_player = player


func set_rain(amount: float) -> void:
	rain_amount = clampf(amount, 0.0, 1.0)
	SaveManager.set_value("weather/rain", rain_amount)
	_particles.emitting = rain_amount > 0.05
	_particles.amount = int(lerpf(40, 320 if SettingsManager.quality > 0 else 100, rain_amount))
	if rain_amount > 0.05 and not _audio.playing:
		_audio.play()
	elif rain_amount <= 0.05 and _audio.playing:
		_audio.stop()
	_audio.volume_db = lerpf(-28.0, -8.0, rain_amount)


func _process(_delta: float) -> void:
	if _player:
		_particles.global_position = _player.global_position + Vector3(0, 18, 0)
