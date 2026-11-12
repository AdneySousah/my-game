class_name Stats
extends RefCounted
## Hero level, XP, attribute points and derived combat stats (GDD 6.1, 6.2, 6.9).
## Pure data + math, no nodes, so it is easy to test.

signal leveled_up(new_level: int)
signal xp_changed(xp: int, needed: int)
signal stats_changed

const ATTRIBUTES: Array[String] = ["str", "vit", "agi", "foc"]

var level: int = 1
var xp: int = 0
var unspent_points: int = 0
var attributes: Dictionary = {}
## Extra attack fraction from buffs (e.g. Brado de Guerra = 0.25).
var atk_buff: float = 0.0
## Seconds left on the "Derrotado" debuff.
var defeated_time_left: float = 0.0
## Flat bonuses of the equipment worn (stat -> amount), set by the Player.
var gear: Dictionary = {}
## Potion buffs: stat ("atk", "def", "speed") -> {"amount": fraction, "time": seconds left}.
var buffs: Dictionary = {}
## Multiplier on every attribute (premium pass = 1.1), set by the Player.
var attr_mult: float = 1.0


func _init() -> void:
	var start: Dictionary = Data.progression.get("start_attributes", {})
	for a: String in ATTRIBUTES:
		attributes[a] = int(start.get(a, 0))


func xp_needed() -> int:
	return Data.xp_needed(level)


func is_max_level() -> bool:
	return level >= Data.level_cap()


func add_xp(amount: int) -> void:
	if amount <= 0 or is_max_level():
		return
	xp += amount
	while not is_max_level() and xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		unspent_points += int(Data.progression.get("points_per_level", 5))
		leveled_up.emit(level)
	if is_max_level():
		xp = 0
	xp_changed.emit(xp, xp_needed())
	stats_changed.emit()


## Loses a fraction of the XP needed for the current level. Never loses a level.
func lose_xp_fraction(fraction: float) -> int:
	var lost: int = mini(xp, int(xp_needed() * fraction))
	xp -= lost
	xp_changed.emit(xp, xp_needed())
	return lost


func spend_point(attribute: String) -> bool:
	if unspent_points <= 0 or not attributes.has(attribute):
		return false
	attributes[attribute] += 1
	unspent_points -= 1
	stats_changed.emit()
	return true


func set_defeated(seconds: float) -> void:
	defeated_time_left = seconds
	stats_changed.emit()


func tick(delta: float) -> void:
	for k: String in buffs.keys():
		buffs[k]["time"] = float(buffs[k]["time"]) - delta
		if float(buffs[k]["time"]) <= 0.0:
			buffs.erase(k)
			stats_changed.emit()
	if defeated_time_left > 0.0:
		defeated_time_left = maxf(0.0, defeated_time_left - delta)
		if defeated_time_left == 0.0:
			stats_changed.emit()


## Final value of a derived stat: base + level growth + attributes, then caps and debuffs.
func get_stat(stat: String) -> float:
	var p: Dictionary = Data.progression
	var value: float = float(p.get("base_stats", {}).get(stat, 0.0))
	value += float(p.get("growth_per_level", {}).get(stat, 0.0)) * (level - 1)
	var effects: Dictionary = p.get("attribute_effects", {})
	for a: String in ATTRIBUTES:
		value += float(effects.get(a, {}).get(stat, 0.0)) * attr_total(a)
	value += float(gear.get(stat, 0.0))
	if stat == "atk":
		value *= 1.0 + atk_buff + buff("atk")
	elif stat == "def":
		value *= 1.0 + buff("def")
	elif stat == "atk_speed":
		value += buff("speed")
	var caps: Dictionary = p.get("stat_caps", {})
	if caps.has(stat):
		value = minf(value, float(caps[stat]))
	if defeated_time_left > 0.0 and stat in ["max_hp", "atk", "def"]:
		value *= float(p.get("death", {}).get("defeated_mult", 0.95))
	return value


## Attribute value with bonuses (premium pass), as used by the stats.
func attr_total(a: String) -> float:
	return float(attributes.get(a, 0)) * attr_mult


## Active potion buff for a stat (0 if none).
func buff(stat: String) -> float:
	return float((buffs.get(stat, {}) as Dictionary).get("amount", 0.0))


## A new buff of the same kind replaces the old one (no stacking).
func add_buff(stat: String, amount: float, seconds: float) -> void:
	buffs[stat] = {"amount": amount, "time": seconds}
	stats_changed.emit()


## Attack speed as a multiplier (1.0 = normal).
func attack_speed_mult() -> float:
	return 1.0 + get_stat("atk_speed")


func cooldown_mult() -> float:
	return 1.0 - get_stat("cdr")


func crit_multiplier() -> float:
	return 1.0 + get_stat("crit_dmg")


func to_dict() -> Dictionary:
	return {"level": level, "xp": xp, "unspent_points": unspent_points, "attributes": attributes,
		"defeated_time_left": defeated_time_left}


func from_dict(d: Dictionary) -> void:
	level = clampi(int(d.get("level", 1)), 1, Data.level_cap())
	xp = maxi(0, int(d.get("xp", 0)))
	unspent_points = maxi(0, int(d.get("unspent_points", 0)))
	var attrs: Dictionary = d.get("attributes", {})
	for a: String in ATTRIBUTES:
		attributes[a] = int(attrs.get(a, attributes.get(a, 0)))
	defeated_time_left = float(d.get("defeated_time_left", 0.0))
	stats_changed.emit()
	xp_changed.emit(xp, xp_needed())
