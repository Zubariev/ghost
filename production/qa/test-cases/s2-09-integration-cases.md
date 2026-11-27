# Test Cases: S2-09 — Integration and regression

**Story type**: Integration · **Output location**: `production/qa/evidence/sprint-002-final/` (+ `tests/integration/` for the new headless test) · **Gate level**: BLOCKING
**Source**: sprint-002.md S2-09 AC "suite green, smoke pass, QA report"; qa-plan-sprint-002-2026-11-26.md § S2-09

---

## TC-S2-09-01 — Full suite green, smoke pass
**Preconditions**: Final build; CI command from `coding-standards.md`.
**Steps**:
1. Run the full gdUnit4 suite.
2. Check `production/qa/smoke-2026-11-27.md`.
**Expected Result**: All cases pass (≥ 547), 0 failures, 0 skipped, 0 orphans; smoke report PASS. Output saved to `sprint-002-final/`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-09-02 — Headless 3-day run over all 15 rooms
**Preconditions**: Headless day-run script.
**Steps**:
1. Run 3 game days headless.
2. Grep the output for `ERROR`, `WARNING`, `SCRIPT ERROR`.
**Expected Result**: No errors or warnings; all 15 rooms visited/simulated.
**Actual Result**:
**Pass/Fail**:

## TC-S2-09-03 — Combined save/load: hostile spider, half-unlocked tree, active elixir
**Preconditions**: Normal game (or the new headless integration test) with: spider HOSTILE with known calories and remaining hostile timer; roots tree with T1 and part of the branches owned (record the exact node set, including an owned G6 or G1 so an effect is visible); one elixir drunk and still active (record its remaining time).
**Steps**:
1. Record spider state/calories/timer, owned node IDs, material counts, elixir type and remaining time, energy, slot count.
2. Save from the pause menu.
3. Quit to the main menu; load the save.
4. Re-read every value from step 1.
5. Advance game time until the elixir ends and confirm it expires at the recorded time.
6. Open the roots screen and confirm owned/available states; try a trade with the spider.
**Expected Result**: All values equal pre-save; elixir still active and expires on schedule (not reset, not lost); tree effects applied once (not doubled); spider still HOSTILE, refuses the trade, timer continues. The headless test asserts the same three.
**Actual Result**:
**Pass/Fail**:

## TC-S2-09-04 — All capture modes run
**Preconditions**: User terminal (windowed).
**Steps**:
1. Run `bash tools/play.sh areas-test`, `crafting-test`, `spider-test`, `routines-test`, `roots-test` in turn.
**Expected Result**: Each completes and writes its screenshots; no crash or script error.
**Actual Result**:
**Pass/Fail**:

## TC-S2-09-05 — Docs updated; "seen" only with a capture
**Preconditions**: Sprint end.
**Steps**:
1. Check Demo Spec, `docs/art/ART_DIRECTION.md` rows, yard docs and the sprint log for sprint 002 changes.
2. For every visual item marked "seen", find its windowed capture file.
**Expected Result**: All docs updated; every "seen" mark backed by a capture.
**Actual Result**:
**Pass/Fail**:
