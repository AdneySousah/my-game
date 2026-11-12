class_name BirdFlock
extends Node3D
## A few birds pecking on the ground together (fields, forest, river banks). When the hero
## comes close they all take off at once; some time later they come back.

const COME_BACK_AFTER: float = 25.0

var player: Node3D
var birds: Array[Bird] = []
var _spots: Array[Vector3] = []
var _away: float = -1.0


func setup(center: Vector3, count: int, seed_value: int, hero: Node3D) -> void:
	player = hero
	position = Vector3.ZERO
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i: int in count:
		var p: Vector3 = center + Vector3(rng.randf_range(-1.6, 1.6), 0, rng.randf_range(-1.6, 1.6))
		_spots.append(p)
		var b := Bird.new()
		b.setup(p, seed_value * 31 + i, hero)
		b.flock = self
		birds.append(b)
		add_child(b)


func scare() -> void:
	if _away >= 0.0:
		return
	_away = 0.0
	for b: Bird in birds:
		b.fly_away()


func _process(delta: float) -> void:
	if _away < 0.0:
		return
	_away += delta
	if _away < COME_BACK_AFTER:
		return
	# Come back only while the hero is not standing right there.
	if player and player.global_position.distance_to(_spots[0]) < 10.0:
		return
	_away = -1.0
	for i: int in birds.size():
		birds[i].return_to(_spots[i])
