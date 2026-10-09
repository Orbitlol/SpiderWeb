extends Node

var active: MissionData
var progress: int = 0
var elapsed: float = 0.0
var rings: Array[Node] = []
var enemies: Array[Node] = []
var _player: Node3D
var crime_timer: float = 40.0


func _ready() -> void:
	EventBus.token_collected.connect(_on_token)
	EventBus.enemy_defeated.connect(_on_enemy)
	EventBus.checkpoint_reached.connect(_on_checkpoint)


func bind_player(player: Node3D) -> void:
	_player = player
	if GameState.mission_id.is_empty():
		return
	var path := "res://resources/missions/%s.tres" % GameState.mission_id
	if ResourceLoader.exists(path):
		start(load(path))


func start(mission: MissionData) -> void:
	clear()
	active = mission
	progress = 0
	elapsed = 0.0
	SaveManager.set_value("missions/active", mission.mission_id)
	EventBus.mission_started.emit(mission.mission_id)
	EventBus.dialogue_requested.emit("Dispatch", mission.briefing)
	match mission.mission_type:
		"traversal":
			_spawn_rings()
		"combat":
			_spawn_thugs(CityLayout.block_center(5, 3) + Vector3(0, 1, 0), 4)
		"boss":
			_spawn_boss("goblin")
		"side_boss":
			_spawn_boss("octavius")
		"time_trial":
			_spawn_rings()
		"collect":
			pass
	_emit_progress()


func clear() -> void:
	for node in rings:
		if is_instance_valid(node):
			node.queue_free()
	for node in enemies:
		if is_instance_valid(node):
			node.queue_free()
	rings.clear()
	enemies.clear()
	active = null


func _process(delta: float) -> void:
	if active == null:
		if _player:
			crime_timer -= delta
			if crime_timer <= 0.0:
				crime_timer = 55.0
				spawn_crime()
		return
	elapsed += delta
	if active.time_limit > 0.0 and elapsed > active.time_limit and active.mission_type == "time_trial":
		fail()


func _spawn_rings() -> void:
	var start := CityLayout.spawn_rooftop()
	for i in active.objective_count:
		var ring := Area3D.new()
		ring.collision_layer = PhysLayers.TRIGGER
		ring.collision_mask = PhysLayers.PLAYER
		ring.monitoring = true
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 3.2
		shape.shape = sphere
		ring.add_child(shape)
		var mesh := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 2.2
		torus.outer_radius = 2.7
		mesh.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.95, 0.35, 0.25)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.4, 0.2)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_override = mat
		ring.add_child(mesh)
		ring.position = start + Vector3(28.0 + float(i) * 36.0, -6.0 + float(i % 2) * 8.0, sin(float(i)) * 10.0)
		ring.set_meta("checkpoint_id", "ring_%d" % i)
		ring.body_entered.connect(_ring_entered.bind(ring))
		add_child(ring)
		rings.append(ring)


func _ring_entered(body: Node, ring: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	EventBus.checkpoint_reached.emit(str(ring.get_meta("checkpoint_id")))
	ring.queue_free()
	rings.erase(ring)


func _spawn_thugs(origin: Vector3, count: int) -> void:
	var packed := preload("res://scenes/enemies/Enemy.tscn")
	var data := load("res://resources/enemies/thug.tres")
	for i in count:
		var enemy := packed.instantiate() as EnemyActor
		enemy.data = data
		enemy.position = origin + Vector3(float(i) * 1.6 - 2.0, 0, float(i % 2) * 1.4)
		add_child(enemy)
		enemies.append(enemy)


func _spawn_boss(kind: String) -> void:
	var path := "res://scenes/bosses/DoctorOctopus.tscn"
	var pos := CityLayout.lab_roof()
	if kind == "goblin":
		path = "res://scenes/bosses/GoblinKing.tscn"
		pos = CityLayout.boss_plaza() + Vector3(0, 8, 0)
	elif kind == "venom":
		path = "res://scenes/bosses/Venom.tscn"
		pos = CityLayout.block_center(6, 5) + Vector3(0, 2, 0)
	var boss := load(path).instantiate() as CharacterBody3D
	boss.position = pos
	add_child(boss)
	enemies.append(boss)


func spawn_crime() -> void:
	enemies = enemies.filter(func(node: Node) -> bool: return is_instance_valid(node))
	if not enemies.is_empty():
		return
	_spawn_thugs(_player.global_position + Vector3(18, 0, 6) if _player else CityLayout.block_center(3, 3), 3)


func _on_token(_id: String) -> void:
	if active and active.mission_type == "collect":
		progress += 1
		_emit_progress()
		if progress >= active.objective_count:
			complete()


func _on_enemy(id: String) -> void:
	if active == null:
		return
	if active.mission_type == "combat" or active.mission_type == "boss" or active.mission_type == "side_boss":
		progress += 1
		_emit_progress()
		if progress >= active.objective_count:
			complete()
		if id == "goblin_king":
			GameState.unlock_suit("velocity")


func _on_checkpoint(_id: String) -> void:
	if active and (active.mission_type == "traversal" or active.mission_type == "time_trial"):
		progress += 1
		_emit_progress()
		if progress >= active.objective_count:
			if active.mission_type == "time_trial":
				var best: Dictionary = SaveManager.get_value("missions/best_times", {}).duplicate()
				var previous := float(best.get(active.mission_id, 9999.0))
				if elapsed < previous:
					best[active.mission_id] = elapsed
					SaveManager.set_value("missions/best_times", best)
			complete()


func complete() -> void:
	if active == null:
		return
	var id := active.mission_id
	var completed: Array = SaveManager.get_value("missions/completed", []).duplicate()
	if id not in completed:
		completed.append(id)
		SaveManager.set_value("missions/completed", completed)
	GameState.add_tokens(active.reward_tokens)
	GameState.add_xp(active.reward_xp)
	if active.reward_suit != "":
		GameState.unlock_suit(active.reward_suit)
	if active.story_flag != "":
		var flags: Dictionary = SaveManager.get_value("story/flags", {}).duplicate()
		flags[active.story_flag] = true
		SaveManager.set_value("story/flags", flags)
		SaveManager.set_value("story/chapter", int(SaveManager.get_value("story/chapter", 0)) + 1)
	var district := active.district_id
	var districts := get_parent().get_node_or_null("City/DistrictManager")
	if districts and districts.has_method("add_reputation"):
		districts.add_reputation(district, 5)
	SaveManager.set_value("missions/active", "")
	EventBus.mission_completed.emit(id)
	EventBus.dialogue_requested.emit("Dispatch", "Objective complete.")
	SaveManager.save_game()
	var next := active.next_mission
	active = null
	if next != "" and GameState.launch_mode == "new_game":
		var path := "res://resources/missions/%s.tres" % next
		if ResourceLoader.exists(path):
			await get_tree().create_timer(1.2).timeout
			start(load(path))


func fail() -> void:
	if active == null:
		return
	EventBus.mission_failed.emit(active.mission_id)
	EventBus.dialogue_requested.emit("Dispatch", "Trial failed. Try again from the menu.")
	active = null


func _emit_progress() -> void:
	if active == null:
		return
	var label := "%s  %d/%d" % [active.title, progress, active.objective_count]
	EventBus.mission_updated.emit(label, float(progress) / float(maxi(active.objective_count, 1)))
