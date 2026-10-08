extends Node

const SUIT_PATHS := {
	"classic": "res://resources/suits/classic.tres",
	"velocity": "res://resources/suits/velocity.tres",
	"stealth": "res://resources/suits/stealth.tres",
	"armored": "res://resources/suits/armored.tres",
	"symbiote": "res://resources/suits/symbiote.tres",
	"custom": "res://resources/suits/custom.tres",
}

const WEB_PATHS := {
	"classic": "res://resources/web_styles/classic.tres",
	"gold": "res://resources/web_styles/gold.tres",
	"symbiote": "res://resources/web_styles/symbiote.tres",
	"neon": "res://resources/web_styles/neon.tres",
	"custom": "res://resources/web_styles/custom.tres",
}

const SKILL_PATHS := [
	"res://resources/skills/swing_pump.tres",
	"res://resources/skills/reel_speed.tres",
	"res://resources/skills/zip_range.tres",
	"res://resources/skills/max_health.tres",
	"res://resources/skills/focus_gain.tres",
	"res://resources/skills/wall_run.tres",
	"res://resources/skills/web_damage.tres",
]

var launch_mode: String = "menu"
var mission_id: String = ""
var equipped_suit_id: String = "classic"
var web_style: WebStyleData
var suits: Dictionary = {}
var web_styles: Dictionary = {}
var skills: Array[SkillData] = []
var gadget: GadgetData


func _ready() -> void:
	_load_catalog()
	equipped_suit_id = str(SaveManager.get_value("suits/equipped", "classic"))
	_load_web_style_from_save()


func _load_catalog() -> void:
	for id in SUIT_PATHS.keys():
		var res := load(SUIT_PATHS[id])
		if res is SuitData:
			suits[id] = res
	for id in WEB_PATHS.keys():
		var res := load(WEB_PATHS[id])
		if res is WebStyleData:
			web_styles[id] = res
	for path in SKILL_PATHS:
		var res := load(path)
		if res is SkillData:
			skills.append(res)
	var loaded_gadget := load("res://resources/weapons/web_bomb.tres")
	if loaded_gadget is GadgetData:
		gadget = loaded_gadget
	if web_style == null and web_styles.has("classic"):
		web_style = web_styles["classic"].duplicate_style()


func _load_web_style_from_save() -> void:
	var stored: Dictionary = SaveManager.get_value("web_style", {})
	if stored.is_empty():
		var suit := get_suit(equipped_suit_id)
		if suit and suit.web_style:
			web_style = suit.web_style.duplicate_style()
		return
	var style := WebStyleData.new()
	style.style_id = str(stored.get("style_id", "custom"))
	style.style_name = str(stored.get("style_name", "Custom"))
	style.primary_color = _color(stored.get("primary", [0.86, 0.93, 1.0, 1.0]))
	style.accent_color = _color(stored.get("accent", [0.55, 0.75, 1.0, 1.0]))
	style.thickness = float(stored.get("thickness", 0.034))
	style.glow = float(stored.get("glow", 1.6))
	style.braid_scale = float(stored.get("braid_scale", 22.0))
	style.scroll_speed = float(stored.get("scroll_speed", 1.4))
	style.strands = int(stored.get("strands", 2))
	style.pattern = str(stored.get("pattern", "braid"))
	web_style = style


func get_suit(id: String) -> SuitData:
	return suits.get(id, null)


func owns_suit(id: String) -> bool:
	var owned: Array = SaveManager.get_value("suits/owned", ["classic"])
	return id in owned or id == "classic" or id == "custom"


func unlock_suit(id: String) -> void:
	var owned: Array = SaveManager.get_value("suits/owned", ["classic"]).duplicate()
	if id not in owned:
		owned.append(id)
		SaveManager.set_value("suits/owned", owned)


func equip_suit(id: String) -> void:
	if not owns_suit(id):
		return
	equipped_suit_id = id
	SaveManager.set_value("suits/equipped", id)
	EventBus.suit_changed.emit(id)


