#!/usr/bin/env bash
# Plays the game from the main menu (stage 6 vertical slice; main menu 2026-11-15).
#   bash tools/play.sh           play
#   bash tools/play.sh capture   start screen + scripted tour + loss run; screenshots to production/qa/evidence/stage6-slice/
#   bash tools/play.sh menu-test  main menu, settings, load, credits, exit (1280×720 and 1600×900) → production/qa/evidence/main-menu/
#   bash tools/play.sh font-test  candidate fonts with the game's Ukrainian text → production/qa/evidence/font-trial/specimen.png
#   bash tools/play.sh hud-test  HUD: help, map found in the library, slot bar, floats → production/qa/evidence/hud-slots-map/
#   bash tools/play.sh art-test  cozy and haunted storybook living room → production/qa/evidence/art-test-living-room/
#   bash tools/play.sh art-test <dir> --code-art   the same with every prop code-drawn (painted sprites off), for comparison
#   bash tools/play.sh character-test father  the painted father: waking, walking, eating, workbench, anxious, repairing, fright, sofa → production/qa/evidence/character-father/
#   bash tools/play.sh character-test  the painted grandma pilot: cooking, walking, anxious, fright, armchair → production/qa/evidence/character-pilot-grandma/
#   bash tools/play.sh props-test  every room with its painted props, by day (cozy) and night (haunted) → production/qa/evidence/art-phase4-props/
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/home/ther0/Games/godot}"
BASE=(--path . --windowed --resolution 1280x720)
GAME=res://src/game/house_game.tscn
if [[ "${1:-}" == "capture" ]]; then
	DIR="$PWD/production/qa/evidence/${2:-stage6-slice}"
	"$GODOT" "${BASE[@]}" res://src/game/title/title_screen.tscn -- "--capture=$DIR"
	"$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$DIR"
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$DIR" --capture-loss
elif [[ "${1:-}" == "menu-test" ]]; then
	DIR="$PWD/production/qa/evidence/${2:-main-menu}"
	"$GODOT" "${BASE[@]}" res://src/game/menu/main_menu.tscn -- "--capture=$DIR"
	exec "$GODOT" --path . --windowed --resolution 1600x900 res://src/game/menu/main_menu.tscn -- "--capture=$DIR/1600x900"
elif [[ "${1:-}" == "font-test" ]]; then
	exec "$GODOT" "${BASE[@]}" -s res://tools/font_specimen.gd -- "$PWD/prototypes/font-trial-2026-11-15/fonts" "$PWD/production/qa/evidence/font-trial/specimen.png"
elif [[ "${1:-}" == "hud-test" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/${2:-hud-slots-map}" --hud-test
elif [[ "${1:-}" == "character-test" && "${2:-}" == "son" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/character-son" --character-test=son
elif [[ "${1:-}" == "character-test" && "${2:-}" == "grandpa" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/character-grandpa" --character-test=grandpa
elif [[ "${1:-}" == "character-test" && "${2:-}" == "mother" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/character-mother" --character-test=mother
elif [[ "${1:-}" == "character-test" && "${2:-}" == "father" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/character-father" --character-test=father
elif [[ "${1:-}" == "character-test" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/${2:-character-pilot-grandma}" --character-test
elif [[ "${1:-}" == "props-test" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/${2:-art-phase4-props}" --props-test "${@:3}"
elif [[ "${1:-}" == "art-test" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/${2:-art-test-living-room}" --art-test "${@:3}"
fi
exec "$GODOT" "${BASE[@]}"
