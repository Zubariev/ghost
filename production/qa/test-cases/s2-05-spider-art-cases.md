# Test Cases: S2-05 — Spider art, rig, animation

**Story type**: Visual/Feel · **Output location**: `production/qa/evidence/sprint-002-spider/` + `production/qa/evidence/sprint-002-spider-evidence.md` · **Gate level**: BLOCKING (retained screenshots + user art sign-off)
**Source**: sprint-002.md S2-05 AC "idle/descend/feed/attack/size seen in capture"; qa-plan-sprint-002-2026-11-26.md § S2-05
**Known deviation**: legs are code-drawn on the painted body — record as deliberate in the evidence doc, not a fail of TC-S2-05-01.

---

## TC-S2-05-01 — Storybook style, parts joined
**Preconditions**: `bash tools/play.sh spider-test` (windowed, user terminal).
**Steps**:
1. View the spider in each state: idle, lowered, eating, grown, hostile wind-up.
2. Check outline colour/weight and palette against `docs/art/ART_DIRECTION.md`.
3. Zoom each capture at leg joints.
**Expected Result**: Painted body with dark-brown organic outline and muted palette; no gaps at joints, no floating parts. Note: tick from `s01`–`s08`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-05-02 — Idle motion
**Preconditions**: spider-test; ghost out of reaction range.
**Steps**:
1. Watch the spider for 10 s.
**Expected Result**: Small visible body and leg motion; stays on its thread. Note: `s01-idle-from-afar.png`, `s02-idle-later.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-05-03 — Descend and return
**Preconditions**: spider-test.
**Steps**:
1. Move the ghost into the reaction range.
2. Watch the descent.
3. Move the ghost away.
**Expected Result**: Smooth descent with no frame jumps; returns up after the ghost leaves. Note: `s02` → `s03-lowering.png` → `s04-lowered-near-ghost.png`; return-up is not captured — observe live.
**Actual Result**:
**Pass/Fail**:

## TC-S2-05-04 — Feeding animation, ghost free to move
**Preconditions**: Spider FRIENDLY; ghost has flies.
**Steps**:
1. Hold E to trade.
2. During the eating motion, move the ghost.
3. Check the inventory.
**Expected Result**: Front-leg eating motion lasting 2–3 s; ghost moves freely; inventory changes as before. Note: `s05-eating.png`, `s06-eating-later.png`.
**Actual Result**:
**Pass/Fail**:

## TC-S2-05-05 — Three sizes
**Preconditions**: Captures or live views at FRIENDLY, GROWN, HOSTILE.
**Steps**:
1. Compare the three side by side at the same camera.
**Expected Result**: GROWN visibly larger than FRIENDLY; HOSTILE largest. Note: `s01` (small), `s07-grown-and-high-again.png` (grown), `s08-hostile-wind-up-mark.png` (hostile).
**Actual Result**:
**Pass/Fail**:

## TC-S2-05-06 — Attack readability: warning, web, hit and miss
**Preconditions**: Spider HOSTILE in spider-test.
**Steps**:
1. Stand in range; watch one attack (hit).
2. Move during the next wind-up (miss).
**Expected Result**: Readable warning pose before each web; web visible in flight; a hit and a miss both seen. Note: `s08-hostile-wind-up-mark.png`, `s09-web-in-flight.png`, `s10-hit-log.png`; no miss capture exists — capture or observe live.
**Actual Result**:
**Pass/Fail**:

## TC-S2-05-07 — Depth order and trade prompt
**Preconditions**: spider-test.
**Steps**:
1. Place the ghost in front of, then behind, the spider.
2. Approach at small, grown and hostile size; read the trade prompt.
**Expected Result**: Ghost draws in front/behind correctly; prompt readable at every size (hostile: refusal text readable).
**Actual Result**:
**Pass/Fail**:
