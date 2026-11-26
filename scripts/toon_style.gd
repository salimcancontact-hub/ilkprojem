extends Node
## Çizgi roman stili (autoload "ToonStyle").
## Sahneye giren her modelin StandardMaterial3D malzemesini basamaklı gölgeli
## toon shader'a çevirir ve kontur geçişi ekler. Saydam ve ışıksız malzemelere dokunmaz.

const TOON_BACK := preload("res://shaders/toon_back.gdshader")
const TOON_DOUBLE := preload("res://shaders/toon_disabled.gdshader")
const OUTLINE := preload("res://shaders/outline.gdshader")

## Karakterlerin konturu çevreden biraz kalın olur.
@export var character_thickness: float = 2.4
@export var world_thickness: float = 1.6
var enabled: bool = true

var _cache: Dictionary = {}  # orijinal malzeme -> toon malzeme
var _outlines: Dictionary = {}


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if enabled and node is MeshInstance3D:
		# Diğer betikler kendi malzemelerini ayarladıktan sonra dönüştür.
		_convert.call_deferred(node)


func _convert(mesh_instance: MeshInstance3D) -> void:
	if not is_instance_valid(mesh_instance) or mesh_instance.mesh == null:
		return
	var thickness := character_thickness if mesh_instance.skeleton != NodePath() and mesh_instance.skin != null else world_thickness
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
