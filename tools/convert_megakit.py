"""Quaternius Modular Sci-Fi MegaKit (USD) -> glTF dönüştürücü.

Blender'ın Python modülüyle (bpy) çalışır:
    python -m pip install bpy
    python tools/convert_megakit.py -- <MegaKit klasörü> <çıktı klasörü>

- Kategori soneki olan kopyalar (…Walls, …Props, …Platforms…) atlanır; ana sürüm alınır.
- Yapısal parçaların nesne adına "-col" eklenir; Godot bunlar için otomatik çarpışma üretir.
- Dokular çıktı klasöründeki ortak "textures/" klasörüne bir kez yazılır.
"""
import bpy, os, sys, json

args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
SRC, DST = args[0], args[1]
SUFFIXES = ("Walls", "Props", "Platforms", "Columns", "Decals", "Aliens")
NO_COLLISION = ("S_Decal", "S_PropCable", "S_PropLight", "S_PropVent", "SK_Alien", "SK_PropFan",
                "S_TopCablesStraightHanging", "S_PropPipeHolder", "S_PropClamp")
# Bunların çarpışması seviye kurucuda basit şekillerle eklenir (eşik ve basamaklara takılmamak için).
NO_COLLISION_EXACT = {"S_DoorFrameSquare", "S_DoorFrameSquareTall", "S_DoorFrame_A", "S_PlatformStairs4Wide",
                      "S_PlatformStairs4WideTall", "S_PlatformStairs_2", "S_PlatformStairs_4"}
os.makedirs(DST, exist_ok=True)
report = {}

files = sorted(f for f in os.listdir(SRC) if f.endswith(".usda"))
for f in files:
    name = f[:-5]
    if name.endswith(SUFFIXES):
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.usd_import(filepath=os.path.join(SRC, f), import_cameras=False, import_lights=False)
    collide = not name.startswith(NO_COLLISION) and name not in NO_COLLISION_EXACT
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in meshes:
        if collide and not o.name.endswith("-col"):
            o.name = o.name + "-col"
    # Boyut raporu (Blender: Z yukarı)
    import mathutils
    pts = [o.matrix_world @ mathutils.Vector(c) for o in meshes for c in o.bound_box]
    if pts:
        mn = [min(p[i] for p in pts) for i in range(3)]
        mx = [max(p[i] for p in pts) for i in range(3)]
        report[name] = {"x": [round(mn[0], 2), round(mx[0], 2)], "y_up": [round(mn[2], 2), round(mx[2], 2)],
                        "z": [round(-mx[1], 2), round(-mn[1], 2)], "collision": collide,
                        "animated": bool(bpy.data.actions)}
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(DST, name + ".gltf"),
        export_format="GLTF_SEPARATE",
        export_texture_dir="textures",
        export_image_format="AUTO",
        export_animations=True,
        export_apply=True,
        export_yup=True,
    )
    print("OK", name)

with open(os.path.join(DST, "_parcalar.json"), "w") as fh:
    json.dump(report, fh, indent=1, sort_keys=True)
print("Toplam:", len(report))
