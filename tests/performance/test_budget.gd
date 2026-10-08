extends RefCounted

static func run() -> PackedStringArray:
	var fails := PackedStringArray()
	for x in CityLayout.chunk_count():
		for z in CityLayout.chunk_count():
			var budget := CityLayout.body_budget(Vector2i(x, z))
			if budget > 80:
				fails.append("chunk %s,%s body budget %s exceeds 80" % [x, z, budget])
	var spawn := CityLayout.spawn_rooftop()
	var chunk := CityLayout.world_to_chunk(spawn)
	if chunk.x < 0 or chunk.y < 0 or chunk.x >= CityLayout.chunk_count() or chunk.y >= CityLayout.chunk_count():
		fails.append("spawn rooftop chunk %s is outside the streamed city" % chunk)
	if spawn.y < 12.0:
		fails.append("spawn rooftop is too low to swing from: %s" % spawn)
	return fails
