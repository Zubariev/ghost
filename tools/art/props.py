"""Painted props at their real size (dev tool; SPRITE_SPEC §2, user review 2026-11-20).

  python3 tools/art/props.py [cut] [key ...]     cut the listed props (all when none) and merge
  python3 tools/art/props.py merge               only merge the table into visual_style.json

Each prop: its source images (one per state, art/concepts/props/...), its real width × height in
metres and, for wall pieces, how high above the floor its bottom hangs. Cut with
tools/sprite_cutout.gd to fit that box at ART_PX_PER_M × 2 (art is 2×, drawn at scale 0.5); a
prop's states share one crop box so it never jumps. merge writes each prop's entry (sprite,
states, anchor, scale, window glass masks, lamp glow, moving-part points) into
assets/art/visual_style.json -> sprites, keeping entries not in this table (the fireplace)."""
import json, os, re, struct, subprocess, sys
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../.."))
GODOT = os.environ.get("GODOT", "/home/ther0/Games/godot")
SRC = ROOT + "/art/concepts/props"
PX_M = 150   # art px per metre (2 × RoomGeometry.ART_PX_PER_M)

def L(d):
    return {"lit": f"lamps/floor_lamp_{d}_lit.png", "out": f"lamps/floor_lamp_{d}_out.png"}
