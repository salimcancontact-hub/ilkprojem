extends Node
## Çizgi roman stili ve grafik kalitesi (autoload "ToonStyle").
## Sahneye giren her modelin StandardMaterial3D malzemesini basamaklı gölgeli
## toon shader'a çevirir ve kontur geçişi ekler. Saydam ve ışıksız malzemelere dokunmaz.

const TOON_BACK := preload("res://shaders/toon_back.gdshader")
const TOON_DOUBLE := preload("res://shaders/toon_disabled.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")

## Karakterlerin konturu çevreden biraz kalın olur.
@export var character_thickness: float = 2.4
@export var world_thickness: float = 1.6
var enabled: bool = true
## Zayıf ekran kartlarında açılır: gölge yok, daha az ışık/karakter, düşük çözünürlük.
var low_quality: bool = false
## "otomatik", "dusuk" veya "yuksek"
var quality_setting: String = "otomatik"

const SETTINGS_PATH := "user://ayarlar.cfg"
const WEAK_GPUS := ["PowerVR", "Mali-4", "Mali-T", "Mali-G31", "Mali-G51", "Mali-G52",
	"Adreno (TM) 3", "Adreno (TM) 4", "Adreno (TM) 50", "Adreno (TM) 51"]

var _cache: Dictionary = {}  # orijinal malzeme -> toon malzeme
var _outlines: Dictionary = {}


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		quality_setting = cfg.get_value("grafik", "kalite", "otomatik")
	_apply_quality_setting()
	get_tree().node_added.connect(_on_node_added)


func is_weak_gpu() -> bool:
	var gpu := RenderingServer.get_video_adapter_name()
	for name in WEAK_GPUS:
		if gpu.contains(name):
			return true
	return false


func set_quality(setting: String) -> void:
	quality_setting = setting
	var cfg := ConfigFile.new()
	cfg.set_value("grafik", "kalite", setting)
	cfg.save(SETTINGS_PATH)
	_apply_quality_setting()


func _apply_quality_setting() -> void:
	match quality_setting:
		"dusuk":
			low_quality = true
		"yuksek":
			low_quality = false
		_:
			low_quality = is_weak_gpu()
	get_tree().root.scaling_3d_scale = 0.7 if low_quality else 1.0


func quality_label() -> String:
	var name := "Düşük" if low_quality else "Yüksek"
	return "Grafik: %s%s" % [name, " (otomatik)" if quality_setting == "otomatik" else ""]


func _on_node_added(node: Node) -> void:
	if enabled and node is MeshInstance3D:
		# Diğer betikler kendi malzemelerini ayarladıktan sonra dönüştür.
		_convert.call_deferred(node)
	if low_quality:
		_reduce.call_deferred(node)


## Düşük kalitede ağır öğeleri kapatır. "detay" grubundakiler tamamen kaldırılır.
func _reduce(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.is_in_group("detay"):
		if node is Light3D:
			(node as Light3D).visible = false
		else:
			node.queue_free()
		return
	if node is Light3D:
		(node as Light3D).shadow_enabled = false
	elif node is CPUParticles3D and node.name == "Smoke":
		node.queue_free()
	elif node is WorldEnvironment and (node as WorldEnvironment).environment:
		var env: Environment = (node as WorldEnvironment).environment.duplicate()
		env.glow_enabled = false
		env.ambient_light_energy *= 1.7  # kapatılan süs ışıklarını telafi et
		(node as WorldEnvironment).environment = env


func _convert(mesh_instance: MeshInstance3D) -> void:
	if not is_instance_valid(mesh_instance) or mesh_instance.mesh == null:
		return
	var is_character := mesh_instance.skin != null
	var thickness := character_thickness if is_character else world_thickness
	if low_quality and not is_character:
		thickness = 0.0  # düşük kalitede çevrede kontur yok
	if mesh_instance.material_override:
		var m := _toon(mesh_instance.material_override, thickness)
		if m:
			mesh_instance.material_override = m
		return
	for i in mesh_instance.mesh.get_surface_count():
		var src := mesh_instance.get_surface_override_material(i)
		if src == null:
			src = mesh_instance.mesh.surface_get_material(i)
		if src == null:
			continue
		var m := _toon(src, thickness)
		if m:
			mesh_instance.set_surface_override_material(i, m)


func _toon(src: Material, thickness: float) -> Material:
	if not src is BaseMaterial3D:
		return null
	var key := "%d_%s" % [src.get_instance_id(), thickness]
	if _cache.has(key):
		return _cache[key]
	var b := src as BaseMaterial3D
	if b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
		_cache[key] = null
		return null
	var m := ShaderMaterial.new()
	m.shader = TOON_DOUBLE if b.cull_mode == BaseMaterial3D.CULL_DISABLED else TOON_BACK
	m.set_shader_parameter("albedo", b.albedo_color)
	if b.albedo_texture:
		m.set_shader_parameter("albedo_tex", b.albedo_texture)
		m.set_shader_parameter("use_albedo_tex", true)
	if b.emission_enabled:
		m.set_shader_parameter("emission", b.emission * b.emission_energy_multiplier)
		if b.emission_texture:
			m.set_shader_parameter("emission_tex", b.emission_texture)
			m.set_shader_parameter("use_emission_tex", true)
	if thickness > 0.0:
		m.next_pass = _outline(thickness)
	_cache[key] = m
	return m


func _outline(thickness: float) -> ShaderMaterial:
	if not _outlines.has(thickness):
		var o := ShaderMaterial.new()
		o.shader = OUTLINE
		o.set_shader_parameter("thickness", thickness)
		_outlines[thickness] = o
	return _outlines[thickness]
