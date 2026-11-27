# Test Cases: S2-04 — Progression logic and modifiers

**Story type**: Integration · **Output location**: `production/qa/evidence/sprint-002-progression/` (`headless-e2e.md` + screenshots) · **Gate level**: BLOCKING
**Source**: sprint-002.md S2-04 AC "graph valid, unlock rules, old saves load"; qa-plan-sprint-002-2026-11-26.md § S2-04
**Owner this cycle**: user reads and confirms `headless-e2e.md`.

---

## TC-S2-04-01 — Graph matches approved catalog
**Preconditions**: Progression data file loaded; approved catalog (D3) in `sprint-002.md`.
**Steps**:
1. List all node IDs in the data.
2. Compare with the catalog: T0–T2, R1–R11, G1–G8, K1–K4.
3. Check the coffin is not a node.
**Expected Result**: Exactly 26 nodes, IDs and parents match; no coffin node.
**Actual Result**:
**Pass/Fail**:

## TC-S2-04-02 — Availability and exact-cost unlock
**Preconditions**: New game; `bash tools/play.sh roots-test`; T0 owned only.
**Steps**:
1. Select a node whose parent is not owned; try Unlock.
2. Select T1 with fewer materials than its cost; try Unlock; note inventory.
3. Gather the exact cost; Unlock T1; note inventory.
4. Try to unlock T1 again.
**Expected Result**: (1) refused; (2) refused, inventory unchanged; (3) unlocked, inventory reduced by exactly the cost; (4) not possible. Note: `r04-locked-node-selected.png`, `r05-short-of-materials.png`, `r06-T1-unlocking-light.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-04-03 — Old save migration
**Preconditions**: Three sprint-001-format saves: tree tier 1, tree tier 2, no crafting data.
**Steps**:
1. Load each save in turn.
2. Open the roots screen (R in the hollow) and note owned nodes.
**Expected Result**: Tier 1 → T1 owned; tier 2 → T1+T2 owned; no crafting data → T0 only. No errors. Note: `headless-e2e.md`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-04-04 — Each effect type observed in game
**Preconditions**: Save with G1, G5, G6, G7, R1, K1 owned (or roots-test unlocking them).
**Steps**:
1. Read energy bar max.
2. Run one search; time it in game minutes.
3. Count slot bar slots.
4. Use the monocle; time its duration.
5. Check the lamp scare cost in the living room.
6. Check the computer scare cost.
**Expected Result**: energy max 120; search 2 min; 12 slots; monocle 135 min; living-room lamp 7 (not 10); computer 15.
**Actual Result**:
**Pass/Fail**:

## TC-S2-04-05 — Room bond applies only in its room
**Preconditions**: R1 (living room bond) owned.
**Steps**:
1. Check the lamp cost in the living room.
2. Check a lamp (or same-cost prop) cost in another room.
**Expected Result**: Discount in the living room only; other room at base cost. Note: `r08-mid-progress-room-bond-selected.png` shows the node.
**Actual Result**:
**Pass/Fail**:

## TC-S2-04-06 — Unknown modifier key fails loudly
**Preconditions**: A copy of the progression data with one modifier key renamed to an unknown key (revert afterwards).
**Steps**:
1. Launch the game with the edited data.
2. Read the output/log.
**Expected Result**: Loading stops with a clear error naming the unknown key and node; no silent ignore.
**Actual Result**:
**Pass/Fail**:
