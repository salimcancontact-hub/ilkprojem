class_name GemiSet
extends RefCounted
## EMANET'in iç mekânlarını kodla kurar (Bölüm 2: Biniş).
##   Bölge 1 (0,0,0):   Yörünge İskelesi (biniş kapısı) + Halka Meydanı (bahçe, hologram, anı duvarı, cam asansör)
##   Bölge 2 (300,0,0): Güverte 8 koridoru + Kamara 412
## Kaba yapı MegaKit parçalarıyla, mobilya ve 2526 dokunuşları (holo ekranlar, kalkış koltuğu) kodla yapılır.
## Döndürülen sözlükler, seviyenin canlandıracağı parçalara (kapılar, ışıklar, koltuk...) referans tutar.

const KIT := "res://assets/megakit/%s.gltf"
const ZONE2 := Vector3(300, 0, 0)
const ZONE3 := Vector3(600, 0, 0)  # köprü
const ZONE4 := Vector3(3000, 0, 0)  # dış çekim: limandaki gemi

static var _mats: Dictionary = {}
static var _kit_cache: Dictionary = {}
static var _glass_mat: StandardMaterial3D


# --- Malzemeler ----------------------------------------------------------------

static func mat(key: String) -> Material:
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.roughness = 0.7
	match key:
		"beyaz": m.albedo_color = Color(0.7, 0.72, 0.75)
		"krem": m.albedo_color = Color(0.66, 0.6, 0.52)
		"gri": m.albedo_color = Color(0.5, 0.53, 0.57)
		"koyu": m.albedo_color = Color(0.13, 0.15, 0.18)
		"zemin": m.albedo_color = Color(0.36, 0.38, 0.42)
		"ahsap": m.albedo_color = Color(0.45, 0.31, 0.2)
		"lacivert": m.albedo_color = Color(0.16, 0.22, 0.34)
		"turuncu": m.albedo_color = Color(0.92, 0.48, 0.16)
		"haki": m.albedo_color = Color(0.38, 0.4, 0.27)
		"yaprak": m.albedo_color = Color(0.3, 0.58, 0.26)
		"yaprak2": m.albedo_color = Color(0.2, 0.44, 0.2)
		"govde": m.albedo_color = Color(0.36, 0.25, 0.17)
		"toprak": m.albedo_color = Color(0.25, 0.18, 0.12)
		"domates": m.albedo_color = Color(0.85, 0.2, 0.12)
		"kirmizi_serit": m.albedo_color = Color(0.75, 0.12, 0.1)
		"yer": m.albedo_color = Color(0.24, 0.19, 0.15)
		"alev":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.albedo_color = Color(0.55, 0.8, 1.0, 0.85)
		"sehir": m.albedo_color = Color(0.12, 0.1, 0.1)
		"yangin":
			m.albedo_color = Color(1.0, 0.45, 0.15)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.4, 0.1)
			m.emission_energy_multiplier = 2.5
		"isik_sicak":
			m.albedo_color = Color(1.0, 0.85, 0.65)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.78, 0.5)
			m.emission_energy_multiplier = 2.2
		"isik_mavi":
			m.albedo_color = Color(0.5, 0.85, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.35, 0.8, 1.0)
			m.emission_energy_multiplier = 2.5
		"isik_yesil":
			m.albedo_color = Color(0.4, 1.0, 0.6)
			m.emission_enabled = true
			m.emission = Color(0.3, 1.0, 0.5)
			m.emission_energy_multiplier = 3.0
		"isik_kirmizi":
			m.albedo_color = Color(1.0, 0.3, 0.25)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.15, 0.1)
			m.emission_energy_multiplier = 3.0
		"ekran":
			m.albedo_color = Color(0.05, 0.12, 0.2)
			m.emission_enabled = true
			m.emission = Color(0.06, 0.2, 0.32)
			m.emission_energy_multiplier = 1.5
		"cam":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.6, 0.8, 1.0, 0.13)
			m.metallic = 0.5
			m.roughness = 0.05
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"holo":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.albedo_color = Color(0.25, 0.7, 1.0, 0.55)
		"holo_soluk":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.albedo_color = Color(0.2, 0.55, 0.9, 0.16)
	_mats[key] = m
	return m


# --- Yapı taşları ---------------------------------------------------------------

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat_key: String, collide: bool = true, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(mat_key)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi


