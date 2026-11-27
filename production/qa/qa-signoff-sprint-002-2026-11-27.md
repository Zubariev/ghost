## QA Sign-Off Report: Sprint 002
**Date**: 2026-11-27
**QA level**: minimal — tests WAIVED as evidence; for Logic, Integration and Config/Data stories the
acceptance-criteria walk is the executed evidence; Visual/Feel and UI stories carry retained screenshots.
**Smoke check**: PASS (`production/qa/smoke-2026-11-27.md`)
**QA plan**: `production/qa/qa-plan-sprint-002-2026-11-27.md` · **Strategy**: `production/qa/qa-strategy-sprint-002-2026-11-27.md`
**Test cases**: `production/qa/test-cases/` (55 cases)

### Test Coverage Summary
| Story | Type | Auto Test | Manual QA | Result |
|---|---|---|---|---|
| S2-01 Prep | Config/Data | WAIVED; baseline run 419 green (`evidence/sprint-002-baseline.txt`) | User confirmed: references moved, D1–D3 recorded, baseline | PASS |
| S2-02 Bathroom routines | Integration | WAIVED | Cases walked; routines screenshots and day log; grandpa morning-only is a recorded, user-approved change | PASS |
| S2-03 Spider ecology | Logic | WAIVED (unit tests exist) | `balance.md` confirmed by the user | PASS |
| S2-04 Progression and modifiers | Integration | WAIVED; headless e2e 29/29 and 10/10 | In-game save/load worked | PASS |
| S2-05 Spider art | Visual/Feel | N/A | `sprint-002-spider-evidence.md` + s01–s10; code-drawn legs on the painted body accepted as a deliberate deviation | PASS WITH NOTES |
| S2-06 Roots screen | UI | N/A | `sprint-002-roots-screen-evidence.md` + r00–r10 | PASS |
| S2-07 Item icons / S2-10 Lore icons | Visual/Feel (+UI) | N/A | `sprint-002-items-evidence.md` + contact sheets, slot bar, search grid, crafting shots | PASS (note: the monocle icon reads a little like a magnifying glass) |
| S2-08 Yards | Visual/Feel | N/A | `sprint-002-yards-evidence.md` + day, 18:30 and night shots | PASS WITH NOTES |
| S2-09 Integration | Integration | WAIVED; 548 tests green; new combined save/load integration test, mutation-checked | `sprint-002-final/final-run.md` | PASS (note: `/code-review` not run yet) |
| S2-12 Roots art (soil, bark) | Visual/Feel | N/A | `sprint-002-roots-art-evidence.md` | PASS (partial scope) |

**Out of scope this cycle** (approved QA plan):
| Item | Why |
|---|---|
| S2-11 `wash` clip | Not built; carried over to sprint 003 |
| S2-13 Yard doors and extra props | Not built; carried over to sprint 003 |
| S2-14 Runtime bathroom hold | Not needed: the day log shows no bathroom overlap |
| S2-12 coffin | Image service down |
| Front-yard porch (S2-08) | Image service down; the unpainted porch is accepted for sprint 002 only |

### Bugs Found
| ID | Story | Severity | Status |
|---|---|---|---|
| — | — | — | No bugs filed in Phase 5; none on file (`production/qa/bugs/` does not exist) |

The S2-05 notes are observations, not filed bugs: the user's wording ("web miss/hit timing feels off", "legs or
body look") has no details yet. Track them through `/bug-report` once the specifics are given.

### Verdict: APPROVED WITH CONDITIONS

**Conditions**:
1. **S2-05 web timing.** The user finds the web's miss/hit timing off. Set a measurable target (e.g. wind-up
   length and hit window) with the game-designer, then retune and re-capture, or file it as S3 via `/bug-report`.
2. **S2-05 legs/body look.** Get the specifics from the user; fix, or record as accepted beside the code-drawn-legs
   deviation, with lead sign-off.
3. **S2-08 front-yard porch.** Accepted for sprint 002 only: schedule it in sprint 003 with the S2-12 coffin once
   the image service is back.
4. **S2-09 code review.** The sprint QA plan's Definition of Done lists a code review; run `/code-review` before
   the build advances.
5. **Advisory (not blocking):** repaint the monocle icon (S2-07) in a polish pass.

### Next Step
Resolve conditions before advancing. S3/S4 bugs may be deferred to polish. In order: run `/code-review` (S2-09);
get the S2-05 specifics and file or accept them; carry S2-11, S2-13, the S2-12 coffin and the porch into sprint 003
planning. Then run `/gate-check`.

*Verdict decided by: no open S1/S2 bugs and no FAILs (not NOT APPROVED); every in-scope story has executed
evidence and the smoke check passed (not NOT ASSESSED); all PASS or PASS WITH NOTES, with the notes documented
(APPROVED WITH CONDITIONS). Drafted by qa-lead, checked against the rules by the orchestrator.*
