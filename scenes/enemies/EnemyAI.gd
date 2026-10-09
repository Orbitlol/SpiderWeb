extends Node

var body: EnemyActor
var windup: float = 0.0
var attack_cooldown: float = 0.0
var state: String = "idle"


func _ready() -> void:
	body = get_parent() as EnemyActor


func _physics_process(delta: float) -> void:
	if body == null or not body.alive:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null:
		return
	var focus := get_tree().get_first_node_in_group("player").get_node_or_null("FocusSystem")
	var scale := 1.0
	if focus and focus.has_method("enemy_scale"):
		scale = focus.enemy_scale()
	delta *= scale
	if bool(get_tree().get_meta("weaver_camouflaged", false)):
		_idle(delta)
		return
	var to_player := player.global_position - body.global_position
	var flat := Vector3(to_player.x, 0, to_player.z)
	var dist := flat.length()
	var detect := body.data.detect_range if body.data else 16.0
	var suit := GameState.get_suit(GameState.equipped_suit_id)
	if suit:
		detect *= suit.detect_range_multiplier
	if body.stun > 0.0:
		state = "stunned"
		return
	if dist < detect and absf(to_player.y) < 12.0:
		state = "chase"
		_chase(flat, dist, player, delta)
	else:
		state = "idle"
		_idle(delta)
	if windup > 0.0:
		windup -= delta
		var sense := player.get_node_or_null("SpiderSense")
		if sense:
			sense.warn(windup)
		if windup <= 0.0:
			_strike(player)


func _chase(flat: Vector3, dist: float, player: CharacterBody3D, delta: float) -> void:
	var speed := body.data.move_speed if body.data else 4.0
	var dir := EnemyBrain.steer(flat, _blocked(flat.normalized()))
	body.velocity.x = dir.x * speed
	body.velocity.z = dir.z * speed
	var range := body.data.attack_range if body.data else 1.8
	if dist <= range + 0.4 and attack_cooldown <= 0.0 and windup <= 0.0:
		windup = body.data.attack_windup if body.data else 0.55
		attack_cooldown = 1.4
		body.velocity.x = 0.0
		body.velocity.z = 0.0


func _idle(delta: float) -> void:
	var to_home := body.home - body.global_position
	to_home.y = 0.0
	if to_home.length() > 2.0:
		var dir := to_home.normalized()
		body.velocity.x = dir.x * 1.4
		body.velocity.z = dir.z * 1.4
	else:
		body.velocity.x = move_toward(body.velocity.x, 0.0, delta * 8.0)
		body.velocity.z = move_toward(body.velocity.z, 0.0, delta * 8.0)


func _strike(player: CharacterBody3D) -> void:
	var dist := body.global_position.distance_to(player.global_position)
	if dist > 2.4:
		return
	var sense := player.get_node_or_null("SpiderSense")
	if sense and sense.in_perfect_window():
		return
	var dmg := body.data.attack_damage if body.data else 8.0
	if player.has_method("apply_damage"):
		player.apply_damage(dmg, body.global_position)


func _blocked(dir: Vector3) -> bool:
	var space := body.get_world_3d().direct_space_state
	var from := body.global_position + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 1.2)
	query.collision_mask = PhysLayers.WORLD
	query.exclude = [body.get_rid()]
	return not space.intersect_ray(query).is_empty()
