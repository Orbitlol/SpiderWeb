extends Resource
class_name WebStyleData

@export var style_id: String = "classic"
@export var style_name: String = "Classic"
@export var primary_color: Color = Color(0.86, 0.93, 1.0, 1.0)
@export var accent_color: Color = Color(0.55, 0.75, 1.0, 1.0)
@export var thickness: float = 0.034
@export var glow: float = 1.6
@export var braid_scale: float = 22.0
@export var scroll_speed: float = 1.4
@export var strands: int = 2
@export var pattern: String = "braid"


func duplicate_style() -> WebStyleData:
	var copy := WebStyleData.new()
	copy.style_id = style_id
	copy.style_name = style_name
	copy.primary_color = primary_color
	copy.accent_color = accent_color
	copy.thickness = thickness
	copy.glow = glow
	copy.braid_scale = braid_scale
	copy.scroll_speed = scroll_speed
	copy.strands = strands
	copy.pattern = pattern
	return copy
