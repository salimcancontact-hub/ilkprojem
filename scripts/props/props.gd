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
	box.size = Vector3(0.09, 0.006, 0.056)
	mi.mesh = box
	mi.material_override = _mat(Color(0.3, 0.7, 1.0), Color(0.3, 0.75, 1.0), 4.0)
	root.add_child(mi)
	var l := OmniLight3D.new()
	l.light_color = Color(0.3, 0.7, 1.0)
	l.light_energy = 0.7
	l.omni_range = 1.0
	root.add_child(l)
	return root


## Yarısı dolu plastik su şişesi.
static func water_bottle() -> Node3D:
	var root := Node3D.new()
	root.name = "SuSisesi"
	var body := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.032
	cyl.bottom_radius = 0.035
	cyl.height = 0.22
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
