class_name AppUpdate
extends Node
## Checks Google Play for a newer version of the game (owner, 14/11) through the
## HerdeiroUpdates Android plugin (addons/HerdeiroUpdates, source in tools/android/updates).
## The game stays offline: the Play Store app answers. On the PC, or a phone without the
## Play Store, nothing happens. Updating runs Play's own full-screen "immediate" update,
## which installs the new version and opens the game again.

signal update_found(version_code: int)
## Play's update page closed without updating (canceled or failed).
signal update_failed

const PLUGIN: String = "HerdeiroUpdates"
## UpdateAvailability.UPDATE_AVAILABLE in Play's library.
const UPDATE_AVAILABLE: int = 2
## Activity.RESULT_CANCELED; anything else but RESULT_OK (-1) is a failure.
const RESULT_CANCELED: int = 0
const RESULT_OK: int = -1

## The version code Play has, once found (0 = none).
var found_code: int = 0
var _plugin: Object


static func available() -> bool:
	return Engine.has_singleton(PLUGIN)


## Asks Play; update_found comes later if there is one. False when there is no plugin.
func check() -> bool:
	if not available():
		return false
	_plugin = Engine.get_singleton(PLUGIN)
	if not _plugin.is_connected("update_checked", _on_checked):
		_plugin.connect("update_checked", _on_checked)
		_plugin.connect("update_failed", _on_failed)
		_plugin.connect("update_result", _on_result)
	_plugin.call("checkForUpdate")
	return true


## Opens Play's update page.
func start() -> void:
	if _plugin:
		_plugin.call("startUpdate")


func _exit_tree() -> void:
	if _plugin and _plugin.is_connected("update_checked", _on_checked):
		_plugin.disconnect("update_checked", _on_checked)
		_plugin.disconnect("update_failed", _on_failed)
		_plugin.disconnect("update_result", _on_result)


func _on_checked(availability: int, version_code: int, immediate_allowed: bool, _stale_days: int, _priority: int) -> void:
	if availability == UPDATE_AVAILABLE and immediate_allowed:
		found_code = version_code
		update_found.emit(version_code)


func _on_failed(message: String) -> void:
	print("AppUpdate: ", message)


func _on_result(result_code: int) -> void:
	if result_code != RESULT_OK and result_code != RESULT_CANCELED:
		update_failed.emit()
