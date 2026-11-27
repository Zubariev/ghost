# Crafting progression — node catalog

**Status: APPROVED by the user, 2026-11-26** (sprint 002, decision D3; `production/sprints/sprint-002.md`).
All costs and numbers are provisional balance values; the structure, node list and effects are approved.

## Rules (user, 2026-11-26)
- Every node unlocks real functionality, a recipe or a meaningful upgrade; no node without a gameplay effect.
- Existing mechanics first; no new mechanics are introduced by this catalog.
- Room nodes extend by data when rooms are added.
- The coffin is an endpoint and a visual mystery only: no quest, boss, reward, node, effect or glow.

## Unlock types
- **Value change**: one existing tuned value, optionally limited to a room or a family role (one shared modifier list:
  key, add or multiply, optional `room` / `npc_role`; read by `GhostEnergy`, ghost speed, `GhostLoot`, `Monocle`, `StealthSystem`;
  an unknown key fails when the data loads).
- **Recipe**: unlocks an existing recipe.

Cost sizes (exact amounts at balancing): **S** common materials (dust, cobweb, old thread, rusty nail, candle stub);
**M** common plus bone, feather, ink or fly; **L** includes ectoplasm.

## Trunk (amber; existing tiers)
| Node | Requires | Unlocks | Cost |
|---|---|---|---|
| T0 Tree | – | energy elixir, speed elixir | owned at start |
| T1 | T0 | distilled ectoplasm; opens all three branches | 3 bone + 2 feather (today's tier 1) |
| T2 | T1 | double energy elixir | 2 ectoplasm + 2 ink (today's tier 2) |
Saves: tier 1 loads as T1, tier 2 as T1 + T2.

## Room-Specific Anomalies (long left branch; ends at the coffin)
Each node is **Room bond: <room>**: while the ghost is in that room, its action energy cost ×0.7 and its energy regeneration ×1.5.
A new room is one data entry.
| # | Room | Requires | Also | Cost |
|---|---|---|---|---|
| R1 | living_room | T1 | – | S |
| R2 | hall | R1 | – | S |
| R3 | dining_room | R2 | – | S |
| R4 | kitchen | R3 | stove and grocery_basket actions −1 game minute | M |
| R5 | library | R2 | – | S |
| R6 | workshop | R1 | – | M |
| R7 | upper_corridor | R2 | the upper fork starts here | M |
| R8 | parents_bedroom | R7 | – | M |
| R9 | grandparents_bedroom | R7 | – | M |
| R10 | children_bedroom | R7 | – | M |
| R11 | upper_bathroom | R8 | – | L |
| – | Coffin | after R11 | no node, no effect, no change of look | – |
Excluded: basement, attic, both yards (the family never goes there; a bond would affect nothing).

## Ghost Abilities (lower right, green)
| # | Node | Effect | Requires | Cost |
|---|---|---|---|---|
| G1 | Deeper reserve | energy `max` 100 → 120 | T1 | M |
| G2 | Quiet rest | `hidden_multiplier` 3 → 4 | G1 | M |
| G3 | Feeds on neglect | `dark_multiplier` 1.5 → 1.75, `cold_multiplier` 1.25 → 1.5 | G2 | L |
| G4 | Light drift | `slowest_in_order` 0.7 → 0.85 | T1 | S |
| G5 | Quick fingers | `search_minutes` 3 → 2 | G4 | M |
| G6 | Deeper pockets | `inventory_slots` 10 → 12 (HUD bar must lay out 12) | G5 | L |
| G7 | Grandpa's habit | monocle 90 → 135 game minutes | G4 | M |
| G8 | Fleeting glimpse | `detection_penalty.peripheral` 10 → 7 | G1 | M |

## Children (upper right, mauve)
| # | Node | Effect (children only) | Requires | Cost |
|---|---|---|---|---|
| K1 | Static in the wires | computer action cost 25 → 15 | T1 | M |
| K2 | Quick glitch | computer action time 5 → 3 game minutes | K1 | M |
| K3 | Just imagination | peripheral sighting by a child costs 10 → 5 energy | T1 | M |
| K4 | Bad dreams | contact morale penalty on a child 4 → 6 | K3 | L |
Kept at four nodes (user, option a). GDD §11.2 fear items (moving doll, cursed photo, …) are not built and are not part of this catalog;
adding them is new scope with its own story.

## Rejected
Spider nest recipe (bypasses the spider's overfeeding consequence); new elixir variants (new items); bonds for rooms without the family;
placeholder roots.

## Balance notes
Ghost and room modifiers multiply; the spider and energy balance runs include the strongest combination (G1–G3 + a room bond).
