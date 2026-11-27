# Test Cases: S2-02 — Bathroom routines

**Story type**: Integration · **Output location**: `production/qa/evidence/sprint-002-routines/` · **Gate level**: BLOCKING (documented playtest; automated tests waived at `qa.level: minimal`)
**Source**: sprint-002.md S2-02 AC "every NPC morning+evening, no overlap, day run clean"; qa-plan-sprint-002-2026-11-26.md § S2-02
**Status this cycle**: user sign-off recorded 2026-11-27; cases kept for traceability and regression.

---

## TC-S2-02-01 — Every NPC washes in the morning
**Preconditions**: Build on `feat/godot-setup-room-spike`; `bash tools/play.sh routines-test` available; final slot times (data, `assets/data/schedules/*.json`; sprint log entry for P1): mother 06:00–06:15, father 06:15–06:30, grandpa 06:30–07:00, grandma 08:00–08:30, son 08:30–08:45, daughter 08:45–09:00.
**Steps**:
1. Run `bash tools/play.sh routines-test`.
2. Observe `upper_bathroom` from 06:00 to 08:30 game time.
3. For each of the six, note the time they enter and leave the bathroom.
**Expected Result**: Each of mother, father, grandpa, son, daughter, grandma enters `upper_bathroom` once in the morning at their recorded slot and leaves. Note: tick from `01-mother-wash-morning.png`, `02-father-wash-morning.png`, `04-grandpa-wash-morning.png`, `05-grandma-wash-morning.png`, `06-son-wash-morning.png`, `07-daughter-wash-morning.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-02-02 — Five washes in the evening (grandpa morning only)
**Preconditions**: As TC-S2-02-01; final evening slots: father 20:00–20:30, grandma 20:30–21:00, son 21:00–21:15, daughter 21:15–21:30, mother 21:30–22:00. Grandpa has **no** evening visit: a deliberate, user-approved change recorded in the sprint log (P1 entry, "Grandpa goes in the morning only; the other five twice"); the S2-02 acceptance text "every NPC morning+evening" predates it.
**Steps**:
1. Run `bash tools/play.sh routines-test` through 20:00–22:00.
2. Note each person's bathroom entry and exit.
**Expected Result**: The five above visit once each in the evening, in that order; grandpa does not. Note: tick from `08-father-wash-evening.png`, `09-grandma-wash-evening.png`, `10-son-wash-evening.png`, `11-daughter-wash-evening.png`, `13-mother-wash-evening.png`; `day-log.md` lists 11 visits a day (grandpa morning only).
**Actual Result**:
**Pass/Fail**:

## TC-S2-02-03 — No bathroom overlap over 3 days
**Preconditions**: Headless 3-day day log `production/qa/evidence/sprint-002-routines/day-log.md` exists.
**Steps**:
1. Open `day-log.md`.
2. For each day 1–3, list every `upper_bathroom` occupancy interval.
3. Check every pair of intervals for overlap.
**Expected Result**: No two people share `upper_bathroom` at any minute on any of the 3 days (including late finishes of prior tasks).
**Actual Result**:
**Pass/Fail**:

## TC-S2-02-04 — Day run clean: no stuck NPC, later windows kept
**Preconditions**: `day-log.md` as above; normal game via `bash tools/play.sh`.
**Steps**:
1. In `day-log.md`, confirm each NPC reaches breakfast (07:00), dinner (19:00) and sleep each day.
2. Confirm shared breakfast starts with all six present and grandma's 06:00 cooking is unchanged.
3. Confirm cleaning/repair windows are the same length as before and the day 1 house restore finishes about 15:20.
4. Search the log for errors, warnings, repeated identical entries (loops) or an NPC idle past its next window.
**Expected Result**: Every window met every day; breakfast full; restore ~15:20; no errors, warnings, loops or stuck NPCs.
**Actual Result**:
**Pass/Fail**:

## TC-S2-02-05 — Task in progress finishes before washing
**Preconditions**: `bash tools/play.sh routines-test`; an NPC whose bathroom slot follows an animated task (e.g. father dressing).
**Steps**:
1. Watch the NPC from 2 game-minutes before their slot.
2. Note whether the current animation completes before they walk to the bathroom.
**Expected Result**: The running animation completes; the NPC then walks to the bathroom (no cut-off mid-clip). Note: `03-father-dressing.png` shows the preceding task.
**Actual Result**:
**Pass/Fail**:

## TC-S2-02-06 — Idle fallback at the sink, nothing explicit
**Preconditions**: No `wash` clip exists (S2-11 not built).
**Steps**:
1. In `routines-test`, observe one morning and one evening visit.
2. Check where the NPC stands and what pose they hold.
**Expected Result**: The NPC stands at the sink in idle, not inside a wall or doorway; nothing explicit is shown. Note: tick from `01-mother-wash-morning.png` (morning) and `08-father-wash-evening.png` (evening); `12-children-bedtime-room.png` confirms children reach their room after.
**Actual Result**:
**Pass/Fail**:
