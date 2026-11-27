# Test Evidence: Roots progression screen

> **Story**: sprint task S2-06 in `production/sprints/sprint-002.md` (no story files; tasks are the stories)
> **Story Type**: UI
> **Date**: 2026-11-27
> **Tester**: project owner (windowed captures and live play); Claude (headless checks, screenshot review)
> **Build / Commit**: branch `feat/godot-setup-room-spike`, HEAD 4f6c374 plus uncommitted sprint 002 work
> **Test cases**: `production/qa/test-cases/s2-06-roots-screen-cases.md`

---

## What Was Tested

The roots screen opened from the hollow (button and physical R): the first visit with T1 selected, a locked node, a node short of materials, unlocking (light runs along the root), owned and available nodes told apart, mid-progress with a room bond selected, everything owned with the long left root ending at the coffin, and back to the hollow. Spec: `design/ux/roots-progression.md`.

**Acceptance criteria covered**: S2-06: "all states and navigation work; 1280×720 fits; screenshots"

---

## Acceptance Criteria Results

| # | Criterion (from the sprint plan) | Result | Notes |
|---|---|---|---|
| AC-1 | all states work | PASS | r03–r09 |
| AC-2 | navigation works | PASS | r02 slide in, r10 back; arrows/Tab/Enter/Esc in the panel hint; headless 10/10 checks |
| AC-3 | 1280×720 fits | PASS | all shots 1280×720, nothing clipped |
| AC-4 | screenshots | PASS | 11 retained |

---

## Screenshots / Video

All files are on disk in the folders named.

| # | Filename | What It Shows | Acceptance Criterion |
|---|---|---|---|
| 1 | `sprint-002-progression/r00-back-yard.png` | the tree in the yard | AC-2 |
| 2 | `sprint-002-progression/r01-hollow-with-roots-button.png` | hollow with the Roots (R) button | AC-2 |
| 3 | `sprint-002-progression/r02-roots-sliding-in.png` | slide transition | AC-2 |
| 4 | `sprint-002-progression/r03-first-visit-T1-selected.png` | first visit, T1 selected | AC-1 |
| 5 | `sprint-002-progression/r04-locked-node-selected.png` | locked node | AC-1 |
| 6 | `sprint-002-progression/r05-short-of-materials.png` | short of materials | AC-1 |
| 7 | `sprint-002-progression/r06-T1-unlocking-light.png` | unlocking | AC-1 |
| 8 | `sprint-002-progression/r07-T1-owned-branches-open.png` | owned vs available | AC-1 |
| 9 | `sprint-002-progression/r08-mid-progress-room-bond-selected.png` | mid progress, room bond | AC-1 |
| 10 | `sprint-002-progression/r09-everything-owned-coffin.png` | all owned, coffin end | AC-1 |
| 11 | `sprint-002-progression/r10-back-in-the-hollow.png` | back in the hollow | AC-2 |

---

## Test Conditions

- **Game state at start**: `bash tools/play.sh roots-test` (back yard, materials given, nodes unlocked through the screen)
- **Platform / hardware**: Linux, NVIDIA GTX 1650 (NVK), Vulkan Forward+, 1280×720 windowed
- **Framerate during test**: smooth (user, smoke check 2026-11-27)
- **Any special setup required**: capture modes in `tools/play.sh`; they set state through the game's own calls

---

## Observations

- Revised during review: locked nodes tinted, owned and available told apart (ring vs halo/pulse).
- The coffin is code-drawn (its painting is deferred, S2-12).

---

## Sign-Off

| Role | Name | Date | Signature |
|---|---|---|---|
| UI review (optional for UI) | project owner | 2026-11-27 | ☑ signed off in session |
