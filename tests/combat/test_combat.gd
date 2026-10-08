extends RefCounted

static func run() -> PackedStringArray:
	var fails := PackedStringArray()
	if not CombatRules.is_perfect_dodge(0.12, true):
		fails.append("perfect dodge window rejected a valid dodge")
	if CombatRules.is_perfect_dodge(0.5, true) or CombatRules.is_perfect_dodge(0.1, false):
		fails.append("perfect dodge window was too wide")
	var light := CombatRules.combo_damage(10.0, 0, 0.0, 1.0)
	var heavy := CombatRules.combo_damage(10.0, 2, 100.0, 1.0)
	if heavy <= light:
		fails.append("combo damage did not scale")
	if not CombatRules.finisher_ready(0.2, 40.0, 2.0):
		fails.append("finisher should be ready")
	if CombatRules.finisher_ready(0.9, 40.0, 2.0) or CombatRules.finisher_ready(0.2, 10.0, 2.0):
		fails.append("finisher ready on a healthy or cold target")
	return fails
