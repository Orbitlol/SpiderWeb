extends RefCounted
class_name Haptics

static func pulse(ms: int, strong: float = 0.45) -> void:
	if not SettingsManager.haptics_enabled:
		return
	Input.vibrate_handheld(ms)
	var seconds := clampf(float(ms) / 1000.0, 0.02, 0.4)
	for id in Input.get_connected_joypads():
		Input.start_joy_vibration(int(id), strong * 0.45, strong, seconds)
