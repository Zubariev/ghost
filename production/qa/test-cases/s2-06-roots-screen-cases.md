# Test Cases: S2-06 — Roots (progression) screen

**Story type**: UI · **Output location**: `production/qa/evidence/sprint-002-progression/` · **Gate level**: BLOCKING (retained screenshot of each screen state)
**Source**: sprint-002.md S2-06 AC "all states and navigation work; 1280×720 fits; screenshots"; qa-plan-sprint-002-2026-11-26.md § S2-06
**Status this cycle**: user sign-off recorded 2026-11-27; cases kept for traceability and regression.

---

## TC-S2-06-01 — Entry and exit navigation
**Preconditions**: `bash tools/play.sh roots-test`, or a normal game standing at the back-yard tree.
**Steps**:
1. Hold E at the tree to open the hollow.
2. Press the roots button (or physical R).
3. Press Esc.
4. Press Esc again.
**Expected Result**: (2) roots screen slides in; (3) back to the hollow; (4) hollow closes to the yard. Note: `r00-back-yard.png`, `r01-hollow-with-roots-button.png`, `r02-roots-sliding-in.png`, `r10-back-in-the-hollow.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-06-02 — Layout and node look
**Preconditions**: Roots screen open at 1280×720.
**Steps**:
1. Check the long root runs left and ends at the coffin; other two branches shorter; layout asymmetric.
2. Check nodes are plain coloured circles; branch colours rooms gold/amber, ghost green, children mauve.
3. Check no node or panel is cut off and no nodes overlap.
**Expected Result**: All three hold. Note: `r03-first-visit-T1-selected.png`, `r09-everything-owned-coffin.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-06-03 — Required state screenshots
**Preconditions**: Evidence folder `sprint-002-progression/`.
**Steps**:
1. Confirm a screenshot for each: start (T0 only), mid-progress, all owned, branch not reachable, selected node with panel.
**Expected Result**: All five present: `r03` (start), `r08-mid-progress-room-bond-selected.png` (mid), `r09` (all owned), `r04-locked-node-selected.png` (unreachable), `r03`/`r08` (panel).
**Actual Result**:
**Pass/Fail**:

## TC-S2-06-04 — States distinguishable without colour
**Preconditions**: `r08` (has locked, available, owned, selected nodes).
**Steps**:
1. Convert `r08` to greyscale.
2. Identify each node's state.
**Expected Result**: Locked, available, owned and selected are each distinguishable by shape/outline/fill, not colour alone.
**Actual Result**:
**Pass/Fail**:

## TC-S2-06-05 — Panel content and unlock flow
**Preconditions**: roots-test; T0 owned.
**Steps**:
1. Select a locked node; read the panel.
2. Select T1 short of materials; check Unlock.
3. Select T1 with enough materials; press Unlock.
**Expected Result**: Panel shows name, effect, cost (have/need), parents; Unlock disabled in (1)–(2); in (3) T1 and its children change state immediately. Note: `r04`, `r05-short-of-materials.png`, `r06-T1-unlocking-light.png`, `r07-T1-owned-branches-open.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-06-06 — Mouse and keyboard reach every node
**Preconditions**: roots-test with ample materials.
**Steps**:
1. Using keyboard only, navigate to and unlock one node in each branch.
2. Using mouse only, do the same for a different node per branch.
3. Confirm every node is reachable by keyboard focus.
**Expected Result**: All nodes reachable and unlockable by both inputs.
**Actual Result**:
**Pass/Fail**:

## TC-S2-06-07 — Clock paused and Ukrainian strings
**Preconditions**: Normal game; note the clock time before opening.
**Steps**:
1. Open the roots screen; wait 60 real seconds; close; read the clock.
2. Read every label, button and panel text; compare with `assets/i18n/strings.csv`.
**Expected Result**: Clock unchanged; all text Ukrainian from `strings.csv`, no raw keys or hardcoded English.
**Actual Result**:
**Pass/Fail**:
