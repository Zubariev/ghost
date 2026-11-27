# Sprint 002 — final integration run (S2-09)

**Date**: 2026-11-27 · **Build**: `feat/godot-setup-room-spike`, HEAD 4f6c374 plus uncommitted sprint 002 work

## Automated
- Full suite: **548 test cases, 0 failures, 0 errors, 0 orphans** (`commands.test`, after `--import`).
- New: `tests/integration/save/sprint002_save_test.gd` — a hostile spider, half the roots tree (paid and
  unlocked through the normal rules) and a running speed elixir saved together and loaded into a fresh game;
  mood, calories, hostile time, owned nodes, energy maximum, slots, elixir time and the whole save match.
  Mutation-checked: without loading the spider it fails (4 failures), without loading the progression it fails
  (2); restored, it passes.
- Leak check: `house_game.tscn` exits headless (`--verbose`) with no "leaked" / "still in use" report after the
  2026-11-27 fix (`CraftingProgression` lambda cycle; regression test in `crafting_progression_test.gd`).

## Smoke
`production/qa/smoke-2026-11-27.md` — **PASS** (launch, core, sprint changes, in-game save/load, frame rate).

## Capture modes run (windowed, user, 2026-11-27)
routines-test, spider-test, roots-test, crafting-test, areas-test (day, 18:30, night), hud-test, capture.

## Code review
`/code-review` 2026-11-27 over the 32 sprint files (about 6,500 lines), with a fresh-context Godot reviewer.
First pass: CHANGES REQUIRED — a hovered plaque took the roots screen's Tab/arrow keys (verified by a
viewport-routed probe), 12 public methods without doc comments; two reviewer claims (right-click close, web
state on load) checked and dropped. Fixed with tests watched failing first: plaque focus off on the roots
screen, focus released when the roots open (a hovered hollow plaque kept it), hover cleared on leaving the
soil, redraw only while animating with "Менше руху", `RoomStage.elapsed()` instead of reading `_stage._time`,
doc comments added. Re-review: **APPROVED WITH SUGGESTIONS** (split `RootsScreen._build`, 42 lines; stop
`HouseGame._ready` / `house_game.gd` growing). 551 tests green; no exit leak.
