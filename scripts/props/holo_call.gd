class_name HoloCall
extends Node3D
## Görüntülü arama: telefonun üstünde, karşıdaki kişinin canlı hologramı.
## Karşıdaki karakter ayrı bir SubViewport dünyasında çizilir ve yarı saydam mavi bir yüzeye yansıtılır.

@export var caller_scene: PackedScene
## Görüntünün üstünde yazan arayan adı (kimin aradığı net olsun).
@export var caller_name: String = ""
var caller: CharacterModel

var _vp: SubViewport
var _quad: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(240, 300)
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.85, 1.0)
	e.ambient_light_energy = 0.9
	env.environment = e
	_vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-25, 160, 0)
	key.light_energy = 1.2
	_vp.add_child(key)
	if caller_scene:
		caller = caller_scene.instantiate()
		caller.start_animation = "Idle_TalkingPhone"
		_vp.add_child(caller)
	var cam := Camera3D.new()
	cam.fov = 32.0
	_vp.add_child(cam)
	cam.position = Vector3(0.0, 1.5, -1.05)
	cam.look_at(Vector3(0.0, 1.45, 0.0))
	cam.current = true

	_quad = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.16, 0.2)
	_quad.mesh = q
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/hologram.gdshader")
	m.set_shader_parameter("feed", _vp.get_texture())
	_quad.material_override = m
	_quad.position = Vector3(0, 0.17, 0)
	add_child(_quad)
	if not caller_name.is_empty():
		var tag := Label3D.new()
		tag.text = caller_name + "  •  ARIYOR"
		tag.font_size = 40
		tag.pixel_size = 0.0007
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.modulate = Color(0.6, 0.92, 1.0)
		tag.outline_size = 8
		tag.outline_modulate = Color(0, 0.1, 0.2, 0.8)
		tag.position = Vector3(0, 0.06, 0)
		add_child(tag)
	# Telefondan görüntüye yükselen ışık huzmesi
	var beam := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.08
	cone.bottom_radius = 0.01
	cone.height = 0.08
	cone.radial_segments = 16
	cone.cap_top = false
	cone.cap_bottom = false
	beam.mesh = cone
	beam.position = Vector3(0, 0.04, 0)
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.albedo_color = Color(0.3, 0.75, 1.0, 0.35)
	beam.material_override = bm
	add_child(beam)
	# Hologramın mavi ışığı
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.45, 0.8, 1.0)
	glow.light_energy = 1.2
	glow.omni_range = 1.2
	add_child(glow)


func _process(delta: float) -> void:
	_t += delta
	# Hafif titreşim ve parlaklık dalgası: hologram hissi
	_quad.position.y = 0.17 + sin(_t * 2.0) * 0.003


## Konuşan karakterin el kol hareketi (konuşuyorsa Idle_Talking).
func set_talking(talking: bool) -> void:
	if caller:
		caller.play("Idle_Talking" if talking else "Idle", 0.3)
