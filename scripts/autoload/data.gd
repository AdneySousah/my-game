extends Node
## Loads every game-content JSON from res://data once. Autoloaded as `Data`.

var progression: Dictionary = {}
var xp_to_next: Array = []
var mob_xp: Array = []
var skills: Array[Dictionary] = []
var enemies: Dictionary = {}
var enemy_scaling: Dictionary = {}
## NPC definitions (data/characters/npcs.json): id -> {name, color, voice, ...}.
var npcs: Dictionary = {}
## Quests in the order they appear in data/quests/quests.json.
var quests: Array[Dictionary] = []
## Dialogue id -> {"lines": [[speaker, key], ...]} from every file in data/dialogues.
var dialogues: Dictionary = {}

var _skills_by_id: Dictionary = {}
var _quests_by_id: Dictionary = {}


func _ready() -> void:
	progression = _load_json("res://data/progression/progression.json")
	var xp_table: Dictionary = _load_json("res://data/progression/xp_table.json")
	xp_to_next = xp_table.get("xp_to_next", [])
	mob_xp = xp_table.get("mob_xp", [])

	var skill_file: Dictionary = _load_json("res://data/skills/skills.json")
	for s: Dictionary in skill_file.get("skills", []):
		skills.append(s)
		_skills_by_id[s["id"]] = s

	var enemy_file: Dictionary = _load_json("res://data/enemies/enemies.json")
	enemies = enemy_file.get("enemies", {})
	enemy_scaling = enemy_file.get("scaling_per_level", {})

	npcs = _load_json("res://data/characters/npcs.json").get("npcs", {})
	for q: Dictionary in _load_json("res://data/quests/quests.json").get("quests", []):
		quests.append(q)
		_quests_by_id[q["id"]] = q
	for f: String in DirAccess.get_files_at("res://data/dialogues"):
		if f.ends_with(".json"):
			dialogues.merge(_load_json("res://data/dialogues/" + f).get("dialogues", {}))


func skill(id: String) -> Dictionary:
	return _skills_by_id.get(id, {})


func quest(id: String) -> Dictionary:
	return _quests_by_id.get(id, {})


func npc(id: String) -> Dictionary:
	return npcs.get(id, {})


func level_cap() -> int:
	return int(progression.get("level_cap", 100))


## XP needed to go from `level` to `level + 1`. 0 at the cap.
func xp_needed(level: int) -> int:
	if level < 1 or level > xp_to_next.size():
		return 0
	return int(xp_to_next[level - 1])


## XP of a regular enemy of `level`.
func mob_xp_for(level: int) -> int:
	var i: int = clampi(level, 1, mob_xp.size()) - 1
	return int(mob_xp[i]) if not mob_xp.is_empty() else 0


func _load_json(path: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("Data: não consegui ler %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_error("Data: JSON inválido em %s" % path)
	return {}
