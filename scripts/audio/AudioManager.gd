extends Node

var streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool3d: Array[AudioStreamPlayer3D] = []
var music: AudioStreamPlayer
var _next := 0
var _next3d := 0


func _ready() -> void:
	_load("web_thwip", "res://assets/audio/web_thwip.wav")
	_load("web_catch", "res://assets/audio/web_catch.wav")
	_load("web_release", "res://assets/audio/web_release.wav")
	_load("jump", "res://assets/audio/jump.wav")
	_load("land", "res://assets/audio/land.wav")
	_load("whoosh", "res://assets/audio/whoosh.wav", true)
	_load("hit", "res://assets/audio/hit.wav")
	_load("dodge", "res://assets/audio/dodge.wav")
	_load("ui", "res://assets/audio/ui_click.wav")
	_load("pickup", "res://assets/audio/pickup.wav")
	_load("sense", "res://assets/audio/sense.wav")
	_load("rain", "res://assets/audio/rain.wav", true)
	_load("ambient", "res://assets/audio/ambient.wav", true)
	_load("power", "res://assets/audio/power.wav")
	_load("explode", "res://assets/audio/explode.wav")
	for i in 8:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_pool.append(player)
	for i in 6:
		var player3 := AudioStreamPlayer3D.new()
		player3.bus = "SFX"
		player3.unit_size = 8.0
		player3.max_distance = 48.0
		add_child(player3)
		_pool3d.append(player3)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.volume_db = -8.0
	add_child(music)
	if streams.has("ambient"):
		music.stream = streams["ambient"]
		music.play()


func _load(id: String, path: String, looped: bool = false) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if looped and stream is AudioStreamWAV:
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	streams[id] = stream


func play(id: String, volume_db: float = 0.0) -> void:
	if not streams.has(id) or _pool.is_empty():
		return
	var player := _pool[_next % _pool.size()]
	_next += 1
	player.stream = streams[id]
	player.volume_db = volume_db
	player.play()


func play_at(id: String, world_pos: Vector3, volume_db: float = 0.0) -> void:
	if not streams.has(id) or _pool3d.is_empty():
		play(id, volume_db)
		return
	var player := _pool3d[_next3d % _pool3d.size()]
	_next3d += 1
	player.stream = streams[id]
	player.volume_db = volume_db
	player.global_position = world_pos
	player.play()


func make_loop(id: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	if streams.has(id):
		player.stream = streams[id]
	return player
