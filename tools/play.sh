#!/usr/bin/env bash
# Plays the game (art test: storybook living room).
#   bash tools/play.sh           play
#   bash tools/play.sh capture   scripted tour; saves screenshots to production/qa/evidence/stage5d-energy/
#   bash tools/play.sh art-test  cozy and haunted storybook living room → production/qa/evidence/art-test-living-room/
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/home/ther0/Games/godot}"
ARGS=(--path . --windowed --resolution 1280x720 res://src/game/house_game.tscn)
if [[ "${1:-}" == "capture" ]]; then
	ARGS+=(-- "--capture=$PWD/production/qa/evidence/${2:-stage5d-energy}")
elif [[ "${1:-}" == "art-test" ]]; then
	ARGS+=(-- "--capture=$PWD/production/qa/evidence/${2:-art-test-living-room}" --art-test)
fi
exec "$GODOT" "${ARGS[@]}"
