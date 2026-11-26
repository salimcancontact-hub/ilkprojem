class_name HoloCall
extends Node3D
## Görüntülü arama: telefonun üstünde, karşıdaki kişinin canlı hologramı.
## Karşıdaki karakter ayrı bir SubViewport dünyasında çizilir ve yarı saydam mavi bir yüzeye yansıtılır.

@export var caller_scene: PackedScene
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
	q.size = Vector2(0.24, 0.3)
	_quad.mesh = q
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _vp.get_texture()
	m.albedo_color = Color(0.7, 0.92, 1.0, 0.92)
	m.emission_enabled = true
	m.emission = Color(0.1, 0.25, 0.4)
	m.no_depth_test = false
	_quad.material_override = m
	add_child(_quad)
	# Hologramın mavi ışığı
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.45, 0.8, 1.0)
	glow.light_energy = 1.6
	glow.omni_range = 1.4
	add_child(glow)


func _process(delta: float) -> void:
	_t += delta
	# Hafif titreşim ve parlaklık dalgası: hologram hissi
	var m := _quad.material_override as StandardMaterial3D
	m.albedo_color.a = 0.82 + sin(_t * 23.0) * 0.05 + sin(_t * 3.1) * 0.05
	_quad.position.y = sin(_t * 2.0) * 0.004


## Konuşan karakterin el kol hareketi (konuşuyorsa Idle_Talking).
func set_talking(talking: bool) -> void:
	if caller:
		caller.play("Idle_Talking" if talking else "Idle", 0.3)
