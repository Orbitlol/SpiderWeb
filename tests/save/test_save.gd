extends RefCounted

static func run() -> PackedStringArray:
	var fails := PackedStringArray()
	var migrated := SaveMigrator.migrate({"version": 1, "mod_note": "keep-me"})
	if int(migrated.get("version", 0)) != SaveMigrator.SAVE_VERSION:
		fails.append("save version was not migrated to %s" % SaveMigrator.SAVE_VERSION)
	if str(migrated.get("mod_note", "")) != "keep-me":
		fails.append("migration dropped an unknown field")
	var skills: Variant = migrated.get("skills", {})
	if typeof(skills) != TYPE_DICTIONARY or not skills.has("ranks") or not skills.has("points"):
		fails.append("version 1 save did not gain skill ranks")
	if not migrated.has("weather") or not migrated.has("web_presets"):
		fails.append("migration did not fill newer sections")
	var fresh := SaveMigrator.migrate({})
	if int(fresh.get("version", 0)) != 3 or str(fresh.get("suits", {}).get("equipped", "")) != "classic":
		fails.append("empty save did not become the default")
	return fails
