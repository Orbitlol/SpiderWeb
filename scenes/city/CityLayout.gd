extends RefCounted
class_name CityLayout

const BLOCK := 84.0
const STREET := 24.0
const GRID := 8
const CHUNK_BLOCKS := 2
const CHUNK_SIZE := BLOCK * float(CHUNK_BLOCKS)
const CITY_ORIGIN := -GRID * BLOCK * 0.5
const SEED := 481516


static func chunk_count() -> int:
	return GRID / CHUNK_BLOCKS


static func world_to_chunk(pos: Vector3) -> Vector2i:
	var local := Vector2(pos.x - CITY_ORIGIN, pos.z - CITY_ORIGIN)
	return Vector2i(floori(local.x / CHUNK_SIZE), floori(local.y / CHUNK_SIZE))


static func chunk_origin(coord: Vector2i) -> Vector3:
	return Vector3(CITY_ORIGIN + float(coord.x) * CHUNK_SIZE, 0.0, CITY_ORIGIN + float(coord.y) * CHUNK_SIZE)


static func block_center(ix: int, iz: int) -> Vector3:
	return Vector3(CITY_ORIGIN + (float(ix) + 0.5) * BLOCK, 0.0, CITY_ORIGIN + (float(iz) + 0.5) * BLOCK)


static func in_bounds(ix: int, iz: int) -> bool:
	return ix >= 0 and iz >= 0 and ix < GRID and iz < GRID


static func district_id(ix: int, iz: int) -> String:
	if ix <= 1 and iz <= 1:
		return "harbor"
	if ix <= 1 and iz >= 5:
		return "yards"
	var dx := absf(float(ix) - 3.5)
	var dz := absf(float(iz) - 3.5)
	if dx + dz < 3.3:
		return "skyline"
	return "midtown"


static func is_plaza(ix: int, iz: int) -> bool:
	return ix == 1 and iz == 6


static func is_water(ix: int, iz: int) -> bool:
	return iz == 0 and ix <= 2


static func randf_det(ix: int, iz: int, salt: int) -> float:
	var n := ix * 374761393 + iz * 668265263 + salt * 1442695041 + SEED
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFFFF) / float(0xFFFFFF)


static func height_for(ix: int, iz: int, district: String) -> float:
	var roll := randf_det(ix, iz, 3)
	match district:
		"skyline":
			return lerpf(42.0, 118.0, roll)
		"yards":
			return lerpf(10.0, 28.0, roll)
		"harbor":
			return lerpf(12.0, 36.0, roll)
		_:
			return lerpf(16.0, 52.0, roll)


static func buildings_for_block(ix: int, iz: int) -> Array[Dictionary]:
	var buildings: Array[Dictionary] = []
	if not in_bounds(ix, iz) or is_plaza(ix, iz) or is_water(ix, iz):
		return buildings
	var district := district_id(ix, iz)
	var center := block_center(ix, iz)
	var height := height_for(ix, iz, district)
	var footprint := lerpf(22.0, 40.0, randf_det(ix, iz, 5))
	var setbacks := 1
	if height > 46.0:
		setbacks = 2
	if height > 78.0:
		setbacks = 3
	var y := 0.0
	var remaining := height
	var width := footprint
	var depth := lerpf(footprint * 0.75, footprint, randf_det(ix, iz, 6))
	for step in setbacks:
		var part_h := remaining * (0.62 if step == 0 else 0.7)
		if step == setbacks - 1:
			part_h = remaining
		buildings.append({
			"position": center + Vector3(0, y, 0),
			"size": Vector3(width, part_h, depth),
			"district": district,
			"kind": "tower",
			"roof": step == setbacks - 1,
		})
		y += part_h
		remaining -= part_h
		width *= 0.72
		depth *= 0.72
	if randf_det(ix, iz, 8) > 0.45:
		buildings.append({
			"position": center + Vector3(width * 0.2, height, depth * 0.1),
			"size": Vector3(1.2, lerpf(6.0, 16.0, randf_det(ix, iz, 9)), 1.2),
			"district": district,
			"kind": "antenna",
			"roof": false,
		})
	if district == "midtown" and randf_det(ix, iz, 11) > 0.62:
		buildings.append({
			"position": center + Vector3(0, height + 4.0, 0),
			"size": Vector3(6.0, 5.0, 6.0),
			"district": district,
			"kind": "water_tower",
			"roof": false,
		})
	if district == "yards" and randf_det(ix, iz, 12) > 0.4:
		buildings.append({
			"position": center + Vector3(0, height + 8.0, 0),
			"size": Vector3(18.0, 1.2, 2.4),
			"district": district,
			"kind": "crane",
			"roof": false,
		})
	return buildings


static func props_for_chunk(coord: Vector2i) -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var origin := chunk_origin(coord)
	var spacing := 36.0
	var count := int(CHUNK_SIZE / spacing)
	for i in count:
		var along := spacing * 0.5 + float(i) * spacing
		props.append({"kind": "streetlight", "position": origin + Vector3(along, 0, STREET * 0.35)})
		props.append({"kind": "streetlight", "position": origin + Vector3(STREET * 0.35, 0, along)})
	return props


static func tokens_for_chunk(coord: Vector2i) -> Array[Dictionary]:
	var tokens: Array[Dictionary] = []
	for n in 3:
		var ix := coord.x * CHUNK_BLOCKS + (n % 2)
		var iz := coord.y * CHUNK_BLOCKS + int(n / 2)
		if not in_bounds(ix, iz) or is_water(ix, iz) or is_plaza(ix, iz):
			continue
		var center := block_center(ix, iz)
		var height := height_for(ix, iz, district_id(ix, iz))
		tokens.append({
			"id": "token_%d_%d_%d" % [coord.x, coord.y, n],
			"position": center + Vector3(0, height + 2.4, 0),
		})
	return tokens


static func spawn_rooftop() -> Vector3:
	var ix := 4
	var iz := 4
	var center := block_center(ix, iz)
	var height := height_for(ix, iz, district_id(ix, iz))
	return center + Vector3(0, height + 2.0, 0)


static func boss_plaza() -> Vector3:
	return block_center(1, 6) + Vector3(0, 1.0, 0)


static func lab_roof() -> Vector3:
	var center := block_center(2, 6)
	return center + Vector3(0, height_for(2, 6, district_id(2, 6)) + 1.5, 0)


static func body_budget(coord: Vector2i) -> int:
	var count := props_for_chunk(coord).size()
	for x in CHUNK_BLOCKS:
		for z in CHUNK_BLOCKS:
			count += buildings_for_block(coord.x * CHUNK_BLOCKS + x, coord.y * CHUNK_BLOCKS + z).size()
	count += tokens_for_chunk(coord).size()
	return count
