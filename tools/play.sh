#!/usr/bin/env bash
# Plays the game (stage 5c: the family walks around furniture and through doors).
#   bash tools/play.sh           play
#   bash tools/play.sh capture   scripted tour; saves screenshots to production/qa/evidence/stage5c-movement/
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/home/ther0/Games/godot}"
ARGS=(--path . --windowed --resolution 1280x720 res://src/game/house_game.tscn)
if [[ "${1:-}" == "capture" ]]; then
	ARGS+=(-- "--capture=$PWD/production/qa/evidence/${2:-stage5c-movement}")
fi
exec "$GODOT" "${ARGS[@]}"
