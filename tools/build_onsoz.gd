extends SceneTree
## Önsöz sokağını (Dünya, 2526 — Seçim Merkezi'nin önü) kurar ve
## scenes/levels/onsoz_sokak.tscn olarak kaydeder.
## Çalıştırma: godot --headless --path . --script res://tools/build_onsoz.gd
##
## Cadde +Z yönünde uzanır (x: -9..9). Seçim Merkezi'nin kapısı z = 62'de.
## Sağdaki binaların arasında (z 5..16) ara sokak vardır.

const OUT := "res://scenes/levels/onsoz_sokak.tscn"
const CITY := "res://assets/city/%s.gltf"
const APO := "res://assets/apocalypse/%s.gltf"
const KIT := "res://assets/megakit/%s.gltf"
const GATE_Z := 62.0

var level: Node3D
var _cache := {}
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 2526
	level = Node3D.new()
	level.name = "OnsozSokak"
	var g := {}
	for n in ["Ground", "Buildings", "Gate", "Props", "Lights"]:
		var node := Node3D.new()
		node.name = n
		level.add_child(node)
		node.owner = level
		g[n] = node

	# --- Zemin: asfalt, kaldırımlar, ara sokak
	for x0 in [-9.0, 0.0]:
		for z0 in range(-18, 72, 9):
			_put(g.Ground, CITY % "S_StreetAsphalt9x9", Vector3(x0 + 9.0, 0, z0 + 9.0))
	for z0 in range(0, 18, 9):
		for x0 in [9.0, 18.0]:
			_put(g.Ground, CITY % "S_StreetAsphalt9x9", Vector3(x0 + 9.0, 0, z0 + 9.0))
	for z in range(-15, 70, 3):
		_put(g.Ground, CITY % "S_SidewalkStraight3m", Vector3(-7.5, 0.0, z + 1.5), Vector3(0, PI / 2, 0))
		if z < 3 or z > 15:
			_put(g.Ground, CITY % "S_SidewalkStraight3m", Vector3(7.5, 0.0, z + 1.5), Vector3(0, -PI / 2, 0))
	_put(g.Ground, CITY % "S_DecalCrosswalkWide", Vector3(0, 0.01, 22), Vector3(0, PI / 2, 0))
	_put(g.Ground, CITY % "S_DecalCrosswalkWide", Vector3(0, 0.01, 52), Vector3(0, PI / 2, 0))

	# --- Binalar (sol taraf +X'e, sağ taraf -X'e bakar)
	_building(g.Buildings, "S_BuildingMedium2_001", -1, 0.0)
	_building(g.Buildings, "S_BuildingLarge_2", -1, 21.0)
	_building(g.Buildings, "S_BuildingSmall_1", -1, 42.0)
	_building(g.Buildings, "S_BuildingMedium2_001", -1, 58.0)
	_building(g.Buildings, "S_BuildingSmall_1", 1, -1.0)
	_building(g.Buildings, "S_BuildingLarge_2", 1, 27.0)
	_building(g.Buildings, "S_BuildingMedium2_001", 1, 50.0)
	_building(g.Buildings, "S_BuildingSmall_1", 1, 64.0)
	_building(g.Buildings, "S_BuildingLarge_2", 1, -22.0)
	_building(g.Buildings, "S_BuildingLarge_2", -1, -21.0)
	# Ara sokağın sonu
	_put(g.Props, APO % "S_ContainerGreen", Vector3(24.5, 0, 10.5), Vector3(0, PI / 2, 0))
	_put(g.Props, APO % "S_ContainerRed", Vector3(24.5, 2.6, 10.0), Vector3(0, PI / 2 + 0.1, 0))
	# Caddenin başı kapalı (arkadan gelinmesin)
	for x in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		_put(g.Props, APO % "S_TrafficBarrier_1", Vector3(x, 0, -12.0), Vector3(0, _rng.randf_range(-0.2, 0.2), 0))
	_put(g.Props, APO % "S_VehicleTruck", Vector3(-2.5, 0, -15.0), Vector3(0, 1.4, 0))
	_put(g.Props, APO % "S_VehiclePickup", Vector3(4.0, 0, -15.5), Vector3(0, -1.9, 0))

	# --- Seçim Merkezi: fütüristik duvar ve kapı
	for x in [-16.0, -12.0, -8.0, -4.0, 4.0, 8.0, 12.0, 16.0]:
		_put(g.Gate, KIT % "S_WallAstraStraight", Vector3(x, 0, GATE_Z + 2.0), Vector3(0, -PI / 2, 0))
		_put(g.Gate, KIT % "S_TopAstraStraight", Vector3(x, 0, GATE_Z + 2.0), Vector3(0, -PI / 2, 0))
		_put(g.Gate, KIT % "S_PlatformDarkPlates", Vector3(x, 0.01, GATE_Z + 2.0))
	_put(g.Gate, KIT % "S_DoorFrame_A", Vector3(0, 0, GATE_Z))
	_put(g.Gate, KIT % "S_DoorDarkMetal", Vector3(2.1, 0, GATE_Z + 0.6))
	_put(g.Gate, KIT % "S_PlatformCenterPlate", Vector3(0, 0.01, GATE_Z + 2.0))
	for x in [-2.2, 2.2]:
		_box(g.Gate, Vector3(x, 2.5, GATE_Z), Vector3(0.7, 5.0, 0.9))
	_box(g.Gate, Vector3(0, 2.5, GATE_Z + 1.2), Vector3(4.0, 5.0, 0.3))  # kapı kapalı
	for x in [-10.5, 10.5]:
		_put(g.Gate, KIT % "S_ColumnLargeStraight", Vector3(x, 0, GATE_Z - 0.6))
	# Holografik tabela
	_sign(g.Gate, "SEÇİM KOMİTESİ", Vector3(0, 7.2, GATE_Z - 0.4), 0.018, Color(0.55, 0.95, 1.0))
	_sign(g.Gate, "EMANET PROGRAMI — SON LİSTE AÇIKLANDI", Vector3(0, 6.2, GATE_Z - 0.4), 0.008, Color(1.0, 0.8, 0.4))

	# --- Barikat hattı (ortada muhafızın durduğu boşluk)
	for i in range(-5, 6):
		var x := i * 1.6
		if absf(x) < 1.2:
			continue
		_put(g.Props, APO % "S_TrafficBarrier_1", Vector3(x, 0, 57.0), Vector3(0, _rng.randf_range(-0.06, 0.06), 0))
	for x in [-1.3, 1.3]:
		_put(g.Props, APO % "S_PlasticBarrier", Vector3(x, 0, 58.2), Vector3(0, PI / 2, 0))

	# --- Terk edilmiş şehir
	_put(g.Props, APO % "S_VehiclePickup", Vector3(4.6, 0, 9.0), Vector3(0, 0.35, 0))
	_put(g.Props, APO % "S_VehicleTruck", Vector3(-5.2, 0, 27.0), Vector3(0, -0.2, 0))
	_put(g.Props, APO % "S_VehicleSports", Vector3(5.3, 0, 45.0), Vector3(0, 2.9, 0))
	_put(g.Props, APO % "S_ContainerRed", Vector3(-6.4, 0, 52.0), Vector3(0, 0.05, 0))
	_put(g.Props, APO % "S_Couch", Vector3(-7.6, 0, 12.0), Vector3(0, PI / 2, 0))
	_put(g.Props, APO % "S_WaterTower", Vector3(13.0, 0, -6.0))
	_put(g.Props, APO % "S_TrafficLight_1", Vector3(7.0, 0, 54.0), Vector3(0, PI, 0))
	_put(g.Props, APO % "S_FireHydrant", Vector3(-6.8, 0, 33.0))
	for p in [Vector3(-7.2, 0, 4.0), Vector3(-6.9, 0, 4.6), Vector3(7.1, 0, 21.0), Vector3(-7.0, 0, 38.5),
			Vector3(-6.6, 0, 38.0), Vector3(20.0, 0, 7.0), Vector3(19.4, 0, 7.6), Vector3(6.8, 0, 35.2)]:
		_put(g.Props, APO % ["S_TrashBag_1", "S_TrashBag_2"][_rng.randi() % 2], p, Vector3(0, _rng.randf() * TAU, 0))
	for p in [Vector3(-2.0, 0, 15.0), Vector3(2.5, 0, 19.0), Vector3(-3.4, 0, 49.0), Vector3(1.8, 0, 54.5)]:
		_put(g.Props, APO % ["S_TrafficCone_1", "S_TrafficCone_2"][_rng.randi() % 2], p, Vector3(0, _rng.randf() * TAU, 0))
	for p in [Vector3(16.0, 0, 13.5), Vector3(17.0, 0, 13.6), Vector3(-7.4, 0, 20.0)]:
		_put(g.Props, APO % "S_PalletBroken", p, Vector3(0, _rng.randf() * TAU, 0))
	_put(g.Props, APO % "S_WheelsStack", Vector3(21.2, 0, 7.0))
	_put(g.Props, APO % "S_Pipes", Vector3(-7.3, 0, 46.0))
	for z in [-6.0, 10.0, 26.0, 42.0]:
		_put(g.Props, CITY % "S_PropManholeCover", Vector3(_rng.randf_range(-3, 3), 0.01, z))

	# --- Yanan variller ve sokak lambaları
	var fire := load("res://scenes/props/fire_barrel.tscn") as PackedScene
	for p in [Vector3(-2.6, 0, 34.0), Vector3(3.2, 0, 40.5), Vector3(-4.2, 0, 47.0), Vector3(19.0, 0, 9.0), Vector3(-6.5, 0, 16.0)]:
		var f: Node3D = fire.instantiate()
		f.position = p
		if p.x < -6.0:
			f.add_to_group("detay", true)
		g.Props.add_child(f)
		f.owner = level
	var lamp_i := 0
	for z in [-4.0, 12.0, 28.0, 44.0]:
		for side in [-1.0, 1.0]:
			lamp_i += 1
			if side > 0 and z == 12.0:
				continue  # ara sokak
			_put(g.Props, APO % "S_StreetLights", Vector3(side * 6.7, 0, z), Vector3(0, PI / 2 if side < 0 else -PI / 2, 0))
			if lamp_i % 3 != 0:  # bazıları bozuk
				_light(g.Lights, Vector3(side * 5.2, 6.2, z), Color(1.0, 0.7, 0.4), 1.6, 12.0, false, true)

	# --- Seçim Merkezi ışıkları
	_light(g.Lights, Vector3(0, 3.0, GATE_Z - 1.5), Color(0.6, 0.9, 1.0), 3.0, 12.0, true)
	_light(g.Lights, Vector3(-8, 4.5, GATE_Z - 1.2), Color(0.5, 0.85, 1.0), 1.6, 9.0, false, true)
	_light(g.Lights, Vector3(8, 4.5, GATE_Z - 1.2), Color(0.5, 0.85, 1.0), 1.6, 9.0, false, true)
	var sweep := load("res://scripts/props/searchlight.gd")
	var i := 0
	for x in [-10.5, 10.5]:
		var s := SpotLight3D.new()
		s.name = "Projektor%d" % i
		s.position = Vector3(x, 9.5, GATE_Z - 1.2)
		s.rotation = Vector3(deg_to_rad(-28), PI + (0.35 if x > 0 else -0.35), 0)
		s.light_color = Color(0.85, 0.95, 1.0)
		s.light_energy = 8.0
		s.spot_range = 45.0
		s.spot_angle = 9.0
		s.set_script(sweep)
		s.set("phase", float(i) * 2.0)
		g.Lights.add_child(s)
		s.owner = level
		i += 1

	var packed := PackedScene.new()
	var err := packed.pack(level)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("Önsöz sokağı kaydedildi: ", OUT, " (hata kodu ", err, ")")
	quit()


