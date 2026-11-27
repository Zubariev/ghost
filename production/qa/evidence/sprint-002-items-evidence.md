# Test Evidence: Item and lore icons

> **Story**: sprint task S2-07 / S2-10 in `production/sprints/sprint-002.md` (no story files; tasks are the stories)
> **Story Type**: Visual/Feel (+UI)
> **Date**: 2026-11-27
> **Tester**: project owner (windowed captures and live play); Claude (headless checks, screenshot review)
> **Build / Commit**: branch `feat/godot-setup-room-spike`, HEAD 4f6c374 plus uncommitted sprint 002 work
> **Test cases**: `production/qa/test-cases/s2-07-item-icons-cases.md`

---

## What Was Tested

The 20 painted item icons (14 Must + 6 lore) loaded from `assets/art/items/`, with the code drawing as fallback: a contact sheet at 40 and 64 px, the HUD slot bar, the search grid, and the hollow's pentagram, recipe list and bar.

**Acceptance criteria covered**: S2-07 / S2-10: "S2-07: set reads at 40 px; fallback test. S2-10: whole catalog painted"

---

## Acceptance Criteria Results

| # | Criterion (from the sprint plan) | Result | Notes |
|---|---|---|---|
| AC-1 | set reads at 40 px | PASS | contact-sheet-40px |
| AC-2 | fallback test | PASS | `tests/unit/art/item_art_test.gd`; unknown items show the fallback dot (35-slots-full filler items) |
| AC-3 | whole catalog painted (S2-10) | PASS | 20 of 20 icons |

---

## Screenshots / Video

All files are on disk in the folders named.

| # | Filename | What It Shows | Acceptance Criterion |
|---|---|---|---|
| 1 | `sprint-002-items/contact-sheet-40px.png` | all 20 at 40 px | AC-1, AC-3 |
| 2 | `sprint-002-items/contact-sheet-64px.png` | all 20 at 64 px | AC-3 |
| 3 | `sprint-002-items-hud/35-slots-full.png` | slot bar with painted items (5 filler items show the fallback) | AC-1, AC-2 |
| 4 | `sprint-002-items-hud/34-slots-map-family-bar-floats.png` | slot bar in play | AC-1 |
| 5 | `sprint-002-items/grid-23-sofa-searched.png` | search grid with painted icons incl. the photo (lore) | AC-1, AC-3 |
| 6 | `sprint-002-items/journal-25.png` | journal (text only, no icons by design) | — |
| 7 | `sprint-002-items/c04-ingredients-on-star.png` | pentagram and bar in the hollow | AC-1 |
| 8 | `sprint-002-items/c07-result-in-bar-locked-recipe.png` | result in the bar, recipe list | AC-1 |

---

## Test Conditions

- **Game state at start**: `bash tools/play.sh hud-test sprint-002-items-hud`, `bash tools/play.sh capture` (copies of 23 and 25 kept here), `bash tools/play.sh crafting-test sprint-002-items`; contact sheets from `tools/art/montage.gd`
- **Platform / hardware**: Linux, NVIDIA GTX 1650 (NVK), Vulkan Forward+, 1280×720 windowed
- **Framerate during test**: smooth (user, smoke check 2026-11-27)
- **Any special setup required**: capture modes in `tools/play.sh`; they set state through the game's own calls

---

## Observations

- The monocle icon still reads a little like a magnifying glass (handle); candidate to repaint.
- The journal shows lore as text only; icons appear in the grid and bar.

---

## Sign-Off

| Role | Name | Date | Signature |
|---|---|---|---|
| Lead sign-off (solo developer) | project owner | 2026-11-27 | ☑ signed off in session (PASS) |
