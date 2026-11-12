## Loads the game's text table (`assets/i18n/strings.csv`: a "keys" column, then one
## column per locale) into Godot's TranslationServer, so every text goes through tr().
## Adding a language is adding a column.
##
## [codeblock]
## Localization.load_csv("res://assets/i18n/strings.csv", "uk")
## label.text = tr("PAUSED")
## [/codeblock]
class_name Localization
extends RefCounted


## Registers every locale column and switches to [param locale]. Returns the locales found.
static func load_csv(path: String, locale: String) -> PackedStringArray:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	var locales := PackedStringArray()
	if file == null:
		push_error("Localization: cannot open %s" % path)
		return locales
	var header: PackedStringArray = file.get_csv_line()
	var tables: Array[Translation] = []
	for column: int in range(1, header.size()):
		var translation := Translation.new()
		translation.locale = header[column]
		tables.append(translation)
		locales.append(header[column])
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 2 or row[0].is_empty():
			continue
		for column: int in range(1, mini(row.size(), header.size())):
			tables[column - 1].add_message(row[0], row[column])
	for translation: Translation in tables:
		TranslationServer.add_translation(translation)
	TranslationServer.set_locale(locale)
	return locales
