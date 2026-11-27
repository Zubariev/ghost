# UX Spec: Roots Progression Screen

> **Status**: Approved (user, 2026-11-27)
> **Author**: user + ux-designer
> **Last Updated**: 2026-11-27
> **Journey Phase(s)**: unknown (no player journey map)
> **Platform Target**: PC; keyboard/mouse primary, gamepad partial
> **Template**: UX Spec

---

## Purpose & Player Need

The player arrives wanting to spend gathered materials on lasting upgrades and to see what the old tree can still give.
Without this screen the 23 branch nodes of the approved catalog (`design/crafting-progression-catalog.md`) and their effects
cannot be reached.

---

## Player Context on Arrival

- Voluntary, from inside the hollow, usually after a gathering run with materials in hand.
- Game time is already paused in the hollow and stays paused: a safe, calm, curious moment.
- First visit: early game, only the tree (T0) owned, T1 the one available node.

---

## Navigation Position

Back-yard tree (hold E) → Hollow (crafting screen) → **Roots** → selected node.
Context-dependent: reachable only from the hollow (not from the pause menu or the HUD).

---

## Entry & Exit Points

| Entry source | Trigger | Context carried |
|---|---|---|
| Hollow screen | "Коріння" plaque button (top left) or **R** | inventory, tree level, owned nodes; the pentagram is untouched |

| Exit destination | Trigger | Notes |
|---|---|---|
| Hollow screen | back arrow, **Esc**, **E** or right-click (one level back) | nothing lost; the hollow redraws with the new level and recipes |

- The hollow's own upgrade button stays; T1/T2 bought in either place is the same `CraftingBoard.upgrade()`.
- No one-way exit; an unlocked node cannot be undone (the panel says so before the player confirms).
- From the hollow, E or Esc closes it as today.

---

## Layout Specification

### ASCII Wireframe

