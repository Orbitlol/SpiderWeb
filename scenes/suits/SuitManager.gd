extends Node
class_name SuitManager

const POWERS := {
	"web_burst": preload("res://scenes/player/powers/WebBurstPower.gd"),
	"velocity_surge": preload("res://scenes/player/powers/VelocitySurgePower.gd"),
	"camouflage": preload("res://scenes/player/powers/CamouflagePower.gd"),
	"armor_pulse": preload("res://scenes/player/powers/ArmorPulsePower.gd"),
	"symbiote_strike": preload("res://scenes/player/powers/SymbioteStrikePower.gd"),
}


static func make_power(power_id: String) -> Node:
	if POWERS.has(power_id):
		return POWERS[power_id].new()
	return null


func equip(id: String) -> void:
	GameState.equip_suit(id)
