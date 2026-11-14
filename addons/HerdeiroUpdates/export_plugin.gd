@tool
extends EditorPlugin
## Puts the HerdeiroUpdates Android plugin (Google Play in-app updates) into the Android
## export. Source and build script: tools/android/updates and tools/android/build_updates_plugin.sh.

var export_plugin: UpdatesExportPlugin


func _enter_tree() -> void:
	export_plugin = UpdatesExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(export_plugin)
	export_plugin = null


class UpdatesExportPlugin extends EditorExportPlugin:
	const PLUGIN_NAME: String = "HerdeiroUpdates"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([PLUGIN_NAME + "/bin/HerdeiroUpdates.aar"])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["com.google.android.play:app-update:2.1.0"])

	func _get_name() -> String:
		return PLUGIN_NAME
