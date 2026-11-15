#!/usr/bin/env bash
# Plays the game from the start screen (stage 6 vertical slice).
#   bash tools/play.sh           play
#   bash tools/play.sh capture   start screen + scripted tour + loss run; screenshots to production/qa/evidence/stage6-slice/
#   bash tools/play.sh hud-test  HUD: help, map found in the library, slot bar, floats → production/qa/evidence/hud-slots-map/
#   bash tools/play.sh art-test  cozy and haunted storybook living room → production/qa/evidence/art-test-living-room/
#   bash tools/play.sh art-test <dir> --code-art   the same with every prop code-drawn (painted sprites off), for comparison
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
elif [[ "${1:-}" == "hud-test" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/${2:-hud-slots-map}" --hud-test
elif [[ "${1:-}" == "art-test" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/${2:-art-test-living-room}" --art-test "${@:3}"
fi
exec "$GODOT" "${BASE[@]}"
