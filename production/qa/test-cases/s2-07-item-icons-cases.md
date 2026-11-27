# Test Cases: S2-07 — Item icons (14) and S2-10 — Lore icons (6)

**Story type**: Visual/Feel · **Output location**: `production/qa/evidence/sprint-002-items/` + `production/qa/evidence/sprint-002-items-evidence.md` · **Gate level**: BLOCKING (retained screenshots + user art sign-off)
**Source**: sprint-002.md S2-07 AC "set reads at 40 px; fallback test"; S2-10 AC "whole catalog painted"; qa-plan-sprint-002-2026-11-26.md § S2-07, § S2-10

---

## TC-S2-07-01 — Contact sheet: 20 icons at 40 and 64 px
**Preconditions**: Contact sheet generated headless with `tools/art/montage.gd` (14 item + 6 lore icons).
**Steps**:
1. Open the contact sheet.
2. At 40 px, name each icon from silhouette alone.
3. Compare outline weight and rendering style across all 20.
**Expected Result**: All 20 recognisable at 40 px; one outline weight and style; the 6 lore icons match the item set (S2-10).
**Actual Result**:
**Pass/Fail**:

## TC-S2-07-02 — Transparency on dark bar and search grid
**Preconditions**: `bash tools/play.sh hud-test sprint-002-items-hud` and `bash tools/play.sh capture` run by the user.
**Steps**:
1. Inspect icons on the HUD slot bar.
2. Inspect icons on a search grid.
**Expected Result**: No halo, fringe or box around any icon on either background.
**Actual Result**:
**Pass/Fail**:

## TC-S2-07-03 — In-game placements captured
**Preconditions**: As TC-S2-07-02; crafting-test captures.
**Steps**:
1. Confirm screenshots of: HUD bar with several items, a search grid, the hollow's bar, the drag image.
**Expected Result**: All four present. Note: hollow bar in `c04-ingredients-on-star.png` / `c07-result-in-bar-locked-recipe.png`; HUD bar and search grid come from the new hud-test/capture runs; drag image — capture or observe live (no existing file).
**Actual Result**:
**Pass/Fail**:

## TC-S2-07-04 — Behaviour unchanged (craft and use spot check)
**Preconditions**: `bash tools/play.sh crafting-test`.
**Steps**:
1. Hold E at the tree; place ingredients for one energy elixir; craft.
2. Close the hollow; drag the elixir onto the ghost.
3. Check names, counts and energy.
**Expected Result**: Crafting result appears; names and counts correct; drag works; elixir applies its effect and count drops by 1. Note: `c01`–`c09`, especially `c06-crafted-in-centre.png`, `c09-elixirs-used-speed-running.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-07-05 — Missing PNG falls back to code drawing
**Preconditions**: One item icon PNG temporarily renamed (restore after).
**Steps**:
1. Launch the game; view the item in the slot bar.
2. Read the log.
3. Restore the file.
**Expected Result**: Item shows the code-drawn fallback; no crash; other icons unaffected.
**Actual Result**:
**Pass/Fail**:

## TC-S2-10-01 — Lore icons in the journal
**Preconditions**: `bash tools/play.sh capture` (journal pass) or a normal game with lore found.
**Steps**:
1. Press J.
2. View the lore entries with icons.
**Expected Result**: The 6 painted lore icons appear, consistent with the item set; journal screenshot retained.
**Actual Result**:
**Pass/Fail**:
