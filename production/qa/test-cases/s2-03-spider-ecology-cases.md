# Test Cases: S2-03 — Spider ecology and web

**Story type**: Logic · **Output location**: `production/qa/evidence/sprint-002-spider/balance.md` (automated tests waived as evidence at `qa.level: minimal`; suite stays a regression guard) · **Gate level**: BLOCKING
**Source**: sprint-002.md S2-03 AC "states, decay by game days, one hit per web, caps, tests"; qa-plan-sprint-002-2026-11-26.md § S2-03
**Owner this cycle**: user reads and confirms `balance.md`.

---

## TC-S2-03-01 — Tuning values are data-driven
**Preconditions**: `assets/data/ghost/spider.json` has an `ecology` block.
**Steps**:
1. Open `spider.json` and list the `ecology` keys (calories_per_fly, decay, thresholds, hostile_days, max_hits_per_day, web_damage_pct, reaction range, etc.).
2. Grep the spider scripts under `src/` for numeric literals matching those values.
**Expected Result**: Every tuning value is in `ecology`; no duplicated literal in scripts.
**Actual Result**:
**Pass/Fail**:

## TC-S2-03-02 — Trade adds calories; size follows calories
**Preconditions**: Spider FRIENDLY, small; ghost carries 6 flies; `bash tools/play.sh spider-test` or a normal game in the attic.
**Steps**:
1. Note the spider's calories (debug/log) and size.
2. Hold E at the spider to trade 6 flies.
3. Note calories and size again.
**Expected Result**: Calories rise by exactly `6 × calories_per_fly`; size grows in line with the new calorie value; 6 flies removed. Note: `balance.md` run log; `sprint-002-areas/spider-01-attic-trade.png` shows the trade.
**Actual Result**:
**Pass/Fail**:

## TC-S2-03-03 — Decay by game time only
**Preconditions**: Spider has calories > 0.
**Steps**:
1. Note calories; open the pause menu (Esc) for 60 real seconds; close it; note calories.
2. Open the hollow crafting screen for 60 real seconds; close; note calories.
3. Let 1 game day pass; note calories.
**Expected Result**: Steps 1–2 show no change; step 3 drops by the configured daily decay.
**Actual Result**:
**Pass/Fail**:

## TC-S2-03-04 — Feeding cadence and state cycle
**Preconditions**: `balance.md` contains a daily-feeding run and an every-2nd-day run.
**Steps**:
1. Read the daily-feeding run: note the day HOSTILE is reached.
2. Read the every-2nd-day run: check the state on every day.
3. In the daily run, follow HOSTILE → RECOVERING → FRIENDLY.
**Expected Result**: Daily feeding reaches HOSTILE on about day 4–5; every-2nd-day never reaches HOSTILE; HOSTILE lasts `hostile_days`, then RECOVERING returns to FRIENDLY at small size.
**Actual Result**:
**Pass/Fail**:

## TC-S2-03-05 — Web hit rules and daily cap
**Preconditions**: Spider HOSTILE; `bash tools/play.sh spider-test`.
**Steps**:
1. Stand still in the attic in range; let one web fire; note energy change.
2. Enter an attic hiding spot; wait for a web; note energy.
3. Leave the attic; wait for the next attack interval; note energy.
4. Keep moving continuously across the attic for one attack cycle.
5. From `balance.md`, read total web damage per day.
**Expected Result**: (1) one web deals one hit only; (2) and (3) no damage; (4) all webs can be dodged; (5) daily damage ≤ `max_hits_per_day × web_damage_pct`. Note: `s10-hit-log.png` shows the hit log.
**Actual Result**:
**Pass/Fail**:

## TC-S2-03-06 — Trade refused while HOSTILE
**Preconditions**: Spider HOSTILE; ghost has flies.
**Steps**:
1. Hold E at the spider.
2. Check the prompt/feedback and inventory.
**Expected Result**: Trade is refused with visible feedback text from `strings.csv`; fly count unchanged.
**Actual Result**:
**Pass/Fail**:

## TC-S2-03-07 — State persists through save/load
**Preconditions**: Spider in a known state with known calories and timer (e.g. HOSTILE, day 2 of `hostile_days`).
**Steps**:
1. Save from the pause menu.
2. Quit to main menu; load the save.
3. Read state, calories and remaining timer.
**Expected Result**: All three equal the pre-save values. (Combined case: TC-S2-09-03.)
**Actual Result**:
**Pass/Fail**:
