extends RefCounted

static func run() -> PackedStringArray:
	var fails := PackedStringArray()
	_catch(fails)
	_rooftop(fails)
	_street_is_rejected_by_clearance(fails)
	_air_is_not_an_anchor(fails)
	return fails


static func _check(fails: PackedStringArray, ok: bool, message: String) -> void:
	if not ok:
		fails.append(message)


static func _catch(fails: PackedStringArray) -> void:
	var player := Vector3(8, 30, 4)
	var anchor := Vector3(0, 48, 0)
	var rope := SwingSolver.catch_rope(player, anchor, Vector3(6, 1, 0))
	var dist := player.distance_to(anchor)
	_check(fails, rope <= dist + 0.001, "catch_rope longer than the hit: %s > %s" % [rope, dist])
	_check(fails, rope >= 5.5, "catch_rope below the minimum rope")
	var falling := Vector3(0, 4, 0)
	var high := Vector3(0, 40, 18)
	var low_anchor := Vector3(0, 14, 0)
	var street_rope := SwingSolver.catch_rope(falling, low_anchor, Vector3(0, -9, 2))
	var street_dist := falling.distance_to(low_anchor)
	_check(fails, street_rope <= street_dist - 2.0, "falling street catch did not shorten the rope")
	var roof_rope := SwingSolver.catch_rope(high, Vector3(0, 55, 0), Vector3(4, 2, 0))
	var roof_dist := high.distance_to(Vector3(0, 55, 0))
	_check(fails, (street_dist - street_rope) > (roof_dist - roof_rope), "street catch should shorten more than a rooftop catch")


static func _rooftop(fails: PackedStringArray) -> void:
	var solver := SwingSolver.new()
	var anchor := Vector3(0, 52, 0)
	var pos := Vector3(12, 34, 8)
	var vel := Vector3(7, 1, 2)
	solver.anchor = anchor
	solver.rope_length = SwingSolver.catch_rope(pos, anchor, vel)
	var min_y := pos.y
	var max_speed := vel.length()
	var late_stretch := 0.0
	for i in 240:
		var result := solver.step(pos, vel, 1.0 / 60.0, Vector3(0, 0, 1), 0.0)
		pos = result.position
		vel = result.velocity
		min_y = minf(min_y, pos.y)
		max_speed = maxf(max_speed, vel.length())
		if i > 180 and solver.taut and solver.rope_length > 1.0:
			late_stretch = maxf(late_stretch, pos.distance_to(anchor) / solver.rope_length - 1.0)
	_check(fails, min_y > 8.0, "rooftop swing dropped to street height %s" % min_y)
	_check(fails, max_speed > 12.0, "swing did not build speed, max %s" % max_speed)
	_check(fails, late_stretch < 0.14, "rope stayed overstretched %s" % late_stretch)
	var released := vel
	released.y -= 32.0 / 60.0
	_check(fails, released.length() > 6.0, "leaving the rope zeroed momentum")
	var predicted := solver.predict_min_height(Vector3(12, 34, 8), Vector3(7, 1, 2), 36, Vector3(0, 0, 1))
	_check(fails, predicted > 8.0, "rooftop prediction is not clear of the street: %s" % predicted)


static func _street_is_rejected_by_clearance(fails: PackedStringArray) -> void:
	var solver := SwingSolver.new()
	var player := Vector3(0, 3, 0)
	var anchor := Vector3(0, 10, 22)
	var velocity := Vector3(0, -10, 4)
	solver.anchor = anchor
	solver.rope_length = SwingSolver.catch_rope(player, anchor, velocity)
	var min_y := solver.predict_min_height(player, velocity, 90, Vector3(0, 0, 1))
	_check(fails, min_y < 1.2, "street anchor should fail the 1.2 clearance test, predicted %s" % min_y)


static func _air_is_not_an_anchor(fails: PackedStringArray) -> void:
	_check(fails, not WebAnchorDetector.is_valid_hit({}), "empty ray was treated as an anchor")
	_check(fails, not WebAnchorDetector.is_valid_hit({"position": Vector3.ZERO}), "ray without a collider was accepted")
	var miss := WebAnchorDetector.score_swing(Vector3.ZERO, Vector3.ZERO, Vector3.FORWARD, Vector3.ZERO, Vector3.UP, 0.0)
	_check(fails, miss < 0.0, "zero-length hit scored as a swing")
