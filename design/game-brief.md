# Game Brief: Ghost vs. Humans — House Takeover

<!-- One-page design record (workflow: minimal). The full design lives in
ghost_house_game_design_document_uk.md (GDD v0.8) and demo_specification_ghost_house_uk.md
(Demo Specification v0.6); they are the source of truth. This brief summarises them and
never overrides them. Last updated 2026-11-13. -->

## In your words
"Treat the existing GDD and Demo Specification as the source of truth. Do not redesign
already agreed mechanics. Clearly distinguish agreed requirements from proposals and
unresolved questions. Do not implement unspecified mechanics without asking. Work
incrementally." — project rules, 2026-11-12. Design: `ghost_house_game_design_document_uk.md`
and `demo_specification_ghost_house_uk.md`.

**Pitch:** You are the ghost of a big old house; learn a family's daily routines and sabotage the things they depend on until all six give up at once.

**Genre:** schedule-driven house simulation with stealth (colony-sim moods and priorities + stealth routines).

**Controls:** WASD float (through walls) · R / C float up / down a floor *(temporary — to be replaced)* · E act on the highlighted object · F hide / leave a hiding spot · Q sight zones (after finding the monocle) · Space pause · 1/2/3 ×1/×2/×4.

**Question:** Do watching routines, timing sabotage and avoiding being seen make a readable, interesting loop over a 3-day scenario?

**Hooks:** you never hunt people — you break the house they live in; every family member's day is a fixed, watchable schedule, and the family repairs and cleans by priority, so sabotage is a timing puzzle.

**Intent:** staged failure *(you said: Broken at ≤10, recovery to 15)* · payoff builds *(from the GDD: cascading consequences)*.

## Look and references
- Look: hand-drawn-style 2D, one room on screen at a time — back wall, slanted side walls, no front wall, plank floor narrowing to the back; inky outlines, muted greens and browns; night turns the room blue-dark, cold tints it blue; every figure drawn, no emoji, no plain circles. Code-drawn original placeholders until the art bible exists; no third-party assets.
- References: *Don't Starve* and its *Hamlet* DLC interiors (presentation of rooms — reference only, nothing copied), *Oxygen Not Included* (task priorities, readable systems), *Neighbours from Hell* (watching routines, timing pranks), *The Sims* (activities tied to rooms and objects).
- View: 2D · Camera: fixed, front-facing room view; a house overview map in the corner.

## First minute
The game opens at 06:00 in the hall. Grandma walks to the kitchen to make breakfast while the others wake. The player floats through a wall into the dining room and kitchen, sees the stove highlighted with «E — Зіпсувати плиту», and the log and morale bars show what each family member is doing. Jamming the stove before grandma cooks makes her wait — and father walks in at 09:00 to repair it first: the routine, the sabotage and the family's response are all visible in the first minutes.

## Challenge
Day 1 is for learning: an undisturbed day leaves everyone at full morale, and the balance target is that nobody is Broken before the first evening. The real challenge is getting all six to ≤10 at the same moment while Broken members recover to 15 and the family repairs and cleans by priority. Being seen costs the family member 10 morale only on contact — and sends the ghost back to the hall. Lose: day 3 ends without the family leaving.

## Core loop
- Watch a family member's routine and find what it depends on (a lamp, the stove, the groceries, a window, the computer).
- Sabotage it at the right moment, unseen: the activity waits, is delayed or skipped; morale drops.
- The family adapts by its rules: father repairs, mother closes windows and cleans, grandma searches for groceries; Broken members recover.
- Avoid sight cones, hide in furniture, slip away during searches — then strike again.
- *Leads:* the simulation (schedules, priorities, morale) leads the rules; stealth leads sight, hiding and search.

## Goal & fail state
- Win: all six family members have morale ≤10 at the same moment — the family leaves the house.
- Lose: the third day ends without that. A summary of key events is shown either way.

## Features
- [x] Game clock: 1 game minute = 1 real second, ×1/×2/×4, pause, day/night
- [x] Six family members on fixed daily schedules (GDD §7.1; grandma per Demo Spec §5.6)
- [x] Priority work windows: father repairs, mother and son clean (GDD §10.4)
- [x] Shared meals; cooking with fixed time that can finish late
- [x] Morale 0–100 with penalties, bonuses, Broken and recovery; win and loss
- [x] Ghost: through walls and floors; five sabotage actions
- [x] Stealth: sight zones, peripheral and deep detection, hiding, search, contact
- [x] Ukrainian HUD with house map, morale and event log
- [ ] Family members walk continuously inside and between rooms (planned)
- [ ] Ghost energy system (ledger already records penalties)
- [ ] Full 3-day scenario as one polished slice

## Your systems
- schedules and activities · in the slice
- work windows and task priorities · in the slice
- morale, Broken, win and loss · in the slice
- ghost movement and sabotage actions · in the slice
- stealth: detection, hiding, search · in the slice
- family movement inside and between rooms · thin stand-in
- ghost energy · thin stand-in
- crafting and resources · later
- family adaptation to repeated sabotage · later

## Keep
- The Hamlet-style one-room view reads clearly *(you said: spike verdict YES)*.
- Peripheral detection is a reflex exception that keeps activity progress *(you said)*.

## Avoid
- Recreating Klei's art, characters or code; using Don't Starve assets even as placeholders.
- Redesigning agreed mechanics or implementing unspecified ones without asking.
- Complex autonomous AI, dozens of needs, real physics or thermodynamics (GDD §14.1).

## Out of scope
- Several houses, families or campaigns: later.
- Several playable ghosts and specialisations (GDD §12.3): later.
- Crafting tree and resource economy (GDD §11): later.
- Complex adaptation of the family to repeated sabotage (GDD §10.3): later.
- Save and load, meta-progression: later.

## Build order
1. Integrated simulation and play (done: Demo Spec roadmap stages 1–5) — the goal and the way to lose are already playable.
2. Family movement inside and between rooms.
3. Ghost energy system.
4. Replace R/C floor controls.
5. Tuning after play.
6. Vertical slice: the full 3-day scenario, start to end summary and restart.

---
**Kill condition:** if, after movement and tuning, watching routines and timing sabotage still does not feel like a choice the player makes (sabotage either always works or never matters).

**Who it's for / what they feel:** players who enjoy planning and mischief — "I know this house better than they do".

**Games you love / don't:** Don't Starve, Oxygen Not Included, Neighbours from Hell, The Sims, Ghost Master, Luigi's Mansion — as references for parts, not models to copy (GDD §13.4, §14).
