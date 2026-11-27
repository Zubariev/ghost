# Test Cases: S2-08 — Yards

**Story type**: Visual/Feel · **Output location**: `production/qa/evidence/sprint-002-areas/` + `production/qa/evidence/sprint-002-yards-evidence.md` · **Gate level**: BLOCKING (retained screenshots + user art sign-off)
**Source**: sprint-002.md S2-08 AC "style match, seams gone, geometry snapshot unchanged"; qa-plan-sprint-002-2026-11-26.md § S2-08
**Open item**: unpainted front porch — user decides accept or defer; record the decision in the evidence doc.

---

## TC-S2-08-01 — Day, dusk and night; style match with the living room
**Preconditions**: `bash tools/play.sh areas-test` with the new 18:30 evening pass, run by the user.
**Steps**:
1. Open day, evening and night captures of both yards.
2. Compare side by side with the living room capture.
**Expected Result**: Both yards in all three lights; same style family as the living room. Note: day `day-03-back_yard.png`, `day-04-front_yard.png`; night `night-03-back_yard.png`, `night-04-front_yard.png`; dusk captures pending from the re-run; living room `character-ghost-game/g00-living-room.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-08-02 — Shared kit, distinct character
**Preconditions**: Captures from TC-S2-08-01.
**Steps**:
1. Find fence, vegetation and house materials in both yards.
2. Compare mood: front tidy/welcoming vs back worn/lived-in.
**Expected Result**: Shared kit visible in both; the two yards read as distinct.
**Actual Result**:
**Pass/Fail**:

## TC-S2-08-03 — Seams and repetition gone
**Preconditions**: Day captures at full size.
**Steps**:
1. Scan the lawn for tile seams.
2. Scan the garden wall ivy for visible repeats.
3. Check the side walls use their own texture.
**Expected Result**: No seams; no visible ivy repeat; side walls distinct.
**Actual Result**:
**Pass/Fail**:

## TC-S2-08-04 — Tree, hollow and yard hiding spots unchanged
**Preconditions**: Normal game in the back yard.
**Steps**:
1. Confirm the tree is at u 0.7; hold E to open the hollow.
2. For each of the 5 yard hiding spots: enter, search, leave.
**Expected Result**: Tree in place, hollow opens; all 5 spots work as in sprint 001. Note: `sprint-002-items/c01-tree-in-back-yard.png`, `c02-holding-e.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-08-05 — Walk area and geometry unchanged
**Preconditions**: Geometry guard test in the suite; sprint 001 yard captures.
**Steps**:
1. Confirm the geometry snapshot test passes.
2. Walk the ghost to each edge of both yards; compare reach with sprint 001 captures.
**Expected Result**: Snapshot unchanged; edges reached match on every side.
**Actual Result**:
**Pass/Fail**:

## TC-S2-08-06 — Room crossings
**Preconditions**: Normal game.
**Steps**:
1. Walk from the back yard into the library and back.
2. Walk from the front yard into the hall and back.
**Expected Result**: Both crossings work; no floating up or down at the threshold.
**Actual Result**:
**Pass/Fail**:

## TC-S2-08-07 — Readability order
**Preconditions**: Captures plus live play near decor.
**Steps**:
1. Move the ghost behind/near new decor items.
2. Trigger a prompt near decor.
**Expected Result**: Decor never hides the ghost or a prompt; readability ghost > interactive props > decor.
**Actual Result**:
**Pass/Fail**:
