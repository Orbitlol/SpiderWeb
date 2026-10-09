extends Node
class_name TraversalStateMachine

enum State {
	GROUNDED,
	AIR,
	SWING,
	ZIP,
	SLINGSHOT,
	WALL_RUN,
	WALL_CRAWL,
	DIVE,
	DODGE,
	HITSTUN,
	PERCH,
}

signal state_changed(previous: State, next: State)

var state: State = State.AIR
var state_time: float = 0.0


func transition(next: State) -> void:
	if next == state:
		return
	var previous := state
	state = next
	state_time = 0.0
	state_changed.emit(previous, next)


func tick(delta: float) -> void:
	state_time += delta


func is_airborne() -> bool:
	return state == State.AIR or state == State.DIVE or state == State.ZIP or state == State.DODGE


func is_webbed() -> bool:
	return state == State.SWING or state == State.SLINGSHOT
