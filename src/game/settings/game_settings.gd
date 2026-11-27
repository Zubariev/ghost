## Player settings (main menu, 2026-11-15): only options that really work — display mode, window
## size, and the game options (the controls help shown at the start of a game, the morale changes
## floating above people, less motion). Saved to [constant PATH] between launches.
## No audio settings: the game has no sound yet (add them with the first audio bus).
##
## [codeblock]
## var settings := GameSettings.load_saved()
## settings.apply_display(get_window())
## [/codeblock]
class_name GameSettings
extends RefCounted

const PATH: String = "user://settings.cfg"
## Window sizes offered in windowed mode (the game is laid out for 1280 × 720 and scales).
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

## Fullscreen instead of a window.
var fullscreen: bool = false
## Window size in windowed mode; one of WINDOW_SIZES.
var window_size: Vector2i = WINDOW_SIZES[0]
## Show the controls help for the first seconds of a game (it always shows while H is held).
var show_help_at_start: bool = true
## Show a person's morale change floating above them.
var show_morale_floats: bool = true
## "Менше руху" (sprint 002, user decision 2026-11-27): screens cut instead of sliding and glow
## instead of pulsing (the roots screen, design/ux/roots-progression.md).
var reduced_motion: bool = false


## The settings a new player starts with.
static func defaults() -> GameSettings:
	return GameSettings.new()


## Settings from [param config]; missing or invalid values fall back to the defaults.
static func from_config(config: ConfigFile) -> GameSettings:
	var s := GameSettings.new()
	s.fullscreen = bool(config.get_value("display", "fullscreen", s.fullscreen))
	var size: Variant = config.get_value("display", "window_size", s.window_size)
	if size is Vector2i and WINDOW_SIZES.has(size):
		s.window_size = size
	s.show_help_at_start = bool(config.get_value("game", "show_help_at_start", s.show_help_at_start))
	s.show_morale_floats = bool(config.get_value("game", "show_morale_floats", s.show_morale_floats))
	s.reduced_motion = bool(config.get_value("game", "reduced_motion", s.reduced_motion))
	return s


## These settings as a config file.
func to_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "window_size", window_size)
	config.set_value("game", "show_help_at_start", show_help_at_start)
	config.set_value("game", "show_morale_floats", show_morale_floats)
	config.set_value("game", "reduced_motion", reduced_motion)
	return config


## The saved settings, or the defaults when nothing is saved yet (or the file is unreadable).
static func load_saved(path: String = PATH) -> GameSettings:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return defaults()
	return from_config(config)


## Saves to [param path]; returns the error code (OK when saved).
func save(path: String = PATH) -> Error:
	return to_config().save(path)


## True when both hold the same values.
func equals(other: GameSettings) -> bool:
	return other != null and fullscreen == other.fullscreen and window_size == other.window_size \
		and show_help_at_start == other.show_help_at_start and show_morale_floats == other.show_morale_floats \
		and reduced_motion == other.reduced_motion


## A copy to edit without touching these settings.
func duplicate_settings() -> GameSettings:
	return from_config(to_config())


## Applies the display settings to [param window]: fullscreen, or a centred window of the size.
func apply_display(window: Window) -> void:
	if fullscreen:
		window.mode = Window.MODE_FULLSCREEN
		return
	window.mode = Window.MODE_WINDOWED
	window.size = window_size
	var screen: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	window.position = screen.position + (screen.size - window_size) / 2
