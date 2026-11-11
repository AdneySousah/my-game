extends Node
## Global game state and constants. Autoloaded as `Game`.

const LEVEL_CAP: int = 100
const SKILL_SLOTS: int = 4

## Collision layers (bit values).
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 4

const MAIN_SCENE: String = "res://scenes/main/main.tscn"
const TITLE_SCENE: String = "res://scenes/ui/title.tscn"


func _ready() -> void:
	_register_inputs()


func version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func is_mobile() -> bool:
	return OS.has_feature("mobile")


## Input actions live in code so they are easy to review and change.
func _register_inputs() -> void:
	_action("move_left", [KEY_A, KEY_LEFT], [], [[JOY_AXIS_LEFT_X, -1.0]])
	_action("move_right", [KEY_D, KEY_RIGHT], [], [[JOY_AXIS_LEFT_X, 1.0]])
	_action("move_up", [KEY_W, KEY_UP], [], [[JOY_AXIS_LEFT_Y, -1.0]])
	_action("move_down", [KEY_S, KEY_DOWN], [], [[JOY_AXIS_LEFT_Y, 1.0]])
	_action("attack", [KEY_J], [JOY_BUTTON_X])
	_action("dodge", [KEY_SPACE], [JOY_BUTTON_A])
	_action("sprint", [KEY_SHIFT], [JOY_BUTTON_LEFT_STICK])
	_action("skill_1", [KEY_1, KEY_U], [JOY_BUTTON_Y])
	_action("skill_2", [KEY_2, KEY_I], [JOY_BUTTON_B])
	_action("skill_3", [KEY_3, KEY_O], [JOY_BUTTON_LEFT_SHOULDER])
	_action("skill_4", [KEY_4, KEY_P], [JOY_BUTTON_RIGHT_SHOULDER])
	_action("toggle_attributes", [KEY_C], [JOY_BUTTON_BACK])
	_action("toggle_skills", [KEY_K], [])
	_action("toggle_map", [KEY_M], [])
	_action("toggle_quests", [KEY_L], [])
	_action("interact", [KEY_E, KEY_F], [JOY_BUTTON_RIGHT_STICK])
	_action("debug_level_up", [KEY_F1], [])


func _action(action: String, keys: Array, buttons: Array, axes: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)
	for b: int in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b as JoyButton
		InputMap.action_add_event(action, jb)
	for a: Array in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = a[0] as JoyAxis
		jm.axis_value = a[1]
		InputMap.action_add_event(action, jm)
