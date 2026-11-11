extends Node
## Local save, encrypted, with an integrity check and a backup copy. Autoloaded as `SaveGame`.
##
## File layout (inside Godot's AES-encrypted file): {"v", "payload", "hash"} where
## payload is the JSON of the game state and hash = SHA-256(payload + SALT).
## A save that fails the check is ignored and the backup (previous save) is used.
## Saving only happens when `active` (set by the title screen), so tests and tools
## that start the game directly never touch the player's save.

const VERSION: int = 1
const SALT: String = "herdeiro-dos-ceus/varenthia/v1"

var path: String = "user://save.dat"
## True while a real game (started from the title screen) is running.
var active: bool = false
## State read by load_game(), waiting for Main to apply it.
var pending: Dictionary = {}


func backup_path() -> String:
	return path.get_basename() + ".bak"


func has_save() -> bool:
	return not _read(path).is_empty() or not _read(backup_path()).is_empty()


## Writes the state. Keeps the previous save as the backup. Returns true on success.
func save_game(state: Dictionary) -> bool:
	var payload: String = JSON.stringify({"v": VERSION, "saved_at": Time.get_unix_time_from_system(), "state": state})
	var wrapper: String = JSON.stringify({"v": VERSION, "payload": payload, "hash": _hash(payload)})
	var tmp: String = path + ".tmp"
	var f := FileAccess.open_encrypted_with_pass(tmp, FileAccess.WRITE, _key())
	if f == null:
		push_error("SaveGame: não consegui gravar (%s)" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(wrapper)
	f.close()
	var dir := DirAccess.open(path.get_base_dir())
	if FileAccess.file_exists(path):
		dir.copy(path, backup_path())
	dir.rename(tmp, path)
	return true


## Reads the save (or the backup if the save is damaged) into `pending`. Returns it.
func load_game() -> Dictionary:
	var data: Dictionary = _read(path)
	if data.is_empty():
		data = _read(backup_path())
	pending = data.get("state", {})
	return pending


func delete_save() -> void:
	for p: String in [path, backup_path()]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	pending = {}


## {} when missing, unreadable or tampered with.
func _read(p: String) -> Dictionary:
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open_encrypted_with_pass(p, FileAccess.READ, _key())
	if f == null:
		return {}
	var text: String = f.get_as_text()
	f.close()
	var wrapper: Variant = JSON.parse_string(text)
	if not (wrapper is Dictionary):
		return {}
	var payload: String = str((wrapper as Dictionary).get("payload", ""))
	if payload == "" or str((wrapper as Dictionary).get("hash", "")) != _hash(payload):
		push_warning("SaveGame: arquivo %s falhou na verificação" % p)
		return {}
	var data: Variant = JSON.parse_string(payload)
	return data if data is Dictionary else {}


func _hash(payload: String) -> String:
	return (payload + SALT).sha256_text()


## Fixed game key (not tied to the device): a phone restored from backup keeps the
## save. Encryption stops casual editing; the hash catches any change.
func _key() -> String:
	return ("hdc|" + SALT).sha256_text()
