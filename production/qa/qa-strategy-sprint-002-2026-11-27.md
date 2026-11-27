# QA Strategy: Sprint 002
**Date**: 2026-11-27 · **Phase**: /team-qa Phase 2 · **Author**: qa-lead
**Config**: `qa.level: minimal` (tests waived; UI and Visual/Feel screenshots required at every level), `team.size: individual`, `review_mode: solo`
**Stories**: the 14 task rows S2-01..S2-14 of `production/sprints/sprint-002.md` plus its progress log (no story files, by user decision).
**Types**: from `production/qa/qa-plan-sprint-002-2026-11-26.md` (Test Summary).
**Sign-off authority**: the user (solo: art-director, designer, qa-lead).

## 1. Strategy table

"Automated" is WAIVED at `qa.level: minimal` wherever it would be a test. The tests listed exist anyway (developer practice, test-first); they are context, not a gate. Suite state per smoke report: 547 green.

| Story | Type | Automated Required | Manual Required | Blocker? |
|---|---|---|---|---|
| S2-01 Prep, D1-D3, baseline | Config/Data | WAIVED (advisory) | Baseline run saved (`sprint-002-baseline.txt` exists); refs in `art/references/sprint-002/` | No |
| S2-02 Bathroom slots | Integration (+Config/Data) | WAIVED. Exists: `bathroom_schedule_test.gd` (4), `schedule_lookup_test`, scenario regression | Day log (exists) + `routines-test` screenshots (13 exist) + user sign-off (GIVEN 2026-11-27) | No |
| S2-03 Spider ecology and web | Logic | WAIVED. Exists: `spider_ecology_test` (14), `spider_web_test` (12), `spider_data_test` (4), 2 in `ghost_energy_test` | Balance run `sprint-002-spider/balance.md` (exists) | No |
| S2-04 Progression logic, modifiers, migration | Integration (+Logic) | WAIVED. Exists: `crafting_progression_test` (10+), `ghost_modifiers_test` (9), `ghost_modifiers_use_test` (8), `progression_data_test` (8), 2 in `stealth_system_test` | Documented playtest or e2e: `sprint-002-progression/headless-e2e.md` (29/29, exists); old-save load; effects seen in game | No (advisory gap, see 4) |
| S2-05 Spider art, rig, wiring | Visual/Feel (+Integration) | WAIVED. Exists: `spider_behaviour_test` (6), `spider_pose_test` (7), `SpiderArt.body_rect` (3) | `spider-test` screenshots s01-s10 (exist) + user sign-off (GIVEN) + `sprint-002-spider-evidence.md` (MISSING) | **Yes**: evidence doc only |
| S2-06 Progression (roots) screen | UI | WAIVED. Exists: `roots_layout_test` (8), `roots_style_test` (8), `roots_screen_test` (9) | Screenshot per state r00-r10 (exist) + user sign-off (GIVEN) | No |
| S2-07 Item art, 14 Must icons | Visual/Feel (+UI) | WAIVED. Exists: `item_art_test` (4) | In-game bar/grid/hollow/drag screenshots, contact sheet 40/64 px, `sprint-002-items-evidence.md`, user sign-off (all MISSING or not recorded) | **Yes** |
| S2-08 Yard art, geometry unchanged | Visual/Feel | WAIVED. Exists: `yard_geometry_test` + snapshot fixture, 2 `RoomSurfaces` tests | `areas-test` day/dusk/night screenshots, `sprint-002-yards-evidence.md` (MISSING), user sign-off (NOT RECORDED) | **Yes** |
| S2-09 Integration, regression, docs | Integration | WAIVED. Suite itself: 547 green | Smoke PASS (done); capture modes all run; combined save/load check; docs check; `sprint-002-final/` evidence (dir MISSING) | **Yes** (closes last) |
| S2-10 6 lore icons | Visual/Feel | WAIVED | Contact sheet; journal (J) screenshot with the lore icons; sign-off | **Yes** (built, evidence missing) |
| S2-11 `wash` clip x6 | Visual/Feel | WAIVED | `routines-test` per person | NOT BUILT: out of scope (see 4) |
| S2-12 Painted soil/bark/coffin | Visual/Feel | WAIVED | Roots screenshots with painted soil and bark; coffin pending | PARTIAL: soil/bark in scope; coffin out of scope (see 4) |
| S2-13 Yard doors, extra props | Visual/Feel | WAIVED | `areas-test` screenshots | NOT BUILT: out of scope |
| S2-14 Runtime bathroom hold | Logic | WAIVED | Day log showing a late finisher | NOT BUILT: out of scope (trigger not met) |

## 2. Smoke Check
**Smoke Check: PASS** (`production/qa/smoke-2026-11-27.md`): 547 tests green, boot check OK, user confirmed launch, core, sprint changes, save/load and frame rate. Build is cleared for manual QA. Re-run if code changes after any fix below (a new painted coffin or porch asset is data-only and does not need it; a code change does).

## 3. Open bugs in scope
**Open bugs in scope: none on file** (`production/qa/bugs/` does not exist). This is "no bug records", not a proven-clean state: the only defect knowledge is the sprint log's accepted findings (below). No S1/S2 known.

Accepted findings, not bugs (sprint log): day-1 morale up to +7 from bathroom changes; son's day-1 08:00-08:30 computer slot skipped (computer starts broken). Open art, not bugs: front-yard porch (not painted), coffin (not painted).

## 4. Missing manual evidence per story

