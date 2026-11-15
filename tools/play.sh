#!/usr/bin/env bash
# Plays the game from the start screen (stage 6 vertical slice).
#   bash tools/play.sh           play
#   bash tools/play.sh capture   start screen + scripted tour + loss run; screenshots to production/qa/evidence/stage6-slice/
#   bash tools/play.sh art-test  cozy and haunted storybook living room → production/qa/evidence/art-test-living-room/
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
elif [[ "${1:-}" == "art-test" ]]; then
	exec "$GODOT" "${BASE[@]}" "$GAME" -- "--capture=$PWD/production/qa/evidence/${2:-art-test-living-room}" --art-test
fi
exec "$GODOT" "${BASE[@]}"
