# Test Evidence: Roots screen soil and bark (partial)

> **Story**: sprint task S2-12 in `production/sprints/sprint-002.md` (no story files; tasks are the stories)
> **Story Type**: Visual/Feel
> **Date**: 2026-11-27
> **Tester**: project owner (windowed captures and live play); Claude (headless checks, screenshot review)
> **Build / Commit**: branch `feat/godot-setup-room-spike`, HEAD 4f6c374 plus uncommitted sprint 002 work
> **Test cases**: `production/qa/test-cases/s2-12-roots-art-cases.md`

---

## What Was Tested

The painted soil (now wrap-seamless, one smooth depth shade) and bark trunk on the roots screen, replacing the drawn bands. The painted coffin is out of scope this cycle; the code-drawn coffin shows, and the screen draws a painted one as soon as `assets/art/props/roots/coffin.png` exists.

**Acceptance criteria covered**: S2-12: "integrated, replaces fallback drawing"

---

## Acceptance Criteria Results

| # | Criterion (from the sprint plan) | Result | Notes |
|---|---|---|---|
| AC-1 | integrated, replaces fallback drawing (soil, bark) | PASS | r00–r10 |
| AC-2 | integrated, replaces fallback drawing (coffin) | DEFERRED | image service down |

---

## Screenshots / Video

All files are on disk in the folders named.

| # | Filename | What It Shows | Acceptance Criterion |
|---|---|---|---|
| 1 | `sprint-002-progression/r03-first-visit-T1-selected.png` | soil and bark | AC-1 |
| 2 | `sprint-002-progression/r09-everything-owned-coffin.png` | soil, bark, code-drawn coffin | AC-1, AC-2 |

---

## Test Conditions

- **Game state at start**: `bash tools/play.sh roots-test`
- **Platform / hardware**: Linux, NVIDIA GTX 1650 (NVK), Vulkan Forward+, 1280×720 windowed
- **Framerate during test**: smooth (user, smoke check 2026-11-27)
- **Any special setup required**: capture modes in `tools/play.sh`; they set state through the game's own calls

---

## Observations

- Fixed during review: a horizontal line from stepped shading, then a vertical seam where the soil repeats (`tools/art/make_seamless.gd`).

---

## Sign-Off

| Role | Name | Date | Signature |
|---|---|---|---|
| Lead sign-off (solo developer) | project owner | 2026-11-27 | ☑ signed off in session (PASS, partial scope) |
