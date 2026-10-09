extends RefCounted

const PATHS := [
	"res://resources/suits/classic.tres",
	"res://resources/suits/velocity.tres",
	"res://resources/suits/stealth.tres",
	"res://resources/suits/armored.tres",
	"res://resources/suits/symbiote.tres",
	"res://resources/suits/custom.tres",
	"res://resources/web_styles/classic.tres",
	"res://resources/web_styles/gold.tres",
	"res://resources/web_styles/symbiote.tres",
	"res://resources/web_styles/neon.tres",
	"res://resources/web_styles/custom.tres",
	"res://resources/skills/swing_pump.tres",
	"res://resources/skills/reel_speed.tres",
	"res://resources/skills/zip_range.tres",
	"res://resources/skills/max_health.tres",
	"res://resources/skills/focus_gain.tres",
	"res://resources/skills/wall_run.tres",
	"res://resources/skills/web_damage.tres",
	"res://resources/enemies/thug.tres",
	"res://resources/enemies/goblin_king.tres",
	"res://resources/enemies/doctor_octopus.tres",
	"res://resources/enemies/venom.tres",
	"res://resources/districts/skyline.tres",
	"res://resources/districts/midtown.tres",
	"res://resources/districts/yards.tres",
	"res://resources/districts/harbor.tres",
	"res://resources/missions/first_flight.tres",
	"res://resources/missions/street_trouble.tres",
	"res://resources/missions/king_of_the_sky.tres",
	"res://resources/missions/lab_escape.tres",
	"res://resources/missions/time_trial.tres",
	"res://resources/missions/token_hunt.tres",
	"res://resources/weapons/web_bomb.tres",
	"res://scenes/enemies/Enemy.tscn",
	"res://scenes/bosses/GoblinKing.tscn",
	"res://scenes/bosses/DoctorOctopus.tscn",
	"res://scenes/bosses/Venom.tscn",
	"res://scenes/vehicles/Car.tscn",
	"res://scenes/npcs/Miles.tscn",
	"res://scenes/npcs/Gwen.tscn",
]

static func run() -> PackedStringArray:
	var fails := PackedStringArray()
	for path in PATHS:
		if not ResourceLoader.exists(path):
			fails.append("missing %s" % path)
			continue
		if load(path) == null:
			fails.append("failed to load %s" % path)
	if GameState.get_suit("classic") == null:
		fails.append("classic suit did not load into GameState")
	if GameState.web_style == null:
		fails.append("web style catalog did not load")
	if GameState.skills.size() < 7:
		fails.append("skill catalog is incomplete")
	return fails
