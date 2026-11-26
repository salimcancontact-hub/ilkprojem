#!/usr/bin/env python3
"""EMANET üniforma boyayıcı.

Quaternius "Universal Base Characters" gövde dokusunun üzerine, her üçgenin
bağlı olduğu kemiklere bakarak (gövde, kol, el, ayak...) bir ekip üniforması boyar.

Kullanım:  python3 tools/paint_uniform.py   (numpy ve Pillow gerekir)
Çıktı:     assets/characters/textures/<ad>_body.png
"""
import json, os, struct
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHAR_DIR = os.path.join(ROOT, "assets", "characters")
OUT_DIR = os.path.join(CHAR_DIR, "textures")

# Karakter tanımları: hangi gövde, hangi renkler.
UNIFORMS = {
    "deniz": dict(base="Superhero_Male.glb", suit=(38, 46, 60), accent=(222, 120, 40),
                  dark=(22, 24, 28), gloves=True, belt=(55, 58, 62)),
    "ada":   dict(base="Superhero_Female.glb", suit=(40, 50, 64), accent=(60, 200, 180),
                  dark=(24, 26, 30), gloves=False, belt=(58, 62, 66)),
}

COMPONENT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path):
    b = open(path, "rb").read()
    jlen = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + jlen])
    binary = b[20 + jlen + 8:]
    return j, binary


def accessor(j, binary, idx):
    a = j["accessors"][idx]
    bv = j["bufferViews"][a["bufferView"]]
    dt = COMPONENT[a["componentType"]]
    n = NCOMP[a["type"]]
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    stride = bv.get("byteStride", 0)
    item = np.dtype(dt).itemsize * n
    if stride and stride != item:
        raw = np.frombuffer(binary, dtype=np.uint8, count=stride * a["count"], offset=start)
        raw = raw.reshape(a["count"], stride)[:, :item].copy()
        arr = raw.view(dt).reshape(a["count"], n)
    else:
        arr = np.frombuffer(binary, dtype=dt, count=a["count"] * n, offset=start).reshape(a["count"], n)
    if a.get("normalized"):
        arr = arr.astype(np.float32) / np.iinfo(dt).max
    return arr


def body_texture(j, binary, mat_index):
    tex = j["materials"][mat_index]["pbrMetallicRoughness"]["baseColorTexture"]["index"]
    img = j["images"][j["textures"][tex]["source"]]
    bv = j["bufferViews"][img["bufferView"]]
    data = binary[bv.get("byteOffset", 0):bv.get("byteOffset", 0) + bv["byteLength"]]
    import io
    return Image.open(io.BytesIO(data)).convert("RGB")


def paint(name, cfg):
    j, binary = read_glb(os.path.join(CHAR_DIR, cfg["base"]))
    bones = [j["nodes"][i]["name"] for i in j["skins"][0]["joints"]]

    # En çok üçgeni olan mesh gövdedir.
    prim = max((p for m in j["meshes"] for p in m["primitives"]),
               key=lambda p: j["accessors"][p["indices"]]["count"])
    attr = prim["attributes"]
    pos = accessor(j, binary, attr["POSITION"])
    uv = accessor(j, binary, attr["TEXCOORD_0"])
    joints = accessor(j, binary, attr["JOINTS_0"]).astype(int)
    weights = accessor(j, binary, attr["WEIGHTS_0"]).astype(np.float32)
    tris = accessor(j, binary, prim["indices"]).reshape(-1, 3)

    def group_weight(pred):
        mask = np.vectorize(lambda k: pred(bones[k]))(joints)
        return (weights * mask).sum(axis=1)

    w_head = group_weight(lambda b: b in ("Head",))
    w_neck = group_weight(lambda b: b == "neck_01")
    w_hand = group_weight(lambda b: "hand" in b or any(f in b for f in ("index", "middle", "ring", "pinky", "thumb")))
    w_foot = group_weight(lambda b: "foot" in b or "ball" in b)
    w_clav = group_weight(lambda b: "clavicle" in b)
    w_spine1 = group_weight(lambda b: b == "spine_01")
    w_pelvis = group_weight(lambda b: b == "pelvis")

    height = pos[:, 1].max() - pos[:, 1].min()
    floor = pos[:, 1].min()
    waist_y = np.median(pos[w_spine1 > 0.5, 1]) - 0.06 * height if (w_spine1 > 0.5).any() else floor + 0.55 * height
    boot_y = floor + 0.085 * height

    base = body_texture(j, binary, prim["material"])
    W, H = base.size
    # Kumaş için orijinal dokudan sadece geniş gölgeleri al (kas detayını sil).
    lum = np.asarray(base.convert("L").filter(ImageFilter.GaussianBlur(10)), dtype=np.float32) / 255.0
    region = Image.new("L", base.size, 0)  # 0 = ten (dokunma)
    draw = ImageDraw.Draw(region)

    SUIT, ACCENT, DARK, BELT, COLLAR, PANEL = 1, 2, 3, 4, 5, 6
    for t in tris:
        c = pos[t].mean(axis=0)
        head, neck = w_head[t].mean(), w_neck[t].mean()
        hand, foot, clav = w_hand[t].mean(), w_foot[t].mean(), w_clav[t].mean()
        if head > 0.35 or (neck > 0.55 and head > 0.05):
            continue  # yüz ve boyun teni
        pelvis = w_pelvis[t].mean()
        if neck > 0.22:
            r = COLLAR  # dik yaka
        elif hand > 0.5:
            if not cfg["gloves"]:
                continue
            r = DARK
        elif 0.08 < hand <= 0.5:
            r = ACCENT  # bilek manşeti
        elif foot > 0.3 or c[1] < boot_y:
            r = DARK
        elif abs(c[1] - waist_y) < 0.022 * height:
            r = BELT
        elif pelvis > 0.55 and c[1] < waist_y:
            r = PANEL  # kalçada koyu dayanıklı panel
        else:
            r = SUIT
        pts = [(float(uv[k, 0]) * W, float(uv[k, 1]) * H) for k in t]
        draw.polygon(pts, fill=r, outline=r, width=3)

    region = np.asarray(region)
    out = np.asarray(base, dtype=np.float32).copy()
    shade = (0.8 + 0.3 * (lum - lum.mean()))[..., None]
    colors = {SUIT: cfg["suit"], ACCENT: cfg["accent"], DARK: cfg["dark"], BELT: cfg["belt"], COLLAR: cfg["accent"],
              PANEL: tuple(int(v * 0.72) for v in cfg["suit"])}
    for r, col in colors.items():
        m = region == r
        out[m] = (np.array(col, dtype=np.float32)[None, :] * shade[m] * 1.25).clip(0, 255)
    os.makedirs(OUT_DIR, exist_ok=True)
    out_path = os.path.join(OUT_DIR, f"{name}_body.png")
    Image.fromarray(out.astype(np.uint8)).save(out_path)
    print("yazıldı:", os.path.relpath(out_path, ROOT), "| bel:", round(float(waist_y), 3), "boy:", round(float(height), 3))


if __name__ == "__main__":
    for n, c in UNIFORMS.items():
        paint(n, c)
