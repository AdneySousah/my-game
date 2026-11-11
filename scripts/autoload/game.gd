extends Node
## Global game state and constants. Autoloaded as `Game`.

const LEVEL_CAP: int = 100
const SKILL_SLOTS: int = 4


func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func is_mobile() -> bool:
	return OS.has_feature("mobile")
