class_name StatusEffects
extends Node
## Timed effects on an actor: stun, slow, def_break, weaken.
## Durations tick in _process, so they freeze while the game is paused.

signal changed

## name -> {"time": float, "value": float}
var _effects: Dictionary = {}


func apply(effect: String, duration: float, value: float = 0.0) -> void:
	var current: Dictionary = _effects.get(effect, {"time": 0.0, "value": 0.0})
	_effects[effect] = {
		"time": maxf(current["time"], duration),
		"value": maxf(current["value"], value),
	}
	changed.emit()


func has(effect: String) -> bool:
	return _effects.has(effect)


func time_left(effect: String) -> float:
	return maxf(0.0, float(_effects.get(effect, {}).get("time", 0.0)))


func value(effect: String) -> float:
	return float(_effects.get(effect, {}).get("value", 0.0))


func clear() -> void:
	_effects.clear()
	changed.emit()


## Ends one effect early (a charge tearing free of roots).
func remove(effect: String) -> void:
	if _effects.erase(effect):
		changed.emit()


func _process(delta: float) -> void:
	if _effects.is_empty():
		return
	var expired: Array[String] = []
	for e: String in _effects:
		_effects[e]["time"] -= delta
		if _effects[e]["time"] <= 0.0:
			expired.append(e)
	for e: String in expired:
		_effects.erase(e)
	if not expired.is_empty():
		changed.emit()