### Built and signed off (S2-02, S2-05, S2-06)
- **S2-02**: nothing missing. Note: final times differ from the QA plan checklist (plan was the 15-min proposal; the log records the approved table), so judge against the log. Idle at the sink is accepted until S2-11.
- **S2-05**: missing `production/qa/evidence/sprint-002-spider-evidence.md` (DoD item). Draft it from s01-s10 and the sprint log, mapping each plan checklist line to a screenshot or "not captured". Gaps against the plan checklist to state in that doc: no captured web *miss*; no side-by-side of three sizes (s07 and s08 only partly cover it); depth order front/behind not shown; the plan says "no code-drawn spider left", but the legs are code-drawn on a painted body (rig decision B2, accepted by the user at sign-off). Record it as a deliberate deviation.
- **S2-06**: nothing missing. r00-r10 cover start, mid, all owned, locked, selected, short-of-materials. The "greyscale distinguishable" line was never checked in greyscale; the owned/available fix was judged by eye. Optional.

### Built, not signed off
- **S2-03** (Logic): the evidence exists (`balance.md`, tests). Missing: the user's acknowledgment of the balance result against the 4-5 day target. I did not re-read `balance.md`; confirm it states the feed-daily and feed-every-2-days outcomes. Not a blocker. Hostile, wind-up, web in flight and hit were seen in s08-s10.
- **S2-04** (Integration): evidence is `headless-e2e.md` (29/29) and the roots captures. Gaps: effects (G1, G5, G6, G7, R1, K1) observed by the user in a window, and the old-save load, are only headless. Integration allows a test or a documented playtest, so this passes at minimal; record the user's acceptance of `headless-e2e.md`.
- **S2-07**: missing (a) user sign-off (log says "items OK" at capture review; no sign-off line), (b) contact sheet at 40 and 64 px (none in the evidence dir; the dir holds only crafting captures c01-c09), (c) screenshots of the HUD bar with several items, a search grid and the drag ghost image (c-series shows the hollow and bar only), (d) `sprint-002-items-evidence.md`. The fallback check is covered by `item_art_test`.
- **S2-08**: missing (a) user sign-off, (b) `sprint-002-yards-evidence.md`, (c) a dusk capture (day-03/04 and night-03/04 exist; dusk is in the plan), (d) the yard walk-area, hiding and library/hall crossing checks recorded (geometry snapshot test covers data; no manual note). Open art for the user to accept or defer: porch (house front, door, wreath) not painted; front yard back wall is still plain weatherboard, so "front tidy/welcoming" is only partly met.
- **S2-10**: the six lore icons are part of the 20 painted icons. Missing: journal (J) screenshot showing them, contact sheet, sign-off. Fold into the S2-07 evidence run.

### Partly built
- **S2-12**: soil and bark done and seen (roots re-captures, "accepted"). Coffin: **OUT OF SCOPE FOR THIS CYCLE**; image service down, code coffin is the accepted fallback, loader already prefers `res://assets/art/props/roots/coffin.png` when present. Missing for the done part: sign-off on S2-12 itself (S2-06 sign-off was given before the soil/bark rework) and the "move one node in data, root follows" check (layout tests cover it; optional manual). Recommendation: close S2-12 as PARTIAL and carry the coffin over.

### Not built
- **S2-11 `wash` clip**: **OUT OF SCOPE FOR THIS CYCLE**. Should Have; idle-at-sink is signed off as the shipped behaviour. Carry over.
- **S2-13 yard doors/extra props**: **OUT OF SCOPE FOR THIS CYCLE**. Nice to Have. Carry over (door grass tufts were also a sprint 001 carryover).
- **S2-14 runtime hold**: **OUT OF SCOPE FOR THIS CYCLE**, and probably not needed: it is conditional on a day-log overlap, and the 3-day day log shows no overlap. Recommend closing it as "not needed".
- No not-built task is a BLOCKER: all three are Should/Nice and none gates a Must story.

### S2-09 (closes the cycle)
Missing: `production/qa/evidence/sprint-002-final/` (or a note that the smoke report plus this strategy stand in for it); the plan's combined save/load check (hostile spider + half-unlocked tree + active elixir, loaded together; the headless e2e covers spider and tree separately, so confirm elixir coverage); a documented code review (plan DoD, no evidence on file); the sprint DoD checkboxes; the open-art list in the sprint log (porch, coffin) with a carryover list for S2-11/13/14.

### Recommendation
Do not block the sprint on the three not-built tasks. Block close on, in order: (1) S2-07 + S2-10 capture run and evidence doc, (2) S2-08 dusk capture, evidence doc and sign-off with an explicit decision on the porch, (3) S2-05 evidence doc, (4) S2-09 combined save/load check and review note. Items (3) and parts of (1)/(2) are documents qa-tester can draft from existing files; only new screenshots and sign-offs need the user's window.

## 5. Manual QA effort estimate
Session = about 1-2 hours, one actor.
| Work | Actor | Sessions |
|---|---|---|
| New captures: items contact sheet, HUD bar/search grid/drag, journal (J), yard dusk | user windowed run (`tools/play.sh`) | 0.5 |
| Evidence docs: spider, yards, items (+ S2-10) | qa-tester drafts, user reviews | 0.75 |
| Sign-offs: S2-04, S2-07, S2-08, S2-10, S2-12 partial; acknowledge S2-03 | user | 0.5 |
| Combined save/load check and code-review note (S2-09) | qa-tester + user | 0.5 |
| Final sign-off report | qa-lead | 0.25 |
| **Total** | | **about 2.5 sessions** (about 1 windowed). Optional playtests from the plan (spider feeding; roots first-use): +1 session each. |