func apply_web_style(style: WebStyleData, save: bool = true) -> void:
	web_style = style.duplicate_style()
	if save:
		SaveManager.set_value("web_style", {
			"style_id": web_style.style_id,
			"style_name": web_style.style_name,
			"primary": [web_style.primary_color.r, web_style.primary_color.g, web_style.primary_color.b, web_style.primary_color.a],
			"accent": [web_style.accent_color.r, web_style.accent_color.g, web_style.accent_color.b, web_style.accent_color.a],
			"thickness": web_style.thickness,
			"glow": web_style.glow,
			"braid_scale": web_style.braid_scale,
			"scroll_speed": web_style.scroll_speed,
			"strands": web_style.strands,
			"pattern": web_style.pattern,
		})
	EventBus.web_style_changed.emit(web_style)


func skill_rank(id: String) -> int:
	var ranks: Dictionary = SaveManager.get_value("skills/ranks", {})
	return int(ranks.get(id, 0))


func skill_multiplier(id: String) -> float:
	var rank := skill_rank(id)
	for skill in skills:
		if skill.skill_id == id:
			return 1.0 + skill.per_rank * float(rank)
	return 1.0


func try_buy_skill(id: String) -> bool:
	var points := int(SaveManager.get_value("skills/points", 0))
	if points <= 0:
		return false
	var ranks: Dictionary = SaveManager.get_value("skills/ranks", {}).duplicate()
	var current := int(ranks.get(id, 0))
	var max_rank := 3
	for skill in skills:
		if skill.skill_id == id:
			max_rank = skill.max_rank
	if current >= max_rank:
		return false
	ranks[id] = current + 1
	SaveManager.set_value("skills/ranks", ranks)
	SaveManager.set_value("skills/points", points - 1)
	return true


func add_xp(amount: int) -> void:
	var xp := int(SaveManager.get_value("skills/xp", 0)) + amount
	var level := int(SaveManager.get_value("skills/level", 1))
	var points := int(SaveManager.get_value("skills/points", 0))
	while xp >= level * 100:
		xp -= level * 100
		level += 1
		points += 1
	SaveManager.set_value("skills/xp", xp)
	SaveManager.set_value("skills/level", level)
	SaveManager.set_value("skills/points", points)


func add_tokens(amount: int) -> void:
	var tokens := int(SaveManager.get_value("currencies/tokens", 0)) + amount
	SaveManager.set_value("currencies/tokens", tokens)


func custom_colors() -> Dictionary:
	var stored: Dictionary = SaveManager.get_value("suits/custom_colors", {})
	return {
		"primary": _color(stored.get("primary", [0.72, 0.08, 0.1, 1.0])),
		"secondary": _color(stored.get("secondary", [0.08, 0.12, 0.32, 1.0])),
		"accent": _color(stored.get("accent", [0.9, 0.82, 0.55, 1.0])),
	}


func set_custom_colors(primary: Color, secondary: Color, accent: Color) -> void:
	SaveManager.set_value("suits/custom_colors", {
		"primary": [primary.r, primary.g, primary.b, primary.a],
		"secondary": [secondary.r, secondary.g, secondary.b, secondary.a],
		"accent": [accent.r, accent.g, accent.b, accent.a],
	})
	EventBus.suit_changed.emit(equipped_suit_id)


func _color(value: Variant) -> Color:
	if value is Array and value.size() >= 3:
		var a := 1.0
		if value.size() > 3:
			a = float(value[3])
		return Color(float(value[0]), float(value[1]), float(value[2]), a)
	return Color.WHITE


func pump_multiplier() -> float:
	var suit := get_suit(equipped_suit_id)
	var suit_mult := suit.swing_multiplier if suit else 1.0
	return suit_mult * skill_multiplier("swing_pump")


func reel_multiplier() -> float:
	return skill_multiplier("reel_speed")


func health_multiplier() -> float:
	var suit := get_suit(equipped_suit_id)
	var suit_mult := suit.health_multiplier if suit else 1.0
	return suit_mult * skill_multiplier("max_health")


func damage_multiplier() -> float:
	var suit := get_suit(equipped_suit_id)
	var suit_mult := suit.damage_multiplier if suit else 1.0
	return suit_mult * skill_multiplier("web_damage")
