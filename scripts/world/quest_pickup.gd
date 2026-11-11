class_name QuestPickup
extends Node3D
## A glowing quest item on the ground (herb, crate...). Exists only while its quest
## step is active. Main picks it up when the hero walks over it.

const RADIUS: float = 1.6

var quest_id: String = ""
var index: int = 0
var item_key: String = ""

var _gem: MeshInstance3D
var _time: float = 0.0


func _ready() -> void:
	add_to_group("quest_pickups")
	add_child(ProtoVisuals.ground_disc(RADIUS * 0.8, Color(0.5, 1.0, 0.7, 0.25)))
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.45, 0.6, 0.45)
	_gem = ProtoVisuals.mesh_instance(mesh, Color("#8cffc1"), true)
	_gem.position.y = 0.7
	add_child(_gem)
	var light := OmniLight3D.new()
	light.light_color = Color("#8cffc1")
	light.light_energy = 1.2
	light.omni_range = 3.5
	light.position.y = 0.9
	add_child(light)
	var label := Label3D.new()
	label.text = tr(item_key)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 26
	label.outline_size = 9
	label.pixel_size = 0.01
	label.position.y = 1.5
	add_child(label)


func contains(pos: Vector3) -> bool:
	var d: Vector3 = pos - global_position
	d.y = 0.0
	return d.length() <= RADIUS


func _process(delta: float) -> void:
	_time += delta
	_gem.rotation.y = _time * 1.6
	_gem.position.y = 0.7 + sin(_time * 2.5) * 0.12
