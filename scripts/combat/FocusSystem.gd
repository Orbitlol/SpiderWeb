extends Node
class_name FocusSystem

signal changed(value: float, active: bool)

var value: float = 0.0
var active: bool = false
var time_left: float = 0.0
const MAX_VALUE := 100.0


func add(amount: float) -> void:
	var gain := amount * GameState.skill_multiplier("focus_gain")
	var suit := GameState.get_suit(GameState.equipped_suit_id)
	if suit:
		gain *= suit.focus_multiplier
	value = clampf(value + gain, 0.0, MAX_VALUE)
	changed.emit(value, active)
	EventBus.focus_changed.emit(value)


func try_activate() -> bool:
	if active or value < 25.0:
		return false
	active = true
	time_left = 2.4
	value -= 25.0
	changed.emit(value, active)
	AudioManager.play("sense", -2.0)
	return true


func tick(delta: float) -> void:
	if not active:
		return
	time_left -= delta
	value = maxf(0.0, value - 18.0 * delta)
	changed.emit(value, active)
	EventBus.focus_changed.emit(value)
	if time_left <= 0.0 or value <= 0.0:
		active = false
		changed.emit(value, active)


func enemy_scale() -> float:
	return 0.32 if active else 1.0
