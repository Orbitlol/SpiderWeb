extends Node
class_name StreamingManager

const SCRIPT := preload("res://scenes/city/CityChunk.gd")

var radius: int = 2
var loaded: Dictionary = {}
var pinned: Vector2i = Vector2i(-999, -999)
var _player: Node3D
var _loads_queued: int = 0


func _ready() -> void:
	add_to_group("streaming")
	radius = 2 if SettingsManager.quality > 0 else 1


func bind_player(player: Node3D) -> void:
	_player = player


func pin_world_position(pos: Vector3) -> void:
	if pos == Vector3.ZERO:
		pinned = Vector2i(-999, -999)
	else:
		pinned = CityLayout.world_to_chunk(pos)


func is_ready_around(pos: Vector3) -> bool:
	var coord := CityLayout.world_to_chunk(pos)
	for x in range(-1, 2):
		for z in range(-1, 2):
			var key := coord + Vector2i(x, z)
			if not _in_city(key):
				continue
			if not loaded.has(key):
				return false
			var chunk: CityChunk = loaded[key]
			if not chunk.ready_visual:
				return false
	return true


func _process(_delta: float) -> void:
	if _player == null:
		return
	var coord := CityLayout.world_to_chunk(_player.global_position)
	var needed := {}
	for x in range(-radius, radius + 1):
		for z in range(-radius, radius + 1):
			var key := coord + Vector2i(x, z)
			if _in_city(key):
				needed[key] = true
	var vel := Vector2.ZERO
	if _player is CharacterBody3D:
		vel = Vector2(_player.velocity.x, _player.velocity.z)
	if vel.length() > 8.0:
		var dir := Vector2i(int(round(vel.normalized().x)), int(round(vel.normalized().y)))
		var ahead := coord + dir * (radius + 1)
		if _in_city(ahead):
			needed[ahead] = true
	if pinned.x > -100 and _in_city(pinned):
		needed[pinned] = true
	var remove: Array[Vector2i] = []
	for key in loaded.keys():
		if not needed.has(key):
			remove.append(key)
	for key in remove:
		var chunk: Node = loaded[key]
		loaded.erase(key)
		chunk.queue_free()
	_loads_queued = 0
	for key in needed.keys():
		if loaded.has(key):
			continue
		if _loads_queued >= 1:
			break
		var chunk := CityChunk.new()
		add_child(chunk)
		chunk.build(key)
		loaded[key] = chunk
		_loads_queued += 1


func _in_city(coord: Vector2i) -> bool:
	return coord.x >= 0 and coord.y >= 0 and coord.x < CityLayout.chunk_count() and coord.y < CityLayout.chunk_count()
