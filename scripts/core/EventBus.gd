extends Node

## Cross-scene signals. Gameplay systems still talk to each other directly
## when they share a scene; this bus is only for menu, save, and mission events.

signal suit_changed(suit_id: String)
signal web_style_changed(style: WebStyleData)
signal mission_started(mission_id: String)
signal mission_updated(objective: String, progress: float)
signal mission_completed(mission_id: String)
signal mission_failed(mission_id: String)
signal token_collected(token_id: String)
signal enemy_defeated(enemy_id: String)
signal checkpoint_reached(checkpoint_id: String)
signal district_entered(district_id: String)
signal player_damaged(amount: float)
signal flow_changed(value: float)
signal focus_changed(value: float)
signal dialogue_requested(speaker: String, line: String)
signal settings_changed
signal photo_mode_toggled(active: bool)
