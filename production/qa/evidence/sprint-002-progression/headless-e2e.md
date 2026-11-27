# S2-04 progression logic — headless end-to-end (2026-11-27)

Scratch script (not kept) loads `src/game/house_game.tscn` headless with the shipped data, gives the ghost
30 of each material, unlocks nodes through `CraftingProgression.unlock` and reads each value where the game
reads it. Headless: **not** visual evidence (the roots screen is P5).

29 of 29 checks passed:
- Start: T1 available, G1 locked. Unlocked T1, G1, R1, K1, G4, G5, G6, G7, K3, K4; tree level 1.
- G1 energy maximum 120 · R1 lamp in the living room 10 → 7, unchanged in the kitchen · K1 computer 25 → 15 ·
  G5 search 3 → 2 min · G6 slots 10 → 12 · G4 tidy-room slowdown 0.7 → 0.85 · K3 a glimpse by the son 10 → 5,
  by the father 10 · K4 contact fright on the son 4 → 6 · G7 monocle used through the game's item use: 135 min.
- Save → fresh game → load: G6 owned, energy 115 kept (above the base maximum), 12 slots.
- A save without `"progression"` (sprint 001): no branch node owned, tree level kept (T1 owned), maximum back to 100.

## Roots screen in the game (2026-11-27, P5)
Scratch script, game scene headless, "Менше руху" on: 10 of 10 checks passed — hollow open with the clock paused;
R (physical key) opens the roots; T1 selected on the first visit; T1 unlocked through the screen raises the tree's
level; after G1, G4, G5, G6 the HUD bar has 12 slots (its real child count); the clock stays paused; Esc returns to
the hollow; Esc again closes it and the clock runs; the save holds the owned nodes. Not visual evidence: the
screenshots come from `bash tools/play.sh roots-test`.
