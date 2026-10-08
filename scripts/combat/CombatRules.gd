extends RefCounted
class_name CombatRules

const PERFECT_WINDOW := 0.2


static func is_perfect_dodge(windup_remaining: float, dodge_pressed: bool) -> bool:
	return dodge_pressed and windup_remaining > 0.0 and windup_remaining <= PERFECT_WINDOW


static func combo_damage(base: float, step_index: int, flow: float, suit_mult: float) -> float:
	var combo := 1.0 + float(step_index) * 0.22
	var flow_bonus := 1.0 + clampf(flow / 100.0, 0.0, 1.0) * 0.35
	return base * combo * flow_bonus * suit_mult


static func finisher_ready(enemy_health_ratio: float, flow: float, distance: float) -> bool:
	return enemy_health_ratio <= 0.28 and flow >= 35.0 and distance <= 2.8
