class_name Npc
extends StaticBody3D
## A villager the hero can talk to. Shows its name, a quest marker ("!" offer,
## "?" next step; gold = main quest, blue = side quest) and short speech balloons
## when the hero walks by. Uses the Meshy model from data when there is one,
## otherwise a grey-box figure in the NPC's colour.

const TALK_RANGE: float = 2.6
const BARK_RANGE: float = 7.0
const BARK_COOLDOWN: float = 14.0
## Within this distance the NPC turns to look at the hero.
const LOOK_RANGE: float = 5.0
const TURN_SPEED: float = 4.0
const MARKER_COLORS: Dictionary = {
	"main": Color("#ffd23f"),
	"side": Color("#7fd1ff"),
}

var npc_id: String = ""
var data: Dictionary = {}
var player: Player
var model: CharacterModel

var _name_label: Label3D
var _marker: Label3D
var _bark: Label3D
var _bark_cd: float = 3.0
var _bark_index: int = 0
var _bark_tween: Tween
var _time: float = 0.0
var _height: float = 1.8
var _home_yaw: float = 0.0


func setup(id: String, hero: Player) -> void:
	npc_id = id
	data = Data.npc(id)
	player = hero
	name = "Npc_" + id
	add_to_group("npcs")


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	add_child(shape)

	var model_id: String = str(data.get("model", ""))
	if model_id != "":
		model = CharacterModel.create(model_id)
	if model:
		# Keeps animating while the game is paused for a conversation.
		model.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(model)
		model.play_loop("idle")
		_height = float(data.get("height", 1.9))
	else:
		add_child(ProtoVisuals.humanoid(Color(str(data.get("color", "#cccccc"))), 1.6))
		_height = 1.6

	_name_label = _label3d(28, Color("#fff3d6"))
	_name_label.text = tr(str(data.get("name", npc_id)))
	_name_label.position.y = _height + 0.35
	add_child(_name_label)

	_home_yaw = rotation.y
	_marker = _label3d(110, Color.WHITE)
	_marker.outline_size = 22
	_marker.position.y = _height + 1.05
	_marker.hide()
	add_child(_marker)

	_bark = _label3d(34, Color("#2b1a0a"))
	_bark.outline_modulate = Color(1, 0.97, 0.88)
	_bark.outline_size = 26
	_bark.position.y = _height + 0.8
	_bark.modulate.a = 0.0
	_bark.outline_modulate.a = 0.0
	add_child(_bark)


## marker: "" | "main_offer" | "side_offer" | "main_step" | "side_step".
func set_marker(marker: String) -> void:
	_marker.visible = marker != ""
	if marker != "":
		var parts: PackedStringArray = marker.split("_")
		_marker.text = "!" if parts[1] == "offer" else "?"
		_marker.modulate = MARKER_COLORS.get(parts[0], Color.WHITE)
	_bark.position.y = _height + (1.9 if _marker.visible else 0.8)


## Talking animation while this NPC has the line in a conversation.
func set_talking(talking: bool) -> void:
	if model:
		model.play_loop("talk" if talking else "idle")


func in_talk_range(pos: Vector3) -> bool:
	var d: Vector3 = pos - global_position
	d.y = 0.0
	return d.length() <= TALK_RANGE


## Turns to the hero at the start of a conversation.
func face(point: Vector3) -> void:
	var d: Vector3 = point - global_position
	d.y = 0.0
	if d.length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)


func _process(delta: float) -> void:
	_time += delta
	if _marker.visible:
		_marker.position.y = _height + 1.05 + sin(_time * 3.0) * 0.12
	if player == null or get_tree().paused:
		return
	# Turn towards the hero when he is close, back to the usual pose otherwise.
	var to: Vector3 = player.global_position - global_position
	to.y = 0.0
	var want: float = atan2(-to.x, -to.z) if to.length() < LOOK_RANGE else _home_yaw
	rotation.y = lerp_angle(rotation.y, want, minf(1.0, delta * TURN_SPEED))
	_bark_cd -= delta
	var barks: Array = data.get("barks", [])
	if _bark_cd <= 0.0 and not barks.is_empty() and global_position.distance_to(player.global_position) < BARK_RANGE:
		_bark_cd = BARK_COOLDOWN
		_show_bark(tr(str(barks[_bark_index % barks.size()])))
		_bark_index += 1


func _show_bark(text: String) -> void:
	_bark.text = text
	if _bark_tween:
		_bark_tween.kill()
	_bark_tween = create_tween().set_parallel()
	_bark_tween.tween_property(_bark, "modulate:a", 1.0, 0.25)
	_bark_tween.tween_property(_bark, "outline_modulate:a", 1.0, 0.25)
	_bark_tween.chain().tween_interval(2.6)
	_bark_tween.chain().tween_property(_bark, "modulate:a", 0.0, 0.4)
	_bark_tween.parallel().tween_property(_bark, "outline_modulate:a", 0.0, 0.4)


func _label3d(size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.font_size = size
	l.outline_size = 10
	l.pixel_size = 0.01
	l.modulate = color
	l.no_depth_test = true
	l.render_priority = 2
	return l
