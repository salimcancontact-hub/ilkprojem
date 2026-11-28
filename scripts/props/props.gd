class_name Props
extends RefCounted
## Hikâyede elde tutulan küçük nesneler (kodla üretilir).


static func _mat(color: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m


## EMANET kimlik kartı: mavi parlayan ince bir kart.
static func card() -> Node3D:
	var root := Node3D.new()
	root.name = "Kart"
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.11, 0.008, 0.07)
	mi.mesh = box
	mi.material_override = _mat(Color(0.3, 0.7, 1.0), Color(0.3, 0.75, 1.0), 6.0)
	root.add_child(mi)
	var l := OmniLight3D.new()
	l.light_color = Color(0.3, 0.7, 1.0)
	l.light_energy = 1.0
	l.omni_range = 1.3
	root.add_child(l)
	return root


## Yarısı dolu plastik su şişesi.
static func water_bottle() -> Node3D:
	var root := Node3D.new()
	root.name = "SuSisesi"
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.036
	cyl.bottom_radius = 0.04
	cyl.height = 0.24
	body.mesh = cyl
	var m := _mat(Color(0.6, 0.8, 0.95, 1.0))
	m.metallic = 0.2
	m.roughness = 0.2
	body.material_override = m
	root.add_child(body)
	var cap := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.015
	c.bottom_radius = 0.015
	c.height = 0.03
	cap.mesh = c
	cap.position = Vector3(0, 0.125, 0)
	cap.material_override = _mat(Color(0.2, 0.4, 0.9))
	root.add_child(cap)
	return root


## Enerji barı: ezik ambalajlı küçük bir kalıp.
static func energy_bar() -> Node3D:
	var root := Node3D.new()
	root.name = "EnerjiBari"
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.14, 0.028, 0.05)
	mi.mesh = box
	mi.material_override = _mat(Color(0.95, 0.45, 0.12), Color(0.5, 0.18, 0.04), 0.6)
	root.add_child(mi)
	# Ambalaj şeridi: elde seçilsin
	var band := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(0.04, 0.03, 0.052)
	band.mesh = bb
	band.material_override = _mat(Color(0.95, 0.92, 0.85))
	band.position = Vector3(0.03, 0, 0)
	root.add_child(band)
	return root


## Şok copu: siyah sap, mavi uç.
static func baton() -> Node3D:
	var root := Node3D.new()
	root.name = "Cop"
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.028
	c.bottom_radius = 0.032
	c.height = 0.6
	mi.mesh = c
	mi.position = Vector3(0, 0.2, 0)
	mi.material_override = _mat(Color(0.08, 0.08, 0.09))
	root.add_child(mi)
	var tip := MeshInstance3D.new()
	var s := CylinderMesh.new()
	s.top_radius = 0.03
	s.bottom_radius = 0.03
	s.height = 0.08
	tip.mesh = s
	tip.position = Vector3(0, 0.52, 0)
	tip.material_override = _mat(Color(0.4, 0.7, 1.0), Color(0.4, 0.75, 1.0), 4.0)
	root.add_child(tip)
	return root


## Telefon: ince, ekranı mavi parlayan.
static func phone() -> Node3D:
	var root := Node3D.new()
	root.name = "Telefon"
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.075, 0.15, 0.01)
	body.mesh = box
	body.material_override = _mat(Color(0.08, 0.08, 0.1))
	root.add_child(body)
	var screen := MeshInstance3D.new()
	var q := BoxMesh.new()
	q.size = Vector3(0.066, 0.135, 0.002)
	screen.mesh = q
	screen.position = Vector3(0, 0, -0.006)
	screen.material_override = _mat(Color(0.4, 0.75, 1.0), Color(0.4, 0.8, 1.0), 3.0)
	root.add_child(screen)
	return root


## Telsiz: kısa antenli küçük kutu.
static func radio() -> Node3D:
	var root := Node3D.new()
	root.name = "Telsiz"
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.11, 0.035)
	body.mesh = box
	body.material_override = _mat(Color(0.12, 0.12, 0.12))
	root.add_child(body)
	var ant := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.006
	c.bottom_radius = 0.008
	c.height = 0.08
	ant.mesh = c
	ant.position = Vector3(0.018, 0.09, 0)
	ant.material_override = _mat(Color(0.1, 0.1, 0.1))
	root.add_child(ant)
	var led := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.006
	s.height = 0.012
	led.mesh = s
	led.position = Vector3(-0.015, 0.04, -0.019)
	led.material_override = _mat(Color(1, 0.2, 0.1), Color(1, 0.2, 0.1), 5.0)
	root.add_child(led)
	return root


