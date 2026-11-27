"""Generates or edits images through ki-chat's image API (dev tool, 2026-11-20).

  KI_CHAT_TOKEN=<session token> python3 tools/art/kichat.py <jobs.json>

jobs.json: [{"out": "<path under art/concepts/props/>", "prompt": "...", "src": "<optional image to
edit, same base>"}]. Without "src" the image is generated from the prompt; with it, the source is
attached and edited (a prop's second state, a fix). A replaced image is kept as <out>.prev.png.
The token is a ki-chat browser session token; never write it to a file."""
import base64, json, os, shutil, subprocess, sys
CURL = os.environ.get("CURL", "/home/ther0/snap/claude-code/common/local/bin/curl")
BASE = "https://ki-chat.uni-mainz.de"
DEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../art/concepts/props")
TOKEN = os.environ["KI_CHAT_TOKEN"]
TMP = os.environ.get("TMPDIR", "/tmp")


def call(endpoint, body):
    path = os.path.join(TMP, "kichat_body.json")
    json.dump(body, open(path, "w"))
    r = subprocess.run([CURL, "-s", "-m", "900", "-X", "POST", "-H", f"Authorization: Bearer {TOKEN}",
        "-H", "Content-Type: application/json", "--data", "@" + path, BASE + endpoint], capture_output=True, text=True)
    reply = json.loads(r.stdout) if r.stdout.strip() else {}
    if not isinstance(reply, list) or not reply:   # an error from the service: show what it said
        raise RuntimeError("service: " + (r.stdout.strip() or ("curl exit %d" % r.returncode))[:300])
    return reply[0]["url"]


for job in json.load(open(sys.argv[1])):
    out = os.path.normpath(os.path.join(DEST, job["out"]))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    try:
        if job.get("src"):
            b64 = base64.b64encode(open(os.path.join(DEST, job["src"]), "rb").read()).decode()
            url = call("/api/v1/images/edit", {"prompt": job["prompt"], "image": "data:image/png;base64," + b64})
        else:
            url = call("/api/v1/images/generations", {"prompt": job["prompt"]})
    except Exception as ex:
        print("failed", job["out"], repr(ex)[:200], flush=True)
        continue
    if os.path.exists(out):
        shutil.copy(out, out[:-4] + ".prev.png")
    subprocess.run([CURL, "-s", "-m", "120", "-H", f"Authorization: Bearer {TOKEN}", "-o", out, BASE + url], check=True)
    print("made", job["out"], flush=True)