WIN = lambda r: {"closed": f"{r}/window_closed.png", "open": f"{r}/window_open.png"}
# key: (sources {state or "": path}, width m, height m, lift m, options {out, white})
T = {
 "floor_lamp": ({"lit": "lamps/floor_lamp_brass_lit.png", "out": "house/floor_lamp.png"}, 0.5, 1.6, 0, {"out": "lamps/floor_lamp_brass"}),
 "dining_room/floor_lamp": (L("standard"), 0.5, 1.6, 0, {"out": "lamps/floor_lamp_standard"}),
 "library/floor_lamp": (L("standard"), 0.5, 1.6, 0, {"out": "lamps/floor_lamp_standard"}),
 "parents_bedroom/floor_lamp": (L("standard"), 0.5, 1.6, 0, {"out": "lamps/floor_lamp_standard"}),
 "kitchen/floor_lamp": (L("tulip"), 0.5, 1.6, 0, {"out": "lamps/floor_lamp_tulip"}),
 "upper_bathroom/floor_lamp": (L("tulip"), 0.5, 1.6, 0, {"out": "lamps/floor_lamp_tulip"}),
 "grandparents_bedroom/floor_lamp": (L("rose"), 0.5, 1.6, 0, {"out": "lamps/floor_lamp_rose"}),
 "children_bedroom/floor_lamp": (L("stars"), 0.5, 1.5, 0, {"out": "lamps/floor_lamp_stars"}),
 "workshop/floor_lamp": ({"lit": "lamps/floor_lamp_work_lit.png", "out": "workshop/floor_lamp.png"}, 0.5, 1.6, 0, {"out": "lamps/floor_lamp_work"}),
 "living_room/window": (WIN("living_room"), 1.6, 2.1, 0.02, {}),
 "kitchen/window": (WIN("kitchen"), 1.3, 1.2, 0.85, {}),
 "dining_room/window": (WIN("dining_room"), 1.4, 2.1, 0.02, {}),
 "workshop/window": (WIN("workshop"), 1.0, 0.9, 1.0, {}),
 "parents_bedroom/window": (WIN("parents_bedroom"), 1.5, 2.1, 0.02, {}),
 "grandparents_bedroom/window": (WIN("grandparents_bedroom"), 1.1, 1.0, 0.95, {}),
 "children_bedroom/window": (WIN("children_bedroom"), 1.3, 1.4, 0.7, {}),
 "living_room/wall_clock": ({"": "living_room/wall_clock.png"}, 0.35, 0.85, 1.15, {}),
 "painting:portrait": ({"": "living_room/painting_portrait.png"}, 0.45, 0.55, 1.25, {"out": "living_room/painting_portrait"}),
 "painting:landscape": ({"": "living_room/painting_landscape.png"}, 0.6, 0.48, 1.3, {"out": "living_room/painting_landscape"}),
 "living_room/sofa": ({"": "living_room/sofa.png"}, 2.0, 0.95, 0, {}),
 "living_room/armchair": ({"": "living_room/armchair.png"}, 0.85, 1.1, 0, {}),
 "armchair:olive": ({"": "living_room/armchair_olive.png"}, 0.85, 1.1, 0, {"out": "living_room/armchair_olive"}),
 "side_table": ({"": "living_room/side_table.png"}, 0.5, 0.7, 0, {"out": "living_room/side_table"}),
 "living_room/tea_table": ({"": "living_room/tea_table.png"}, 0.5, 0.7, 0, {}),
 "living_room/bookshelf": ({"": "living_room/bookshelf.png"}, 0.9, 1.9, 0, {}),
 "living_room/gramophone": ({"": "living_room/gramophone_cabinet.png"}, 0.75, 1.5, 0, {}),
 "plant:fern": ({"": "living_room/plant_fern.png"}, 0.7, 1.25, 0, {"out": "living_room/plant_fern"}),
 "plant:palm": ({"": "living_room/plant_palm.png"}, 0.9, 1.6, 0, {"out": "living_room/plant_palm"}),
 "barrel": ({"": "house/barrel.png"}, 0.6, 0.85, 0, {"out": "barrel"}),
 "library/desk": ({"": "library/desk_globe.png"}, 1.2, 1.35, 0, {}),
 "parents_bedroom/nightstand": ({"": "parents_bedroom/nightstand.png"}, 0.5, 0.85, 0, {}),
 "children_bedroom/rocking_horse": ({"": "children_bedroom/rocking_horse.png"}, 0.9, 0.8, 0, {}),
 "upper_bathroom/laundry_basket": ({"": "upper_bathroom/laundry_basket.png"}, 0.5, 0.75, 0, {}),
 "kitchen/stove": ({"working": "kitchen/stove_working.png", "broken": "kitchen/stove_broken.png"}, 0.9, 1.7, 0, {}),
 "kitchen/basket": ({"available": "kitchen/basket_available.png", "hidden": "kitchen/basket_hidden.png"}, 0.45, 0.5, 0, {}),
 "kitchen/counter": ({"": "kitchen/counter.png"}, 1.8, 1.15, 0, {}),
 "kitchen/kitchen_table": ({"": "kitchen/kitchen_table.png"}, 1.3, 0.9, 0, {}),
 "dining_room/dining_table": ({"none": "dining_room/dining_table_none.png", "ready": "dining_room/dining_table_ready.png"}, 2.0, 1.0, 0, {"white": True}),
 "chair": ({"": "dining_room/chair.png"}, 0.45, 1.05, 0, {"out": "dining_room/chair"}),
 "chair:side": ({"": "house/chair_side.png"}, 0.5, 1.05, 0, {"out": "chair_side"}),
 "chair:back": ({"": "house/chair_back.png"}, 0.45, 1.05, 0, {"out": "chair_back"}),
 "dining_room/sideboard": ({"": "dining_room/sideboard.png"}, 1.2, 2.0, 0, {}),
 "hall/stairs": ({"": "hall/stairs.png"}, 2.5, 2.9, 0, {}),
 "hall/coat_stand": ({"": "hall/coat_stand.png"}, 0.6, 1.85, 0, {}),
 "hall/chest": ({"": "hall/chest.png"}, 0.95, 0.65, 0, {}),
 "library/bookshelf": ({"": "library/bookshelf_scrolls.png"}, 1.4, 2.0, 0, {}),
 "library/bookshelf:books": ({"": "library/bookshelf_books.png"}, 1.4, 2.0, 0, {}),
 "library/bookshelf:curios": ({"": "library/bookshelf_curios.png"}, 1.4, 2.0, 0, {}),
 "library/reading_chair": ({"": "library/reading_chair.png"}, 0.85, 1.1, 0, {}),
 "workshop/tool_rack": ({"": "workshop/tool_rack.png"}, 1.2, 1.2, 0, {}),
 "workshop/workbench": ({"": "workshop/workbench.png"}, 1.7, 0.95, 0, {}),
 "workshop/crate": ({"": "workshop/crate.png"}, 0.65, 0.55, 0, {}),
 "upper_corridor/stairs": ({"": "upper_corridor/stairs.png"}, 1.6, 1.1, 0, {}),
 "upper_corridor/chest": ({"": "upper_corridor/chest.png"}, 0.95, 0.65, 0, {}),
 "parents_bedroom/double_bed": ({"": "parents_bedroom/double_bed.png"}, 1.7, 1.2, 0, {}),
 "parents_bedroom/wardrobe": ({"": "parents_bedroom/wardrobe.png"}, 1.1, 2.1, 0, {}),
 "grandparents_bedroom/double_bed": ({"": "grandparents_bedroom/double_bed.png"}, 1.7, 1.25, 0, {}),
 "grandparents_bedroom/wardrobe": ({"": "grandparents_bedroom/wardrobe.png"}, 1.0, 2.1, 0, {}),
 "grandparents_bedroom/rocking_chair": ({"": "grandparents_bedroom/rocking_chair.png"}, 0.75, 1.1, 0, {}),
 "grandparents_bedroom/dresser": ({"": "grandparents_bedroom/dresser.png"}, 0.95, 1.65, 0, {}),
 "children_bedroom/bed": ({"": "children_bedroom/bed.png"}, 1.0, 0.9, 0, {}),
 "children_bedroom/bed:starry": ({"": "children_bedroom/bed_starry.png"}, 1.0, 0.9, 0, {}),
 "children_bedroom/computer_desk": ({"working": "children_bedroom/computer_desk_working.png", "broken": "children_bedroom/computer_desk_broken.png"}, 1.1, 1.25, 0, {}),
 "children_bedroom/toy_box": ({"": "children_bedroom/toy_box.png"}, 0.8, 0.5, 0, {}),
 "children_bedroom/easel": ({"": "children_bedroom/easel.png"}, 0.6, 1.4, 0, {}),
 "upper_bathroom/bathtub": ({"": "upper_bathroom/bathtub.png"}, 1.7, 1.05, 0, {"white": True}),
 "upper_bathroom/sink": ({"": "upper_bathroom/sink.png"}, 0.6, 1.75, 0, {"white": True}),
 # sprint 002 (P7, S2-08): the yards repainted from Reference A in the storybook style (art/prompts/sprint-002/yards.json)
 "back_yard/crafting_tree": ({"": "sprint002/yards/crafting_tree.png"}, 4.6, 4.6, 0, {"out": "back_yard/crafting_tree_v2"}),
 "back_yard/shed": ({"": "sprint002/yards/shed.png"}, 2.4, 2.6, 0, {"out": "back_yard/shed_v2"}),
 "back_yard/woodpile": ({"": "sprint002/yards/woodpile.png"}, 1.6, 1.0, 0, {"out": "back_yard/woodpile_v2"}),
 "back_yard/barrel": ({"": "sprint002/yards/rain_barrel.png"}, 0.7, 1.0, 0, {"out": "back_yard/rain_barrel"}),
 "front_yard/hedge": ({"": "sprint002/yards/hedge_long.png"}, 2.2, 1.2, 0, {"out": "front_yard/hedge_long"}),
 # decor only ("decor": true in furniture.json: drawn, never an obstacle, spot or object)
 "clothesline": ({"": "sprint002/yards/clothesline.png"}, 3.0, 2.0, 0, {"out": "back_yard/clothesline"}),
 "sandbox": ({"": "sprint002/yards/sandbox.png"}, 1.5, 0.75, 0, {"out": "back_yard/sandbox"}),
 "tricycle_toy": ({"": "sprint002/yards/tricycle.png"}, 0.8, 0.65, 0, {"out": "back_yard/tricycle"}),
 "garden_bed": ({"": "sprint002/yards/garden_bed.png"}, 1.8, 0.8, 0, {"out": "back_yard/garden_bed"}),
 "watering_can": ({"": "sprint002/yards/watering_can.png"}, 0.5, 0.4, 0, {"out": "back_yard/watering_can"}),
 "birdhouse": ({"": "sprint002/yards/birdhouse.png"}, 0.5, 2.0, 0, {"out": "back_yard/birdhouse"}),
 "swing_oak": ({"": "sprint002/yards/swing_oak.png"}, 3.5, 4.2, 0, {"out": "front_yard/swing_oak"}),
 "hydrangea": ({"": "sprint002/yards/hydrangea.png"}, 1.2, 1.1, 0, {"out": "front_yard/hydrangea"}),
 "mailbox": ({"": "sprint002/yards/mailbox.png"}, 0.5, 1.2, 0, {"out": "front_yard/mailbox"}),
}
# Where the code draws on a painted prop, as fractions of its image (x right, y down).
FRAC = {
 "floor_lamp": {"glow": [0.5, 0.15]}, "dining_room/floor_lamp": {"glow": [0.5, 0.1]}, "library/floor_lamp": {"glow": [0.5, 0.1]},
 "parents_bedroom/floor_lamp": {"glow": [0.5, 0.1]}, "kitchen/floor_lamp": {"glow": [0.5, 0.08]}, "upper_bathroom/floor_lamp": {"glow": [0.5, 0.08]},
 "grandparents_bedroom/floor_lamp": {"glow": [0.5, 0.1]}, "children_bedroom/floor_lamp": {"glow": [0.5, 0.12]}, "workshop/floor_lamp": {"glow": [0.5, 0.08]},
 "kitchen/stove": {"fire": [0.55, 0.78]}, "children_bedroom/computer_desk": {"screen": [0.38, 0.25]},
}