## Kaynak kesicisi: metal sap ve mavi alev.
static func cutter() -> Node3D:
	var root := Node3D.new()
	root.name = "Kesici"
	var handle := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.018
	cyl.bottom_radius = 0.025
	cyl.height = 0.3
	handle.mesh = cyl
	handle.material_override = _mat(Color(0.35, 0.36, 0.4))
	root.add_child(handle)
	var tip := Node3D.new()
	tip.name = "Uc"
	tip.position = Vector3(0, 0.17, 0)
	root.add_child(tip)
	var flame := CPUParticles3D.new()
	flame.name = "Alev"
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fm.vertex_color_use_as_albedo = true
	q.material = fm
	flame.mesh = q
	flame.amount = 24
	flame.lifetime = 0.25
	flame.direction = Vector3(0, 1, 0)
	flame.spread = 8.0
	flame.initial_velocity_min = 0.6
	flame.initial_velocity_max = 1.0
	flame.gravity = Vector3.ZERO
	var g := Gradient.new()
	g.set_color(0, Color(0.8, 0.95, 1.0, 1.0))
	g.set_color(1, Color(0.1, 0.3, 1.0, 0.0))
	flame.color_ramp = g
	tip.add_child(flame)
	var l := OmniLight3D.new()
	l.name = "Isik"
	l.light_color = Color(0.4, 0.6, 1.0)
	l.light_energy = 1.6
	l.omni_range = 2.5
	tip.add_child(l)
	return root


## Bileğe takılan iletişim ekranı.
static func wrist_screen() -> Node3D:
	var root := Node3D.new()
	root.name = "BilekEkrani"
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.012, 0.045)
	mi.mesh = box
	mi.material_override = _mat(Color(0.4, 0.8, 1.0), Color(0.4, 0.85, 1.0), 5.0)
	root.add_child(mi)
	return root


# --- Kan (çizgi roman tarzı) ------------------------------------------------------

static var _blood_mat: StandardMaterial3D
static var _pool_mat: StandardMaterial3D


static func _blood_material() -> StandardMaterial3D:
	if _blood_mat == null:
		_blood_mat = StandardMaterial3D.new()
		_blood_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_blood_mat.albedo_color = Color(0.85, 0.04, 0.04)  # gece sahnesinde de seçilsin (ışıksız, parlak)
		_blood_mat.vertex_color_use_as_albedo = false
	return _blood_mat


## Darbe anında sıçrayan kan damlaları (tek seferlik, kendini siler). dir: sıçrama yönü.
static func blood_burst(parent: Node, at: Vector3, dir: Vector3 = Vector3.UP, amount: int = 26) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var drop := SphereMesh.new()
	drop.radius = 0.028
	drop.height = 0.056
	drop.radial_segments = 6
	drop.rings = 3
	drop.material = _blood_material()
	p.mesh = drop
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.92
	p.lifetime = 0.9
	p.direction = dir.normalized() if dir.length() > 0.01 else Vector3.UP
	p.spread = 38.0
	p.initial_velocity_min = 1.4
	p.initial_velocity_max = 3.2
	p.gravity = Vector3(0, -9.8, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.5
	p.local_coords = false
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## Yerde yavaşça büyüyen kan gölü (koyu, hafif parlak).
static func blood_pool(parent: Node, at: Vector3, radius: float = 0.45, grow_time: float = 6.0) -> MeshInstance3D:
	if _pool_mat == null:
		_pool_mat = StandardMaterial3D.new()
		_pool_mat.albedo_color = Color(0.42, 0.01, 0.01)
		_pool_mat.emission_enabled = true
		_pool_mat.emission = Color(0.12, 0.0, 0.0)
		_pool_mat.roughness = 0.15
		_pool_mat.metallic = 0.2
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 0.004
	cm.radial_segments = 20
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = _pool_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = Vector3(at.x, at.y, at.z)
	mi.scale = Vector3(0.05, 1, 0.05)
	var tw := mi.create_tween()
	tw.tween_property(mi, "scale", Vector3(radius, 1, radius * 0.8), grow_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return mi



## Yere sıçramış kan lekeleri (darbe anında, damlaların düştüğü yerde).
static func blood_splatter(parent: Node, at: Vector3, count: int = 5, spread: float = 0.35) -> void:
	for i in count:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 1.0
		cm.bottom_radius = 1.0
		cm.height = 0.003
		cm.radial_segments = 10
		cm.rings = 1
		mi.mesh = cm
		mi.material_override = _blood_material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		var r := randf_range(0.03, 0.09)
		mi.scale = Vector3(r, 1, r * randf_range(0.5, 1.0))
		mi.rotation.y = randf() * TAU
		mi.global_position = at + Vector3(randf_range(-spread, spread), 0.002 + i * 0.0004, randf_range(-spread, spread))


static var _smear_mats: Array[StandardMaterial3D] = []


## Yerde sürtünme izi / ellerdeki kan için koyu, parlak kırmızı.
static func smear_material(shade: int = 0) -> StandardMaterial3D:
	if _smear_mats.is_empty():
		for c in [Color(0.46, 0.02, 0.02), Color(0.36, 0.015, 0.015), Color(0.55, 0.04, 0.03)]:
			var m := StandardMaterial3D.new()
			m.albedo_color = c
			m.roughness = 0.15
			m.metallic_specular = 0.8
			_smear_mats.append(m)
	return _smear_mats[shade % _smear_mats.size()]


## Avuca/eklemlere bulaşmış kan (ele takılır).
static func hand_blood() -> Node3D:
	var root := Node3D.new()
	root.name = "ElKani"
	for i in 4:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 8
		sm.rings = 4
		mi.mesh = sm
		mi.material_override = smear_material()
		mi.scale = Vector3(0.028, 0.012, 0.035) * randf_range(0.8, 1.3)
		mi.position = Vector3(randf_range(-0.02, 0.02), 0.05 + i * 0.022, randf_range(0.0, 0.03))
		root.add_child(mi)
	return root
