extends Resource
class_name SuitData

@export var suit_id: String = "classic"
@export var suit_name: String = "Classic"
@export var description: String = ""
@export var suit_power_id: String = "web_burst"
@export var passive_perks: PackedStringArray = PackedStringArray()
@export var web_style: WebStyleData
@export var primary_color: Color = Color(0.72, 0.08, 0.1, 1)
@export var secondary_color: Color = Color(0.08, 0.12, 0.32, 1)
@export var accent_color: Color = Color(0.9, 0.82, 0.55, 1)
@export var eye_color: Color = Color(1.0, 0.95, 0.85, 1)
@export var color_variants: PackedColorArray = PackedColorArray()
@export var health_multiplier: float = 1.0
@export var swing_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var focus_multiplier: float = 1.0
@export var detect_range_multiplier: float = 1.0
@export var unlocked_by_default: bool = true
