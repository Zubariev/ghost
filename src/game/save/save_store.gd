## Save games on disk (2026-11-16; user decisions: save anywhere, an unlimited list of saves,
## an autosave at each dawn, automatic names). One file per save in [constant DIR], Godot's
## binary Variant format (exact numbers, no objects decoded): {version, meta, state}. The single
## autosave file is replaced each dawn; manual saves are kept until deleted.
##
## [codeblock]
## var store := SaveStore.new()
## store.save(game.save_state(), game.save_meta(false))
## for entry: Dictionary in store.list(): print(entry["meta"]["day"])
## var state: Dictionary = store.read(entry["path"])
## [/codeblock]
class_name SaveStore
extends RefCounted

const DIR: String = "user://saves"
## Bump when the saved state's shape changes; older saves are listed as unusable.
const VERSION: int = 1
const AUTOSAVE_FILE: String = "autosave.sav"
const EXTENSION: String = "sav"

var _dir: String


## A store in [param dir] (tests use their own folder).
func _init(dir: String = DIR) -> void:
	_dir = dir


## Writes a save of [param state] described by [param meta]; [param autosave] replaces the
## autosave instead of adding to the list. Returns the file path, or "" when it could not write.
func save(state: Dictionary, meta: Dictionary, autosave: bool = false) -> String:
	DirAccess.make_dir_recursive_absolute(_dir)
	var file_meta: Dictionary = meta.duplicate()
	file_meta["autosave"] = autosave
	if not file_meta.has("saved_at"):
		file_meta["saved_at"] = Time.get_unix_time_from_system()
	var name: String = AUTOSAVE_FILE if autosave else _new_name()
	var path: String = _dir.path_join(name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_var({"version": VERSION, "meta": file_meta, "state": state})
	file.close()
	return path


## Every save, newest first: {path, meta, usable} (usable: written by this version of the game).
func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(_dir):
		return out
	for file_name: String in DirAccess.get_files_at(_dir):
		if file_name.get_extension() != EXTENSION:
			continue
		var data: Dictionary = _read_file(_dir.path_join(file_name))
		if data.is_empty():
			continue
		out.append({"path": _dir.path_join(file_name), "meta": data.get("meta", {}),
			"usable": int(data.get("version", -1)) == VERSION})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["meta"].get("saved_at", 0.0)) > float(b["meta"].get("saved_at", 0.0)))
	return out


## True when there is at least one save.
func has_any() -> bool:
	return not list().is_empty()


## The saved game state in [param path]; empty if the file is missing, damaged or from another
## version.
func read(path: String) -> Dictionary:
	var data: Dictionary = _read_file(path)
	if int(data.get("version", -1)) != VERSION:
		return {}
	return data.get("state", {})


## Deletes the save in [param path]; true when it is gone.
func delete(path: String) -> bool:
	if not path.begins_with(_dir) or not FileAccess.file_exists(path):
		return false
	return DirAccess.remove_absolute(path) == OK


func _read_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data: Variant = file.get_var(false)   # never decode objects
	file.close()
	return data if data is Dictionary else {}


func _new_name() -> String:
	var stamp: int = int(Time.get_unix_time_from_system() * 1000.0)
	var name: String = "save_%d.%s" % [stamp, EXTENSION]
	var n: int = 1
	while FileAccess.file_exists(_dir.path_join(name)):
		name = "save_%d_%d.%s" % [stamp, n, EXTENSION]
		n += 1
	return name
