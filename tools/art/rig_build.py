"""Builds a family member's cutout rig (character pipeline, 2026-11-20).

  python3 tools/art/rig_build.py grandma

Reads art/concepts/characters/family/<id>/rig_src.json: per view (front, side, back), each part's
source image, how to cut it (a polygon in canvas px, or a whole connected piece: all / left /
right), its pivot in canvas px, parent and draw order. Cuts every part (tools/sprite_cutout.gd
for the background, tools/art/cut_part.gd for the part), scales it by "scale", and writes
assets/art/characters/<id>/rig.json for the game (CharacterRig): parts with their texture,
origin and pivot in the scaled canvas, the foot point, the art's px per metre, and the clips."""
import json, os, re, subprocess, sys
ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../.."))
GODOT = os.environ.get("GODOT", "/home/ther0/Games/godot")
TMP = os.environ.get("TMPDIR", "/tmp")


def run(args):
    r = subprocess.run([GODOT, "--headless", "--path", ROOT, "-s"] + args, capture_output=True, text=True)
    return r.stdout + r.stderr


def main(cid):
    src_dir = f"{ROOT}/art/concepts/characters/family/{cid}"
    spec = json.load(open(f"{src_dir}/rig_src.json"))
    k = float(spec["scale"])
    out_dir = f"{ROOT}/assets/art/characters/{cid}"
    os.makedirs(out_dir, exist_ok=True)
    canvases = {}
    rig = {"_source": f"Built by tools/art/rig_build.py from art/concepts/characters/family/{cid}/rig_src.json — do not edit by hand.",
           "id": cid, "height_m": spec["height_m"], "stride_m": spec.get("stride_m", 1.1), "px_per_m": spec["px_per_m"] * k, "views": {}, "clips": spec.get("clips", {}),
           "states": spec.get("states", {})}
    for view, vdef in spec["views"].items():
        parts = {}
        for name, p in vdef["parts"].items():
            src = p["src"]
            if src not in canvases:
                canvas = f"{TMP}/{cid}_{src.replace('.png', '')}_canvas.png"
                out = run(["res://tools/sprite_cutout.gd", "--", f"{src_dir}/{src}", canvas, "0", "1", "0.86", "0,0,1024,1024"])
                if "wrote" not in out:
                    raise RuntimeError(out)
                canvases[src] = canvas
            png = f"{out_dir}/{view}_{name}.png"
            mode = ["poly", ";".join(f"{x},{y}" for x, y in p["poly"])] if "poly" in p else ["comp", p.get("comp", "all")]
            out = run(["res://tools/art/cut_part.gd", "--", canvases[src], png, str(k), "4"] + mode)
            m = re.search(r"origin ([-0-9.]+) ([-0-9.]+) size (\d+) (\d+)", out)
            if not m:
                raise RuntimeError(out)
            ox, oy, w, h = float(m[1]), float(m[2]), int(m[3]), int(m[4])
            if "grey_to" in p:   # a colour that drifted in a generated pose (e.g. grey tights)
                run(["res://tools/art/grey_to.gd", "--", png, png, ",".join(str(v) for v in p["grey_to"])])
            pivot = p.get("pivot")
            if pivot is None:   # "top": the middle of the part's top, a little down (a shoulder, a hip)
                pivot = [ox / k + w / k / 2, oy / k + h / k * float(p.get("pivot_down", 0.06))]
            parts[name] = {"texture": f"res://assets/art/characters/{cid}/{view}_{name}.png", "origin": [round(ox, 2), round(oy, 2)],
                           "pivot": [round(pivot[0] * k, 2), round(pivot[1] * k, 2)], "parent": p.get("parent", ""), "z": p.get("z", 0)}
            print(view, name, "origin", ox, oy, "size", w, h, flush=True)
        rig["views"][view] = {"foot": [vdef["foot"][0] * k, vdef["foot"][1] * k], "parts": parts,
                              "px_per_m": float(vdef.get("px_per_m", spec["px_per_m"])) * k}
    open(f"{out_dir}/rig.json", "w").write(json.dumps(rig, indent="\t", ensure_ascii=False) + "\n")
    print("wrote", f"{out_dir}/rig.json")


if __name__ == "__main__":
    main(sys.argv[1])
