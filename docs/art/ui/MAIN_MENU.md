# Main Menu

| | Status |
|---|---|
| Main menu (built 2026-11-15) | **PROVISIONAL** — awaiting the user's review of the captures |
| Concept `art/references/Примарний маєток_ Привид проти людей.png` | Visual and compositional reference only (never shown in game) |
| Asset sheet `art/references/Вікторіанська вітальня та кнопки UI.png` | Source of the menu's room artwork and the two plaque states |

## What it is

The game now starts here (`project.godot` → `src/game/menu/main_menu.tscn`). Title top left with a
small bobbing ghost and gold flourishes; five parchment plaques below; the illustrated living
room on the right over a dark painted wall; a dark shade on the left keeps the plaques clear of
the painting.

| Entry | Does |
|---|---|
| Нова гра | Opens the existing briefing screen (premise, family, controls; Esc returns to the menu), then the game — the startup flow is unchanged |
| Завантажити гру | The save-selection screen, showing its empty state: **there is no save system yet** (see Missing) |
| Налаштування | Display mode, window size, controls help at the start, morale changes above people; Apply saves and applies, За замовчуванням fills in the defaults, Назад discards. Saved in `user://settings.cfg` (`GameSettings`) |
| Автори | Placeholders for people (no names invented); real attributions for the fonts and the engine |
| Вихід | Asks «Вийти з гри?», then quits |

Keyboard: arrows move, Enter / Space activate, Esc closes a sub-screen and gives the focus back to
its plaque. The mouse moves the focus too, so one plaque is lit at a time. The game's end
summary «На головну» returns here.

## Pause menu (2026-11-15)

Esc in a game pauses it and opens the pause menu over the dimmed room (`PauseMenu`, a layer above
the HUD; it replaces the old «ПАУЗА» caption): **Продовжити** (resume), **Налаштування** (the same
`SettingsPanel` as the main menu; applying it switches the floating morale texts at once),
**Головне меню** (asks first — the game is not saved). Esc steps back out of a sub-screen, then
resumes. Not offered while the end summary shows.

**Saving — next task** (user decision 2026-11-15): a save system with an unlimited list of saves;
then the pause menu gets «Зберегти гру» and the Load screen lists the saves.

## Look

- **Room:** `assets/art/ui/menu/menu_room.png` (1199 × 764), cut from the sheet with
  `tools/sprite_cutout.gd` (`bg_min` 0.5 for the painted checkerboard); scaled to the screen
  height, right-aligned.
- **Plaques:** `plaque_normal.png` (muted parchment), `plaque_hover.png` (warm, glowing) at 0.52;
  nine-patch ends of 30 px so the ornaments never stretch. Hover and keyboard focus: the warm
  plaque; pressed: warm, darkened; disabled: muted and faded (`PlaqueButton`).
- **Panels:** dark walnut with a thin antique-gold border, a Yeseva One title over a small
  ornamental divider (`MenuPanel`).
- **Type:** Yeseva One for the title and panel titles, Alegreya for plaque labels and story
  lines, PT Sans for settings and notes — the approved set (`ART_DIRECTION.md` §6).
- **Animation** (`MenuBackdrop`, a separate layer; the room image is never redrawn or changed):
  firelight breathing on the stones and floor, a few embers rising, a candle glow, dust motes
  in the window light, the ghost glimpsed in the window for ~4 s every 24 s; the title ghost
  bobs. No curtain movement: the curtains are part of the one painting (it would need a
  separate curtain layer).

## Differences from the brief (and why)

- **Fonts:** the brief names Atkinson Hyperlegible Next and IM Fell English. Neither has Cyrillic,
  so they cannot show the game's Ukrainian text; the approved set (Yeseva One, PT Sans, Alegreya)
  is used instead.
- **No volume sliders:** the game has no audio at all yet, so they would change nothing (the brief:
  do not expose controls without a working implementation). The settings screen says so.
- **No overwrite confirmation on New Game:** there is nothing to overwrite without saves.
- **Title in Ukrainian:** «Привид / проти / людей», laid out like the concept's three lines.

## Missing integrations

- **Saving and loading:** none in the game — the next task (unlimited list of saves, user decision
  2026-11-15). The Load screen shows its empty state until then; with saves: list them with their
  metadata (and delete), add «Зберегти гру» to the pause menu; the main-menu question in the
  pause menu can then offer to save first.
- **Audio:** add Master / Music / Effects volume to `GameSettings` and the Settings screen with
  the first audio bus.
- **Credits:** fill in the people when known.

## Verification

`bash tools/play.sh menu-test` → `production/qa/evidence/main-menu/` (40–45 at 1280 × 720,
`1600x900/` the same at 1600 × 900); the pause menu in `bash tools/play.sh hud-test` (36–38).
Tests: `tests/unit/settings/game_settings_test.gd`, `tests/integration/menu/main_menu_test.gd`
(including every sub-screen fitting the screen), `tests/integration/menu/pause_menu_test.gd`.