## Binayı caddeye bakacak şekilde yerleştirir. side: -1 sol, +1 sağ. z: binanın orta noktası.
func _building(parent: Node3D, piece: String, side: int, z: float) -> void:
	var inst := _put(parent, CITY % piece, Vector3.ZERO, Vector3(0, -side * PI / 2, 0))
	var aabb := _local_aabb(inst)
	# Döndürmeden sonra cephe (yerel +Z) caddeye bakar: sol için x = origin + zmax, sağ için x = origin - zmax
	var front := aabb.end.z
	var mid_local_x := aabb.position.x + aabb.size.x / 2.0
	if side < 0:
		inst.position = Vector3(-9.0 - front, 0, z + mid_local_x)
	else:
		inst.position = Vector3(9.0 + front, 0, z - mid_local_x)


func _local_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for m: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var t: Transform3D = Transform3D.IDENTITY
		var n: Node = m
		while n != node:
			t = (n as Node3D).transform * t
			n = n.get_parent()
		var bb: AABB = t * m.get_aabb()
		result = bb if first else result.merge(bb)
		first = false
	return result


func _put(parent: Node3D, path: String, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> Node3D:
	if not _cache.has(path):
		_cache[path] = load(path)
	var inst: Node3D = (_cache[path] as PackedScene).instantiate()
	inst.position = pos
	inst.rotation = rot
	parent.add_child(inst)
	inst.owner = level
	return inst


func _box(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	body.owner = level
	shape.owner = level


func _sign(parent: Node3D, text: String, pos: Vector3, pixel: float, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.rotation = Vector3(0, PI, 0)
	l.pixel_size = pixel
	l.font_size = 96
	l.outline_size = 12
	l.modulate = color
	l.outline_modulate = Color(color.r * 0.2, color.g * 0.2, color.b * 0.3, 0.8)
	l.shaded = false
	parent.add_child(l)
	l.owner = level


func _light(parent: Node3D, pos: Vector3, color: Color, energy: float, rng: float, shadow: bool, detail: bool = false) -> void:
	var l := OmniLight3D.new()
	if detail:
		l.add_to_group("detay", true)
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadow
	parent.add_child(l)
	l.owner = level