def base_of(key):
    room = key.split("/")[0] if "/" in key else ""
    bare = key.split("/")[-1].replace(":", "_")
    return T[key][4].get("out", (room + "/" if room else "") + bare)


def out_paths(key):
    srcs = T[key][0]
    return {s: f"res://assets/art/props/{base_of(key)}{'_' + s if s else ''}.png" for s in srcs}


def png_size(path):
    with open(path, "rb") as f:
        head = f.read(24)
    return struct.unpack(">II", head[16:24])


def cut_one(src, out, scale=1.0, box=None, white=False):
    args = [GODOT, "--headless", "--path", ROOT, "-s", "res://tools/sprite_cutout.gd", "--", src, out, "0", str(scale),
        "0.9" if white else "0.86", ",".join(map(str, box)) if box else "", "0" if white else "1"]
    r = subprocess.run(args, capture_output=True, text=True)
    m = re.search(r"source box \[P: \((\d+), (\d+)\), S: \((\d+), (\d+)\)\]", r.stdout)
    if not m:
        raise RuntimeError(r.stdout + r.stderr)
    return [int(x) for x in m.groups()]


def cut(key):
    srcs, rw, rh, lift, opt = T[key]
    white = opt.get("white", False)
    paths = {s: SRC + "/" + p for s, p in srcs.items()}
    probe = os.path.join(os.environ.get("TMPDIR", "/tmp"), "props_probe.png")
    boxes = [cut_one(p, probe, white=white) for p in paths.values()]
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[0] + b[2] for b in boxes); y1 = max(b[1] + b[3] for b in boxes)
    box = [x0, y0, x1 - x0, y1 - y0]
    scale = min(rw * PX_M / box[2], rh * PX_M / box[3])
    for s, p in paths.items():
        out = out_paths(key)[s].replace("res://", ROOT + "/")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        cut_one(p, out, round(scale, 4), box, white)
    print(key, "scale", round(scale, 4), flush=True)


