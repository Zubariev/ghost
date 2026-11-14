# Painted prop sprites

The storybook look is code-drawn for now (`src/game/art/storybook_art.gd`, `storybook_shell.gd`).
Any prop can be swapped for a painted image without touching gameplay.

## Replacing a prop

1. Paint the prop as a PNG or WebP with a transparent background, front view, as it stands in
   the room. Put it in this folder, e.g. `assets/art/props/fireplace_burning.png`.
2. Add an entry under `"sprites"` in `assets/art/visual_style.json`:

   ```json
   "fireplace": {
     "sprite": "res://assets/art/props/fireplace_burning.png",
     "states": {"burning": "res://assets/art/props/fireplace_burning.png",
                "out": "res://assets/art/props/fireplace_out.png"},
     "anchor": [0.5, 1.0],
     "scale": 1.0
   }
   ```

   - Key: the furniture `kind` from `assets/data/house/furniture.json`, or `kind:variant` for one
     variant only (`"armchair:olive"`, `"painting:portrait"`).
   - `states`: one image per visual state. Lamps `lit` / `out`, windows `closed` / `open`,
     fireplace `burning` / `out`, the stove `working` / `broken`. A missing state uses `sprite`.
   - `anchor`: the point of the image (0..1 of its width and height) that sits on the piece's floor
     position. Floor props: bottom centre `[0.5, 1.0]`. Wall props (window, fireplace, paintings,
     clock) sit on the back wall's base at their `u`.
   - `scale`: image size at the front of the room. Pieces further back are scaled down
     automatically (wall pieces are not).
3. Run `bash tools/play.sh art-test` and check the screenshots.

If the file is missing, the code drawing is used and a warning is printed.

## What the image never changes

The walking footprint (`assets/data/house/movement.json` → `footprints`), sight blockers
(`blocks_sight`), hiding spots (`hide_id`), interaction range and the floor position stay in the
data files and do not depend on the image's size. A bigger painting does not make a bigger
obstacle.

## Style

Follow `design/art-direction.md`: the storybook palette (`src/game/art/palette.gd`, `SB_*`), muted
brown-charcoal contours (never pure black), visible but subtle brushwork, interactive objects
clearly readable. Paint the neutral (cozy) lighting; the game adds the warm and haunted grade and
the light pools itself, so do not bake strong lighting into the image.