```
1280 × 720
┌──────────────────────────────────────────────────────────────────────────────┐
│ [←] Коріння старого дерева           sky · fence · shed      (tree + hollow) │  0–150   above ground
│──────────────────────────────grass line──────────────────────────────────────│
│        ○ rooms (upper fork)       ●T1       ◉ mauve (children)               │
│   ○──○──○──○ (gold, rooms) ──○──●T0 trunk ──○──○                             │  150–560 soil: roots
│ ○──○                              │ ●T2       ◉──◉ green (ghost)              │          and nodes
│[coffin]──○                        ○               ◉──◉──◉                    │
├──────────────────────────────────────────────────────────────────────────────┤
│ ● Зв'язок: Вітальня   «У вітальні дії −30% енергії, сили +50%»               │  560–720 node panel
│ Ціна: пил 2/3 · недогарок 2/2        Потрібно: Т1 ✓        [ Розкрити ]      │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Layout Zones

| Zone | Rect (px) | Holds |
|---|---|---|
| Above ground | 0–150 | back arrow, title, ground strip (sky, fence, shed), tree base with the hollow |
| Soil | 150–560, full width | root network and nodes; the long rooms branch runs left to the coffin (bottom left) |
| Node panel | 560–720, full width | the selected node (user choice 2026-11-27: bottom panel, keeps full width for the long branch) |

### Component Inventory

| Component | Type | Shows | Interactive |
|---|---|---|---|
| Back arrow | plaque button | ← | yes: one level back |
| Title | label | "Коріння старого дерева" | no |
| Roots canvas | custom draw | root curves (bark brown, thick at the trunk, thin at tips; a segment turns warm gold once its node is owned) and node circles; hit-testing | yes: hover, click, focus |
| Coffin | sprite (drawn fallback) | the end of the rooms branch; no state, no interaction | no |
| Node panel | parchment strip | name, effect text, cost per item as have/need (short items in rose), parents ✓/✗, "cannot be undone" note | no |
| Unlock button | plaque button | "Розкрити" | yes |
| Key hint | small label | R/Esc/E/Enter/arrows | no |

Node positions: `layout: {x, y}` per node in `progression.json` (hand-placed, roots-canvas coordinates); a node without
it is placed automatically along its branch's direction after its parent, so a new node or room works with data alone
(user choice 2026-11-27). Root curves are generated from parent → child positions with a seeded wobble (stable between visits).
New pattern for a future pattern library: *node graph with a detail strip*.

### Information Hierarchy

1. The root network: where each branch goes, how far the ghost has grown.
2. Node states (locked / available / owned).
3. The selected node: name, effect, cost against what the ghost holds.
4. Branch identity by colour; the coffin as a landmark.
5. Navigation: back arrow, title.

---

## States & Variants

Node states — readable without colour (size, ring, glow):

| Node state | Look |
|---|---|
| Locked (a parent not owned) | small (r ≈ 9), dark fill keeping ~45% of the branch colour, darker branch-coloured rim (revised 2026-11-27 after the first screenshots: branches must read on a first visit) |
| Available, cannot afford | full size (r ≈ 13), branch colour, no glow |
| Available, affordable | full size, branch colour, wide soft pulsing halo, no ring |
| Owned | full size, brighter colour, thick (4 px) candle-gold ring, small steady halo (revised 2026-11-27: must differ from "available" in a still) |
| Selected | extra brass outer ring; shown in the node panel |

Branch colours (palette keys from `progression.json`): trunk amber, rooms gold, ghost green, children mauve.
The whole network is drawn from the first visit, locked parts dimmed (user choice 2026-11-27).

| Screen state | Trigger | What changes |
|---|---|---|
| First visit | only T0 owned | T1 glows; everything else locked and dim; T1 selected |
| Cannot afford | selected node short of materials | Unlock disabled; missing items in rose; nothing paid |
| Unlocked | Unlock pressed and paid | node → owned, its root lights, its children may become available, panel refreshes |
| Branch complete | last node of a branch owned | the whole root lit; the coffin does not change (user decision 2026-11-26) |
| Bad data | `CraftingProgression.check()` problems | error logged at game start; a node with an unknown branch is not drawn |
| Loading | — | none (local data) |

---

## Interaction Map

Mapping for keyboard/mouse (primary) and gamepad (partial).

| Component | Action | Input | Feedback | Outcome |
|---|---|---|---|---|
| Node | hover | mouse | node grows slightly; pointer cursor | none (preview) |
| Node | move focus | arrows / d-pad: nearest node in that direction; Tab / Shift+Tab: nodes branch by branch in data order | focus = selection | selection only |
| Node | select | click | brass ring; panel fills | selection only |
| Unlock | single press (user choice 2026-11-27) | click, Enter, gamepad A | node flash; root lights parent → node; log line | `CraftingProgression.unlock(id)` |
| Unlock (short of materials) | — | — | button disabled; missing items in rose | nothing paid |
| Back | leave | ← button, Esc, E, right-click, gamepad B | slide up | hollow screen |
| — | wheel / drag | — | — | no panning: the network fits one screen |

On opening, the first available node is selected (T1 on the first visit).

---

## Data Requirements

| Data | Source | Read / Write | Notes |
|---|---|---|---|
| Branches, nodes, layout | `progression.json` via `CraftingProgression` | read | layout optional per node (auto fallback) |
| Node state, cost | `CraftingProgression.state`, `cost` | read | |
| Unlock | `CraftingProgression.unlock` (trunk → `CraftingBoard.upgrade`) | **write** | persistent: owned nodes, inventory, tree level |
| Material counts | `GhostLoot.count` | read | |
| Names, effect texts | `strings.csv`: `NODE_<id>`, `NODE_<id>_TEXT`, `BRANCH_<id>` | read | |
| Colours | `Palette` keys from the branch `colour` | read | |

The screen keeps no game state of its own, only the current selection.

---

## Events Fired

| Player action | Event | Payload |
|---|---|---|
| Unlock | `CraftingProgression.changed` → `GhostModifiers.set_effects`; HUD slot bar refreshed | node id (log line) |
| Back / close | `RootsScreen.closed` | — |
| Hover, select | none (no analytics in this game) | — |

Unlock changes persistent state (save data: owned nodes, inventory, tree level).

---

## Transitions & Animations

- Enter: 0.35 s slide down from the hollow into the soil (user choice 2026-11-27); exit: slide back up. Reduced motion: instant cut.
- Unlock: 0.4 s warm light runs along the root from the parent to the node, then the node settles into its owned glow.
- Available and affordable nodes pulse slowly (2 s cycle); reduced motion: a steady glow.

---

## Input Method Completeness Checklist

Touch: not supported (omitted).

**Keyboard**
- [x] Every node and button reachable with arrows / Tab alone
- [x] Tab follows the branches in data order
- [x] Every mouse action has a keyboard path (select, Unlock = Enter, back = Esc / E)
- [x] Focus always visible (brass ring = selection)
- [x] Focus stays inside the screen while it is open
- [x] Esc steps back one level, never quits the game

**Gamepad (partial support)**
- [x] Every node reachable with the d-pad
- [x] A = Unlock, B = back
- [x] No analog precision needed
- [x] No bumpers or triggers used
- [x] Controller disconnect: no-op, the screen stays open

**Mouse**
- [x] Hover states on nodes and buttons
- [x] Node hit areas are 36 px circles (larger than the drawn circle)
- [x] Right-click = back
- [x] Wheel: no-op (nothing scrolls)

---

## Accessibility

No project accessibility tier yet (see Open Questions); WCAG-AA used as the baseline here.
- Node states never by colour alone: size, ring and glow differ; missing materials show ✗ as well as rose.
- Panel text: dark ink on parchment, ≥ 16 px.
- **Reduced motion: a new "Менше руху" setting (user decision 2026-11-27, sprint 002 scope addition)** in the settings menu,
  saved with the other settings. When on: the slide becomes an instant cut, the pulse a steady glow, the unlock light a
  single frame change.
- Screen reader: none in this game (no AccessKit integration); noted as a gap.

---

## Localization Considerations

- Ukrainian only today; all text in `strings.csv` (`NODE_<id>`, `NODE_<id>_TEXT`, `BRANCH_<id>`, screen labels).
- Node name ≤ ~40 characters; effect text ≤ 2 lines (autowrap in the panel).
- **HIGH PRIORITY:** the Unlock label ("Розкрити") must stay on one line in a fixed 180 px button.
- Costs are whole numbers; no dates or currencies.

---

## Acceptance Criteria

- [ ] Opens and closes with only the 0.35 s slide (instant with "Менше руху"); no frame over 50 ms
- [ ] The "Коріння" button or R opens it from the hollow; ←, Esc, E and right-click return to the hollow; E again closes the hollow
- [ ] All 26 nodes inside the soil zone with centres ≥ 30 px apart; the rooms branch reaches the left side and ends at the coffin
- [ ] First visit: only T0 owned, T1 selected and pulsing, everything else locked and dim
- [ ] Short of materials: Unlock disabled, missing items rose with ✗, nothing paid
- [ ] A paid unlock owns the node, takes exactly its cost, makes its children available, its effect shows (e.g. G1: energy bar maximum 120) and survives save/load
- [ ] Keyboard alone reaches every node and unlocks with Enter; focus ring always visible
- [ ] The four node states are distinguishable in a greyscale screenshot
- [ ] The game clock does not advance while the screen is open
- [ ] No text clipped at 1280 × 720; all text from `strings.csv`
- [ ] With "Менше руху" on, no slide, pulse or light run plays; the setting survives a restart

---

## Open Questions

- Player journey map not yet created. Author it from the template at `.claude/docs/templates/player-journey.md` to establish player context for this screen.
- Accessibility tier not yet defined — WCAG-AA used as a baseline here.
- UI style (dark wood, parchment, brass) is EXPERIMENTAL in `ART_DIRECTION.md`; this screen follows it without making it a standard.
- Painted soil, bark and coffin are sprint task S2-12 (Should); drawn fallbacks until then.

