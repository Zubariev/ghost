## Save files (2026-11-16): saves are listed newest first and read back exactly; the autosave is
## one file replaced each time; a save from another version is listed but cannot be read; a
## damaged file is skipped; deleting removes a save. Uses its own folder under user://.
extends GdUnitTestSuite

const DIR: String = "user://test_saves"

var _store: SaveStore


func before_test() -> void:
	_clean()
	_store = SaveStore.new(DIR)


func after_test() -> void:
	_clean()


func _clean() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for file: String in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(file))
		DirAccess.remove_absolute(DIR)


func test_saves_are_listed_newest_first_and_read_back_exactly() -> void:
	# Arrange: an older and a newer save (explicit times), state with exact floats and vectors
	var state: Dictionary = {"uv": Vector2(0.123456789, 0.987654321), "value": 33.3333333333, "names": ["a", "b"]}
	var older: String = _store.save({"n": 1}, {"day": 1, "saved_at": 1000.0})
	var newer: String = _store.save(state, {"day": 2, "saved_at": 2000.0})
	# Act
	var saves: Array[Dictionary] = _store.list()
	# Assert
	assert_int(saves.size()).is_equal(2)
	assert_str(String(saves[0]["path"])).is_equal(newer)
	assert_str(String(saves[1]["path"])).is_equal(older)
	assert_bool(bool(saves[0]["meta"]["autosave"])).is_false()
	assert_str(var_to_str(_store.read(newer))).is_equal(var_to_str(state))


func test_the_autosave_is_one_file_replaced_each_time() -> void:
	_store.save({"day": 1}, {"day": 1}, true)
	_store.save({"day": 2}, {"day": 2}, true)
	var saves: Array[Dictionary] = _store.list()
	assert_int(saves.size()).is_equal(1)
	assert_bool(bool(saves[0]["meta"]["autosave"])).is_true()
	assert_int(int(_store.read(String(saves[0]["path"]))["day"])).is_equal(2)


func test_a_save_from_another_version_is_listed_but_unreadable_and_junk_is_skipped() -> void:
	# Arrange: a file from a future version and a damaged file
	DirAccess.make_dir_recursive_absolute(DIR)
	var old := FileAccess.open(DIR.path_join("save_1.sav"), FileAccess.WRITE)
	old.store_var({"version": SaveStore.VERSION + 1, "meta": {"day": 3}, "state": {"x": 1}})
	old.close()
	var junk := FileAccess.open(DIR.path_join("save_2.sav"), FileAccess.WRITE)
	junk.store_string("not a save")
	junk.close()
	# Act
	var saves: Array[Dictionary] = _store.list()
	# Assert
	assert_int(saves.size()).is_equal(1)
	assert_bool(bool(saves[0]["usable"])).is_false()
	assert_dict(_store.read(String(saves[0]["path"]))).is_empty()


func test_deleting_removes_a_save_and_nothing_outside_the_folder() -> void:
	var path: String = _store.save({"n": 1}, {"day": 1})
	assert_bool(_store.delete("user://settings.cfg")).is_false()
	assert_bool(_store.delete(path)).is_true()
	assert_bool(_store.has_any()).is_false()