def entry(key):
    srcs, rw, rh, lift, opt = T[key]
    paths = out_paths(key)
    first = paths[next(iter(srcs))]
    w, h = png_size(first.replace("res://", ROOT + "/"))
    e = {"sprite": paths.get("", first), "anchor": [0.5, round((h - 4 + lift * PX_M) / h, 4)], "scale": 0.5}
    if "" not in paths:
        e["states"] = paths
    if key.split("/")[-1].split(":")[0] == "window":
        e["glass"] = {s: p.replace(".png", "_glass.png") for s, p in paths.items()}
    ax, ay = e["anchor"]
    at = lambda f: [round((f[0] - ax) * w * 0.5, 1), round((f[1] - ay) * h * 0.5, 1)]
    frac = FRAC.get(key, {})
    if "glow" in frac:   # the code glow is drawn at (0, -128) × scale: scale it so it lands on the shade
        g = at(frac["glow"])
        e["effects"] = {"offset": [g[0], 0], "scale": round(-g[1] / 128.0, 3)}
    points = {n: at(f) for n, f in frac.items() if n != "glow"}
    if points:
        e["effects"] = {"points": points}
    return e


def merge():
    p = ROOT + "/assets/art/visual_style.json"
    style = json.load(open(p))
    for key in T:
        style["sprites"][key] = entry(key)
    open(p, "w").write(json.dumps(style, indent="\t", ensure_ascii=False) + "\n")
    print(len(style["sprites"]), "sprite entries")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "merge":
        merge()
    else:
        keys = [k for k in args if k != "cut"] or list(T)
        for k in keys:
            cut(k)
        merge()
