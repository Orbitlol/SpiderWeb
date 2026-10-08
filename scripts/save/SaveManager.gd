extends Node

const SAVE_PATH := "user://spiderweb_save.json"
const SAVE_TEMP := "user://spiderweb_save.tmp"

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> Dictionary:
	if not has_save():
		data = SaveMigrator.default_save()
		return data
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("SpiderWeb save could not be opened: %s" % FileAccess.get_open_error())
		data = SaveMigrator.default_save()
		return data
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SpiderWeb save was unreadable. Starting from defaults without deleting the file.")
		data = SaveMigrator.default_save()
		return data
	data = SaveMigrator.migrate(parsed)
	return data


func save_game() -> bool:
	data["version"] = SaveMigrator.SAVE_VERSION
	var json := JSON.stringify(data, "\t")
	var temp := FileAccess.open(SAVE_TEMP, FileAccess.WRITE)
	if temp == null:
		push_warning("SpiderWeb could not write save temp file.")
		return false
	temp.store_string(json)
	temp.close()
	var read_back := FileAccess.open(SAVE_TEMP, FileAccess.READ)
	if read_back == null:
		return false
	var check := read_back.get_as_text()
	read_back.close()
	if check != json:
		push_warning("SpiderWeb save verification failed. Existing save left untouched.")
		return false
	var dir := DirAccess.open("user://")
	if dir == null:
		return false
	if dir.file_exists(SAVE_PATH):
		var backup := "user://spiderweb_save.bak"
		dir.remove(backup.trim_prefix("user://"))
		dir.rename(SAVE_PATH.trim_prefix("user://"), backup.trim_prefix("user://"))
	var err := dir.rename(SAVE_TEMP.trim_prefix("user://"), SAVE_PATH.trim_prefix("user://"))
	return err == OK


func reset_save() -> void:
	data = SaveMigrator.default_save()
	save_game()


func get_value(path: String, fallback: Variant = null) -> Variant:
	var node: Variant = data
	for part in path.split("/"):
		if typeof(node) != TYPE_DICTIONARY or not node.has(part):
			return fallback
		node = node[part]
	return node


func set_value(path: String, value: Variant) -> void:
	var parts := path.split("/")
	var node: Dictionary = data
	for i in parts.size() - 1:
		var part: String = parts[i]
		if not node.has(part) or typeof(node[part]) != TYPE_DICTIONARY:
			node[part] = {}
		node = node[part]
	node[parts[parts.size() - 1]] = value
