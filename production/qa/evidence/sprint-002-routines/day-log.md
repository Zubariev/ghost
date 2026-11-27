# S2-02 bathroom routines — headless day log

Run 2026-11-26 with `HouseSim.from_data_files`, 3 game days, undisturbed (no ghost), by a scratch script
(not kept). Headless: this is **not** visual evidence; the screenshots come from `bash tools/play.sh routines-test`.

| Check | Run-down start (scenario) | Tidy start |
|---|---|---|
| Most people in the bathroom at once | 1 | 1 |
| Minutes with two or more inside | 0 | 0 |
| Bathroom visits over 3 days | 33 (11 a day) | 33 |
| Visits with under 5 min in the room | 0 | 0 |
| Skipped activities | `son_play_morning` on day 1 (see note) | none |
| Anyone moving/waiting > 60 min | son, day 1 (waits for the broken computer; same before this change) | none |

Minutes in the bathroom, day 1, run-down / tidy: mother morning 10/11, father morning 10/11, grandpa 22/24,
grandma morning 12/16, son morning 11/11, daughter morning 11/13, father evening 21/21, grandma evening 18/18,
son evening 8/8, daughter evening 10/10, mother evening 22/22.

Note: on day 1 the computer starts broken (scenario). Before this change the son waited through one
08:00–12:00 window; now the first 30 minutes (08:00–08:30) are recorded as skipped and he waits in the
08:45 window. Skipping it has no morale effect (only meals and sleep carry a skip penalty).

Morale, end of day 1, run-down start (old → new): grandma 82 → 89, grandpa 74 → 79, son 80 → 81,
daughter 68 → 69; father and mother 100 both. All reach 100 by day 2–3 either way. Cause: each completed
activity in good conditions gives `activity_good` (+1), and the new washing and split activities add completions.
