extends Node
class_name FlowSystem

signal changed(value: float)

var value: float = 0.0


func tick(delta: float, speed: float, state: TraversalStateMachine.State) -> void:
	var target_gain := 0.0
	if state == TraversalStateMachine.State.SWING or state == TraversalStateMachine.State.ZIP or state == TraversalStateMachine.State.DIVE:
		target_gain = clampf(speed / 36.0, 0.0, 1.0) * 16.0
	elif state == TraversalStateMachine.State.WALL_RUN:
		target_gain = 8.0
	elif state == TraversalStateMachine.State.GROUNDED and speed < 4.0:
		target_gain = -10.0
	else:
		target_gain = -4.0
	value = clampf(value + target_gain * delta, 0.0, 100.0)
	changed.emit(value)
	EventBus.flow_changed.emit(value)


func bump(amount: float) -> void:
	value = clampf(value + amount, 0.0, 100.0)
	changed.emit(value)
	EventBus.flow_changed.emit(value)
