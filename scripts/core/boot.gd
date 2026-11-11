extends Control
## First scene: shows the version, then opens the title screen.

@onready var _info: Label = %Info


func _ready() -> void:
	var platform: String = "mobile" if Game.is_mobile() else "desktop"
	_info.text = "v%s · %s · Godot %s" % [
		Game.version(), platform, Engine.get_version_info().string
	]
	print("BOOT_OK version=%s platform=%s" % [Game.version(), platform])
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file(Game.TITLE_SCENE)
