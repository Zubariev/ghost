# Test Cases: S2-12 — Roots screen art (soil and bark; PARTIAL)

**Story type**: Visual/Feel · **Output location**: `production/qa/evidence/sprint-002-progression/` · **Gate level**: BLOCKING (retained screenshots + user sign-off)
**Source**: sprint-002.md S2-12 AC "integrated, replaces fallback drawing"; qa-plan-sprint-002-2026-11-26.md § S2-12
**Scope**: soil and bark only. Coffin painting is out of scope this cycle (image service down) — story closes PARTIAL.

---

## TC-S2-12-01 — Painted soil and bark replace the fallback
**Preconditions**: `bash tools/play.sh roots-test`.
**Steps**:
1. Open the roots screen.
2. Inspect the background soil and the root/bark strokes.
**Expected Result**: Painted soil and bark are shown, not the code-drawn fallback; style consistent with `ART_DIRECTION.md`. Note: tick from `r02-roots-sliding-in.png`–`r09-everything-owned-coffin.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-12-02 — Roots still follow node data
**Preconditions**: Copy of the progression data with one node's position changed (revert after).
**Steps**:
1. Launch roots-test with the edited data.
2. Observe the moved node and its connecting root.
**Expected Result**: The root redraws to the new node position; no orphaned painted segment.
**Actual Result**:
**Pass/Fail**:

## TC-S2-12-03 — Coffin non-interactive (regression only)
**Preconditions**: Roots screen open.
**Steps**:
1. Hover/click the coffin; try to focus it by keyboard.
**Expected Result**: No glow, no selection, no panel. Note: `r09-everything-owned-coffin.png`. Painted coffin not checked (deferred).
**Actual Result**:
**Pass/Fail**:
