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
## Item definitions (data/items/items.json): id -> {...}; items_config has the rest of the file.
var items: Dictionary = {}
var items_config: Dictionary = {}
## Blacksmith rules (data/smith/smith.json): enhance chances and costs, sockets, recipes.
var smith: Dictionary = {}
## Gold shops (data/shop/shop.json) and the real-money shop (data/shop/store.json).
var shop: Dictionary = {}
var store: Dictionary = {}
## Daily missions, login calendar, achievements (data/routine/routine.json).
var routine: Dictionary = {}
## Day/night light per hour and the wind (data/world/daynight.json).
var daynight: Dictionary = {}
## Villagers, animals and birds that bring the maps to life (data/world/ambience.json).
var ambience: Dictionary = {}
## The illustrated world map of the travel window and where each map sits on it.
var world_map: Dictionary = {}
## Dungeon difficulty signs, quest boards and the cities' wanted bosses.
var boards: Dictionary = {}

var _skills_by_id: Dictionary = {}
var _quests_by_id: Dictionary = {}


func _ready() -> void:
	progression = _load_json("res://data/progression/progression.json")
	daynight = _load_json("res://data/world/daynight.json")
	ambience = _load_json("res://data/world/ambience.json")
	world_map = _load_json("res://data/world/world_map.json")
	boards = _load_json("res://data/world/boards.json")
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

	items_config = _load_json("res://data/items/items.json")
	items = items_config.get("items", {})
	smith = _load_json("res://data/smith/smith.json")
	shop = _load_json("res://data/shop/shop.json")
	store = _load_json("res://data/shop/store.json")
	routine = _load_json("res://data/routine/routine.json")
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


func item(id: String) -> Dictionary:
	return items.get(id, {})


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
