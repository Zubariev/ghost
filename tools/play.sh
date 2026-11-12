#!/usr/bin/env bash
# Plays the game (stage 5a: the ghost in Hamlet-style rooms).
#   bash tools/play.sh           play
#   bash tools/play.sh capture   scripted tour; saves screenshots to production/qa/evidence/stage5a-ghost/
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/home/ther0/Games/godot}"
ARGS=(--path . --windowed --resolution 1280x720 res://src/game/house_game.tscn)
if [[ "${1:-}" == "capture" ]]; then
	ARGS+=(-- "--capture=$PWD/production/qa/evidence/${2:-stage5a-ghost}")
fi
exec "$GODOT" "${ARGS[@]}"
