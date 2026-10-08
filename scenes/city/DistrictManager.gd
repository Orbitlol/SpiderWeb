extends Node
class_name DistrictManager

var current_id: String = ""
var districts: Dictionary = {}


func _ready() -> void:
	for id in ["skyline", "midtown", "yards", "harbor"]:
		var path := "res://resources/districts/%s.tres" % id
		if ResourceLoader.exists(path):
			districts[id] = load(path)


func update_player(pos: Vector3) -> void:
	var chunk := CityLayout.world_to_chunk(pos)
	var ix := clampi(chunk.x * CityLayout.CHUNK_BLOCKS, 0, CityLayout.GRID - 1)
	var iz := clampi(chunk.y * CityLayout.CHUNK_BLOCKS, 0, CityLayout.GRID - 1)
	var id := CityLayout.district_id(ix, iz)
	if id == current_id:
		return
	current_id = id
	SaveManager.set_value("player/district", id)
	EventBus.district_entered.emit(id)


func display_name() -> String:
	if districts.has(current_id) and districts[current_id] is DistrictData:
		return districts[current_id].display_name
	return current_id.capitalize()


func add_reputation(id: String, amount: int) -> void:
	var rep: Dictionary = SaveManager.get_value("reputation", {}).duplicate()
	rep[id] = int(rep.get(id, 0)) + amount
	SaveManager.set_value("reputation", rep)
