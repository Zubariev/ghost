# Fonts

Chosen 2026-11-15 (user decision, after a trial at 1280 × 720 with the game's Ukrainian text:
`production/qa/evidence/font-trial/specimen.png`). All three cover the full Ukrainian alphabet
(a test checks it) and are licensed under the **SIL Open Font License 1.1** — free to embed in a
commercial game; the font files may not be sold on their own; each font's licence text must ship
with them (the `*-OFL.txt` files here; keep them in builds and credit the fonts).

| Role | Font | File | Author | Licence |
|---|---|---|---|---|
| Titles: game title, headings, day card, pause, end-summary title | Yeseva One | `YesevaOne-Regular.ttf` | Jovanny Lemonad (The Yeseva One Project Authors) | `YesevaOne-OFL.txt` (Reserved Font Name "Yeseva") |
| Interface: HUD, numbers, slots, messages, buttons, help — the default font | PT Sans | `PTSans-Regular.ttf` | ParaType Ltd. | `PTSans-OFL.txt` (Reserved Font Names "PT Sans", "ParaType") |
| Story: premise, family intros, lore notes, journal, end-summary text | Alegreya | `Alegreya-Variable.ttf` | Huerta Tipográfica (The Alegreya Project Authors) | `Alegreya-OFL.txt` |

Source: the Google Fonts repository (github.com/google/fonts, `ofl/`), unmodified.
Rejected in the trial: Atkinson Hyperlegible Next and IM Fell English (no Cyrillic), Alegreya Sans
(word spaces collapse at 12–15 px), Rubik and Kurale (less fitting).

Code: `src/game/ui/ui_fonts.gd` (`UiFonts`).
