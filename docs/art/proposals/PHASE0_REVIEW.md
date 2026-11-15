# Phase 0 review — art documentation consolidation

Date: 2026-11-15. Status: **approved by the user 2026-11-15.** §2 applied to GDD v0.9 §13.1 and
§3 to Demo Specification v0.14 §4.1. The optional §13.2 / §13.4 edits were not applied (not
confirmed). No game code or data changed.

## 1. What changed in `docs/art/`

| File | Change |
|---|---|
| `ART_DIRECTION.md` | Rewritten as the merged main document: OPEN status added; authority and conflict rules; reference hierarchy; change control; production constraints (no physics collisions — footprints, sight blockers, hiding spots and ranges are data); reconciliation note (§4); decision table updated with the 2026-11-15 decisions: palette PROVISIONAL, ghost depth-sorted APPROVED, living-room concept APPROVED as Phase 1 target, foreground occluders and characters OPEN (deferred), dirt visuals OPEN. |
| `COLOR_PALETTE.md` | Palette PROVISIONAL (values unchanged, as in `Palette.SB_*`); usage principles and cozy/haunted use from the package; roles corrected to the built room (sofa faded green, olive fireside chair); contour colours explained (built `#3B2C25` main, `#62564D` soft; research proposes `#62564D` main). |
| `VISUAL_STYLE_GUIDE.md` | Merged: shape language, texture rules, material table (stone, glass, wallpaper, paper added), character readability, five-level hierarchy, tangencies, layering mapped to the actual draw order, avoid list. |
| `environments/ENVIRONMENT_GUIDELINES.md` | Merged: goals, composition, the room box with its real numbers, cozy/haunted with real light sources, **draw order corrected (ghost depth-sorted with furniture)**, placeholder cold overlay noted as a known gap, dirt visuals OPEN, review checklist. |
| `environments/LIVING_ROOM.md` | The built room's data table; **sofa corrected to faded green**; built-vs-target table for Phase 1; the package's open questions answered for the built room; the Phase 1 art integration review checklist (your additional requirements). |
| `SPRITE_SPEC.md` | **New, PROVISIONAL**: how `PropVisuals` sizes and anchors images, 2× authoring at `scale` 0.5, current on-screen sizes, format, lighting, contours, naming, states per kind, open points for the Phase 3 trial. |
| `research/GEMINI_ART_DIRECTION_REPORT.md` | **New**: the package's research report, unchanged. |
| `proposals/PHASE0_REVIEW.md` | This file. |

Also: `CLAUDE.md` art section merged with the package's section (status list with OPEN,
authority and conflicts, collisions-as-data); `assets/art/props/sprite_guide.md` points to
`SPRITE_SPEC.md`.

Not taken from the package (and why):

- File names `GDD.md`, `DEMO_SPECIFICATION.md`, "GDD v0.7" — the repository's files are
  `ghost_house_game_design_document_uk.md` (v0.8) and `demo_specification_ghost_house_uk.md`.
- `living_room_cozy_candidate.jpeg` — the same image is already `living_room_cozy.jpeg`.
- "Living room PROVISIONAL — concept candidate" — the in-game art test is built and approved; the
  concept is now the approved Phase 1 target.
- "Foreground occluders" as a required asset layer — OPEN (deferred).

## 2. Proposed wording — GDD §13.1 (replaces the current §13.1 text)

> ## 13.1. Загальний стиль
>
> **\[УЗГОДЖЕНО 15.11.2026 — замінює попередню редакцію\]** Візуальний художній напрям —
> **Whimsical Gothic Storybook**: мальована 2D-ілюстрація в дусі старої книжки казок —
> органічні контури змінної товщини темно-коричневого кольору, стримана фактура паперу й
> пігменту, приглушена осіння палітра, тепле світло в домі й холодні тіні. Натхнення —
> принципи *Over the Garden Wall* (без копіювання персонажів, композицій чи дизайну). Повний
> опис і статуси рішень: `docs/art/ART_DIRECTION.md`.
>
> ***Don't Starve: Hamlet*** **— лише просторовий і композиційний референс**: спосіб показу
> інтер'єру (одна кімната на екрані, задня й бічні стіни без передньої, підлога, що звужується
> вглиб, глибина через накладання об'єктів). Візуальну ідентичність *Don't Starve* (його
> персонажів, графічний стиль, впізнавану подачу світу) не відтворюємо.
>
> Камера, геометрія кімнат, проєкція, навігація та ігрові правила **не змінюються**: вони
> залишаються такими, як визначено в §13.2 і реалізовано (просторовий прототип 12.11.2026).
>
> Візуальні характеристики: виразні силуети персонажів; трохи перебільшені пропорції та
> міміка; читабельні контури й форми; стилізовані предмети побуту; контраст між затишком дому
> та паранормальними явищами; виразні анімації, що передають стан NPC без складного AI;
> світло, що змінюється між днем, вечором і ніччю та між затишним і «переслідуваним» станом
> кімнати.

Related lines that would read inconsistently afterwards (proposed, optional — tell me if you want
them in the same change):

- §13.2, first sentence "Камера та подача наслідують *Don't Starve*." → "Камера та подача кімнат
  наслідують просторовий референс *Don't Starve: Hamlet* (див. §13.1)."
- §13.4, the *Don't Starve* block → title "*Don't Starve: Hamlet* — просторовий референс",
  keeping the points about readable silhouettes and the mix of cute and eerie, and adding "не
  копіювати візуальний стиль".

## 3. Proposed wording — Demo Specification §4.1 (replaces the first paragraph)

> ## 4.1. Візуальний і просторовий референс
>
> **[УЗГОДЖЕНО 15.11.2026 — замінює попередню редакцію]** Візуальний художній напрям —
> **Whimsical Gothic Storybook** (`docs/art/ART_DIRECTION.md`; GDD §13.1). Подача інтер'єру й
> кімнат спирається на житлову систему з DLC *Don't Starve: Hamlet* **лише як на просторовий і
> композиційний референс**: одна кімната на екрані, задня й бічні стіни без передньої,
> підлога, що звужується вглиб. Візуальний стиль *Don't Starve* не відтворюється. Камера,
> геометрія кімнат, проєкція, навігація та ігрові правила лишаються такими, як реалізовано
> (§8.7); художні зміни їх не змінюють.

(The "Технічна перевірка" paragraph after it stays as it is.)

Plus a version entry when applied, e.g. "Версія 0.14 — §4.1: художній напрям Whimsical Gothic
Storybook; *Hamlet* — лише просторовий референс."

## 4. Decisions recorded (2026-11-15)

| Item | Decision |
|---|---|
| C1 | Draft GDD §13.1 / Spec §4.1 wording (above); do not apply until approved |
| C2 | Merge the package into the repository docs; repository is the source of truth |
| A1 | Ghost stays depth-sorted with furniture |
| A4 | Living-room concept is the Phase 1 visual target (look, not perspective or geometry) |
| A5 | Palette values kept, status PROVISIONAL |
| A2, A3 | Foreground occluders and character designs deferred |

## 5. Next after approval

1. Apply §2 and §3 to the GDD and Demo Specification (with version entries).
2. Commit Phase 0 (docs only).
3. Phase 1 — living room toward the concept (code drawing only), with the art integration review
   in `environments/LIVING_ROOM.md` §6.
