class_name Damage
extends RefCounted
## Damage formula shared by the hero and enemies.

## Defense reduces damage smoothly: 100 def = half damage.
const DEFENSE_CONSTANT: float = 100.0
const VARIANCE: float = 0.1


## Returns {"amount": int, "crit": bool}.
static func compute(
		atk: float, mult: float, defense: float,
		crit_chance: float = 0.0, crit_mult: float = 1.5,
		rng: RandomNumberGenerator = null) -> Dictionary:
	var r: RandomNumberGenerator = rng if rng != null else _shared_rng()
	var raw: float = atk * mult
	var reduced: float = raw * DEFENSE_CONSTANT / (DEFENSE_CONSTANT + maxf(defense, 0.0))
	var crit: bool = r.randf() < crit_chance
	if crit:
		reduced *= crit_mult
	reduced *= r.randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)
	return {"amount": maxi(1, roundi(reduced)), "crit": crit}


static var _rng: RandomNumberGenerator


static func _shared_rng() -> RandomNumberGenerator:
	if _rng == null:
		_rng = RandomNumberGenerator.new()
		_rng.randomize()
	return _rng
