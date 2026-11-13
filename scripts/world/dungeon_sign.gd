class_name DungeonSign
extends Node3D
## Signs and boards the hero uses with the interact button (Main finds the nearest one):
##  - "reset": at a dungeon's entrance once its boss is down, brings the boss back
##    (Session.dungeon_resets) for another run;
##  - "infernal": the red post-game sign, the same in Infernal Mode;
##  - "tier": outside a dungeon, picks how hard it is (stronger monsters, more drops);
##  - "board": quest board outside a dungeon (3 small jobs a day, see Bounties);
##  - "wanted": the city's wanted poster (a daily world boss, see Bounties).

const RADIUS: float = 2.4
const COLORS: Dictionary = {
	"reset": Color("#ffd23f"), "infernal": Color("#ff5a3a"), "tier": Color("#ff9a3c"),
	"board": Color("#9ee37d"), "wanted": Color("#ff7a7a"),
}

var kind: String = "reset"
## The red "Modo Infernal" sign (post-game) instead of the normal reset.
var infernal: bool = false:
	set(v):
		infernal = v
		if v:
			kind = "infernal"
## The dungeon ("tier", "board") or city ("wanted") the sign is about.
var target: String = ""
var _label: Label3D


func _ready() -> void:
	PropFactory.spawn(self, "prp_placa", Vector3.ZERO, 0.0, 1.2)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 34
	_label.outline_size = 10
	_label.pixel_size = 0.01
	_label.modulate = COLORS.get(kind, Color.WHITE)
	_label.no_depth_test = true
	_label.position.y = 2.6
	add_child(_label)
	var c: Color = COLORS.get(kind, Color.WHITE)
	add_child(ProtoVisuals.ground_disc(RADIUS * 0.8, Color(c, 0.2)))
	refresh_label()


## The words over the sign (the tier one shows the dungeon's current difficulty).
func refresh_label() -> void:
	if _label == null:
		return
	match kind:
		"infernal":
			_label.text = tr("DUNGEON_INFERNAL_SIGN")
		"tier":
			_label.text = tr("DTIER_SIGN") % tr(str(Bounties.tier_info(Session.dungeon_tier_of(target)).get("name", "")))
		"board":
			_label.text = tr("BOARD_SIGN")
		"wanted":
			_label.text = tr("WANTED_SIGN")
		_:
			_label.text = tr("DUNGEON_RESET_SIGN")


func in_range(pos: Vector3) -> bool:
	if not visible:
		return false
	var d: Vector3 = pos - global_position
	d.y = 0.0
	return d.length() <= RADIUS
