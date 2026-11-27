# Test Evidence: Attic spider art, rig and animation

> **Story**: sprint task S2-05 in `production/sprints/sprint-002.md` (no story files; tasks are the stories)
> **Story Type**: Visual/Feel
> **Date**: 2026-11-27
> **Tester**: project owner (windowed captures and live play); Claude (headless checks, screenshot review)
> **Build / Commit**: branch `feat/godot-setup-room-spike`, HEAD 4f6c374 plus uncommitted sprint 002 work
> **Test cases**: `production/qa/test-cases/s2-05-spider-art-cases.md`

---

## What Was Tested

The painted spider (body and head image on the rig, legs drawn from the rig in the painting's warm charcoal with terracotta joints): idle sway, lowering toward a near ghost, eating after a trade, growth with calories, the hostile wind-up (front legs raised, red eyes, web mark at the ghost's feet), the web in flight and the hit message. The user also checked live that a moving ghost is missed and the drawing order in front of and behind the spider.

**Acceptance criteria covered**: S2-05: "idle/descend/feed/attack/size seen in capture"

---

## Acceptance Criteria Results

| # | Criterion (from the sprint plan) | Result | Notes |
|---|---|---|---|
| AC-1 | idle seen in capture | PASS | s01, s02 |
| AC-2 | descend seen in capture | PASS | s03, s04; climbing back in s07 |
| AC-3 | feed seen in capture | PASS | s05, s06 |
| AC-4 | attack seen in capture | PASS WITH NOTES | s08–s10; a moving ghost is missed (live). User note: web miss/hit timing feels off |
| AC-5 | size seen in capture | PASS | s07 vs s01 |

---

## Screenshots / Video

All files are on disk in the folders named.

| # | Filename | What It Shows | Acceptance Criterion |
|---|---|---|---|
| 1 | `sprint-002-spider/s01-idle-from-afar.png` | idle, ghost far | AC-1 |
| 2 | `sprint-002-spider/s02-idle-later.png` | idle sway later | AC-1 |
| 3 | `sprint-002-spider/s03-lowering.png` | lowering toward the ghost | AC-2 |
| 4 | `sprint-002-spider/s04-lowered-near-ghost.png` | lowered, trade prompt | AC-2 |
| 5 | `sprint-002-spider/s05-eating.png` | eating after a trade | AC-3 |
| 6 | `sprint-002-spider/s06-eating-later.png` | eating, later frame | AC-3 |
| 7 | `sprint-002-spider/s07-grown-and-high-again.png` | grown, back up high | AC-2, AC-5 |
| 8 | `sprint-002-spider/s08-hostile-wind-up-mark.png` | hostile wind-up and web mark | AC-4 |
| 9 | `sprint-002-spider/s09-web-in-flight.png` | web in flight | AC-4 |
| 10 | `sprint-002-spider/s10-hit-log.png` | hit: energy −10 and log | AC-4 |

---

## Test Conditions

- **Game state at start**: `bash tools/play.sh spider-test` (attic, 10:00, flies traded through the real trade); live play for the miss and draw order
- **Platform / hardware**: Linux, NVIDIA GTX 1650 (NVK), Vulkan Forward+, 1280×720 windowed
- **Framerate during test**: smooth (user, smoke check 2026-11-27)
- **Any special setup required**: capture modes in `tools/play.sh`; they set state through the game's own calls

---

## Observations

- **Deliberate deviation**: the plan said "no code-drawn spider left"; the legs are code-drawn from the rig on the painted body (the generated leg image did not match the body). Accepted by the user at sign-off.
- User notes (PASS WITH NOTES): the web's miss/hit timing feels off; the legs or body look could be better. No details given; candidates for polish.
- Lowered near the ghost, the spider hangs right behind the ghost's head (readable, a little crowded).
- Fixed during review: the capture did not drive the spider (captures run with `_process` off); the leg colour edit had not applied at first.

---

## Sign-Off

| Role | Name | Date | Signature |
|---|---|---|---|
| Lead sign-off (solo developer) | project owner | 2026-11-27 | ☑ signed off in session (PASS WITH NOTES) |
