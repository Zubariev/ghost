# Test Evidence: Back and front yards

> **Story**: sprint task S2-08 in `production/sprints/sprint-002.md` (no story files; tasks are the stories)
> **Story Type**: Visual/Feel
> **Date**: 2026-11-27
> **Tester**: project owner (windowed captures and live play); Claude (headless checks, screenshot review)
> **Build / Commit**: branch `feat/godot-setup-room-spike`, HEAD 4f6c374 plus uncommitted sprint 002 work
> **Test cases**: `production/qa/test-cases/s2-08-yards-cases.md`

---

## What Was Tested

Both yards in the storybook style: back yard (fence and trees on the back wall, fence with hedge on the sides, calm lawn, repainted tree with hollow, shed, woodpile, barrel, decor) and front yard (long hedge, swing oak, hydrangeas, mailbox, picket fence sides), by day, evening and night, with gameplay geometry unchanged.

**Acceptance criteria covered**: S2-08: "style match, seams gone, geometry snapshot unchanged"

---

## Acceptance Criteria Results

| # | Criterion (from the sprint plan) | Result | Notes |
|---|---|---|---|
| AC-1 | style match | PASS WITH NOTES | front-yard porch not painted (accepted for sprint 002 only) |
| AC-2 | seams gone | PASS | lawn rebuilt without the repeating root patches |
| AC-3 | geometry snapshot unchanged | PASS | `tests/integration/data/yard_geometry_test.gd` green; decor carries no gameplay data |

---

## Screenshots / Video

All files are on disk in the folders named.

| # | Filename | What It Shows | Acceptance Criterion |
|---|---|---|---|
| 1 | `sprint-002-areas/day-03-back_yard.png` | back yard, day | AC-1, AC-2 |
| 2 | `sprint-002-areas/evening-03-back_yard.png` | back yard, 18:30 | AC-1 |
| 3 | `sprint-002-areas/night-03-back_yard.png` | back yard, night | AC-1 |
| 4 | `sprint-002-areas/day-04-front_yard.png` | front yard, day | AC-1 |
| 5 | `sprint-002-areas/evening-04-front_yard.png` | front yard, 18:30 | AC-1 |
| 6 | `sprint-002-areas/night-04-front_yard.png` | front yard, night | AC-1 |

---

## Test Conditions

- **Game state at start**: `bash tools/play.sh areas-test sprint-002-areas` (10:00, 18:30, 22:10)
- **Platform / hardware**: Linux, NVIDIA GTX 1650 (NVK), Vulkan Forward+, 1280×720 windowed
- **Framerate during test**: smooth (user, smoke check 2026-11-27)
- **Any special setup required**: capture modes in `tools/play.sh`; they set state through the game's own calls

---

## Observations

- **Accepted gap (sprint 002 only)**: the front yard's back wall is still the plain weatherboard; the porch with door and wreath was not painted (image service down). Prompt ready in `art/prompts/sprint-002/retry4.json`.
- The game has only day and night (night from 22:00): the 18:30 shots show day lighting. The plan's "dusk" has no game state to check.
- The new lawn is even and a little plain (built from the old painting by `tools/art/calm_texture.gd`).

---

## Sign-Off

| Role | Name | Date | Signature |
|---|---|---|---|
| Lead sign-off (solo developer) | project owner | 2026-11-27 | ☑ signed off in session (PASS WITH NOTES) |
