class_name BossGround
extends Node3D
## The arena turns in the boss's favour when it shows its true form ("power_ground" in
## enemies.json + "power_spots" of the boss in the map). Today: wheat patches that sprout
## when the Harvest Herald becomes the Scarecrow. Walking over a ripe patch heals the boss
## (a fraction of its max health) and dries the patch; it grows back after a while. The
## hero cuts a patch by attacking next to it, so the healing can be denied.
##   "power_ground": {"prop": "prp_trigo", "heal": 0.15, "radius": 1.3, "regrow": 30.0,
##                    "seek_below": 0.8, "stalks": 7}

signal healed(amount: float)

var boss: Enemy
var cfg: Dictionary = {}
## One entry per patch: {"node": Node3D, "ready": bool, "timer": float}.
var _patches: Array[Dictionary] = []


func setup(the_boss: Enemy, spots: Array, config: Dictionary) -> void:
	boss = the_boss
	cfg = config
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for s: Variant in spots:
		var spot: Array = s
		var patch := Node3D.new()
		patch.position = Vector3(float(spot[0]), 0.0, float(spot[1]))
		patch.scale = Vector3(1.0, 0.01, 1.0)
		patch.visible = false
		add_child(patch)
		var r: float = radius()
		var stalks: int = int(cfg.get("stalks", 7))
		for i: int in stalks:
			var ang: float = TAU * i / stalks + rng.randf() * 0.6
			var dist: float = 0.0 if i == 0 else r * rng.randf_range(0.35, 0.8)
			var body: StaticBody3D = PropFactory.spawn(patch, str(cfg.get("prop", "prp_trigo")),
				Vector3(cos(ang) * dist, 0.0, sin(ang) * dist), rng.randf() * 360.0, rng.randf_range(0.9, 1.25))
			if body:
				body.collision_layer = 0
		_patches.append({"node": patch, "ready": false, "timer": 0.0})


func radius() -> float:
	return float(cfg.get("radius", 1.3))


## The patches come out of the ground one after the other (transformation scene).
func sprout(seconds: float) -> void:
	for i: int in _patches.size():
		var p: Dictionary = _patches[i]
		var n: Node3D = p["node"]
		var tw := create_tween()
		tw.tween_interval(seconds * 0.6 * i / maxf(_patches.size(), 1.0))
		tw.tween_callback(func() -> void:
			n.visible = true
			ProtoVisuals.flash_disc(get_parent(), n.global_position, radius(), Color(1.0, 0.85, 0.3, 0.45), 0.4))
		tw.tween_property(n, "scale", Vector3.ONE, seconds * 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void: p["ready"] = true)


func ready_count() -> int:
	var n: int = 0
	for p: Dictionary in _patches:
		if p["ready"]:
			n += 1
	return n


## Nearest ripe patch within `max_dist` of `from` (Vector3.INF when none).
func nearest_ready(from: Vector3, max_dist: float) -> Vector3:
	var best: Vector3 = Vector3.INF
	var best_d: float = max_dist
	for p: Dictionary in _patches:
		if not p["ready"]:
			continue
		var at: Vector3 = (p["node"] as Node3D).global_position
		var d: float = Vector2(at.x - from.x, at.z - from.z).length()
		if d < best_d:
			best_d = d
			best = at
	return best


## The hero's blade (attacks and skills) cuts ripe patches it reaches.
func cut_at(center: Vector3, reach: float) -> void:
	for p: Dictionary in _patches:
		if not p["ready"]:
			continue
		var at: Vector3 = (p["node"] as Node3D).global_position
		if Vector2(at.x - center.x, at.z - center.z).length() <= reach + radius() * 0.6:
			_dry(p, Color(0.95, 0.8, 0.35, 0.5))
			Audio.play_sfx("hit", at, 1.3)


func _physics_process(delta: float) -> void:
	for p: Dictionary in _patches:
		if not p["ready"] and float(p["timer"]) > 0.0:
			p["timer"] = float(p["timer"]) - delta
			if float(p["timer"]) <= 0.0:
				_regrow(p)
	if not is_instance_valid(boss) or boss.is_dead() or boss.invulnerable:
		return
	for p: Dictionary in _patches:
		if not p["ready"]:
			continue
		var at: Vector3 = (p["node"] as Node3D).global_position
		var b: Vector3 = boss.global_position
		if Vector2(at.x - b.x, at.z - b.z).length() <= radius() + 0.3:
			_dry(p, Color(0.4, 1.0, 0.45, 0.55))
			var amount: float = boss.heal(float(cfg.get("heal", 0.15)))
			if amount > 0.0:
				healed.emit(amount)


## Patch eaten (by the boss) or cut (by the hero): it dries down and grows back later.
func _dry(p: Dictionary, color: Color) -> void:
	p["ready"] = false
	p["timer"] = float(cfg.get("regrow", 30.0))
	var n: Node3D = p["node"]
	ProtoVisuals.flash_disc(get_parent(), n.global_position, radius(), color, 0.5)
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector3(1.15, 0.12, 1.15), 0.35).set_ease(Tween.EASE_IN)


func _regrow(p: Dictionary) -> void:
	var n: Node3D = p["node"]
	var tw := create_tween()
	tw.tween_property(n, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: p["ready"] = true)
