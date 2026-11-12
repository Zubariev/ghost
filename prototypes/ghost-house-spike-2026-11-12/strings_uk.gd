# PROTOTYPE - NOT FOR PRODUCTION
#
## Ukrainian player-facing text, looked up by key so it can move to Godot's
## translation files later without touching gameplay code.
extends RefCounted

const TEXT: Dictionary = {
	&"title": "Технічний тест: кімната",
	&"help": "WASD — рух    E — взаємодія    Q — поля зору    Пробіл — пауза    1 / 2 / 3 — ×1 / ×2 / ×4",
	&"phase_day": "День",
	&"phase_night": "Ніч",
	&"paused": "ПАУЗА",
	&"speed": "Швидкість ×%d",
	&"npc_grandma": "Бабуся",
	&"obj_lamp": "Лампа",
	&"obj_stove": "Плита",
	&"obj_window": "Вікно",
	&"prompt_snuff_lamp": "E — Загасити лампу",
	&"prompt_light_lamp": "E — Запалити лампу",
	&"prompt_unavailable": "%s — дія ще не входить у тест",
	&"log_lamp_snuffed": "Привид загасив лампу. У кімнаті стемніло.",
	&"log_lamp_lit": "Лампу знову запалено (лише для тесту).",
	&"log_unavailable": "Дію з об'єктом «%s» ще не реалізовано в цьому тесті.",
	&"log_sight_on": "Поля зору: показано.",
	&"log_sight_off": "Поля зору: приховано.",
	&"log_speed": "Швидкість часу: ×%d.",
	&"log_paused": "Пауза.",
	&"log_resumed": "Гру відновлено.",
	&"log_start": "Пройдіться кімнатою, крізь стіни, до лампи.",
}


## Returns the text for [param key], or the key itself when it is missing.
static func t(key: StringName) -> String:
	return TEXT.get(key, String(key))
