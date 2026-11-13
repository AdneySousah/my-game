class_name StarEvent
extends WorldEvent
## Star shower (Fase 8G, at night): shining shards fall around the hero for a while and
## stay glowing on the ground for a bit more; walking over one picks up a Star Shard
## (10 of them fuse into a rune in the bag).

const PICK_RANGE: float = 1.4

var _left: float = 90.0
var _linger: float = 40.0
var _to_drop: int = 14
var _drop_timer: float = 0.0
var _shards: Array[Node3D] = []
var _picked: int = 0
var _mat: StandardMaterial3D


func begin() -> void:
	_left = float(cfg.get("seconds", 90))
	_linger = float(cfg.get("linger", 40))
	_to_drop = int(cfg.get("shards", 14))
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.albedo_color = Color("#fff4c2")


func _physics_process(delta: float) -> void:
	if _done:
		return
	if _left > 0.0:
		_left -= delta
		_drop_timer -= delta
		if _to_drop > 0 and _drop_timer <= 0.0:
			_drop_timer = float(cfg.get("seconds", 90)) / float(maxi(int(cfg.get("shards", 14)), 1)) * 0.8
			_to_drop -= 1
			_drop_shard()
	else:
		_linger -= delta
	var pos: Vector3 = player.global_position
	for s: Node3D in _shards.duplicate():
		if not is_instance_valid(s):
			_shards.erase(s)
			continue
		s.rotate_y(delta * 2.0)
		if bool(s.get_meta("landed", false)) and Vector2(s.global_position.x - pos.x, s.global_position.z - pos.z).length() < PICK_RANGE:
			_shards.erase(s)
			_picked += 1
			main.give_item("mat_fragmento_estelar", 1)
			Audio.play_sfx("pickup", s.global_position)
			ProtoVisuals.flash_disc(map, s.global_position, 0.9, Color(1, 0.95, 0.6, 0.8), 0.4)
			s.queue_free()
	if (_left <= 0.0 and _shards.is_empty() and _to_drop <= 0) or (_left <= 0.0 and _linger <= 0.0):
		for s: Node3D in _shards:
			if is_instance_valid(s):
				s.queue_free()
		_shards.clear()
		main.hud.toast(tr("EV_STARS_END") % _picked, 2.5)
		finish(_picked > 0)


func _drop_shard() -> void:
	var at: Vector3 = spot_near(player.global_position, 3.0, float(cfg.get("radius", 13.0)))
	var s := Node3D.new()
	s.name = "StarShard"
	add_child(s)
	s.global_position = at + Vector3(2.5, 14.0, -2.5)
	var gem := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.34
	m.height = 0.85
	m.radial_segments = 4
	m.rings = 2
	gem.mesh = m
	gem.material_override = _mat
	gem.position.y = 0.0
	s.add_child(gem)
	var spark := Label3D.new()
	spark.text = "✦"
	spark.font_size = 128
	spark.pixel_size = 0.01
	spark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spark.modulate = Color("#ffe27a")
	spark.outline_size = 0
	spark.no_depth_test = false
	s.add_child(spark)
	# A soft glow on the ground once it lands.
	var glow: MeshInstance3D = ProtoVisuals.ground_disc(0.7, Color(1.0, 0.85, 0.35, 0.35))
	glow.position.y = -0.37
	glow.visible = false
	s.add_child(glow)
	_shards.append(s)
	var tw := s.create_tween()
	tw.tween_property(s, "global_position", at + Vector3(0, 0.4, 0), 1.1).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		s.set_meta("landed", true)
		glow.visible = true
		ProtoVisuals.flash_disc(map, at, 1.1, Color(1, 0.9, 0.5, 0.7), 0.5)
		Audio.play_sfx("mana", at, 0.7))


func status_text() -> String:
	return tr("EV_STARS_STATUS") % [_picked, WorldEvent.time_text(_left if _left > 0.0 else _linger)]


func progress() -> float:
	return -1.0
