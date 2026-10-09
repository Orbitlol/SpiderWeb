extends Resource
class_name EnemyData

@export var enemy_id: String = "thug"
@export var display_name: String = "Thug"
@export var max_health: float = 70.0
@export var move_speed: float = 4.2
@export var attack_damage: float = 8.0
@export var attack_range: float = 1.8
@export var detect_range: float = 18.0
@export var attack_windup: float = 0.55
@export var color: Color = Color(0.25, 0.27, 0.32, 1)
@export var can_swing_anchor: bool = false
@export var score_value: int = 10
