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
## The autosave writes the file on a worker thread (owner, 13/11: the game hitched now
## and then; slow phone storage made the write + backup copy stall a frame).
var _task: int = -1
var _queued: String = ""
var _paths: Array[String] = []
var _mutex := Mutex.new()


func backup_path() -> String:
	return path.get_basename() + ".bak"


func has_save() -> bool:
	flush()
	return not _read(path).is_empty() or not _read(backup_path()).is_empty()


## Writes the state. Keeps the previous save as the backup. Returns true on success.
## `background`: the file is written on a worker thread (the periodic autosave); a later
## save or a read waits for it. Every other save is written right away.
func save_game(state: Dictionary, background: bool = false) -> bool:
	var payload: String = JSON.stringify({"v": VERSION, "saved_at": Time.get_unix_time_from_system(), "state": state})
	var wrapper: String = JSON.stringify({"v": VERSION, "payload": payload, "hash": _hash(payload)})
	if background:
		_mutex.lock()
		_queued = wrapper
		_paths = [path, backup_path()]
		_mutex.unlock()
		if _task < 0:
			_task = WorkerThreadPool.add_task(_write_queued, false, "save")
		return true
	flush()
	return _write(wrapper, path, backup_path())


## Waits for a save being written in the background.
func flush() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _process(_delta: float) -> void:
	if _task >= 0 and WorkerThreadPool.is_task_completed(_task):
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


## Worker thread: writes the newest queued save (a newer one may come in meanwhile).
func _write_queued() -> void:
	while true:
		_mutex.lock()
		var w: String = _queued
		var paths: Array[String] = _paths.duplicate()
		_queued = ""
		_mutex.unlock()
		if w == "":
			return
		_write(w, paths[0], paths[1])


func _write(wrapper: String, to: String, backup: String) -> bool:
	var tmp: String = to + ".tmp"
	var f := FileAccess.open_encrypted_with_pass(tmp, FileAccess.WRITE, _key())
	if f == null:
		push_error("SaveGame: não consegui gravar (%s)" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(wrapper)
	f.close()
	var dir := DirAccess.open(to.get_base_dir())
	if FileAccess.file_exists(to):
		dir.copy(to, backup)
	dir.rename(tmp, to)
	return true


## Reads the save (or the backup if the save is damaged) into `pending`. Returns it.
func load_game() -> Dictionary:
	flush()
	var data: Dictionary = _read(path)
	if data.is_empty():
		data = _read(backup_path())
	pending = data.get("state", {})
	return pending


func delete_save() -> void:
	flush()
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
