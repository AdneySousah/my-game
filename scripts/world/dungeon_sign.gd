class_name DungeonSign
extends Node3D
## Sign at a dungeon's entrance, shown once its final boss is down: "Resetar masmorra".
## Main lights the interact button when the hero stands next to it; pressing it brings
## the boss back (Session.dungeon_resets) for another run (drops, quests, insignias).

const RADIUS: float = 2.4

## The red "Modo Infernal" sign (post-game) instead of the normal reset.
var infernal: bool = false
var _label: Label3D


func _ready() -> void:
	PropFactory.spawn(self, "prp_placa", Vector3.ZERO, 0.0, 1.2)
	_label = Label3D.new()
	_label.text = tr("DUNGEON_INFERNAL_SIGN" if infernal else "DUNGEON_RESET_SIGN")
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 34
	_label.outline_size = 10
	_label.pixel_size = 0.01
	_label.modulate = Color("#ff5a3a") if infernal else Color("#ffd23f")
	_label.no_depth_test = true
	_label.position.y = 2.6
	add_child(_label)
	add_child(ProtoVisuals.ground_disc(RADIUS * 0.8, Color(1.0, 0.25, 0.1, 0.22) if infernal else Color(1.0, 0.8, 0.3, 0.16)))


func in_range(pos: Vector3) -> bool:
	if not visible:
		return false
	var d: Vector3 = pos - global_position
	d.y = 0.0
	return d.length() <= RADIUS
