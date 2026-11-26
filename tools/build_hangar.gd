extends SceneTree
## EMANET hangarını MegaKit parçalarından kurar ve scenes/levels/emanet_hangar.tscn olarak kaydeder.
## Çalıştırma:  godot --headless --path . --script res://tools/build_hangar.gd
##
## Izgara: her hücre 4x4 metre. Hücre (cx, cz) merkezi = (cx*4, 0, cz*4).
## Harita:  '#' zemin, 'K' asma kat (2 m yüksekte), 'S' merdiven (-X yönüne çıkar), '.' boş

const KIT := "res://assets/megakit/%s.gltf"
const CELL := 4.0
const WALL_H := 5.0
const MAP := [
	"...#...",
	"...#...",
	"...#...",
	"#######",
	"#######",
	"#######",
	"#######",
	"KKKS###",
]
const OUT := "res://scenes/levels/emanet_hangar.tscn"

var level: Node3D
var _cache := {}
var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 2526
	level = Node3D.new()
	level.name = "EmanetHangar"
	level.set_script(load("res://scripts/levels/level_fixups.gd"))
	var groups := {}
	for g in ["Floor", "Walls", "Ceiling", "Mezzanine", "Props", "Lights"]:
		var n := Node3D.new()
		n.name = g
		level.add_child(n)
		n.owner = level
		groups[g] = n

	for cz in MAP.size():
		for cx in MAP[cz].length():
			var c: String = MAP[cz][cx]
			if c == ".":
				continue
			var center := Vector3(cx * CELL, 0, cz * CELL)
			var corridor := cz < 3
			# Zemin
			var floor_piece: String = "S_PlatformMetal2" if corridor else ["S_PlatformMetal", "S_PlatformDarkPlates", "S_Platform3Plates", "S_PlatformSquares"][_rng.randi() % 4]
			if cx == 3 and cz == 5:
				floor_piece = "S_PlatformCenterPlate"
			_put(groups.Floor, floor_piece, center)
			# Tavan (ters çevrilmiş zemin)
			_put(groups.Ceiling, "S_PlatformSimple", center + Vector3(0, WALL_H, 0), Vector3(PI, 0, 0))
			if (cx + cz) % 2 == 0 or corridor:
				_put(groups.Lights, "S_PropLightWide", center + Vector3(0, WALL_H, 0), Vector3(0, PI / 2 if corridor else 0.0, 0))
			# Duvarlar: komşusu boş olan her kenar
			for side in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				if _cell(cx + side.x, cz + side.y) != ".":
					continue
				var rot := _side_rotation(side)
				var lower := "S_WallAstraStraight"
				var r := _rng.randf()
				if corridor:
					lower = "S_WallBandStraight"
				elif r < 0.25:
					lower = "S_WallAstraStraightDivided"
				elif r < 0.4:
					lower = "S_WallBandStraight"
				var upper := "S_TopWindowStraight" if (not corridor and side != Vector2i(0, -1)) else "S_TopAstraStraight"
				_put(groups.Walls, lower, center, Vector3(0, rot, 0))
				_put(groups.Walls, upper, center, Vector3(0, rot, 0))
				_put(groups.Floor, "S_BottomMetalStraight", center, Vector3(0, rot, 0))
			# Asma kat
			if c == "K":
				_put(groups.Mezzanine, "S_PlatformMetal2", center + Vector3(0, 2, 0))
				if _cell(cx, cz - 1) == "#":
					_put(groups.Mezzanine, "S_ShortWallMetal2Straight", center, Vector3(0, _side_rotation(Vector2i(0, -1)), 0))
					_put(groups.Mezzanine, "S_PropRail_4", center + Vector3(-2, 2, -1.9), Vector3(0, -PI / 2, 0))
			if c == "S":
				_put(groups.Mezzanine, "S_PlatformStairs4Wide", center + Vector3(2, 0, 0), Vector3(0, -PI / 2, 0))
				# Görünmez rampa: 4 m'de 2 m yükselir (-X yönüne)
				var slope := atan2(2.0, 4.0)
				_box(groups.Mezzanine, center + Vector3(0, 0.98, 0), Vector3(4.6, 0.1, 4.0), Vector3(0, 0, -slope))

	# Kapılar
	_put(groups.Walls, "S_DoorFrameSquare", Vector3(3 * CELL, 0, 2.5 * CELL))
	for side in [-1.0, 1.0]:
		_box(groups.Walls, Vector3(3 * CELL + side * 2.05, 2.5, 2.5 * CELL), Vector3(0.8, 5.0, 0.5))
	_put(groups.Walls, "S_DoorFrameSquareBlocked", Vector3(3 * CELL, 0, -0.5 * CELL))
	# İniş pisti
	_put(groups.Props, "S_PlatformRound1", Vector3(3 * CELL, 0.01, 5 * CELL))

	# Eşyalar
	var P: Node3D = groups.Props
	for x in [0.5, 4.5]:
		_put(P, "S_PropComputer", Vector3(x, 0, 10.8), Vector3(0, PI, 0))
	_put(P, "S_PropComputer", Vector3(25.2, 0, 13.0), Vector3(0, PI / 2, 0))
	_put(P, "S_PropComputer", Vector3(25.2, 0, 14.2), Vector3(0, PI / 2, 0))
	_put(P, "S_PropAccessPoint", Vector3(13.6, 0, 1.0), Vector3(0, PI / 2, 0))
	for p in [Vector3(-0.8, 0.5, 16.5), Vector3(-0.8, 0.5, 17.6), Vector3(-0.8, 1.5, 17.0), Vector3(0.4, 0.5, 17.1)]:
		_put(P, "S_PropCrate3", p, Vector3(0, _rng.randf() * 0.3, 0))
	for p in [Vector3(24.4, 0.56, 24.5), Vector3(24.6, 0.56, 25.8), Vector3(23.3, 0.56, 25.4)]:
		_put(P, "S_PropCrate4", p, Vector3(0, _rng.randf() * 0.5, 0))
	for p in [Vector3(1.0, 0, 25.0), Vector3(2.0, 0, 25.2), Vector3(5.5, 0, 25.1)]:
		_put(P, "S_PropBarrelLarge", p)
	_put(P, "SK_PropChest", Vector3(20.0, 0, 28.8))
	_put(P, "S_PropPipeHolder", Vector3(16.0, 0, 29.0))
	_put(P, "S_PropVentBig", Vector3(8.0, 0.01, 18.0))
	_put(P, "S_PropVentBig", Vector3(18.0, 0.01, 16.0), Vector3(0, PI / 2, 0))
	_put(P, "S_PropCable_3", Vector3(14.6, 0.01, 18.5))
	_put(P, "S_PropLightFloor", Vector3(9.0, 0, 20.0), Vector3(0, PI / 2, 0))
	_put(P, "S_PropLightFloor", Vector3(15.0, 0, 20.0), Vector3(0, PI / 2, 0))
	_put(P, "S_PropItemHolder", Vector3(4.0, 2.0, 29.2))
	_put(P, "S_PropComputer", Vector3(7.0, 2.0, 29.4))

	# Işıklar (iç mekân lambalarla aydınlanır; güneş yalnızca gezegeni aydınlatır)
	var L: Node3D = groups.Lights
	_light(L, Vector3(12, 4.5, 1.5), Color(0.7, 0.82, 1.0), 1.3, 7.0, false)
	_light(L, Vector3(12, 4.5, 13.0), Color(1.0, 0.9, 0.78), 1.8, 11.0, true)
	_light(L, Vector3(4, 4.5, 21.0), Color(1.0, 0.9, 0.78), 1.3, 9.0, false)
	_light(L, Vector3(20, 4.5, 21.0), Color(1.0, 0.9, 0.78), 1.3, 9.0, false)
	_light(L, Vector3(12, 0.6, 20.0), Color(1.0, 0.4, 0.12), 2.6, 6.5, false)
	_light(L, Vector3(4, 3.6, 28.0), Color(0.3, 0.7, 1.0), 1.6, 6.0, false)
	_light(L, Vector3(25.0, 1.4, 13.6), Color(0.3, 1.0, 0.8), 1.4, 4.0, false)
	# Pencerelerden süzülen soğuk yıldız ışığı
	for p in [Vector3(1.0, 4.2, 18.0), Vector3(23.0, 4.2, 18.0), Vector3(12.0, 4.2, 29.0)]:
		_light(L, p, Color(0.45, 0.6, 1.0), 0.9, 8.0, false)

	var packed := PackedScene.new()
	var err := packed.pack(level)
	if err == OK:
		err = ResourceSaver.save(packed, OUT)
	print("Hangar kaydedildi: ", OUT, " (hata kodu ", err, ")")
	quit()


func _cell(cx: int, cz: int) -> String:
	if cz < 0 or cz >= MAP.size() or cx < 0 or cx >= MAP[cz].length():
		return "."
	return MAP[cz][cx]


## Parçalar varsayılan olarak hücrenin -X kenarındadır; istenen kenara döndürür.
func _side_rotation(side: Vector2i) -> float:
	match side:
		Vector2i(-1, 0): return 0.0
		Vector2i(1, 0): return PI
		Vector2i(0, -1): return -PI / 2
		_: return PI / 2


func _put(parent: Node3D, piece: String, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> Node3D:
	if not _cache.has(piece):
		_cache[piece] = load(KIT % piece)
	var inst: Node3D = (_cache[piece] as PackedScene).instantiate()
	inst.position = pos
	inst.rotation = rot
	parent.add_child(inst)
	inst.owner = level
	return inst


## Görünmez çarpışma kutusu.
func _box(parent: Node3D, pos: Vector3, size: Vector3, rot: Vector3 = Vector3.ZERO) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation = rot
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	parent.add_child(body)
	body.owner = level
	shape.owner = level


func _light(parent: Node3D, pos: Vector3, color: Color, energy: float, rng: float, shadow: bool) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadow
	parent.add_child(l)
	l.owner = level
