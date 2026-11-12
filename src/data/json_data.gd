## Reads JSON data files from `assets/data/`. The only place game data touches the disk,
## so every gameplay class can be built from plain dictionaries in tests.
class_name JsonData
extends RefCounted


## Returns the file's top-level object, or an empty dictionary (with an error) on failure.
static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("JsonData: missing file %s" % path)
		return {}
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_error("JsonData: %s is not a JSON object" % path)
	return {}