static func cyl(parent: Node3D, pos: Vector3, r_top: float, r_bottom: float, h: float, mat_key: String, collide: bool = false, segments: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bottom
	cm.height = h
	cm.radial_segments = segments
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat(mat_key)
	mi.position = pos
	parent.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = maxf(r_top, r_bottom)
		shape.height = h
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi


static func ball(parent: Node3D, pos: Vector3, r: float, mat_key: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 10
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = mat(mat_key)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func label(parent: Node3D, pos: Vector3, text: String, size: int, color: Color, yaw: float = 0.0, pixel: float = 0.004) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = pixel
	l.modulate = color
	l.outline_size = 0
	l.double_sided = false
	l.position = pos
	l.rotation = Vector3(0, yaw, 0)
	parent.add_child(l)
	return l


static func kit(parent: Node3D, piece: String, pos: Vector3, yaw: float = 0.0, rot_x: float = 0.0) -> Node3D:
	if not _kit_cache.has(piece):
		_kit_cache[piece] = load(KIT % piece)
	var inst: Node3D = (_kit_cache[piece] as PackedScene).instantiate()
	inst.position = pos
	inst.rotation = Vector3(rot_x, yaw, 0)
	parent.add_child(inst)
	return inst


static func omni(parent: Node3D, pos: Vector3, color: Color, energy: float, range_m: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = range_m
	l.shadow_enabled = false
	parent.add_child(l)
	return l


## MegaKit'in opak gelen camlarını gerçek şeffaf cama çevirir.
static func glassify(root: Node) -> void:
	if _glass_mat == null:
		_glass_mat = mat("cam")
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(i)
			if m and m.resource_name == "M_Glass":
				mi.set_surface_override_material(i, _glass_mat)


## 2526 Dünyası: dokulu küre, gündüz/gece ve atmosfer halesi.
static func earth(parent: Node3D, pos: Vector3, radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 48
	sm.rings = 24
	mi.mesh = sm
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/earth.gdshader")
	m.set_shader_parameter("surface", load("res://assets/textures/earth.png"))
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Hücre kenarı için MegaKit dönüşü (parçalar hücrenin -X kenarındadır).
static func _side_yaw(side: Vector2i) -> float:
	match side:
		Vector2i(-1, 0): return 0.0
		Vector2i(1, 0): return PI
		Vector2i(0, -1): return -PI / 2
		_: return PI / 2


# =============================================================================
# Bölge 1: Yörünge İskelesi + Halka Meydanı
# =============================================================================
# Izgara: hücre 4x4 m, merkez (cx*4, 0, cz*4). cx 0..4, cz 0..2 iskele (5 m), cz 3..7 meydan (10 m).

static func build_zone1(root: Node3D) -> Dictionary:
	var refs := {}
	var z1 := Node3D.new()
	z1.name = "Bolge1"
	root.add_child(z1)
	refs["root"] = z1
	var floors := ["S_PlatformMetal2", "S_PlatformSimple"]
	for cz in 8:
		var atrium := cz >= 3
		for cx in 5:
			var c := Vector3(cx * 4.0, 0, cz * 4.0)
			kit(z1, floors[1] if atrium else floors[0], c)
			kit(z1, "S_PlatformSimple", c + Vector3(0, 10.0 if atrium else 5.0, 0), 0.0, PI)
			if not atrium or (cx + cz) % 2 == 0:
				kit(z1, "S_PropLightWide", c + Vector3(0, 10.0 if atrium else 5.0, 0), PI / 2)
			# Kenarlar
			var sides: Array[Vector2i] = []
			if cx == 0: sides.append(Vector2i(-1, 0))
			if cx == 4: sides.append(Vector2i(1, 0))
			if cz == 0: sides.append(Vector2i(0, -1))
			if cz == 7: sides.append(Vector2i(0, 1))
			for side in sides:
				var yaw := _side_yaw(side)
				if side.x == -1:
					# Dünya'ya bakan dev pencereler
					kit(z1, "S_WallWindowStraight", c, yaw)
					kit(z1, "S_TopWindowStraight", c, yaw)
					if atrium:
						kit(z1, "S_WallWindowStraight", c + Vector3(0, 5, 0), yaw)
						kit(z1, "S_TopWindowStraight", c + Vector3(0, 5, 0), yaw)
				else:
					var lower := "S_WallAstraStraight"
					if atrium and side.x == 1:
						lower = "S_WallBandStraight"
					kit(z1, lower, c, yaw)
					kit(z1, "S_TopAstraStraight", c, yaw)
					if atrium:
						kit(z1, "S_WallAstraStraightDivided", c + Vector3(0, 5, 0), yaw)
						kit(z1, "S_TopAstraStraight", c + Vector3(0, 5, 0), yaw)
			# İskele ile meydan arasındaki duvar (biniş kapısı ortada)
			if cz == 2 and cx != 2:
				kit(z1, "S_WallBandStraight", c, _side_yaw(Vector2i(0, 1)))
				kit(z1, "S_TopAstraStraight", c, _side_yaw(Vector2i(0, 1)))
			if cz == 3:
				kit(z1, "S_WallBandStraight", c + Vector3(0, 5, 0), _side_yaw(Vector2i(0, -1)))
				kit(z1, "S_TopAstraStraight", c + Vector3(0, 5, 0), _side_yaw(Vector2i(0, -1)))
	# Arkadaki uzay asansörü kapısı (gelinen yer)
	kit(z1, "S_DoorFrameSquareBlocked", Vector3(8, 0, -1.7))
	label(z1, Vector3(8, 4.3, -1.4), "TERMİNAL — LİMAN ÇIKIŞI", 48, Color(0.6, 0.85, 1.0))
	# Pencere önü korkulukları
	for z0 in range(-2, 30, 4):
		kit(z1, "S_PropRail_4", Vector3(-1.1, 0, z0 + 4.0))

	# İç yüzeylere görünmez çarpışma: MegaKit duvarlarının çarpışması görünen yüzün arkasında kalıyor,
	# kamera görünen yüzü geçip duvarın içine (ve dışarıya) bakmasın.
	_col(z1, Vector3(-1.82, 5, 14), Vector3(0.1, 10, 32))
	_col(z1, Vector3(17.5, 2.5, 4), Vector3(0.1, 5, 12))
	_col(z1, Vector3(17.95, 5, 20), Vector3(0.1, 10, 20))
	_col(z1, Vector3(8, 2.5, -1.52), Vector3(20, 5, 0.1))
	_col(z1, Vector3(8, 5, 29.52), Vector3(20, 10, 0.1))
	_build_gate(z1, refs)
	_build_terminal_props(z1, refs)
	_build_atrium(z1, refs)
	_build_elevator(z1, refs)

	# Işıklar
	var L := Node3D.new()
	L.name = "Isiklar"
	z1.add_child(L)
	omni(L, Vector3(8, 4.3, 2.0), Color(0.95, 0.95, 1.0), 1.2, 9.0)
	omni(L, Vector3(8, 4.3, 7.5), Color(0.95, 0.95, 1.0), 1.0, 8.0)
	omni(L, Vector3(15, 4.0, 5.0), Color(0.6, 0.85, 1.0), 0.8, 7.0)
	omni(L, Vector3(8, 8.5, 15.0), Color(1.0, 0.93, 0.82), 1.4, 13.0)
	omni(L, Vector3(8, 8.5, 25.0), Color(1.0, 0.93, 0.82), 1.4, 13.0)
	omni(L, Vector3(16, 3.6, 17.0), Color(0.9, 1.0, 0.8), 0.9, 6.0)
	omni(L, Vector3(16, 3.6, 24.0), Color(0.5, 0.8, 1.0), 0.8, 6.0)
	_build_spaceport(z1, refs)
	glassify(z1)
	return refs


## Biniş kapısı: çerçeve, iki sürgülü kapı, kart okuyucu ve görevli masası.
static func _build_gate(z1: Node3D, refs: Dictionary) -> void:
	kit(z1, "S_DoorFrameSquare", Vector3(8, 0, 10))
	var left := kit(z1, "S_DoorSimple", Vector3(8, 0, 10))
	var right := kit(z1, "S_DoorSimple", Vector3(8, 0, 10), PI)
	refs["gate_l"] = left
	refs["gate_r"] = right
	# Çerçeve ile duvar arasındaki boşluklar
	box(z1, Vector3(5.7, 2.5, 10), Vector3(0.4, 5, 0.5), "koyu", true)
	box(z1, Vector3(10.3, 2.5, 10), Vector3(0.4, 5, 0.5), "koyu", true)
	label(z1, Vector3(8, 4.55, 9.7), "BİNİŞ — EMANET", 56, Color(0.7, 0.9, 1.0), PI)
	# Kapı üstü durum ışığı
	refs["gate_light"] = box(z1, Vector3(8, 4.25, 9.72), Vector3(1.6, 0.06, 0.04), "isik_kirmizi", false)
	# Kart okuyucu
	var rd := Node3D.new()
	rd.name = "KartOkuyucu"
	rd.position = Vector3(6.0, 0, 9.2)
	z1.add_child(rd)
	box(rd, Vector3(0, 0.55, 0), Vector3(0.28, 1.1, 0.28), "beyaz", true)
	box(rd, Vector3(0, 1.17, -0.02), Vector3(0.36, 0.26, 0.1), "koyu", false, Vector3(-0.5, 0, 0))
	var screen := box(rd, Vector3(0, 1.18, -0.08), Vector3(0.3, 0.2, 0.02), "isik_mavi", false, Vector3(-0.5, 0, 0))
	refs["reader_screen"] = screen
	var rl := omni(rd, Vector3(0, 1.4, -0.3), Color(0.35, 0.8, 1.0), 0.6, 1.6)
	refs["reader_light"] = rl
	var target := Node3D.new()
	target.name = "OkutmaNoktasi"
	rd.add_child(target)
	target.position = Vector3(0, 1.22, -0.16)
	refs["reader_point"] = target
	var info := label(rd, Vector3(-0.2, 2.25, 0), "", 34, Color(0.5, 1.0, 0.65), PI)
	refs["reader_text"] = info
	# Görevli masası
	box(z1, Vector3(11.4, 0.5, 8.9), Vector3(1.6, 1.0, 0.6), "beyaz", true)
	box(z1, Vector3(11.4, 1.02, 8.9), Vector3(1.7, 0.04, 0.7), "koyu", false)
	box(z1, Vector3(11.4, 1.3, 9.1), Vector3(0.6, 0.4, 0.03), "ekran", false, Vector3(-0.3, 0, 0))


static func _build_terminal_props(z1: Node3D, refs: Dictionary) -> void:
	# Biniş bilgi ekranı (sağ duvar)
	var scr := box(z1, Vector3(17.45, 2.3, 4.5), Vector3(0.04, 1.6, 3.2), "ekran", false)
	label(z1, Vector3(17.4, 2.75, 4.5), "EMANET — YOLCU BİNİŞİ", 52, Color(0.6, 0.9, 1.0), -PI / 2)
	var lines := "GEÇİT B   ●  AÇIK\nYOLCU  412 / 500\nKALKIŞ  T-00:52\nHEDEF  VAAT (Tau Ceti)"
	label(z1, Vector3(17.4, 2.05, 4.5), lines, 34, Color(0.5, 1.0, 0.7), -PI / 2)
	refs["info_screen"] = scr
	# Kuyruk direkleri (oyuncunun arkasında bekleyenler)
	for z in [-0.6, 1.4]:
		for x in [6.6, 9.4]:
			cyl(z1, Vector3(x, 0.5, z), 0.04, 0.06, 1.0, "gri", true)
		box(z1, Vector3(8.0, 0.92, z), Vector3(2.8, 0.06, 0.02), "kirmizi_serit", false)
	# Banklar ve bavullar
	box(z1, Vector3(15.6, 0.25, 0.6), Vector3(2.4, 0.5, 0.6), "lacivert", true)
	box(z1, Vector3(15.6, 0.5, 0.35), Vector3(2.4, 0.5, 0.1), "lacivert", false)
	kit(z1, "S_PropCrate3", Vector3(16.6, 0.5, 8.4), 0.3)
	kit(z1, "S_PropCrate4", Vector3(15.2, 0.56, 8.7), -0.2)
	kit(z1, "S_PropComputer", Vector3(1.0, 0, -1.0), PI)


## Halka Meydanı: hologram, ağaçlar, askılı bahçe, anı duvarı, galeri.
static func _build_atrium(z1: Node3D, refs: Dictionary) -> void:
	# Ortada dönen gemi hologramı
	kit(z1, "S_PlatformRound1", Vector3(8, 0.01, 20))
	var holo := Node3D.new()
	holo.name = "GemiHolo"
	holo.position = Vector3(8, 2.4, 20)
	z1.add_child(holo)
	var hull := cyl(holo, Vector3.ZERO, 0.16, 0.2, 3.2, "holo")
	hull.rotation = Vector3(0, 0, PI / 2)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.55
	tm.outer_radius = 0.66
	tm.rings = 24
	tm.ring_segments = 8
	ring.mesh = tm
	ring.material_override = mat("holo")
	ring.rotation = Vector3(0, 0, PI / 2)
	holo.add_child(ring)
	var engine := cyl(holo, Vector3(-1.75, 0, 0), 0.22, 0.38, 0.4, "holo")
	engine.rotation = Vector3(0, 0, PI / 2)
	for s in [-1.0, 1.0]:
		var sail := box(holo, Vector3(1.4, 0, s * 0.5), Vector3(0.9, 0.02, 0.7), "holo", false)
		sail.rotation = Vector3(s * 0.4, 0, 0)
	refs["ship_holo"] = holo
	cyl(z1, Vector3(8, 1.2, 20), 1.0, 1.0, 2.4, "holo_soluk")
	label(z1, Vector3(8, 4.0, 20), "EMANET", 72, Color(0.6, 0.9, 1.0)).billboard = BaseMaterial3D.BILLBOARD_ENABLED
	omni(z1, Vector3(8, 2.4, 20), Color(0.3, 0.75, 1.0), 1.2, 5.0)
	# Ağaçlar
	for p in [Vector3(3, 0, 14), Vector3(13, 0, 14), Vector3(3, 0, 25.5), Vector3(13, 0, 25.5)]:
		_tree(z1, p)
	# Askılı bahçe (sağ duvar)
	for row in 3:
		var y := 0.3 + row * 1.05
		box(z1, Vector3(17.55, y, 17.0), Vector3(0.7, 0.35, 4.6), "beyaz", row == 0)
		box(z1, Vector3(17.55, y + 0.2, 17.0), Vector3(0.62, 0.06, 4.5), "toprak", false)
		for i in 9:
			var z := 15.0 + i * 0.5
			ball(z1, Vector3(17.5, y + 0.42, z), 0.2 + 0.05 * float((i + row) % 3), "yaprak" if (i + row) % 2 == 0 else "yaprak2")
			if (i * 3 + row) % 4 == 0:
				ball(z1, Vector3(17.3, y + 0.36, z + 0.1), 0.05, "domates")
	label(z1, Vector3(17.15, 0.36, 17.0), "YEŞİL KUBBE'DEN ÖRNEKTİR — KOPARMAYINIZ", 22, Color(0.2, 0.3, 0.2), -PI / 2, 0.003)
	# Anı duvarı: notlarla dolu ışıklı cam
	box(z1, Vector3(17.85, 1.65, 24.2), Vector3(0.05, 2.3, 5.4), "holo_soluk", false)
	var notes := ["Anneme:\nSeni yanımda\ngötürüyorum.", "Kardeşime:\nÖzür dilerim.\nBilet tekti.", "Bizi\nunutmayın.", "Bahar 2526\nİzmir", "Babam\nher gece\nyıldızlara bakardı.",
		"Ayşe + Kerem", "Dönmeyeceğim.\nAma unutmayacağım.", "Gidemeyenler için.", "Su kuyusunun\nbaşındaki\nkızlara", "Seni seviyorum\nMarco"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 412
	for i in notes.size():
		var col := i % 5
		var rowi := i / 5
		var p := Vector3(17.8, 2.3 - rowi * 1.0 + rng.randf_range(-0.15, 0.15), 22.0 + col * 1.05 + rng.randf_range(-0.1, 0.1))
		label(z1, p, notes[i], 26, Color(0.75, 0.92, 1.0, 0.95), -PI / 2, 0.0028)
	label(z1, Vector3(17.8, 3.15, 24.2), "ANI DUVARI — DÜNYA'DA BIRAKTIKLARIMIZ", 34, Color(0.8, 0.95, 1.0), -PI / 2, 0.0035)
	refs["memorial_point"] = _marker(z1, Vector3(17.75, 1.25, 25.6))
	# Pencere önü banklar
	for z in [16.0, 23.0]:
		box(z1, Vector3(0.2, 0.22, z), Vector3(0.55, 0.44, 2.2), "ahsap", true)
	# Galeri (5 m yükseklikte, sağ duvar boyunca)
	for cz in range(3, 8):
		kit(z1, "S_PlatformMetal2", Vector3(16, 5, cz * 4.0))
		kit(z1, "S_PropRail_4", Vector3(14.05, 5, cz * 4.0 + 2.0))
	box(z1, Vector3(16, 4.92, 20), Vector3(4, 0.14, 20), "beyaz", false)
	for z in [13.0, 19.0, 25.0]:
		box(z1, Vector3(16, 4.86, z), Vector3(3.2, 0.03, 0.5), "isik_sicak", false)


static func _tree(parent: Node3D, p: Vector3) -> void:
	cyl(parent, p + Vector3(0, 0.35, 0), 0.95, 0.85, 0.7, "beyaz", true)
	cyl(parent, p + Vector3(0, 0.71, 0), 0.88, 0.88, 0.04, "toprak")
	cyl(parent, p + Vector3(0, 1.8, 0), 0.09, 0.14, 2.2, "govde")
	ball(parent, p + Vector3(0, 3.1, 0), 1.0, "yaprak")
	ball(parent, p + Vector3(0.55, 2.7, 0.3), 0.7, "yaprak2")
	ball(parent, p + Vector3(-0.5, 2.8, -0.35), 0.72, "yaprak")
	ball(parent, p + Vector3(0.1, 3.7, -0.2), 0.6, "yaprak2")


static func _marker(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


## Cam tüp içinde yükselen asansör kabini.
static func _build_elevator(z1: Node3D, refs: Dictionary) -> void:
	var base := Vector3(8, 0, 27.6)
	var tube := cyl(z1, base + Vector3(0, 5, 0), 1.22, 1.22, 10.0, "cam", false, 24)
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Tüpün çarpışması (binerken kapatılır)
	var wall := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.25
	sh.height = 10.0
	cs.shape = sh
	wall.add_child(cs)
	wall.position = base + Vector3(0, 5, 0)
	z1.add_child(wall)
	refs["tube_collision"] = cs
	for y in [0.02, 10.0]:
		cyl(z1, base + Vector3(0, y, 0), 1.32, 1.32, 0.12, "koyu")
	# Kabin
	var cab := Node3D.new()
	cab.name = "AsansorKabini"
	cab.position = base
	z1.add_child(cab)
	cyl(cab, Vector3(0, 0.03, 0), 1.12, 1.12, 0.06, "zemin")
	cyl(cab, Vector3(0, 2.7, 0), 1.12, 1.12, 0.12, "beyaz")
	cyl(cab, Vector3(0, 2.62, 0), 0.9, 0.9, 0.02, "isik_sicak")
	var rail := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.0
	tm.outer_radius = 1.05
	tm.rings = 24
	tm.ring_segments = 6
	rail.mesh = tm
	rail.material_override = mat("gri")
	rail.position = Vector3(0, 1.0, 0)
	cab.add_child(rail)
	omni(cab, Vector3(0, 2.3, 0), Color(1.0, 0.92, 0.8), 0.9, 4.0)
	var door := box(cab, Vector3(0, 1.3, -1.12), Vector3(1.3, 2.5, 0.03), "cam", false)
	door.position.x = 1.35  # açık
	refs["cab_door"] = door
	refs["cab"] = cab
	# Kat göstergesi
	refs["cab_display"] = label(cab, Vector3(0, 2.4, 1.0), "G1", 64, Color(0.5, 1.0, 0.7), PI, 0.004)
	# Çağırma paneli
	var panel := Node3D.new()
	panel.position = Vector3(5.9, 0, 26.6)
	z1.add_child(panel)
	box(panel, Vector3(0, 0.6, 0), Vector3(0.3, 1.2, 0.3), "beyaz", true)
	box(panel, Vector3(0, 1.22, -0.1), Vector3(0.2, 0.2, 0.06), "isik_mavi", false)
	label(z1, Vector3(8, 3.4, 26.25), "ASANSÖR — GÜVERTE 1–9", 48, Color(0.7, 0.92, 1.0), PI)


# =============================================================================
# Bölge 2: Güverte 8 koridoru + Kamara 412
# =============================================================================

static func build_zone2(root: Node3D) -> Dictionary:
	var refs := {}
	var z2 := Node3D.new()
	z2.name = "Bolge2"
	z2.position = ZONE2
	root.add_child(z2)
	refs["root"] = z2
	_build_corridor(z2, refs)
	_build_cabin(z2, refs)
	# Pencereden görünen dış dünya: 8. güverte yerden ~60 m yukarıda; kalkışta aşağı kayıp gider
	var out := Node3D.new()
	out.name = "Disari"
	z2.add_child(out)
	refs["outside"] = out
	_ground(out, Vector3(300, -60, 7), 3000.0)
	for i in 4:
		_tower(out, Vector3(170 + i * 70, -60, -120 + i * 80), 70.0 + (i % 2) * 20.0)
	_skyline(out, Vector3(700, -60, 7), 900.0, 18)
	# Dünya (kalkıştan sonra görünür)
	var e := earth(z2, Vector3(350, -388, 7), 400.0)
	e.visible = false
	refs["earth"] = e
	return refs


static func _build_corridor(z2: Node3D, refs: Dictionary) -> void:
	# Koridor x: -1.6..1.6, z: -1..22, tavan 3 m
	box(z2, Vector3(0, -0.1, 10.5), Vector3(3.2, 0.2, 23), "zemin", true)
	box(z2, Vector3(0, 3.1, 10.5), Vector3(3.6, 0.2, 23.4), "beyaz", true)
	box(z2, Vector3(0, 2.98, 10.5), Vector3(0.5, 0.03, 22), "isik_sicak", false)
	for x in [-1.55, 1.55]:
		box(z2, Vector3(x, 0.03, 10.5), Vector3(0.05, 0.04, 23), "isik_mavi", false)
	# Sol duvar (tek sayılar)
	box(z2, Vector3(-1.7, 1.5, 10.5), Vector3(0.2, 3.0, 23), "beyaz", true)
	# Sağ duvar (çift sayılar): 412'nin kapısı açık geçit
	box(z2, Vector3(1.7, 1.5, 2.7), Vector3(0.2, 3.0, 7.4), "beyaz", true)
	box(z2, Vector3(1.7, 1.5, 14.8), Vector3(0.2, 3.0, 14.4), "beyaz", true)
	box(z2, Vector3(1.7, 2.6, 7.0), Vector3(0.2, 0.8, 1.2), "beyaz", true)
	# Uç duvarlar
	box(z2, Vector3(0, 1.5, -1.1), Vector3(3.2, 3.0, 0.2), "krem", true)
	box(z2, Vector3(0, 1.5, 22.1), Vector3(3.2, 3.0, 0.2), "krem", true)
	label(z2, Vector3(0, 2.0, 21.98), "GÜVERTE 8\nKUZEY KANADI", 64, Color(0.3, 0.45, 0.6), PI)
	# Asansör kapısı (gelinen yer)
	box(z2, Vector3(0, 1.25, -0.98), Vector3(1.4, 2.5, 0.04), "cam", false)
	box(z2, Vector3(0, 2.6, -0.97), Vector3(1.6, 0.1, 0.05), "isik_mavi", false)
	label(z2, Vector3(0, 2.8, -0.95), "ASANSÖR", 40, Color(0.5, 0.75, 0.95))
	# Kapılar
	for i in 5:
		var z := 3.0 + i * 4.0
		_cabin_door(z2, Vector3(-1.58, 0, z), 409 + i * 2, PI / 2)
		if 410 + i * 2 != 412:
			_cabin_door(z2, Vector3(1.58, 0, z), 410 + i * 2, -PI / 2)
	label(z2, Vector3(-1.58, 1.95, 7.0), "B. DEMİR — MAKİNE", 26, Color(0.25, 0.3, 0.4), PI / 2, 0.003)
	# 412: gerçek kayar kapı
	var door := box(z2, Vector3(1.7, 1.1, 7.0), Vector3(0.08, 2.2, 1.2), "lacivert", true)
	refs["cabin_door"] = door
	label(z2, Vector3(1.58, 2.45, 7.0), "412", 64, Color(0.2, 0.3, 0.45), -PI / 2)
	var panel := box(z2, Vector3(1.56, 1.25, 6.05), Vector3(0.04, 0.22, 0.14), "isik_mavi", false)
	refs["door_panel"] = panel
	var pt := Node3D.new()
	pt.position = Vector3(1.5, 1.25, 6.05)
	z2.add_child(pt)
	refs["door_panel_point"] = pt
	# Tabela
	box(z2, Vector3(-1.58, 1.6, 0.9), Vector3(0.03, 0.9, 1.3), "ekran", false)
	label(z2, Vector3(-1.56, 1.6, 0.9), "GÜVERTE 8\nKAMARALAR 401–440\n\nYEMEKHANE  G6\nTIP MERKEZİ  G3", 30, Color(0.6, 0.9, 1.0), PI / 2, 0.0028)
	for z in [2.0, 10.0, 18.0]:
		omni(z2, Vector3(0, 2.6, z), Color(1.0, 0.95, 0.88), 0.8, 6.0)


static func _cabin_door(parent: Node3D, pos: Vector3, number: int, yaw: float) -> void:
	var side := 1.0 if pos.x < 0 else -1.0
	var d := box(parent, pos + Vector3(0, 1.1, 0), Vector3(0.05, 2.2, 1.2), "gri", false)
	d.position.x += side * 0.01
	label(parent, pos + Vector3(side * 0.03, 2.45, 0), str(number), 64, Color(0.2, 0.3, 0.45), yaw)
	box(parent, pos + Vector3(side * 0.03, 1.25, -0.95), Vector3(0.03, 0.18, 0.12), "isik_yesil", false)


## Kamara 412: x 1.6..7.6, z 5..9 (bölge koordinatı). Pencere +X duvarında.
static func _build_cabin(z2: Node3D, refs: Dictionary) -> void:
	var c := Node3D.new()
	c.name = "Kamara412"
	z2.add_child(c)
	refs["cabin"] = c
	box(c, Vector3(4.6, -0.1, 7), Vector3(6, 0.2, 4), "ahsap", true)
	box(c, Vector3(4.6, 2.9, 7), Vector3(6.4, 0.2, 4.4), "beyaz", true)
	box(c, Vector3(4.6, 1.4, 4.9), Vector3(6, 2.8, 0.2), "krem", true)
	box(c, Vector3(4.6, 1.4, 9.1), Vector3(6, 2.8, 0.2), "krem", true)
	# Pencere duvarı
	box(c, Vector3(7.7, 0.4, 7), Vector3(0.2, 0.8, 4), "krem", true)
	box(c, Vector3(7.7, 2.6, 7), Vector3(0.2, 0.4, 4), "krem", true)
	box(c, Vector3(7.7, 1.6, 5.4), Vector3(0.2, 1.6, 0.8), "krem", true)
	box(c, Vector3(7.7, 1.6, 8.6), Vector3(0.2, 1.6, 0.8), "krem", true)
	box(c, Vector3(7.72, 1.6, 7), Vector3(0.03, 1.6, 2.4), "cam", true)
	box(c, Vector3(7.6, 0.79, 7), Vector3(0.12, 0.03, 2.5), "isik_sicak", false)
	# Tavan kenarı gizli ışık şeritleri
	var strips: Array[MeshInstance3D] = []
	for z in [5.05, 8.95]:
		strips.append(box(c, Vector3(4.6, 2.76, z), Vector3(5.8, 0.03, 0.05), "isik_sicak", false))
	refs["strips"] = strips
	var lights: Array[OmniLight3D] = []
	lights.append(omni(c, Vector3(3.2, 2.4, 7), Color(1.0, 0.86, 0.7), 0.9, 5.0))
	lights.append(omni(c, Vector3(6.0, 2.4, 7), Color(1.0, 0.86, 0.7), 0.9, 5.0))
	lights.append(omni(c, Vector3(7.2, 1.6, 7), Color(0.5, 0.7, 1.0), 0.6, 4.0))
	refs["cabin_lights"] = lights

	# Yatak (sol duvar boyunca)
	box(c, Vector3(4.4, 0.2, 8.45), Vector3(2.0, 0.4, 1.0), "koyu", true)
	box(c, Vector3(4.4, 0.5, 8.45), Vector3(1.95, 0.2, 0.95), "beyaz", false)
	box(c, Vector3(5.2, 0.66, 8.45), Vector3(0.35, 0.12, 0.7), "krem", false)
	box(c, Vector3(3.75, 0.64, 8.45), Vector3(0.45, 0.08, 0.9), "lacivert", false)
	box(c, Vector3(3.75, 0.69, 8.3), Vector3(0.12, 0.005, 0.09), "krem", false)
	# Dolap (kapının yanında)
	box(c, Vector3(2.15, 1.0, 8.6), Vector3(0.9, 2.0, 0.7), "beyaz", true)
	box(c, Vector3(2.15, 1.0, 8.24), Vector3(0.02, 1.9, 0.01), "gri", false)
	# Kalkış saati (yatağın üstünde)
	box(c, Vector3(4.4, 2.0, 8.98), Vector3(1.0, 0.32, 0.02), "ekran", false)
	refs["clock"] = label(c, Vector3(4.4, 2.0, 8.96), "KALKIŞ  T-00:40:00", 30, Color(0.5, 1.0, 0.7), PI, 0.0028)

	# Masa ve terminal (sağ duvar)
	box(c, Vector3(5.2, 0.73, 5.35), Vector3(1.6, 0.05, 0.6), "beyaz", true)
	box(c, Vector3(5.2, 0.4, 5.1), Vector3(1.4, 0.66, 0.08), "gri", false)
	cyl(c, Vector3(5.2, 0.23, 6.05), 0.2, 0.16, 0.46, "lacivert", true)
	var term := box(c, Vector3(5.2, 1.4, 5.04), Vector3(0.9, 0.55, 0.02), "ekran", false)
	refs["terminal"] = term
	refs["terminal_text"] = label(c, Vector3(5.2, 1.42, 5.06), "● KALKIŞ SABAHI DİNLE\n— D.A.", 26, Color(1.0, 0.75, 0.35), 0.0, 0.0028)
	refs["terminal_point"] = _marker(c, Vector3(5.0, 0.8, 5.5))
	refs["desk_spot"] = _marker(c, Vector3(4.75, 0.76, 5.4))
	refs["holo_spot"] = _marker(c, Vector3(5.2, 0.76, 5.45))

	# Alet çantası (pencere köşesi, yerde)
	var tool := Node3D.new()
	tool.position = Vector3(6.9, 0, 5.45)
	c.add_child(tool)
	box(tool, Vector3(0, 0.07, 0), Vector3(0.6, 0.14, 0.4), "koyu", true)
	box(tool, Vector3(0, 0.145, 0), Vector3(0.56, 0.01, 0.36), "gri", false)
	for i in 3:
		cyl(tool, Vector3(-0.2 + i * 0.07, 0.16, -0.08), 0.015, 0.015, 0.02, "turuncu")
	box(tool, Vector3(0.08, 0.152, 0.07), Vector3(0.3, 0.005, 0.07), "koyu", false)
	refs["tool_slot"] = _marker(tool, Vector3(0.08, 0.17, 0.07))
	var lid := box(tool, Vector3(0, 0.32, -0.21), Vector3(0.6, 0.36, 0.03), "koyu", false)
	lid.rotation = Vector3(-0.25, 0, 0)

	# Deniz'in eşya kutusu (yatağın ayak ucu, pencere köşesi)
	var crate := Node3D.new()
	crate.position = Vector3(6.4, 0, 8.4)
	c.add_child(crate)
	box(crate, Vector3(0, 0.225, 0), Vector3(0.7, 0.45, 0.5), "haki", true)
	label(crate, Vector3(-0.351, 0.25, 0), "D. ARMAN — 412", 28, Color(0.1, 0.1, 0.08), -PI / 2, 0.0028)
	box(crate, Vector3(0, 0.44, 0), Vector3(0.62, 0.02, 0.42), "turuncu", false)
	var hinge := Node3D.new()
	hinge.position = Vector3(0, 0.45, 0.25)
	crate.add_child(hinge)
	box(hinge, Vector3(0, 0.03, -0.25), Vector3(0.72, 0.06, 0.52), "haki", false)
	refs["crate_lid"] = hinge
	refs["crate_inside"] = _marker(crate, Vector3(0.05, 0.47, -0.05))

	# Erzak bölmesi (sağ duvar, kapının yanında)
	var ration := Node3D.new()
	ration.position = Vector3(2.7, 1.25, 5.15)
	c.add_child(ration)
	box(ration, Vector3(0, 0, 0), Vector3(0.62, 0.62, 0.3), "beyaz", true)
	box(ration, Vector3(0, 0, 0.13), Vector3(0.52, 0.52, 0.06), "koyu", false)
	var rdoor := box(ration, Vector3(0, 0, 0.165), Vector3(0.54, 0.54, 0.02), "gri", false)
	refs["ration_door"] = rdoor
	label(ration, Vector3(0, 0.38, 0.152), "ERZAK", 30, Color(0.2, 0.3, 0.4), 0.0, 0.003)
	var pkg := box(ration, Vector3(0, -0.05, 0.12), Vector3(0.32, 0.2, 0.2), "turuncu", false)
	label(pkg, Vector3(0, 0.0, 0.101), "TAHSİSAT\n412", 26, Color(1, 1, 1), 0.0, 0.0025)
	pkg.visible = false
	refs["ration_pkg"] = pkg
	box(ration, Vector3(0.24, -0.24, 0.17), Vector3(0.04, 0.04, 0.01), "isik_yesil", false)

	# Kalkış koltuğu: zemindeki kapağın altında saklı, anonsla yükselir
	var hatch := box(c, Vector3(5.0, 0.005, 7.0), Vector3(1.2, 0.012, 1.0), "koyu", false)
	refs["hatch"] = hatch
	var seat := Node3D.new()
	seat.name = "KalkisKoltugu"
	seat.position = Vector3(5.0, -1.4, 7.0)
	c.add_child(seat)
	refs["seat"] = seat
	cyl(seat, Vector3(0, 0.18, 0), 0.22, 0.3, 0.36, "gri")
	box(seat, Vector3(0, 0.42, 0), Vector3(0.56, 0.14, 0.62), "lacivert", false)
	var back := box(seat, Vector3(-0.32, 0.92, 0), Vector3(0.14, 0.95, 0.6), "lacivert", false)
	back.rotation = Vector3(0, 0, -0.28)
	box(seat, Vector3(-0.47, 1.45, 0), Vector3(0.14, 0.24, 0.34), "lacivert", false, Vector3(0, 0, -0.28))
	for s in [-1.0, 1.0]:
		box(seat, Vector3(0.0, 0.62, s * 0.35), Vector3(0.56, 0.07, 0.09), "koyu", false)
		box(seat, Vector3(0.24, 0.64, s * 0.35), Vector3(0.08, 0.04, 0.1), "turuncu", false)
	var grips: Array[Node3D] = []
	for s in [-1.0, 1.0]:
		grips.append(_marker(seat, Vector3(0.2, 0.68, s * 0.33)))
	refs["seat_grips"] = grips
	# Kemerler: omuz üstünden iner (başta yukarıda)
	var belts: Array[Node3D] = []
	for s in [-1.0, 1.0]:
		var piv := Node3D.new()
		piv.position = Vector3(-0.42, 1.36, s * 0.16)
		seat.add_child(piv)
		var strap := box(piv, Vector3(0.28, 0, 0), Vector3(0.56, 0.06, 0.08), "turuncu", false)
		strap.position = Vector3(0.28, 0, 0)
		piv.rotation = Vector3(0, 0, 1.2)  # yukarı kalkık
		belts.append(piv)
	refs["belts"] = belts
	var seat_body := StaticBody3D.new()
	var scs := CollisionShape3D.new()
	var ssh := BoxShape3D.new()
	ssh.size = Vector3(0.9, 1.2, 0.8)
	scs.shape = ssh
	scs.position = Vector3(-0.1, 0.6, 0)
	scs.disabled = true
	seat_body.add_child(scs)
	seat.add_child(seat_body)
	refs["seat_collision"] = scs
	refs["seat_point"] = _marker(seat, Vector3(-0.02, 0.0, 0))


# --- Dış dünya: uzay limanı ------------------------------------------------------

static func _ground(parent: Node3D, pos: Vector3, size: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(size, size)
	mi.mesh = pm
	mi.material_override = mat("yer")
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	# Pist çizgileri
	for i in 6:
		box(parent, pos + Vector3(-size * 0.1 + i * 60.0, 0.05, 0), Vector3(3, 0.05, size * 0.6), "isik_sicak", false)
	return mi


## Fırlatma kulesi: kafes gövde, kırmızı uyarı ışığı.
static func _tower(parent: Node3D, base: Vector3, h: float) -> Node3D:
	var t := Node3D.new()
	t.position = base
	parent.add_child(t)
	box(t, Vector3(0, h / 2.0, 0), Vector3(6, h, 6), "koyu", false)
	for k in int(h / 12.0):
		box(t, Vector3(0, 6 + k * 12.0, 0), Vector3(6.6, 0.6, 6.6), "gri", false)
	box(t, Vector3(0, h + 0.6, 0), Vector3(1.2, 1.2, 1.2), "isik_kirmizi", false)
	return t


## Ufuktaki şehir: kararmış kuleler, yer yer yangın ışığı.
static func _skyline(parent: Node3D, center: Vector3, radius: float, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2526
	for i in count:
		var a := rng.randf_range(-0.9, 0.9)
		var p := center + Vector3(cos(a) * radius * 0.3, 0, sin(a) * radius)
		var h := rng.randf_range(40.0, 140.0)
		box(parent, p + Vector3(0, h / 2.0, 0), Vector3(rng.randf_range(20, 50), h, rng.randf_range(20, 50)), "sehir", false)
		if i % 4 == 0:
			box(parent, p + Vector3(0, h * 0.3, 0), Vector3(14, 8, 14), "yangin", false)


## İskele dışı: terminalin camından EMANET'in dev gövdesi, kuleler, pist.
static func _build_spaceport(z1: Node3D, refs: Dictionary) -> void:
	var out := Node3D.new()
	out.name = "Liman"
	z1.add_child(out)
	_ground(out, Vector3(-200, -0.6, 10), 2400.0)
	# EMANET: pencerenin ötesinde yatan bir kilometrelik gövde
	var hull := Node3D.new()
	hull.position = Vector3(-95, 38, -290)
	out.add_child(hull)
	var body := cyl(hull, Vector3.ZERO, 34, 34, 560, "beyaz", false, 32)
	body.rotation = Vector3(PI / 2, 0, 0)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 52
	tm.outer_radius = 62
	tm.rings = 48
	tm.ring_segments = 12
	ring.mesh = tm
	ring.material_override = mat("gri")
	ring.rotation = Vector3(PI / 2, 0, 0)
	ring.position = Vector3(0, 0, 60)
	hull.add_child(ring)
	for k in 9:
		box(hull, Vector3(34.5, 0, -240 + k * 60.0), Vector3(1, 3, 18), "isik_mavi", false)
	label(hull, Vector3(34.8, 8, 120), "EMANET", 420, Color(0.25, 0.3, 0.4), PI / 2, 0.06)
	# Gövdeyi taşıyan beşik ve kuleler
	for k in 4:
		box(out, Vector3(-90, 2, -440 + k * 120.0), Vector3(50, 6, 16), "koyu", false)
	for i in 4:
		_tower(out, Vector3(-40 - i * 8, -0.6, -60 - i * 80.0), 90.0)
	_skyline(out, Vector3(-900, -0.6, 10), 900.0, 20)
	refs["spaceport"] = out


# =============================================================================
# Bölge 3: Köprü (uçuş ekibi)
# =============================================================================

static func build_bridge(root: Node3D) -> Dictionary:
	var refs := {}
	var b := Node3D.new()
	b.name = "Kopru"
	b.position = ZONE3
	root.add_child(b)
	refs["root"] = b
	# Oda: x -5..5, z -4..4, ön cam +Z yönünde
	box(b, Vector3(0, -0.1, 0), Vector3(10, 0.2, 8), "koyu", true)
	box(b, Vector3(0, 3.4, 0), Vector3(10, 0.2, 8), "gri", true)
	box(b, Vector3(-5.1, 1.7, 0), Vector3(0.2, 3.4, 8), "lacivert", true)
	box(b, Vector3(5.1, 1.7, 0), Vector3(0.2, 3.4, 8), "lacivert", true)
	box(b, Vector3(0, 1.7, -4.1), Vector3(10, 3.4, 0.2), "lacivert", true)
	box(b, Vector3(0, 0.45, 4.1), Vector3(10, 0.9, 0.2), "koyu", true)
	box(b, Vector3(0, 3.15, 4.1), Vector3(10, 0.5, 0.2), "koyu", true)
	box(b, Vector3(0, 1.9, 4.12), Vector3(10, 2.0, 0.04), "cam", true)
	box(b, Vector3(0, 3.28, 0), Vector3(6, 0.03, 0.4), "isik_mavi", false)
	# Konsollar ve ekranlar
	for x in [-2.6, 0.0, 2.6]:
		box(b, Vector3(x, 0.5, 2.6), Vector3(1.8, 1.0, 0.7), "gri", true)
		box(b, Vector3(x, 1.25, 2.85), Vector3(1.6, 0.6, 0.04), "ekran", false, Vector3(-0.35, 0, 0))
		box(b, Vector3(x, 1.02, 2.45), Vector3(1.6, 0.03, 0.4), "isik_mavi", false)
	refs["screen_text"] = label(b, Vector3(0, 1.3, 2.82), "FÜZYON ÇEKİRDEĞİ  %100\nKULE BAĞLANTISI  AYRILDI\nYÖRÜNGE  T-00:01:00", 34, Color(0.5, 1.0, 0.7), PI, 0.003)
	# Koltuklar
	for x in [-2.6, 2.6]:
		box(b, Vector3(x, 0.45, 1.75), Vector3(0.6, 0.12, 0.6), "lacivert", false)
		box(b, Vector3(x, 0.9, 1.45), Vector3(0.6, 0.8, 0.12), "lacivert", false, Vector3(-0.15, 0, 0))
	omni(b, Vector3(0, 2.8, 0), Color(0.7, 0.85, 1.0), 1.0, 9.0)
	omni(b, Vector3(0, 1.4, 2.6), Color(0.3, 0.8, 1.0), 0.8, 4.0)
	# Camdan görünen liman (kalkışta aşağı kayar)
	var out := Node3D.new()
	out.name = "Disari"
	b.add_child(out)
	refs["outside"] = out
	_ground(out, Vector3(0, -70, 600), 3000.0)
	for i in 4:
		_tower(out, Vector3(-60 + i * 40, -70, 80 + i * 25), 80.0)
	_skyline(out, Vector3(0, -70, 900), 900.0, 16)
	return refs


# =============================================================================
# Bölge 4: Dış çekim — limandaki EMANET, ateşleme
# =============================================================================

static func build_exterior(root: Node3D) -> Dictionary:
	var refs := {}
	var x := Node3D.new()
	x.name = "DisCekim"
	x.position = ZONE4
	root.add_child(x)
	refs["root"] = x
	_ground(x, Vector3(0, 0, 0), 4000.0)
	var ship := Node3D.new()
	ship.position = Vector3(0, 40, 0)
	x.add_child(ship)
	refs["ship"] = ship
	var body := cyl(ship, Vector3.ZERO, 34, 34, 560, "beyaz", false, 32)
	body.rotation = Vector3(PI / 2, 0, 0)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 52
	tm.outer_radius = 62
	tm.rings = 48
	tm.ring_segments = 12
	ring.mesh = tm
	ring.material_override = mat("gri")
	ring.rotation = Vector3(PI / 2, 0, 0)
	ring.position = Vector3(0, 0, 60)
	ship.add_child(ring)
	for k in 9:
		box(ship, Vector3(34.5, 0, -240 + k * 60.0), Vector3(1, 3, 18), "isik_mavi", false)
	# Alt yüzeydeki füzyon iticileri ve alevler (ateşlemede büyür)
	var flames: Array[MeshInstance3D] = []
	for k in 4:
		var z := -180 + k * 120.0
		cyl(ship, Vector3(0, -36, z), 10, 14, 8, "koyu")
		var f := cyl(ship, Vector3(0, -36 - 30, z), 12, 2, 60, "alev", false)
		f.rotation = Vector3(PI, 0, 0)
		f.scale = Vector3(0.05, 0.05, 0.05)
		flames.append(f)
	refs["flames"] = flames
	var glow := omni(ship, Vector3(0, -60, 0), Color(0.5, 0.75, 1.0), 0.0, 400.0)
	refs["flame_light"] = glow
	# Beşik ve kuleler
	for k in 4:
		box(x, Vector3(0, 3, -180 + k * 120.0), Vector3(60, 6, 16), "koyu", false)
	for i in 5:
		_tower(x, Vector3(70, 0, -240 + i * 120.0), 110.0)
	_skyline(x, Vector3(-1200, 0, 0), 1200.0, 22)
	return refs



## Görünmez çarpışma kutusu.
static func _col(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	parent.add_child(body)
