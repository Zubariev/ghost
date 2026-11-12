#!/usr/bin/env bash
# Opens the stage 2 debug simulation view (DEBUG ONLY).
#   bash tools/sim-view.sh           watch it live
#   bash tools/sim-view.sh capture   scripted run; saves screenshots to production/qa/evidence/stage4-morale/
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/home/ther0/Games/godot}"
ARGS=(--path . --windowed --resolution 1280x720 res://src/debug/sim_view/sim_view.tscn)
if [[ "${1:-}" == "capture" ]]; then
	ARGS+=(-- "--capture=$PWD/production/qa/evidence/${2:-stage4-morale}")
fi
exec "$GODOT" "${ARGS[@]}"
