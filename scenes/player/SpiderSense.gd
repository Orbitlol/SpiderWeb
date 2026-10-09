extends Node
class_name SpiderSense

signal danger(amount: float)
signal perfect_window(active: bool)

var danger_level: float = 0.0
var window_time: float = 0.0
var _warned: bool = false


func warn(windup: float) -> void:
	danger_level = 1.0
	window_time = windup
	if not _warned:
		_warned = true
		AudioManager.play("sense", -6.0)
		Haptics.pulse(22, 0.35)
	danger.emit(danger_level)
	perfect_window.emit(window_time > 0.0 and window_time <= CombatRules.PERFECT_WINDOW)


func clear() -> void:
	danger_level = 0.0
	window_time = 0.0
	_warned = false
	danger.emit(0.0)
	perfect_window.emit(false)


func tick(delta: float) -> void:
	if window_time > 0.0:
		window_time = maxf(0.0, window_time - delta)
		danger_level = clampf(window_time / 0.55, 0.0, 1.0)
		danger.emit(danger_level)
		perfect_window.emit(window_time > 0.0 and window_time <= CombatRules.PERFECT_WINDOW)
		if window_time <= 0.0:
			_warned = false
	elif danger_level > 0.0:
		danger_level = move_toward(danger_level, 0.0, delta * 2.0)
		danger.emit(danger_level)


func in_perfect_window() -> bool:
	return window_time > 0.0 and window_time <= CombatRules.PERFECT_WINDOW
