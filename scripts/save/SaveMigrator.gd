extends RefCounted
class_name SaveMigrator

const SAVE_VERSION := 3


static func default_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"story": {"chapter": 0, "flags": {}},
		"missions": {"completed": [], "active": "", "best_times": {}},
		"suits": {
			"owned": ["classic"],
			"equipped": "classic",
			"custom_colors": {
				"primary": [0.72, 0.08, 0.1, 1.0],
				"secondary": [0.08, 0.12, 0.32, 1.0],
				"accent": [0.9, 0.82, 0.55, 1.0],
			},
		},
		"powers": {},
		"skills": {"points": 0, "ranks": {}, "xp": 0, "level": 1},
		"currencies": {"tokens": 0, "fluid": 0},
		"web_presets": [],
		"web_style": {},
		"settings": {},
		"player": {"position": [0.0, 40.0, 0.0], "yaw": 0.0, "district": "skyline"},
		"world": {"collected": [], "defeated_groups": [], "reputation": {}},
		"weather": {"time": 0.62, "rain": 0.0},
		"reputation": {"skyline": 0, "midtown": 0, "yards": 0, "harbor": 0},
	}


static func migrate(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return default_save()
	var version := int(data.get("version", 1))
	if version < 2:
		if not data.has("reputation"):
			data["reputation"] = {"skyline": 0, "midtown": 0, "yards": 0, "harbor": 0}
		if not data.has("web_presets"):
			data["web_presets"] = []
		version = 2
	if version < 3:
		var skills: Dictionary = data.get("skills", {})
		if typeof(skills) != TYPE_DICTIONARY:
			skills = {}
		if not skills.has("ranks"):
			skills["ranks"] = {}
		if not skills.has("points"):
			skills["points"] = 0
		if not skills.has("xp"):
			skills["xp"] = 0
		if not skills.has("level"):
			skills["level"] = 1
		data["skills"] = skills
		if not data.has("weather"):
			data["weather"] = {"time": 0.62, "rain": 0.0}
		version = 3
	data["version"] = SAVE_VERSION
	_fill(data, default_save())
	return data


static func _fill(target: Dictionary, defaults: Dictionary) -> void:
	for key in defaults.keys():
		if not target.has(key):
			target[key] = defaults[key]
		elif typeof(defaults[key]) == TYPE_DICTIONARY and typeof(target[key]) == TYPE_DICTIONARY:
			_fill(target[key], defaults[key])
